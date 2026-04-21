#!/usr/bin/env bash
# startup-notify.sh — Notificação de inicialização do agente
#
# Executado quando o serviço claudin-agent inicia.
# Envia mensagem no Discord informando que o agente está online.

set -euo pipefail

ENV_FILE="$(dirname "$0")/../.env"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
MACHINE_NAME="${MACHINE_NAME:-agent}"

if [ -z "$DISCORD_WEBHOOK_URL" ]; then
  echo "DISCORD_WEBHOOK_URL não configurado"
  exit 0
fi

UPTIME=$(uptime -p 2>/dev/null || echo "desconhecido")
IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "desconhecido")

curl -fsS -X POST "$DISCORD_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"Claudin\",
    \"embeds\": [{
      \"title\": \"🤖 Claudin Online\",
      \"description\": \"Agente iniciado e pronto para trabalhar.\",
      \"color\": 52,
      \"fields\": [
        {\"name\": \"Máquina\", \"value\": \"\`${MACHINE_NAME}\`\", \"inline\": true},
        {\"name\": \"IP\", \"value\": \"\`${IP}\`\", \"inline\": true},
        {\"name\": \"Uptime\", \"value\": \"${UPTIME}\", \"inline\": false}
      ],
      \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
      \"footer\": {\"text\": \"Claudin Agent v1.0\"}
    }]
  }" > /dev/null

echo "Notificação de startup enviada"
