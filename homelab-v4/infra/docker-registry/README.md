# Docker Registry Oficial - Repositório de Imagens Leve para K3s/Raspberry Pi

Esta pasta contém os manifestos e instruções para rodar o Docker Registry oficial, ideal para ambientes de borda/homelab.

## Instalação rápida (Kubernetes)

```sh
kubectl create namespace registry
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml  # Opcional, se quiser expor via domínio
```

- O registry ficará disponível em `registry.phantombyte.uk` (ajuste o domínio conforme necessário).
- Para autenticação, use um proxy reverso (Nginx, Traefik) ou configure autenticação básica.

Consulte a documentação oficial para configurações avançadas:
- https://hub.docker.com/_/registry
- https://docs.docker.com/registry/deploying/
