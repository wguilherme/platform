 helm upgrade gitea gitea-charts/gitea -n gitea --values values.yaml

 helm install gitea gitea-charts/gitea -f values.yaml -n gitea