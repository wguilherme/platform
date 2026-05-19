#!/bin/bash
# Script para instalar o K3s (com Traefik desabilitado) e Nginx Ingress Controller
# Adaptado para Raspberry Pi rodando k3s

set -e

# Instalação do K3s sem Traefik
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Aguarda o cluster subir
sleep 20

# Instala o Nginx Ingress Controller via Helm
kubectl create namespace ingress-nginx || true
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx

# Mostra status
kubectl get pods -n ingress-nginx
