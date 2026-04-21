#!/usr/bin/env bash
# start-local.sh — Inicia o Claudin localmente (Mac/teste)
#
# Uso: make start
#
# O Claude Code fica aberto como sessão persistente recebendo
# mensagens do Discord via plugin:discord@claude-plugins-official.

set -euo pipefail

CLAUDIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$(cd "${CLAUDIN_DIR}/.." && pwd)"
INSTALLED_PLUGINS="${HOME}/.claude/plugins/installed_plugins.json"
DISCORD_ENV="${HOME}/.claude/channels/discord/.env"

# ── Carrega .env ──────────────────────────────────────────────
if [ ! -f "${CLAUDIN_DIR}/.env" ]; then
  echo "❌ .env não encontrado. Rode: cp claudin/.env.example claudin/.env"
  exit 1
fi
set -a && source "${CLAUDIN_DIR}/.env" && set +a

# ── Valida setup ──────────────────────────────────────────────
SETUP_NEEDED=false

# Verifica plugin instalado
if ! python3 -c "
import json, sys
d = json.load(open('${INSTALLED_PLUGINS}'))
sys.exit(0 if 'discord@claude-plugins-official' in d.get('plugins', {}) else 1)
" 2>/dev/null; then
  echo "⚠️  Plugin Discord não instalado. Rode: make setup"
  SETUP_NEEDED=true
fi

# Verifica token configurado
if [ ! -f "$DISCORD_ENV" ] || ! grep -q "DISCORD_BOT_TOKEN" "$DISCORD_ENV" 2>/dev/null; then
  echo "⚠️  Bot token não configurado. Rode: make setup"
  SETUP_NEEDED=true
fi

if $SETUP_NEEDED; then
  read -rp "Rodar 'make setup' agora? (s/N): " RUN_SETUP
  if [[ "$RUN_SETUP" == "s" || "$RUN_SETUP" == "S" ]]; then
    bash "${CLAUDIN_DIR}/scripts/setup-discord.sh"
  else
    exit 1
  fi
fi

# ── Gera MCP config com valores reais ────────────────────────
MCP_TEMP=$(mktemp /tmp/claudin-mcp-XXXXXX.json)
trap 'rm -f "$MCP_TEMP"' EXIT INT TERM

cat > "$MCP_TEMP" <<EOF
{
  "mcpServers": {
    "claudin-discord": {
      "command": "bun",
      "args": ["run", "${CLAUDIN_DIR}/channels/discord-mcp.ts"],
      "env": {
        "DISCORD_WEBHOOK_URL": "${DISCORD_WEBHOOK_URL:-}",
        "HEALTHCHECK_PING_URL": "${HEALTHCHECK_PING_URL:-}",
        "MACHINE_NAME": "${MACHINE_NAME:-mac-local}"
      }
    }
  }
}
EOF

# ── Carrega SSH se configurado ────────────────────────────────
if [ -n "${SSH_KEY_PATH:-}" ] && [ -f "$SSH_KEY_PATH" ]; then
  eval "$(ssh-agent -s)" > /dev/null 2>&1
  ssh-add "$SSH_KEY_PATH" > /dev/null 2>&1
fi

# ── Startup ───────────────────────────────────────────────────
clear
echo "=================================================="
echo "  Claudin — Online"
echo "=================================================="
echo ""
echo "  Projeto:  ${PROJECT_DIR}"
echo "  Máquina:  ${MACHINE_NAME:-mac-local}"
echo "  Discord:  plugin:discord@claude-plugins-official"
echo ""
echo "  Aguardando mensagens do Discord..."
echo "  Ctrl+C para encerrar"
echo ""

bash "${CLAUDIN_DIR}/health/startup-notify.sh" 2>/dev/null || true

cd "$PROJECT_DIR"

# Inicia Claude Code com channels ativo + MCP de webhook para notificações
exec claude \
  --dangerously-skip-permissions \
  --channels "plugin:discord@claude-plugins-official" \
  --mcp-config "$MCP_TEMP" \
  --append-system-prompt "$(cat "${CLAUDIN_DIR}/CLAUDE.md")" \
  "Inicie o loop de trabalho autônomo agora: leia claudin/tasks/backlog.md, execute as tarefas pendentes [ ] uma a uma, marque como concluídas [x], reporte cada conclusão via send_to_discord. Quando o backlog estiver vazio, envie send_to_discord com status waiting e fique aguardando — novas tarefas podem chegar via Discord a qualquer momento."
