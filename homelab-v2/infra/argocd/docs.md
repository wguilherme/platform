
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update



# Instale usando Helm
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values argo-cd.dev.values.yaml


# Senha default do admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d


kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d;

// info
Warning: annotation "kubernetes.io/ingress.class" is deprecated, please use 'spec.ingressClassName' instead

// secrets
kubectl create secret generic argocd-github-ssh -n argocd --from-file=sshPrivateKey=./argocd_deploy_key