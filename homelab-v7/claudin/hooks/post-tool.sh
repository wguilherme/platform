#!/usr/bin/env bash
# post-tool.sh — Hook executado após cada ferramenta Bash
# Registra atividade em log local para auditoria

LOG_FILE="${HOME}/project/claudin/health/activity.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Atualiza timestamp da última atividade (usado pelo watchdog)
touch "${HOME}/project/claudin/health/.last_activity"

# Append ao log de atividade (mantém últimas 1000 linhas)
echo "[${TIMESTAMP}] Tool executed" >> "${LOG_FILE}"
tail -n 1000 "${LOG_FILE}" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "${LOG_FILE}"
