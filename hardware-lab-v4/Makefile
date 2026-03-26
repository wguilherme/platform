COMPOSE     = docker compose -f infra/docker/docker-compose.yml
ESPHOME_DIR = esphome
RPI_HOST   ?= wguilherme@raspberry.local
SSH_KEY    ?= ~/.ssh/personal/wguilherme.dev.github
SSH        = ssh -i $(SSH_KEY)
RSYNC      = rsync -avz -e "ssh -i $(SSH_KEY)"

include infra/docker/.env
WAHA_URL    = http://localhost:3000
WAHA_HEADER = X-Api-Key: $(WAHA_API_KEY)

.PHONY: up down restart logs ps \
        waha-password waha-session waha-start waha-qr waha-status \
        deploy-esphome \
        rpi-setup rpi-deploy rpi-logs \
        gate-setup gate-restart gate-logs gate-pulse \
        sync-ip sync-ip-cron sync-ip-cron-remove

# ── Infra local ──────────────────────────────────────────────────────────────

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

# ── WAHA ─────────────────────────────────────────────────────────────────────

waha-password:
	@docker logs waha 2>&1 | grep "WAHA_DASHBOARD_PASSWORD" | tail -1

waha-session:
	curl -s -X POST $(WAHA_URL)/api/sessions \
		-H "$(WAHA_HEADER)" \
		-H "Content-Type: application/json" \
		-d '{"name":"default"}' | jq .

waha-start:
	curl -s -X POST $(WAHA_URL)/api/sessions/default/start \
		-H "$(WAHA_HEADER)" | jq .status

waha-qr:
	@sleep 2
	curl -s "$(WAHA_URL)/api/default/auth/qr?format=image" \
		-H "$(WAHA_HEADER)" \
		-o /tmp/waha-qr.png && open /tmp/waha-qr.png

waha-status:
	curl -s $(WAHA_URL)/api/sessions/default \
		-H "$(WAHA_HEADER)" | jq .status

# Resolve JID de um numero: make waha-jid PHONE=5511999998888
waha-jid:
	curl -s "$(WAHA_URL)/api/default/contacts/check-exists?phone=$(PHONE)" \
		-H "$(WAHA_HEADER)" | jq '{phone: .chatId}'

# ── ESPHome ───────────────────────────────────────────────────────────────────

deploy-esphome:
	cd $(ESPHOME_DIR) && esphome run garage-controller.yaml

# ── Raspberry Pi ──────────────────────────────────────────────────────────────

rpi-setup:
	@echo "Instalando Docker no RPi..."
	$(SSH) $(RPI_HOST) "curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker wguilherme"

rpi-deploy:
	$(RSYNC) --exclude='.pio' --exclude='archive' infra/ esphome/ \
		$(RPI_HOST):~/hardware-lab-v4/
	$(SSH) $(RPI_HOST) "cd ~/hardware-lab-v4 && docker compose -f docker/docker-compose.yml up -d"

rpi-logs:
	$(SSH) $(RPI_HOST) "cd ~/hardware-lab-v4 && docker compose -f docker/docker-compose.yml logs -f"

# ── Gate API ──────────────────────────────────────────────────────────────────

gate-setup:
	$(SSH) $(RPI_HOST) "mkdir -p ~/hardware-lab-v4/core ~/hardware-lab-v4/infra/systemd"
	$(RSYNC) core/ $(RPI_HOST):~/hardware-lab-v4/core/
	$(RSYNC) infra/systemd/ $(RPI_HOST):~/hardware-lab-v4/infra/systemd/
	$(SSH) $(RPI_HOST) " \
		python3 -m venv ~/hardware-lab-v4/core/venv && \
		~/hardware-lab-v4/core/venv/bin/pip install -r ~/hardware-lab-v4/core/requirements.txt && \
		sudo cp ~/hardware-lab-v4/infra/systemd/gate.service /etc/systemd/system/ && \
		sudo systemctl daemon-reload && \
		sudo systemctl enable gate && \
		sudo systemctl restart gate"

gate-restart:
	$(SSH) $(RPI_HOST) "sudo systemctl restart gate"

gate-logs:
	$(SSH) $(RPI_HOST) "journalctl -u gate -f"

gate-pulse:
	$(SSH) $(RPI_HOST) "curl -s -X POST http://localhost:8000/pulse"

# ── Sync RPi IP ───────────────────────────────────────────────────────────────

SYNC_SCRIPT = $(shell pwd)/infra/scripts/sync-rpi-ip.sh
CRON_JOB    = */30 * * * * $(SYNC_SCRIPT) >> /tmp/sync-rpi-ip.log 2>&1

sync-ip:
	@bash $(SYNC_SCRIPT)

sync-ip-cron:
	@(crontab -l 2>/dev/null | grep -v sync-rpi-ip; echo "$(CRON_JOB)") | crontab -
	@echo "Cron instalado: a cada 30min"

sync-ip-cron-remove:
	@crontab -l 2>/dev/null | grep -v sync-rpi-ip | crontab -
	@echo "Cron removido"

# ── Reboot RPi diário ─────────────────────────────────────────────────────────

rpi-reboot-setup:
	$(RSYNC) infra/systemd/reboot.service infra/systemd/reboot.timer \
		$(RPI_HOST):~/hardware-lab-v4/infra/systemd/
	$(SSH) $(RPI_HOST) " \
		sudo cp ~/hardware-lab-v4/infra/systemd/reboot.service /etc/systemd/system/ && \
		sudo cp ~/hardware-lab-v4/infra/systemd/reboot.timer /etc/systemd/system/ && \
		sudo systemctl daemon-reload && \
		sudo systemctl enable reboot.timer && \
		sudo systemctl start reboot.timer && \
		systemctl status reboot.timer --no-pager"

sync-ip-logs:
	@tail -50 /tmp/sync-rpi-ip.log 2>/dev/null || echo "Sem logs ainda."
