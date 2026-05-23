ZOT_PORT      ?= 5000
GO_HELLO_PORT ?= 8082
BUN_HELLO_PORT ?= 8083
PYTHON_HELLO_PORT ?= 8084

.PHONY: test-zot test-go-hello test-bun-hello test-python-hello test-all

# ── Zot registry ─────────────────────────────────────────────────────────────

test-zot:
	@echo "→ Zot registry em http://localhost:$(ZOT_PORT)"
	$(KUBECTL) port-forward svc/zot $(ZOT_PORT):5000 -n zot &
	sleep 2 && curl -s http://localhost:$(ZOT_PORT)/v2/

# ── go-hello ─────────────────────────────────────────────────────────────────

test-go-hello:
	@echo "→ go-hello em http://localhost:$(GO_HELLO_PORT)"
	$(KUBECTL) port-forward svc/go-hello $(GO_HELLO_PORT):80 -n default &
	sleep 2 && curl -s http://localhost:$(GO_HELLO_PORT)

# ── bun-hello ─────────────────────────────────────────────────────────────────

test-bun-hello:
	@echo "→ bun-hello em http://localhost:$(BUN_HELLO_PORT)"
	$(KUBECTL) port-forward svc/bun-hello $(BUN_HELLO_PORT):80 -n default &
	sleep 2 && curl -s http://localhost:$(BUN_HELLO_PORT)

# ── python-hello ──────────────────────────────────────────────────────────────

test-python-hello:
	@echo "→ python-hello em http://localhost:$(PYTHON_HELLO_PORT)"
	$(KUBECTL) port-forward svc/python-hello $(PYTHON_HELLO_PORT):80 -n default &
	sleep 2 && curl -s http://localhost:$(PYTHON_HELLO_PORT)

# ── Tudo ──────────────────────────────────────────────────────────────────────

test-all: test-go-hello test-bun-hello test-python-hello
