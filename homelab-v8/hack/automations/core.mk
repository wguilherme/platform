AUTOMATIONS_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include $(AUTOMATIONS_DIR)kind.mk
include $(AUTOMATIONS_DIR)flux.mk
