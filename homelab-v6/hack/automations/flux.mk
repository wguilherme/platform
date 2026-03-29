# ── Flux ──────────────────────────────────────────────────────────────────────
# Uso: make -f homelab-v6/hack/automations/flux.mk <target>
#
# Pré-requisitos:
#   - kubectl instalado
#   - SSH tunnel ativo: ssh -f -N -L 6444:127.0.0.1:6443 wguilherme@raspberry.local
#   - KUBECONFIG apontando para o cluster RPi

KUBECONFIG ?= $(HOME)/.kube/local/platform/config.rpi
KUBECTL     = KUBECONFIG=$(KUBECONFIG) kubectl
NS_FLUX     = flux-system
NS_ESP32    = tekton-pipelines

.PHONY: flux-image-status flux-flash-status

# Última sincronização de imagem OCI: data/hora e tag resolvida
flux-image-status:
	@$(KUBECTL) get imagepolicy esp32-firmware -n $(NS_FLUX) \
		-o jsonpath='{.status.conditions[0]}' | python3 -m json.tool

# Status do Job de implantação no ESP32: se rodou, quando e resultado
flux-flash-status:
	@$(KUBECTL) describe job -n $(NS_ESP32)
