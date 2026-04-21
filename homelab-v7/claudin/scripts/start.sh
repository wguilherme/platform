#!/usr/bin/env bash
# start.sh — Inicia o agente manualmente (sem systemd)
# Útil para testar antes de colocar como serviço

set -euo pipefail

CLAUDIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$(cd "${CLAUDIN_DIR}/.." && pwd)"

source "${CLAUDIN_DIR}/.env"

# Carrega chave SSH se configurada
if [ -n "${SSH_KEY_PATH:-}" ] && [ -f "$SSH_KEY_PATH" ]; then
  eval "$(ssh-agent -s)" > /dev/null
  ssh-add "$SSH_KEY_PATH" 2>/dev/null
  echo "✓ Chave SSH carregada: ${SSH_KEY_PATH}"
fi

export DISCORD_WEBHOOK_URL
export HEALTHCHECK_PING_URL
export MACHINE_NAME
export GIT_USER_NAME
export GIT_USER_EMAIL

cd "$PROJECT_DIR"

echo "🤖 Iniciando Claudin..."
echo "   Projeto: ${PROJECT_DIR}"
echo "   Máquina: ${MACHINE_NAME:-localhost}"
echo ""
echo "IMPORTANTE: Claude Code Channels requer login via 'claude login'"
echo "Não funciona com ANTHROPIC_API_KEY."
echo ""

# Notifica Discord
bash "${CLAUDIN_DIR}/health/startup-notify.sh" || true

# Inicia Claude Code com o plugin Discord
# --dangerously-skip-permissions: modo totalmente autônomo
claude \
  --channels "plugin:discord@claude-plugins-official" \
  --dangerously-skip-permissions \
  --print "Leia claudin/CLAUDE.md e inicie o loop de trabalho autônomo"
