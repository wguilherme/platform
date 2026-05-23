CLUSTER_NAME        ?= homelab-v8
KUBECONFIG_PLATFORM ?= $(HOME)/.kube/local/platform/config.platform
KIND_CONFIG         := $(AUTOMATIONS_DIR)kind-config.yaml
KUBECTL              = KUBECONFIG=$(KUBECONFIG_PLATFORM) kubectl
FLUX                 = KUBECONFIG=$(KUBECONFIG_PLATFORM) flux

.PHONY: kind-up kind-down kind-restart kind-status kind-kubeconfig kind-secrets kind-wait-controllers kind-wait

# ── Cluster ───────────────────────────────────────────────────────────────────

kind-up:
	kind get clusters | grep -q '^$(CLUSTER_NAME)$$' \
		&& echo "Cluster $(CLUSTER_NAME) já existe, pulando criação." \
		|| kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)
	$(MAKE) kind-kubeconfig

kind-kubeconfig:
	mkdir -p $(dir $(KUBECONFIG_KIND))
	kind get kubeconfig --name $(CLUSTER_NAME) > $(KUBECONFIG_KIND)
	@echo "KUBECONFIG=$(KUBECONFIG_KIND)"

kind-down:
	kind delete cluster --name $(CLUSTER_NAME)
	rm -f $(KUBECONFIG_KIND)

kind-restart: kind-down kind-up

kind-status:
	$(KUBECTL) get nodes -o wide
	$(KUBECTL) get pods -A --field-selector=status.phase!=Running 2>/dev/null || true

# ── Secrets (plain — sem kubeseal, apenas Kind local) ─────────────────────────

kind-secrets:
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

# ── Espera ────────────────────────────────────────────────────────────────────

kind-wait-controllers:
	@echo "→ Aguardando infrastructure-controllers..."
	until $(FLUX) get kustomization infrastructure-controllers 2>/dev/null | grep -q "True"; do sleep 5; done
	@echo "✓ infrastructure-controllers pronto"

kind-wait:
	@echo "→ Aguardando infrastructure (pode levar até 10m — Tekton + health checks)..."
	until $(FLUX) get kustomization infrastructure 2>/dev/null | grep -q "True"; do \
		$(FLUX) get kustomization infrastructure 2>/dev/null | grep -v "^NAME" || true; \
		sleep 10; \
	done
	@echo "✓ infrastructure pronto"
	@echo "ℹ apps ficam prontos após o primeiro CI build (make ci-status)"
