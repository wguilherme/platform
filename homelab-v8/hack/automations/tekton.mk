ZOT_LOCAL_PORT ?= 5000

.PHONY: tekton-build-push tekton-run tekton-logs tekton-dashboard

# ── Build e push manual para Zot local ───────────────────────────────────────

tekton-build-push:
	docker build -t localhost:$(ZOT_LOCAL_PORT)/go-hello:test \
		homelab-v8/apps/go-hello/src/
	docker push localhost:$(ZOT_LOCAL_PORT)/go-hello:test

# ── TaskRun manual (dispara CI sem webhook GitHub) ────────────────────────────

tekton-run:
	@for app in go-hello bun-hello python-hello dotnet-hello; do \
		printf 'apiVersion: tekton.dev/v1\nkind: TaskRun\nmetadata:\n  generateName: %s-ci-manual-\n  namespace: tekton-pipelines\nspec:\n  taskRef:\n    name: %s-ci\n  params:\n  - name: image-repo\n    value: registry.wguilherme.com/%s\n  workspaces:\n  - name: source\n    emptyDir: {}\n' $$app $$app $$app \
			| $(KUBECTL) create -f -; \
	done

tekton-logs:
	$(KUBECTL) get taskruns -n tekton-pipelines
	$(KUBECTL) logs -n tekton-pipelines -l tekton.dev/taskRun --tail=50 -f 2>/dev/null || true

tekton-dashboard:
	@echo "→ Tekton Dashboard em http://localhost:9097"
	$(KUBECTL) port-forward svc/tekton-dashboard 9097:9097 -n tekton-pipelines

