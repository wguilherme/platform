# ── Kind (ambiente local de teste) ────────────────────────────────────────────
# Uso: make -f homelab-v8/hack/automations/kind.mk <target>
#
# Pré-requisitos:
#   - kind, kubectl, flux CLI instalados
#   - GITHUB_TOKEN exportado (para Flux bootstrap)
#
# Fluxo completo:
#   make -f homelab-v8/hack/automations/kind.mk kind

CLUSTER_NAME  ?= homelab-v8
KUBECONFIG_KIND := $(HOME)/.kube/kind-$(CLUSTER_NAME)
KUBECTL       = KUBECONFIG=$(KUBECONFIG_KIND) kubectl
HELM          = KUBECONFIG=$(KUBECONFIG_KIND) helm
FLUX          = KUBECONFIG=$(KUBECONFIG_KIND) flux
GITHUB_USER   ?= wguilherme
GITHUB_REPO   ?= platform
GITHUB_BRANCH ?= main
KIND_CONFIG   := $(dir $(lastword $(MAKEFILE_LIST)))kind-config.yaml

.PHONY: kind kind-up kind-down kind-flux-bootstrap kind-status kind-clean

kind: kind-up kind-flux-bootstrap
	@echo "✓ Cluster pronto. Rode: make -f ... kind-status"

kind-up:
	@echo "→ Criando cluster kind: $(CLUSTER_NAME)"
	kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)
	kind get kubeconfig --name $(CLUSTER_NAME) > $(KUBECONFIG_KIND)
	@echo "→ Instalando ingress-nginx no kind"
	$(KUBECTL) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	$(KUBECTL) rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s

kind-flux-bootstrap:
	@echo "→ Bootstrap Flux CD"
	KUBECONFIG=$(KUBECONFIG_KIND) flux bootstrap github \
		--owner=$(GITHUB_USER) \
		--repository=$(GITHUB_REPO) \
		--branch=$(GITHUB_BRANCH) \
		--path=homelab-v8/flux/clusters/homelab \
		--personal \
		--components-extra=image-reflector-controller,image-automation-controller

kind-status:
	@echo "=== Nodes ===" && $(KUBECTL) get nodes -o wide
	@echo "\n=== Flux ===" && $(FLUX) get all -A 2>/dev/null || echo "(Flux não instalado)"
	@echo "\n=== Pods não Running ===" && $(KUBECTL) get pods -A --field-selector=status.phase!=Running 2>/dev/null || true

kind-down:
	kind delete cluster --name $(CLUSTER_NAME)
	rm -f $(KUBECONFIG_KIND)

kind-clean: kind-down
