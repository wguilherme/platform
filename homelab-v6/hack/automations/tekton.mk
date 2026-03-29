# ── Tekton ────────────────────────────────────────────────────────────────────
# Uso: make -f homelab-v6/hack/automations/tekton.mk <target>
#
# Pré-requisitos:
#   - kubectl instalado
#   - SSH tunnel ativo: ssh -f -N -L 6444:127.0.0.1:6443 wguilherme@raspberry.local
#   - KUBECONFIG apontando para o cluster RPi

KUBECONFIG ?= $(HOME)/.kube/local/platform/config.rpi
KUBECTL     = KUBECONFIG=$(KUBECONFIG) kubectl
NS          = tekton-pipelines

.PHONY: tekton-stop tekton-clean tekton-status tekton-tunnel

# Para todas as TaskRuns em execução (Running/Pending)
tekton-stop:
	@echo "Parando TaskRuns em execução..."
	@$(KUBECTL) delete taskrun -n $(NS) \
		$$($(KUBECTL) get taskrun -n $(NS) --no-headers \
			-o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[0].reason \
			| grep -E "Running|Pending" | awk '{print $$1}') 2>/dev/null || true
	@echo "Feito."

# Remove todas as TaskRuns (incluindo concluídas e com falha)
tekton-clean:
	@echo "Removendo todas as TaskRuns..."
	@$(KUBECTL) delete taskrun --all -n $(NS) 2>/dev/null || true
	@echo "Feito."

# Mostra status atual das TaskRuns
tekton-status:
	@$(KUBECTL) get taskrun -n $(NS) --sort-by=.metadata.creationTimestamp

# Abre o tunnel SSH para o RPi (necessário antes de qualquer kubectl)
tekton-tunnel:
	@pkill -f "ssh.*6444" 2>/dev/null || true
	@ssh -f -N -L 6444:127.0.0.1:6443 wguilherme@raspberry.local
	@echo "Tunnel ativo em 127.0.0.1:6444"
