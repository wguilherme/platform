CLUSTER_NAME      ?= homelab-v8
KUBECONFIG_KIND   := $(HOME)/.kube/kind-$(CLUSTER_NAME)
KIND_CONFIG       := $(AUTOMATIONS_DIR)kind-config.yaml
KUBECTL           = KUBECONFIG=$(KUBECONFIG_KIND) kubectl
FLUX              = KUBECONFIG=$(KUBECONFIG_KIND) flux

.PHONY: kind-up kind-down kind-restart kind-status

kind-up:
	kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)
	kind get kubeconfig --name $(CLUSTER_NAME) > $(KUBECONFIG_KIND)
	@echo "KUBECONFIG=$(KUBECONFIG_KIND)"

kind-down:
	kind delete cluster --name $(CLUSTER_NAME)
	rm -f $(KUBECONFIG_KIND)

kind-restart: kind-down kind-up

kind-status:
	$(KUBECTL) get nodes -o wide
	$(KUBECTL) get pods -A --field-selector=status.phase!=Running 2>/dev/null || true
