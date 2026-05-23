ZOT_LOCAL_PORT ?= 5000

.PHONY: tekton-build-push tekton-run tekton-logs tekton-dashboard

# ── Build e push manual para Zot local ───────────────────────────────────────

tekton-build-push:
	docker build -t localhost:$(ZOT_LOCAL_PORT)/go-hello:test \
		homelab-v8/apps/go-hello/src/
	docker push localhost:$(ZOT_LOCAL_PORT)/go-hello:test

# ── TaskRun manual (dispara CI sem webhook GitHub) ────────────────────────────

tekton-run:
	$(KUBECTL) create -f - <<'EOF'
	apiVersion: tekton.dev/v1
	kind: TaskRun
	metadata:
	  generateName: go-hello-ci-manual-
	  namespace: tekton-pipelines
	spec:
	  taskRef:
	    name: go-hello-ci
	  params:
	    - name: image-repo
	      value: localhost:$(ZOT_LOCAL_PORT)/go-hello
	  workspaces:
	    - name: source
	      emptyDir: {}
	EOF

tekton-logs:
	$(KUBECTL) get taskruns -n tekton-pipelines
	$(KUBECTL) logs -n tekton-pipelines -l tekton.dev/taskRun --tail=50 -f 2>/dev/null || true

tekton-dashboard:
	@echo "→ Tekton Dashboard em http://localhost:9097"
	$(KUBECTL) port-forward svc/tekton-dashboard 9097:9097 -n tekton-pipelines
