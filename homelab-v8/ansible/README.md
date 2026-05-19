# K3s Single-Node + Nginx Ingress Controller - Ansible Automation

Automação completa para deploy de K3s single-node com Nginx Ingress Controller em Raspberry Pi (ou qualquer servidor Linux). Esta solução foi projetada para trabalhar com Rancher, onde workers serão adicionados posteriormente via automação do Rancher.

## Estrutura

```
ansible/
├── inventory/             # Inventário e variáveis
│   ├── hosts.yml          # Definição do host
├── roles/                 # Roles Ansible
│   ├── k3s/               # Role para instalação do K3s
│   └── nginx-ingress/     # Role para Nginx Ingress
├── playbooks/             # Playbooks específicos
├── site.yml               # Playbook principal
├── ansible.cfg            # Configuração do Ansible
└── requirements.yml       # Dependências
```

## Pré-requisitos

### No Raspberry Pi:
- Raspberry Pi OS (64-bit recomendado)
- Python 3 instalado
- Acesso SSH configurado
- Usuário com privilégios sudo

### Na máquina de controle:
```bash
# Instalar Ansible e dependências
pip install ansible kubernetes

# Instalar collections necessárias
ansible-galaxy collection install -r requirements.yml
```

## Configuração

### 1. Configurar inventário
Edite `inventory/hosts.yml` com o IP do seu Raspberry Pi:

```yaml
k3s_cluster:
  hosts:
    rpi-k3s:
      ansible_host: 192.168.1.100  # IP do seu Raspberry Pi
      ansible_user: pi              # Usuário SSH
```

### 2. Configurar SSH
```bash
# Gerar chave SSH (se ainda não tiver)
ssh-keygen -t rsa -b 4096

# Copiar chave para o Raspberry Pi
ssh-copy-id pi@192.168.1.100
```

## Uso

### Deploy completo (K3s + Nginx Ingress)
```bash
cd homelab-v5/ansible
ansible-playbook site.yml
```

### Deploy no Orbstack (desenvolvimento local)
```bash
# Criar máquina no Orbstack
orb create ubuntu:22.04 rancher

# Deploy usando inventário específico do Orbstack
ansible-playbook -i inventory/orbstack.ini site.yml

# Deploy com kubeconfig customizado
ansible-playbook -i inventory/orbstack.ini site.yml \
  -e "k3s_local_kubeconfig_path=$HOME/.kube/config-homelab"
```

### Deploy apenas K3s
```bash
ansible-playbook playbooks/setup-k3s-cluster.yml
```

### Deploy apenas Nginx Ingress
```bash
ansible-playbook playbooks/install-nginx-ingress.yml
```

### Verificar conectividade
```bash
ansible all -m ping
```

### Deploy com modo verbose
```bash
ansible-playbook site.yml -v
```

## Customização

### Variáveis do K3s
Edite `roles/k3s/defaults/main.yml`:
- `k3s_version`: Versão do K3s
- `k3s_install_options`: Opções de instalação
- `k3s_single_node`: Configuração single-node (sempre true)

### Variáveis do Nginx Ingress
Edite `roles/nginx-ingress/defaults/main.yml`:
- `nginx_ingress_version`: Versão do chart Helm
- `nginx_ingress_service_type`: Tipo de serviço (LoadBalancer/NodePort)
- `nginx_ingress_controller_replicas`: Número de réplicas

## Integração com Rancher

Após o deploy, você pode adicionar workers através do Rancher:

1. O token do node estará disponível em: `/var/lib/rancher/k3s/server/node-token`
2. A URL do servidor será: `https://<IP_DO_RASPBERRY>:6443`
3. Use esses dados no Rancher para adicionar novos nodes ao cluster

## Acesso ao Cluster

Após o deploy, o kubeconfig será salvo em `ansible/kubeconfig`.

```bash
# Usar o kubeconfig
export KUBECONFIG=~/Projects/personal/platform/homelab-v5/ansible/kubeconfig

# Verificar nodes
kubectl get nodes

# Verificar Nginx Ingress
kubectl get pods -n ingress-nginx
```

## Troubleshooting

### Verificar logs do K3s
```bash
ansible k3s_cluster -m shell -a "sudo journalctl -u k3s -n 50"
```

### Reiniciar K3s
```bash
ansible k3s_cluster -m systemd -a "name=k3s state=restarted" --become
```

### Obter token para adicionar workers
```bash
ansible k3s_cluster -m shell -a "sudo cat /var/lib/rancher/k3s/server/node-token" --become
```

### Remover K3s (cleanup completo)
```bash
# Cleanup completo - remove tudo
ansible-playbook -i inventory/orbstack.ini cleanup.yml

# Ou para Raspberry Pi
ansible-playbook -i inventory/raspberry.ini cleanup.yml

# Cleanup rápido (apenas desinstalar K3s)
ansible k3s_cluster -m shell -a "/usr/local/bin/k3s-uninstall.sh" --become
```

## Tags disponíveis

- `k3s`: Deploy apenas K3s
- `nginx`: Deploy apenas Nginx Ingress
- `info`: Mostrar informações do cluster

Exemplo:
```bash
ansible-playbook site.yml --tags nginx
```

## Notas Importantes

- Esta solução instala apenas um nó K3s single-node
- Workers devem ser adicionados posteriormente via Rancher ou manualmente
- O Traefik é desabilitado por padrão em favor do Nginx Ingress
- O token do node é preservado para uso futuro com Rancher