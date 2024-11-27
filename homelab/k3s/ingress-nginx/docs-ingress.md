## Preparação

```bash
sudo ufw disable
sudo apt update 
sudo swapoff -a
free -h
sudo nano /boot/cmdline.txt
cgroup_memory=1 cgroup_enable=memory
sudo reboot
```

## Instala o K3S como server sem traefik habilitado
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.25.13+k3s1 sh -s - server --disable=traefik
```

## Instala o ingress-nginx

## Nginx-ingress

### Adicionar o repositório do nginx-ingress
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### Instalar o nginx-ingress
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

## Instala o rancher
```bash
helm install rancher rancher-stable/rancher \
--namespace cattle-system \
--create-namespace \
--set ingress.ingressClassName=nginx \
--set hostname=rancher.phantombyte.uk \
--set tls=external \
--version 2.7.5
```

### Verifica status dos pods
```bash
kubectl get pods -n cattle-system
``` 