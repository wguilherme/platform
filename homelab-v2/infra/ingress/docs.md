## Nginx-ingress
### Adicionar o repositório do nginx-ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
### Instalar o nginx-ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
