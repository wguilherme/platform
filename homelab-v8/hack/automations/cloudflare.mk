CLOUDFLARE_NS      ?= cloudflare
CLOUDFLARE_CHART   ?= cloudflare/cloudflare-tunnel-remote
CLOUDFLARE_RELEASE ?= cloudflare-tunnel

.PHONY: cloudflare-setup cloudflare-install cloudflare-secret cloudflare-status cloudflare-logs cloudflare-uninstall

# ── Setup completo (repo + secret + install) ──────────────────────────────────

cloudflare-setup: cloudflare-repo cloudflare-secret cloudflare-install

# ── Helm repo ─────────────────────────────────────────────────────────────────

cloudflare-repo:
	helm repo add cloudflare https://cloudflare.github.io/helm-charts
	helm repo update cloudflare

# ── Namespace + Secret ────────────────────────────────────────────────────────

cloudflare-secret:
	$(KUBECTL) create namespace $(CLOUDFLARE_NS) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	$(KUBECTL) create secret generic tunnel-token \
		--namespace $(CLOUDFLARE_NS) \
		--from-literal=token="$(TUNNEL_TOKEN)" \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -

# ── Helm install ──────────────────────────────────────────────────────────────

cloudflare-install:
	KUBECONFIG=$(KUBECONFIG_PLATFORM) helm upgrade --install $(CLOUDFLARE_RELEASE) $(CLOUDFLARE_CHART) \
		--namespace $(CLOUDFLARE_NS) \
		--set cloudflare.tunnel_token="$(TUNNEL_TOKEN)" \
		--wait

# ── Observabilidade ───────────────────────────────────────────────────────────

cloudflare-status:
	$(KUBECTL) get pods -n $(CLOUDFLARE_NS)

cloudflare-logs:
	$(KUBECTL) logs -n $(CLOUDFLARE_NS) \
		-l app.kubernetes.io/name=cloudflare-tunnel-remote \
		--tail=50 -f

# ── Teardown ──────────────────────────────────────────────────────────────────

cloudflare-uninstall:
	KUBECONFIG=$(KUBECONFIG_PLATFORM) helm uninstall $(CLOUDFLARE_RELEASE) --namespace $(CLOUDFLARE_NS) 2>/dev/null || true
	$(KUBECTL) delete namespace $(CLOUDFLARE_NS) --ignore-not-found
