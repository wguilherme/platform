# Cloudflare Tunnel via Kubernetes

Automação e manifestos para subir o Cloudflare Tunnel via Kubernetes.

## Passo a passo para subir o Cloudflare Argo Tunnel

1. **Crie o namespace cloudflare** (se ainda não existir):
   ```sh
   kubectl create namespace cloudflare
   ```

2. **Crie o secret com as credenciais do tunnel:**
   > O arquivo `key.json` precisa ser gerado via dashboard do Cloudflare (ou exportado do ambiente antigo)
   ```sh
   kubectl create secret generic tunnel-credentials --from-file=credentials.json=key.json -n cloudflare
   ```

3. **Adicione o repositório Helm do Cloudflare:**
   ```sh
   helm repo add cloudflare https://cloudflare.github.io/helm-charts
   helm repo update
   ```

4. **Instale o tunnel usando o values.yaml:**
   ```sh
   helm install cloudflared cloudflare/cloudflare-tunnel -n cloudflare -f values.yaml
   ```
   > Use `helm upgrade` se já existir uma instalação anterior.

5. **Verifique os pods:**
   ```sh
   kubectl get pods -n cloudflare
   ```

## Referências
- https://github.com/cloudflare/helm-charts/tree/main/charts/cloudflare-tunnel
- https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/deploy-cloudflare-tunnel-kubernetes/
