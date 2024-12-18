#!/bin/bash

.PHONY: up down logs clean dev

KUBECONFIG := /Users/withneyguilherme/.kube/k3d/config.skaffold1

up:
	env KUBECONFIG=$(KUBECONFIG) skaffold dev

down:
	env KUBECONFIG=$(KUBECONFIG) skaffold delete

logs:
	kubectl --kubeconfig $(KUBECONFIG) logs -n nodejs-v1 -l app=node-app -f

clean:
	env KUBECONFIG=$(KUBECONFIG) skaffold delete
	k3d cluster delete dev-cluster

dev:
	@skaffold dev