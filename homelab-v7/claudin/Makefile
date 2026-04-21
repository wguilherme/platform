.PHONY: help setup setup-discord setup-ssh deps loop-deps install start start-loop start-pi stop-pi test-webhook test-heartbeat test-watchdog test-mcp test-loop logs status last-heartbeat activity

CLAUDIN_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PROJECT_DIR := $(shell dirname $(CLAUDIN_DIR))

help: ## Mostra este menu
	@echo ""
	@echo "  Claudin — Comandos disponíveis"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

# ── Setup ─────────────────────────────────────────────────────────────────────

setup: deps setup-discord ## Setup completo (deps + Discord plugin) — idempotente

setup-discord: ## Configura Discord plugin (instala, token, pareamento) — pula o que já foi feito
	@bash $(CLAUDIN_DIR)/scripts/setup-discord.sh

setup-ssh: ## Configura chave SSH para Git
	@bash $(CLAUDIN_DIR)/scripts/setup-ssh.sh

deps: loop-deps ## Instala todas as dependências (MCP server + Agent SDK)
	@cd $(CLAUDIN_DIR)/channels && bun install --silent
	@echo "✓ Dependências instaladas"

loop-deps: ## Instala @anthropic-ai/claude-agent-sdk
	@cd $(CLAUDIN_DIR) && bun add @anthropic-ai/claude-agent-sdk --silent
	@echo "✓ Agent SDK instalado"

install: ## Instalação completa para servidor (systemd + serviços)
	@bash $(CLAUDIN_DIR)/scripts/install.sh

# ── Iniciar ───────────────────────────────────────────────────────────────────

start-loop: ## Inicia o agent-loop.ts  (TASK_PROVIDER=markdown|trello|mcp-jira, default: do .env)
	@set -a && source $(CLAUDIN_DIR)/.env && set +a && \
	cd $(PROJECT_DIR) && TASK_PROVIDER=$${TASK_PROVIDER:-markdown} bun run $(CLAUDIN_DIR)/src/main.ts

test-loop: ## Dry-run de um ciclo (TASK_PROVIDER=markdown|trello|mcp-jira, default: do .env)
	@set -a && source $(CLAUDIN_DIR)/.env && set +a && \
	cd $(PROJECT_DIR) && DRY_RUN=1 MAX_TURNS_PER_TASK=5 SLEEP_BETWEEN_CYCLES_MS=2000 \
	TASK_PROVIDER=$${TASK_PROVIDER:-markdown} bun run $(CLAUDIN_DIR)/src/main.ts

start: ## Inicia o agente via Claude Code CLI + Discord channels (legado)
	@bash $(CLAUDIN_DIR)/scripts/start-local.sh

start-pi: ## Inicia o agente via systemd (Raspberry Pi)
	@sudo systemctl start claudin-agent claudin-watchdog.timer
	@echo "✓ Serviços iniciados"

stop-pi: ## Para o agente no Raspberry Pi
	@sudo systemctl stop claudin-agent
	@echo "✓ Agente parado"

# ── Testes ────────────────────────────────────────────────────────────────────

test-webhook: ## Testa conectividade do webhook Discord
	@set -a && source $(CLAUDIN_DIR)/.env && set +a && \
	echo "Testando webhook..." && \
	curl -fsS -X POST "$$DISCORD_WEBHOOK_URL" \
	  -H "Content-Type: application/json" \
	  -d '{"username":"Claudin (teste)","embeds":[{"title":"🧪 Teste de Webhook","description":"Webhook funcionando corretamente.","color":52}]}' \
	&& echo "✅ Webhook OK" || echo "❌ Webhook falhou — verifique DISCORD_WEBHOOK_URL no .env"

test-heartbeat: ## Testa o script de heartbeat isolado
	@set -a && source $(CLAUDIN_DIR)/.env && set +a && \
	bash $(CLAUDIN_DIR)/health/heartbeat.sh && echo "✅ Heartbeat OK"

test-watchdog: ## Executa o watchdog manualmente
	@set -a && source $(CLAUDIN_DIR)/.env && set +a && \
	bash $(CLAUDIN_DIR)/health/watchdog.sh

test-mcp: ## Verifica se o MCP server Discord sobe corretamente
	@set -a && source $(CLAUDIN_DIR)/.env && set +a && \
	echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | \
	DISCORD_WEBHOOK_URL="$$DISCORD_WEBHOOK_URL" MACHINE_NAME="$$MACHINE_NAME" \
	bun run $(CLAUDIN_DIR)/channels/discord-mcp.ts 2>/dev/null | head -5 \
	&& echo "✅ MCP server OK" || echo "❌ MCP server falhou"

# ── Monitoramento ─────────────────────────────────────────────────────────────

logs: ## Logs em tempo real do agente (systemd — apenas Pi)
	@journalctl -u claudin-agent -f

status: ## Status dos serviços systemd (apenas Pi)
	@systemctl status claudin-agent claudin-watchdog.timer --no-pager

last-heartbeat: ## Mostra timestamp do último heartbeat registrado
	@if [ -f $(CLAUDIN_DIR)/health/.last_heartbeat ]; then \
	  echo "Último heartbeat: $$(cat $(CLAUDIN_DIR)/health/.last_heartbeat)"; \
	else \
	  echo "Nenhum heartbeat registrado ainda"; \
	fi

activity: ## Últimas 20 linhas do log de atividade
	@tail -20 $(CLAUDIN_DIR)/health/activity.log 2>/dev/null || echo "Sem atividade registrada ainda"
