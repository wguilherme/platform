ANSIBLE_DIR   := ansible
INVENTORY     := $(ANSIBLE_DIR)/inventory/hosts.yml
KUBECONFIG    := $(HOME)/.kube/local/platform/config.rpi
FLUX_PATH     := flux/clusters/homelab
GITHUB_USER   ?= wguilherme
GITHUB_REPO   ?= platform
GITHUB_BRANCH ?= main

export KUBECONFIG

# ─── Cores ────────────────────────────────────────────────────────────────────
CYAN  := \033[0;36m
RESET := \033[0m
info  = @printf "$(CYAN)→ %s$(RESET)\n" "$(1)"

.DEFAULT_GOAL := help

# ─── Help ─────────────────────────────────────────────────────────────────────
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ─── Ansible ──────────────────────────────────────────────────────────────────
.PHONY: ansible-deps
ansible-deps: ## Instala collections Ansible (requirements.yml)
	$(call info,Instalando collections Ansible)
	cd $(ANSIBLE_DIR) && ansible-galaxy collection install -r requirements.yml

.PHONY: ansible-ping
ansible-ping: ## Testa conectividade com todos os nós
	$(call info,Testando conectividade)
	cd $(ANSIBLE_DIR) && ansible all -i $(INVENTORY) -m ping

.PHONY: ansible-prepare
ansible-prepare: ## Prepara o OS de todos os nós (cgroups, swap, pacotes)
	$(call info,Preparando nós)
	cd $(ANSIBLE_DIR) && ansible-playbook site.yml -i $(INVENTORY) --tags prepare

.PHONY: ansible-k3s
ansible-k3s: ## Instala K3s no control-plane e workers
	$(call info,Instalando K3s)
	cd $(ANSIBLE_DIR) && ansible-playbook site.yml -i $(INVENTORY) --tags k3s-server,k3s-agent

.PHONY: ansible-cilium
ansible-cilium: ## Instala Cilium CNI
	$(call info,Instalando Cilium)
	cd $(ANSIBLE_DIR) && ansible-playbook site.yml -i $(INVENTORY) --tags cilium

.PHONY: ansible-all
ansible-all: ## Executa tudo: prepare → k3s → cilium
	$(call info,Provisionando cluster completo)
	cd $(ANSIBLE_DIR) && ansible-playbook site.yml -i $(INVENTORY)

# ─── Flux CD ──────────────────────────────────────────────────────────────────
.PHONY: flux-prereqs
flux-prereqs: ## Verifica pré-requisitos do Flux
	$(call info,Verificando pré-requisitos do Flux)
	flux check --pre

.PHONY: flux-bootstrap
flux-bootstrap: ## Faz bootstrap do Flux CD no cluster (requer GITHUB_TOKEN)
	$(call info,Fazendo bootstrap do Flux)
	flux bootstrap github \
		--owner=$(GITHUB_USER) \
		--repository=$(GITHUB_REPO) \
		--branch=$(GITHUB_BRANCH) \
		--path=homelab-v7/$(FLUX_PATH) \
		--personal \
		--components-extra=image-reflector-controller,image-automation-controller

.PHONY: flux-reconcile
flux-reconcile: ## Força reconciliação imediata de todos os recursos
	$(call info,Reconciliando Flux)
	flux reconcile source git flux-system
	flux reconcile kustomization flux-system
	flux reconcile kustomization infrastructure
	flux reconcile kustomization apps

.PHONY: flux-status
flux-status: ## Exibe status de todos os recursos Flux
	$(call info,Status do Flux)
	flux get all -A

.PHONY: flux-logs
flux-logs: ## Exibe logs dos controllers Flux
	$(call info,Logs do Flux)
	flux logs --all-namespaces --level=error

# ─── Cluster ──────────────────────────────────────────────────────────────────
.PHONY: nodes
nodes: ## Lista os nodes do cluster
	kubectl get nodes -o wide

.PHONY: cluster-status
cluster-status: ## Status geral do cluster
	$(call info,Status do cluster)
	@echo "\n=== Nodes ==="; kubectl get nodes -o wide
	@echo "\n=== Pods críticos ==="; kubectl get pods -A --field-selector=status.phase!=Running 2>/dev/null || true
	@echo "\n=== Flux ==="; flux get kustomizations -A

.PHONY: kubeconfig
kubeconfig: ## Exibe o caminho do kubeconfig atual
	@echo "KUBECONFIG=$(KUBECONFIG)"

# ─── Secrets ──────────────────────────────────────────────────────────────────
.PHONY: kubeseal-fetch-cert
kubeseal-fetch-cert: ## Busca o certificado público do Sealed Secrets controller
	$(call info,Buscando certificado do Sealed Secrets)
	kubeseal --fetch-cert \
		--controller-name=sealed-secrets-controller \
		--controller-namespace=kube-system \
		> sealed-secrets-cert.pem

.PHONY: kubeseal-secret
kubeseal-secret: ## Cria um SealedSecret (uso: make kubeseal-secret FILE=secret.yaml)
	$(call info,Criando SealedSecret de $(FILE))
	kubeseal --format yaml \
		--cert sealed-secrets-cert.pem \
		< $(FILE) > $(basename $(FILE)).sealed.yaml

# ─── Cloudflare Tunnel ────────────────────────────────────────────────────────
.PHONY: tunnel-secret
tunnel-secret: ## Cria o Secret do tunnel a partir de tunnel-creds.json (depois seele)
	$(call info,Criando Secret do Cloudflare Tunnel)
	kubectl create secret generic tunnel-credentials \
		--from-file=credentials.json=tunnel-creds.json \
		--dry-run=client -o yaml \
		| kubeseal --format yaml --cert sealed-secrets-cert.pem \
		> infrastructure/cloudflare-tunnel/tunnel-credentials.sealed.yaml

# ─── Observabilidade ──────────────────────────────────────────────────────────
.PHONY: grafana-password
grafana-password: ## Exibe a senha do admin do Grafana
	$(call info,Senha do Grafana)
	kubectl get secret -n monitoring kube-prometheus-stack-grafana \
		-o jsonpath="{.data.admin-password}" | base64 --decode && echo

.PHONY: cilium-status
cilium-status: ## Exibe status do Cilium e kube-proxy replacement
	$(call info,Status do Cilium)
	kubectl -n kube-system exec ds/cilium -- cilium-dbg status

# ─── Utilitários ──────────────────────────────────────────────────────────────
.PHONY: clean-kubeconfig
clean-kubeconfig: ## Remove kubeconfig local gerado pelo Ansible
	rm -f $(KUBECONFIG)

# ─── Tekton ───────────────────────────────────────────────────────────────────
TEKTON_PIPELINE_VERSION  ?= v1.10.2
TEKTON_TRIGGERS_VERSION  ?= v0.35.0
TEKTON_DASHBOARD_VERSION ?= v0.66.0

.PHONY: tekton-install
tekton-install: ## Instala Tekton Pipelines, Triggers e Dashboard via kubectl apply
	$(call info,Instalando Tekton Pipelines $(TEKTON_PIPELINE_VERSION))
	kubectl apply -f https://github.com/tektoncd/pipeline/releases/download/$(TEKTON_PIPELINE_VERSION)/release.yaml
	$(call info,Instalando Tekton Triggers $(TEKTON_TRIGGERS_VERSION))
	kubectl apply -f https://github.com/tektoncd/triggers/releases/download/$(TEKTON_TRIGGERS_VERSION)/release.yaml
	kubectl apply -f https://github.com/tektoncd/triggers/releases/download/$(TEKTON_TRIGGERS_VERSION)/interceptors.yaml
	$(call info,Instalando Tekton Dashboard $(TEKTON_DASHBOARD_VERSION))
	kubectl apply -f https://github.com/tektoncd/dashboard/releases/download/$(TEKTON_DASHBOARD_VERSION)/release.yaml

.PHONY: esp32-serial
esp32-serial: ## Lê a serial do ESP32 por 5s (valida firmware deployado)
	$(call info,Lendo serial do ESP32)
	ssh -i ~/.ssh/personal/wguilherme.dev.github wguilherme@10.3.152.16 \
		"stty -F /dev/ttyUSB0 115200 raw && timeout 5 dd if=/dev/ttyUSB0 bs=1 count=500 2>/dev/null | strings"

.PHONY: tekton-status
tekton-status: ## Verifica status dos pods do Tekton
	kubectl get pods -n tekton-pipelines
	kubectl get pods -n tekton-pipelines-resolvers 2>/dev/null || true

.PHONY: tekton-uninstall
tekton-uninstall: ## Remove o Tekton do cluster
	kubectl delete -f https://github.com/tektoncd/pipeline/releases/download/$(TEKTON_PIPELINE_VERSION)/release.yaml --ignore-not-found
	kubectl delete -f https://github.com/tektoncd/triggers/releases/download/$(TEKTON_TRIGGERS_VERSION)/release.yaml --ignore-not-found
	kubectl delete -f https://github.com/tektoncd/dashboard/releases/download/$(TEKTON_DASHBOARD_VERSION)/release.yaml --ignore-not-found

# ─── Automações (hack/automations/) ───────────────────────────────────────────
include hack/automations/sealed-secrets.mk
include hack/automations/kind.mk
