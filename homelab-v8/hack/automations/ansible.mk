ANSIBLE_DIR    := $(AUTOMATIONS_DIR)../../ansible
RPI_HOSTNAME   ?= rpi.local
RPI_HOST       ?= rpi.local
RPI_USER       ?= ubuntu

.PHONY: rpi-discover rpi-ping rpi-check rpi-trust rpi-resources ansible-setup kubeconfig-rpi rpi-setup rpi-teardown rpi-reset

# ── Connectivity check ────────────────────────────────────────────────────────

rpi-discover:
	@echo "→ Buscando RPi na rede local..."
	@echo "(aguarde alguns segundos — resolvendo hostname via mDNS e aguardando resposta do RPi...)"
	@ping -c 1 $(RPI_HOSTNAME) 2>&1 | grep PING || true
	@arp -a 2>/dev/null | grep -iE "rpi|raspberry|ubuntu" || true
	@command -v nmap > /dev/null 2>&1 \
		&& nmap -sn $$(route -n get default 2>/dev/null | awk '/gateway/{print $$2}' | sed 's/\.[0-9]*$$/\.0/')/24 2>/dev/null \
			| grep -A1 -iE "rpi|raspberry|ubuntu" \
		|| true
	@echo ""
	@echo "! Atualize o IP encontrado no .env → RPI_HOST=<ip-encontrado>"

rpi-ping:
	@ping -c 1 -W 2 $(RPI_HOST) > /dev/null 2>&1 \
		&& echo "✓ $(RPI_HOST) reachable" \
		|| echo "✗ $(RPI_HOST) unreachable"

rpi-trust:
	ssh-keygen -R $(RPI_HOST) 2>/dev/null || true
	ssh-keyscan -H $(RPI_HOST) >> ~/.ssh/known_hosts 2>/dev/null
	@echo "✓ Host key atualizado para $(RPI_HOST)"

rpi-resources:
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		-i ~/.ssh/id_rsa $(RPI_USER)@$(RPI_HOST) \
		'printf "CPU:     %s cores / %s%% used\nMemory:  %s total / %s used\nStorage: %s total / %s used\nTemp:    %s\n" \
			"$$(nproc)" \
			"$$(top -bn1 | grep "Cpu(s)" | awk "{print \$$2}")" \
			"$$(free -h | awk "/Mem:/{print \$$2}")" \
			"$$(free -h | awk "/Mem:/{print \$$3}")" \
			"$$(df -h / | awk "NR==2{print \$$2}")" \
			"$$(df -h / | awk "NR==2{print \$$3}")" \
			"$$(cat /sys/class/thermal/thermal_zone0/temp | awk "{printf \"%.1f°C\", \$$1/1000}")"'

rpi-check: rpi-ping
	ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
		-i ~/.ssh/id_rsa $(RPI_USER)@$(RPI_HOST) \
		'echo "✓ SSH ok — hostname: $$(hostname) — arch: $$(uname -m)"'

# ── Env validation ───────────────────────────────────────────────────────────

_rpi-check-env:
	@test -n "$(RPI_HOST)"     || (echo "✗ RPI_HOST não definido em .env";     exit 1)
	@test "$(RPI_HOST)" != "rpi.local" || (echo "✗ RPI_HOST ainda é o valor padrão — rode: make rpi-discover"; exit 1)
	@test -n "$(RPI_USER)"     || (echo "✗ RPI_USER não definido em .env";     exit 1)
	@test -n "$(RPI_PASSWORD)" || (echo "✗ RPI_PASSWORD não definido em .env"; exit 1)
	@echo "✓ RPI_HOST=$(RPI_HOST)  RPI_USER=$(RPI_USER)  RPI_PASSWORD=***"

# ── Provisioning ──────────────────────────────────────────────────────────────

ansible-setup: _rpi-check-env
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/hosts.yml site.yml

# ── Kubeconfig ────────────────────────────────────────────────────────────────

kubeconfig-rpi:
	mkdir -p $(dir $(KUBECONFIG_PLATFORM))
	cp $(ANSIBLE_DIR)/kubeconfig $(KUBECONFIG_PLATFORM)
	@echo "KUBECONFIG=$(KUBECONFIG_PLATFORM)"

# ── Setup/Teardown completo ───────────────────────────────────────────────────

rpi-setup: _rpi-check-env ansible-setup kubeconfig-rpi kind-secrets flux-bootstrap kind-wait-controllers kind-wait flux-status
	@echo ""
	@echo "✓ RPi setup completo."

rpi-teardown: _rpi-check-env
	ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa $(RPI_USER)@$(RPI_HOST) \
		'echo $(RPI_PASSWORD) | sudo -S /usr/local/bin/k3s-uninstall.sh'
	rm -f $(KUBECONFIG_PLATFORM)
	@echo "✓ K3s removido do RPi"

rpi-reset: rpi-teardown rpi-setup
	@echo "✓ RPi reset completo"
