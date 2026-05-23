ANSIBLE_DIR    := $(AUTOMATIONS_DIR)../../ansible
RPI_HOSTNAME   ?= rpi.local
RPI_HOST       ?= rpi.local
RPI_USER       ?= ubuntu

.PHONY: rpi-discover rpi-ping rpi-check ansible-setup kubeconfig-rpi rpi-setup rpi-teardown

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

rpi-check: rpi-ping
	ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
		-i ~/.ssh/id_rsa $(RPI_USER)@$(RPI_HOST) \
		'echo "✓ SSH ok — hostname: $$(hostname) — arch: $$(uname -m)"'

# ── Provisioning ──────────────────────────────────────────────────────────────

ansible-setup:
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/hosts.yml site.yml

# ── Kubeconfig ────────────────────────────────────────────────────────────────

kubeconfig-rpi:
	mkdir -p $(dir $(KUBECONFIG_PLATFORM))
	cp $(ANSIBLE_DIR)/kubeconfig $(KUBECONFIG_PLATFORM)
	@echo "KUBECONFIG=$(KUBECONFIG_PLATFORM)"

# ── Setup/Teardown completo ───────────────────────────────────────────────────

rpi-setup: ansible-setup kubeconfig-rpi kind-secrets flux-bootstrap kind-wait-controllers kind-wait flux-status
	@echo ""
	@echo "✓ RPi setup completo."

rpi-teardown:
	@echo "RPi teardown: desinstale K3s via Ansible ou manualmente no host."
	@echo "  ssh pi@<ip> 'sudo /usr/local/bin/k3s-uninstall.sh'"
