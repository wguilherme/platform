#!/usr/bin/env bash
# watchdog.sh — Monitora se o agente está vivo
#
# Este script roda como serviço separado (systemd timer a cada 5 min).
# Verifica se o agente heartbeat está sendo atualizado.
# Se o agente parar por mais de STALE_THRESHOLD segundos → alerta no Discord.
#
# Detecta: pausa do agente (processo travado/morto mas máquina UP)
# NÃO detecta: queda da máquina (use healthchecks.io para isso)

set -euo pipefail

ENV_FILE="$(dirname "$0")/../.env"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
MACHINE_NAME="${MACHINE_NAME:-agent}"
HEARTBEAT_FILE="$(dirname "$0")/.last_heartbeat"
STALE_THRESHOLD="${STALE_THRESHOLD:-600}"  # 10 minutos em segundos
ALERT_COOLDOWN_FILE="$(dirname "$0")/.watchdog_alert_sent"
ALERT_COOLDOWN=1800  # Só reenvia alerta a cada 30 min para não spammar

send_discord_alert() {
  local message="$1"
  if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    echo "DISCORD_WEBHOOK_URL não configurado — alerta não enviado"
    return
  fi

  curl -fsS -X POST "$DISCORD_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"Claudin Watchdog\",
      \"embeds\": [{
        \"title\": \"🚨 AGENTE PARADO (${MACHINE_NAME})\",
        \"description\": \"${message}\",
        \"color\": 13959168,
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"footer\": {\"text\": \"Watchdog · ${MACHINE_NAME}\"}
      }]
    }" > /dev/null 2>&1
}

# Verifica cooldown de alerta (evita spam)
should_send_alert() {
  if [ ! -f "$ALERT_COOLDOWN_FILE" ]; then
    return 0  # Nunca enviou, pode enviar
  fi
  local last_alert
  last_alert=$(cat "$ALERT_COOLDOWN_FILE")
  local now
  now=$(date +%s)
  local diff=$(( now - last_alert ))
  [ "$diff" -gt "$ALERT_COOLDOWN" ]
}

# ── Verificação principal ─────────────────────────────────────────────────────

if [ ! -f "$HEARTBEAT_FILE" ]; then
  # Arquivo não existe — agente nunca iniciou ou foi resetado
  if should_send_alert; then
    send_discord_alert "⚠️ Arquivo de heartbeat não encontrado. O agente nunca iniciou ou foi resetado.\n\nMáquina: \`${MACHINE_NAME}\`\nAção necessária: verificar se o serviço \`claudin-agent\` está rodando."
    date +%s > "$ALERT_COOLDOWN_FILE"
  fi
  exit 1
fi

LAST_HEARTBEAT=$(cat "$HEARTBEAT_FILE")
LAST_TIMESTAMP=$(date -d "$LAST_HEARTBEAT" +%s 2>/dev/null || date -j -f '%Y-%m-%d %H:%M:%S' "$LAST_HEARTBEAT" +%s 2>/dev/null || echo 0)
NOW=$(date +%s)
DIFF=$(( NOW - LAST_TIMESTAMP ))

if [ "$DIFF" -gt "$STALE_THRESHOLD" ]; then
  MINUTES=$(( DIFF / 60 ))
  if should_send_alert; then
    send_discord_alert "O agente não enviou heartbeat há **${MINUTES} minutos**.\n\n\`\`\`\nÚltimo heartbeat: ${LAST_HEARTBEAT}\nAgora: $(date '+%Y-%m-%d %H:%M:%S')\nMáquina: ${MACHINE_NAME}\n\`\`\`\n\n**Ações possíveis:**\n- Verificar logs: \`journalctl -u claudin-agent -n 50\`\n- Reiniciar: \`sudo systemctl restart claudin-agent\`"
    date +%s > "$ALERT_COOLDOWN_FILE"
    echo "ALERTA enviado: agente parado há ${MINUTES} min"
  else
    echo "Agente parado há ${MINUTES} min — alerta em cooldown"
  fi
else
  # Tudo ok — remove cooldown file se existir
  rm -f "$ALERT_COOLDOWN_FILE"
  echo "Agente OK — último heartbeat há $(( DIFF / 60 )) min $(( DIFF % 60 )) seg"
fi
