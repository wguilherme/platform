K3S_VERSION      ?= v1.36.1-k3s1
K3D_CLUSTER_NAME ?= homelab-k3d

.PHONY: k3d-up k3d-down k3d-restart kubeconfig-k3d k3d-status k3d-secrets k3d-bootstrap k3d-wait-controllers k3d-wait k3d-setup k3d-teardown

# ── Cluster ───────────────────────────────────────────────────────────────────

k3d-up:
	k3d cluster list | grep -q '^$(K3D_CLUSTER_NAME)' \
		&& echo "Cluster $(K3D_CLUSTER_NAME) já existe, pulando criação." \
		|| k3d cluster create $(K3D_CLUSTER_NAME) \
			--image rancher/k3s:$(K3S_VERSION) \
			--k3s-arg "--disable=traefik@server:0"
	$(MAKE) kubeconfig-k3d

kubeconfig-k3d:
	mkdir -p $(dir $(KUBECONFIG_PLATFORM))
	k3d kubeconfig get $(K3D_CLUSTER_NAME) > $(KUBECONFIG_PLATFORM)
	@echo "KUBECONFIG=$(KUBECONFIG_PLATFORM)"

k3d-down:
	k3d cluster delete $(K3D_CLUSTER_NAME)
	rm -f $(KUBECONFIG_PLATFORM)

k3d-restart: k3d-down k3d-up

k3d-status:
	$(KUBECTL) get nodes -o wide
	$(KUBECTL) get pods -A --field-selector=status.phase!=Running 2>/dev/null || true

# ── Secrets ───────────────────────────────────────────────────────────────────

k3d-secrets:
	$(KUBECTL) create namespace cloudflare --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) create namespace tekton-pipelines --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) create secret generic github-webhook-secret \
		--namespace tekton-pipelines \
		--from-literal=token=local-dev \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) create secret generic github-token \
		--namespace tekton-pipelines \
		--from-literal=token=$$(grep '^GITHUB_TOKEN=' .env | cut -d= -f2-) \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) create secret generic tunnel-token \
		--namespace cloudflare \
		--from-literal=token=$$(grep '^TUNNEL_TOKEN=' .env | cut -d= -f2-) \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -

# ── Flux ──────────────────────────────────────────────────────────────────────

k3d-bootstrap:
	$(FLUX) bootstrap github \
		--owner=$(GITHUB_USER) \
		--repository=$(GITHUB_REPO) \
		--branch=$(GITHUB_BRANCH) \
		--path=homelab-v8/flux/clusters/homelab \
		--personal \
		--token-auth \
		--timeout=10m \
		--components-extra=image-reflector-controller,image-automation-controller

# ── Espera ────────────────────────────────────────────────────────────────────

k3d-wait-controllers:
	@echo "→ Aguardando infrastructure-controllers..."
	until $(FLUX) get kustomization infrastructure-controllers 2>/dev/null | grep -q "True"; do sleep 5; done
	@echo "✓ infrastructure-controllers pronto"

k3d-wait:
	@echo "→ Aguardando infrastructure (pode levar até 20m — Tekton + health checks)..."
	until $(FLUX) get kustomization infrastructure 2>/dev/null | grep -q "True"; do \
		$(FLUX) get kustomization infrastructure 2>/dev/null | grep -v "^NAME" || true; \
		sleep 10; \
	done
	@echo "✓ infrastructure pronto"

# ── Setup/Teardown completo ───────────────────────────────────────────────────

k3d-setup: k3d-up k3d-secrets k3d-bootstrap k3d-wait-controllers k3d-wait
	@echo ""
	@echo "✓ k3d setup completo (K3s $(K3S_VERSION))."

k3d-teardown: k3d-down
