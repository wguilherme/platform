#!/usr/bin/env bash
# heartbeat.sh — Sinal de vida do agente
#
# Executado pelo agente Claude Code periodicamente.
# Faz duas coisas:
#   1. Ping para serviço externo de dead man's switch (detecta queda da máquina)
#   2. Atualiza timestamp local (detecta pausa do agente)

set -euo pipefail

ENV_FILE="$(dirname "$0")/../.env"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

HEALTHCHECK_PING_URL="${HEALTHCHECK_PING_URL:-}"
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
MACHINE_NAME="${MACHINE_NAME:-agent}"
HEARTBEAT_LOG="$(dirname "$0")/heartbeat.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 1. Atualiza arquivo de timestamp local
echo "$TIMESTAMP" > "$(dirname "$0")/.last_heartbeat"

# 2. Ping para healthchecks.io (ou similar) — detecta queda da MÁQUINA
if [ -n "$HEALTHCHECK_PING_URL" ]; then
  curl -fsS --retry 3 --max-time 10 "$HEALTHCHECK_PING_URL" > /dev/null 2>&1 || \
    echo "[${TIMESTAMP}] WARNING: healthcheck ping failed" >> "$HEARTBEAT_LOG"
fi

# 3. Registra no log local
echo "[${TIMESTAMP}] Heartbeat OK (${MACHINE_NAME})" >> "$HEARTBEAT_LOG"

# Mantém log com no máximo 500 linhas
tail -n 500 "$HEARTBEAT_LOG" > "${HEARTBEAT_LOG}.tmp" && mv "${HEARTBEAT_LOG}.tmp" "$HEARTBEAT_LOG"
