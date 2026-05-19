# ── Flux helpers (K3s produção) ───────────────────────────────────────────────
# Uso: make -f homelab-v8/hack/automations/flux.mk <target>
#
# Pré-requisitos:
#   - KUBECONFIG apontando para o cluster K3s
#   - GITHUB_TOKEN exportado
#   - flux CLI instalado

GITHUB_USER   ?= wguilherme
GITHUB_REPO   ?= platform
GITHUB_BRANCH ?= main

.PHONY: flux-bootstrap flux-reconcile flux-status

flux-bootstrap:
	flux bootstrap github \
		--owner=$(GITHUB_USER) \
		--repository=$(GITHUB_REPO) \
		--branch=$(GITHUB_BRANCH) \
		--path=homelab-v8/flux/clusters/homelab \
		--personal \
		--components-extra=image-reflector-controller,image-automation-controller

flux-reconcile:
	flux reconcile kustomization flux-system --with-source
	flux reconcile kustomization infrastructure-controllers --with-source
	flux reconcile kustomization infrastructure --with-source
	flux reconcile kustomization apps --with-source

flux-status:
	flux get kustomizations -A
	flux get helmreleases -A
