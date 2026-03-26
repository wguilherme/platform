# ── Sealed Secrets ────────────────────────────────────────────────────────────
# Uso: make -f hack/automations/sealed-secrets.mk <target>
#
# Pré-requisitos:
#   - kubeseal instalado (brew install kubeseal)
#   - KUBECONFIG apontando para o cluster (export KUBECONFIG=./kubeconfig)
#   - sealed-secrets-controller rodando no cluster

KUBECONFIG         ?= $(shell pwd)/kubeconfig
KUBESEAL           = kubeseal --controller-name sealed-secrets-controller \
                              --controller-namespace kube-system \
                              --format yaml
INFRA_DIR          = infrastructure
SEALED_SECRETS_DIR = $(INFRA_DIR)/sealed-secrets

.PHONY: seal-tunnel seal-tunnel-from-token seal-check kubeseal-check

# ── Cloudflare Tunnel ──────────────────────────────────────────────────────────

# Sela as credenciais do Cloudflare Tunnel a partir de um arquivo JSON.
# Uso: make -f hack/automations/sealed-secrets.mk seal-tunnel CREDS_FILE=/path/to/creds.json
#
# O arquivo JSON deve seguir o formato:
#   { "AccountTag": "...", "TunnelID": "...", "TunnelSecret": "..." }
#
# Para obter o JSON de um tunnel existente:
#   cloudflared tunnel token --cred-file /tmp/creds.json <TUNNEL_ID>
#
seal-tunnel: kubeseal-check
ifndef CREDS_FILE
	$(error CREDS_FILE não definido. Uso: make seal-tunnel CREDS_FILE=/tmp/tunnel-creds.json)
endif
	@echo "Selando credenciais do Cloudflare Tunnel..."
	@KUBECONFIG=$(KUBECONFIG) kubectl create secret generic tunnel-credentials \
		--from-file=credentials.json=$(CREDS_FILE) \
		--namespace default \
		--dry-run=client -o yaml 2>/dev/null | \
	$(KUBESEAL) \
		> $(INFRA_DIR)/cloudflare-tunnel/sealed-secret.yaml
	@echo "Selado em: $(INFRA_DIR)/cloudflare-tunnel/sealed-secret.yaml"
	@echo "Commit e push para ativar: git add $(INFRA_DIR)/cloudflare-tunnel/sealed-secret.yaml && git push"

# Sela as credenciais do Cloudflare Tunnel a partir do token JWT gerado pelo painel.
# Uso: make -f hack/automations/sealed-secrets.mk seal-tunnel-from-token TOKEN=eyJ...
#
# O token é gerado no painel: Zero Trust → Networks → Tunnels → Create → Docker command
#
seal-tunnel-from-token: kubeseal-check
ifndef TOKEN
	$(error TOKEN não definido. Uso: make seal-tunnel-from-token TOKEN=eyJ...)
endif
	@echo "Decodificando token e gerando credentials.json..."
	@echo "$(TOKEN)" | base64 -d | python3 -c " \
import sys, json; \
d = json.load(sys.stdin); \
creds = json.dumps({'AccountTag': d['a'], 'TunnelID': d['t'], 'TunnelSecret': d['s']}); \
open('/tmp/_tunnel-creds.json', 'w').write(creds)" 2>/dev/null || \
	(echo "$(TOKEN)" | python3 -c " \
import sys, json, base64; \
raw = sys.stdin.read().strip(); \
padded = raw + '=' * (-len(raw) % 4); \
d = json.loads(base64.b64decode(padded)); \
creds = json.dumps({'AccountTag': d['a'], 'TunnelID': d['t'], 'TunnelSecret': d['s']}); \
open('/tmp/_tunnel-creds.json', 'w').write(creds)")
	@echo "Selando..."
	@cat /tmp/_tunnel-creds.json | python3 -c "import sys,json; d=json.load(sys.stdin); print('TunnelID:', d['TunnelID'])"
	@KUBECONFIG=$(KUBECONFIG) kubectl create secret generic tunnel-credentials \
		--from-file=credentials.json=/tmp/_tunnel-creds.json \
		--namespace default \
		--dry-run=client -o yaml 2>/dev/null | \
	$(KUBESEAL) \
		> $(INFRA_DIR)/cloudflare-tunnel/sealed-secret.yaml
	@rm -f /tmp/_tunnel-creds.json
	@echo "Selado em: $(INFRA_DIR)/cloudflare-tunnel/sealed-secret.yaml"
	@echo "Commit e push: git add $(INFRA_DIR)/cloudflare-tunnel/sealed-secret.yaml && git push"

# ── Utilitários ───────────────────────────────────────────────────────────────

# Verifica se o sealed-secrets controller está rodando
seal-check:
	@KUBECONFIG=$(KUBECONFIG) kubectl get pods -n kube-system \
		-l app.kubernetes.io/name=sealed-secrets \
		--no-headers 2>&1 | grep -q Running && \
	echo "sealed-secrets-controller: Running" || \
	echo "sealed-secrets-controller: NOT RUNNING"

kubeseal-check:
	@which kubeseal > /dev/null 2>&1 || (echo "kubeseal não encontrado. Instale: brew install kubeseal" && exit 1)
