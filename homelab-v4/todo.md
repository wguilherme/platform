# Plano de Automação do Homelab v4

## Infraestrutura

- [x] Automatizar instalação do K3s (comandos já existentes no projeto)
- [x] Instalar Nginx Ingress (desabilitando Traefik na instalação do K3s)
- [ ] Subir Cloudflare Argo Tunnel via Kubernetes (usando manifestos/referências do projeto)

## K3s: CI/CD, Observabilidade e Artefatos

- [x] Instalar e configurar ArgoCD
- [x] Instalar stack de observabilidade (Prometheus + Grafana)
- [x] Instalar Tekton para pipelines de CI
- [x] Instalar Harbor como repositório de artefatos
