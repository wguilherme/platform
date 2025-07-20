# Harbor - Repositório de Artefatos

Sugestão: instalar via Helm.

## Instalação rápida (Helm)

```sh
kubectl create namespace harbor
helm repo add harbor https://helm.goharbor.io
helm repo update
helm install harbor harbor/harbor --namespace harbor -f values.yaml

# upgrades
helm upgrade harbor harbor/harbor --namespace harbor -f values.yaml
```

Consulte a documentação oficial para configurações avançadas:
- https://goharbor.io/docs/
- https://github.com/goharbor/harbor-helm
