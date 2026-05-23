.PHONY: apps-status apps-restart go-hello-status bun-hello-status python-hello-status

# ── Status geral ──────────────────────────────────────────────────────────────

apps-status:
	$(KUBECTL) get pods,svc,ingress -n default

# ── Por app ───────────────────────────────────────────────────────────────────

go-hello-status:
	$(KUBECTL) get pods,svc,ingress -l app=go-hello -n default

bun-hello-status:
	$(KUBECTL) get pods,svc,ingress -l app=bun-hello -n default

python-hello-status:
	$(KUBECTL) get pods,svc,ingress -l app=python-hello -n default

# ── Restart (força pull da imagem mais nova) ──────────────────────────────────

apps-restart:
	$(KUBECTL) rollout restart deployment/go-hello deployment/bun-hello deployment/python-hello -n default

# ── CI TaskRuns (histórico recente) ──────────────────────────────────────────

ci-status:
	$(KUBECTL) get taskruns -n tekton-pipelines --sort-by=.metadata.creationTimestamp | tail -20

ci-logs:
	$(KUBECTL) logs -n tekton-pipelines -l tekton.dev/task --tail=100 -f
