AUTOMATIONS_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

-include $(AUTOMATIONS_DIR)../../.env
export

include $(AUTOMATIONS_DIR)kind.mk
include $(AUTOMATIONS_DIR)k3d.mk
include $(AUTOMATIONS_DIR)flux.mk
include $(AUTOMATIONS_DIR)cloudflare.mk
include $(AUTOMATIONS_DIR)tekton.mk
include $(AUTOMATIONS_DIR)test.mk
include $(AUTOMATIONS_DIR)apps.mk
include $(AUTOMATIONS_DIR)ansible.mk

.PHONY: setup teardown

# ── Setup completo (passos 1–6) ───────────────────────────────────────────────
# Sobe cluster + Flux + secrets + aguarda infraestrutura pronta
setup: kind-up kind-secrets flux-bootstrap kind-wait-controllers kind-wait flux-status
	@echo ""
	@echo "✓ Setup completo. Ver hack/automations/SETUP.md para próximos passos."

# ── Teardown ──────────────────────────────────────────────────────────────────
teardown: kind-down
