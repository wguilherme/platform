#!/bin/bash

COMPOSE_FILE="$(dirname "$0")/../docker/docker-compose.yml"

CURRENT_IP=$(ping -c1 -W1 raspberry.local 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$CURRENT_IP" ]; then
    echo "[$(date)] RPi offline — nao foi possivel resolver raspberry.local"
    exit 1
fi

WAHA_API_KEY=$(grep '^WAHA_API_KEY=' "$(dirname "$0")/../docker/.env" | cut -d= -f2)

echo "[$(date)] RPi IP: $CURRENT_IP — atualizando WAHA..."
RPI_IP="$CURRENT_IP" docker compose -f "$COMPOSE_FILE" up -d waha

echo "[$(date)] Aguardando WAHA inicializar..."
sleep 8

STATUS=$(curl -s http://localhost:3000/api/sessions/default \
  -H "X-Api-Key: $WAHA_API_KEY" | grep -o '"WORKING"\|"STOPPED"\|"STARTING"' | tr -d '"')

if [ "$STATUS" = "STOPPED" ]; then
    echo "[$(date)] Sessão STOPPED — iniciando..."
    curl -s -X POST http://localhost:3000/api/sessions/default/start \
      -H "X-Api-Key: $WAHA_API_KEY" > /dev/null
    sleep 5
fi

echo "[$(date)] WAHA pronto. Status: $(curl -s http://localhost:3000/api/sessions/default -H "X-Api-Key: $WAHA_API_KEY" | grep -o '"WORKING"\|"STOPPED"\|"STARTING"' | tr -d '"')"
