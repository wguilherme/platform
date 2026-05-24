GITHUB_USER   ?= wguilherme
GITHUB_REPO   ?= platform
GITHUB_BRANCH ?= main

.PHONY: flux-bootstrap flux-reconcile flux-status flux-check

flux-bootstrap:
	$(FLUX) bootstrap github \
		--owner=$(GITHUB_USER) \
		--repository=$(GITHUB_REPO) \
		--branch=$(GITHUB_BRANCH) \
		--path=homelab-v8/flux/clusters/homelab \
		--personal \
		--token-auth \
		--timeout=20m \
		--components-extra=image-reflector-controller,image-automation-controller

flux-reconcile:
	$(FLUX) reconcile kustomization flux-system --with-source
	$(FLUX) reconcile kustomization infrastructure-controllers --with-source
	$(FLUX) reconcile kustomization infrastructure --with-source
	$(FLUX) reconcile kustomization apps --with-source

flux-status:
	$(FLUX) get kustomizations -A
	$(FLUX) get helmreleases -A

flux-check:
	@echo "=== Kustomizations ==="
	@$(FLUX) get kustomizations -A
	@echo ""
	@echo "=== HelmReleases ==="
	@$(FLUX) get helmreleases -A
	@echo ""
	@echo "=== Infrastructure ready? ==="
	@$(FLUX) get kustomization infrastructure 2>/dev/null | grep -q "True" \
		&& echo "✓ infrastructure True — wait concluído" \
		|| echo "✗ infrastructure ainda não pronta"
	@echo ""
	@echo "=== Infrastructure — último evento ==="
	@$(KUBECTL) get kustomization infrastructure -n flux-system -o jsonpath='{range .status.conditions[*]}{.type}: {.message}{"\n"}{end}' 2>/dev/null || true
	@echo ""
	@echo "=== Pods não prontos ==="
	@$(KUBECTL) get pods -A | grep -v "Running\|Completed\|NAME" || echo "todos prontos"
