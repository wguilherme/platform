## Preparação

```bash
sudo ufw disable
sudo apt update 
sudo swapoff -a
free -h
sudo nano /boot/cmdline.txt
# adicionar ao cmdline.txt
cgroup_memory=1 cgroup_enable=memory
sudo reboot
```

```bash
# adicionar ao cmdline.txt
cgroup_memory=1 cgroup_enable=memory
```

## Instala o K3S como server sem traefik habilitado
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.25.13+k3s1 sh -s - server
```

## Instala o rancher
```bash
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=rancher.phantombyte.uk \
  --set replicas=1 \
  --set tls=external \
  --set ingress.enabled=false \
  --version=2.7.5 \
  --set global.cattle.psp.enabled=false \
  --set auditLog.level=1 \
  --set features=multi-cluster-management=true
```

### Verifica status dos pods
```bash
kubectl get pods -n cattle-system
``` 