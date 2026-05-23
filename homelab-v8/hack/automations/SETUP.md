# Setup — homelab-v8 no Kind

## Pré-requisito

```sh
cp homelab-v8/.env.example homelab-v8/.env
# preencher GITHUB_TOKEN e TUNNEL_TOKEN
```

## Comando único

```sh
make setup   # roda todas as etapas abaixo em ordem, para se qualquer uma falhar
```

## Ordem de execução (passo a passo)

```sh
make kind-up               # 1. sobe cluster Kind + exporta kubeconfig para KUBECONFIG_PLATFORM  (necessário env: KUBECONFIG_PLATFORM)
make kind-secrets          # 2. cria secrets no cluster  (necessário env: GITHUB_TOKEN, TUNNEL_TOKEN)
make flux-bootstrap        # 3. instala Flux + dispara reconciliação de toda infra via GitOps  (necessário env: GITHUB_TOKEN, GITHUB_USER, GITHUB_REPO)
make kind-wait-controllers # 4. aguarda nginx-ingress + infrastructure-controllers ficarem Ready
make kind-wait             # 5. aguarda infrastructure (zot, tekton, cloudflare) + apps
make flux-status           # 6. confirma tudo True
```

> Flux sobe automaticamente: nginx-ingress · zot · tekton · cloudflare-tunnel

## Cloudflare Tunnel — URL do serviço

A URL `http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80` é resolvida via CoreDNS porque o pod do tunnel roda **dentro do cluster**. Só funciona assim — se o tunnel rodasse fora (binário no host), precisaria do IP do node.

## Webhook GitHub (manual, uma vez)

Pré-requisito: Cloudflare Tunnel ativo e DNS `*.wguilherme.com` apontando para o tunnel correto.

GitHub → repositório → Settings → Webhooks → Add webhook:

| Campo        | Valor                                          |
| ------------ | ---------------------------------------------- |
| Payload URL  | `https://tekton-webhook.wguilherme.com`        |
| Content type | `application/json`                             |
| Secret       | `local-dev` (valor padrão do `kind-secrets`)   |
| Events       | Just the `push` event                          |

Após salvar, qualquer push em `main` que altere arquivos em `homelab-v8/apps/*/src/` dispara o CI automaticamente.

## Raspberry Pi (produção física)

### Pré-requisitos

- Ubuntu Server 24.04 LTS 64-bit gravado no SD card (via RPi Imager)
- SSH habilitado no Imager com chave pública `~/.ssh/id_rsa.pub`, usuário `ubuntu`, hostname `rpi`
- `.env` preenchido (GITHUB_TOKEN, TUNNEL_TOKEN)

### Passo a passo

```sh
make rpi-discover      # 0. descobre IP do RPi na rede via mDNS (rpi.local)
                       #    → atualize RPI_HOST=<ip> no .env
make rpi-check         # 1. valida ping + SSH + hostname + arch
make rpi-setup         # 2. roda tudo abaixo em sequência
```

### Comando único (após discovery)

```sh
make rpi-setup   # ansible → kubeconfig → secrets → flux → wait
```

### Passo a passo detalhado

```sh
make ansible-setup     # 1. provisiona K3s + nginx-ingress no RPi via Ansible  (necessário env: RPI_HOST)
make kubeconfig-rpi    # 2. copia kubeconfig do RPi para KUBECONFIG_PLATFORM  (necessário env: KUBECONFIG_PLATFORM)
make kind-secrets      # 3. cria secrets no cluster RPi  (necessário env: GITHUB_TOKEN, TUNNEL_TOKEN)
make flux-bootstrap    # 4. instala Flux + dispara reconciliação  (necessário env: GITHUB_TOKEN, GITHUB_USER, GITHUB_REPO)
make kind-wait-controllers
make kind-wait
make flux-status
```

> Kubeconfig salvo em `ansible/kubeconfig` e copiado para `KUBECONFIG_PLATFORM`.
> Todos os targets `make kind-*` funcionam no RPi desde que `KUBECONFIG_PLATFORM` aponte para o kubeconfig correto.

### Teardown

```sh
make rpi-teardown   # instruções para desinstalar K3s no RPi
```

## Teardown Kind/k3d

```sh
make teardown    # kind
make k3d-teardown
```
