GITHUB_USER   ?= wguilherme
GITHUB_REPO   ?= platform
GITHUB_BRANCH ?= main

.PHONY: flux-bootstrap flux-reconcile flux-status

flux-bootstrap:
	KUBECONFIG=$(KUBECONFIG_KIND) flux bootstrap github \
		--owner=$(GITHUB_USER) \
		--repository=$(GITHUB_REPO) \
		--branch=$(GITHUB_BRANCH) \
		--path=homelab-v8/flux/clusters/homelab \
		--personal \
		--components-extra=image-reflector-controller,image-automation-controller

flux-reconcile:
	$(FLUX) reconcile kustomization flux-system --with-source
	$(FLUX) reconcile kustomization infrastructure-controllers --with-source
	$(FLUX) reconcile kustomization infrastructure --with-source
	$(FLUX) reconcile kustomization apps --with-source

flux-status:
	$(FLUX) get kustomizations -A
	$(FLUX) get helmreleases -A
