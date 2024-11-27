## Cria a Secret

kubectl create ns cloudflare;
kubectl create secret generic tunnel-credentials \
  --from-file=credentials.json=key.json -n cloudflare

## Helm install

helm install cloudflared cloudflare/cloudflare-tunnel \
-f values.yaml \
-n cloudflare \
--create-namespace

## Helm update

helm upgrade cloudflared cloudflare/cloudflare-tunnel \
  -f values.yaml \
  -n cloudflare

## Helm update dry run

helm upgrade cloudflared cloudflare/cloudflare-tunnel \
  -f values.yaml \
  -n cloudflare \
  --dry-run

## Helm uninstall
helm uninstall cloudflared -n cloudflare