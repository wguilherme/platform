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

ubuntu@ip-172-31-21-69:~$ sudo ip addr add 10.3.152.31/32 dev eth0
ubuntu@ip-172-31-21-69:~$ sudo socat TCP-LISTEN:6443,bind=10.3.152.31,fork TCP:rancher.phantombyte.uk:443