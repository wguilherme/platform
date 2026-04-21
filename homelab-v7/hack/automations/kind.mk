# ── Kind (ambiente local de teste) ────────────────────────────────────────────
# Uso: make -f homelab-v7/hack/automations/kind.mk <target>
#
# Pré-requisitos:
#   - kind, kubectl, helm, flux CLI instalados
#   - CLAUDE_OAUTH_TOKEN, GITHUB_CLIENT_ID/SECRET, JIRA_CLIENT_ID/SECRET exportados
#   - Para Flux bootstrap: GITHUB_TOKEN exportado
#
# Fluxo completo:
#   make -f ... kind-up
#   make -f ... kind-flux-bootstrap
#   make -f ... kind-secrets
#   make -f ... kind-status

CLUSTER_NAME  ?= homelab-v7
KUBECONFIG_KIND := $(HOME)/.kube/kind-$(CLUSTER_NAME)
KUBECTL       = KUBECONFIG=$(KUBECONFIG_KIND) kubectl
HELM          = KUBECONFIG=$(KUBECONFIG_KIND) helm
FLUX          = KUBECONFIG=$(KUBECONFIG_KIND) flux
GITHUB_USER   ?= wguilherme
GITHUB_REPO   ?= platform
GITHUB_BRANCH ?= main

.PHONY: kind-up kind-down kind-flux-bootstrap kind-secrets kind-status kind-coder-forward kind-clean

KIND_CONFIG := $(dir $(lastword $(MAKEFILE_LIST)))kind-config.yaml

# Cria o cluster Kind com ingress-nginx habilitado
kind-up:
	@echo "→ Criando cluster kind: $(CLUSTER_NAME)"
	kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)
	kind get kubeconfig --name $(CLUSTER_NAME) > $(KUBECONFIG_KIND)
	@echo "→ KUBECONFIG: $(KUBECONFIG_KIND)"
	@echo "→ Instalando ingress-nginx no kind"
	$(KUBECTL) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@echo "→ Aguardando ingress-nginx ficar pronto..."
	$(KUBECTL) rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s

# Remove o cluster Kind
kind-down:
	@echo "→ Removendo cluster kind: $(CLUSTER_NAME)"
	kind delete cluster --name $(CLUSTER_NAME)
	rm -f $(KUBECONFIG_KIND)

ENV_FILE := $(shell git rev-parse --show-toplevel)/homelab-v7/.env

# Bootstrap do Flux CD apontando para homelab-v7/
kind-flux-bootstrap:
	@echo "→ Bootstrap Flux CD no kind"
	@set -a && . $(ENV_FILE) && set +a && KUBECONFIG=$(KUBECONFIG_KIND) flux bootstrap github \
		--owner=$(GITHUB_USER) \
		--repository=$(GITHUB_REPO) \
		--branch=$(GITHUB_BRANCH) \
		--path=homelab-v7/flux/clusters/homelab \
		--personal \
		--components-extra=image-reflector-controller,image-automation-controller

# Cria os secrets necessários em plain text (sem kubeseal — apenas para kind/local)
kind-secrets:
	@set -a && . $(ENV_FILE) && set +a && \
	echo "→ Criando namespaces" && \
	$(KUBECTL) create namespace coder --dry-run=client -o yaml | $(KUBECTL) apply -f - && \
	$(KUBECTL) create namespace postgresql-coder --dry-run=client -o yaml | $(KUBECTL) apply -f - && \
	echo "→ Criando secret do banco PostgreSQL" && \
	$(KUBECTL) create secret generic postgresql-coder-credentials \
		--namespace postgresql-coder \
		--from-literal=postgres-password="$$DB_PASSWORD" \
		--from-literal=password="$$DB_PASSWORD" \
		--dry-run=client -o yaml | $(KUBECTL) apply -f - && \
	echo "→ Criando secret da connection string do Coder" && \
	$(KUBECTL) create secret generic coder-db-url \
		--namespace coder \
		--from-literal=url="postgres://coder:$$DB_PASSWORD@postgresql-coder-postgresql.postgresql-coder.svc.cluster.local:5432/coder?sslmode=disable" \
		--dry-run=client -o yaml | $(KUBECTL) apply -f - && \
	echo "→ Criando secret do Claude OAuth" && \
	$(KUBECTL) create secret generic claude-oauth \
		--namespace coder \
		--from-literal=token="$$CLAUDE_OAUTH_TOKEN" \
		--dry-run=client -o yaml | $(KUBECTL) apply -f - && \
	echo "→ Criando secret GitHub OAuth" && \
	$(KUBECTL) create secret generic coder-github-oauth \
		--namespace coder \
		--from-literal=client-id="$$GITHUB_CLIENT_ID" \
		--from-literal=client-secret="$$GITHUB_CLIENT_SECRET" \
		--dry-run=client -o yaml | $(KUBECTL) apply -f - && \
	echo "→ Criando secret Jira OAuth" && \
	$(KUBECTL) create secret generic coder-jira-oauth \
		--namespace coder \
		--from-literal=client-id="$$JIRA_CLIENT_ID" \
		--from-literal=client-secret="$$JIRA_CLIENT_SECRET" \
		--dry-run=client -o yaml | $(KUBECTL) apply -f - && \
	echo "✓ Secrets criados"

# Status geral do ambiente kind
kind-status:
	@echo "=== Nodes ==="
	$(KUBECTL) get nodes -o wide
	@echo "\n=== Flux ==="
	$(FLUX) get all -A 2>/dev/null || echo "(Flux ainda não instalado)"
	@echo "\n=== Pods (não Running) ==="
	$(KUBECTL) get pods -A --field-selector=status.phase!=Running 2>/dev/null || true
	@echo "\n=== Coder ==="
	$(KUBECTL) get pods -n coder 2>/dev/null || echo "(namespace coder não existe)"

# Port-forward do Coder para acesso local em localhost:8080
kind-coder-forward:
	@echo "→ Acessar Coder em http://localhost:8080"
	$(KUBECTL) port-forward svc/coder -n coder 8080:80

# Remove tudo (cluster + kubeconfig)
kind-clean: kind-down
