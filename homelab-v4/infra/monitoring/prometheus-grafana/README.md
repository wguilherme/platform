# Observabilidade: Prometheus + Grafana

Inclua aqui os manifestos para deploy do Prometheus e Grafana. Recomenda-se o uso do Helm para facilitar customizações.

## Instalação rápida (Helm)

```sh
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
helm install grafana grafana/grafana --namespace monitoring
```

Consulte os valores customizáveis na documentação oficial:
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- https://github.com/grafana/helm-charts/tree/main/charts/grafana
