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
make kind-up               # 1. sobe cluster Kind + exporta kubeconfig para KUBECONFIG_KIND  (necessário env: KUBECONFIG_KIND)
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

Após o cluster estar Ready:
- URL: `https://tekton-webhook.wguilherme.com`
- Content-Type: `application/json`
- Secret: valor de `github-webhook-secret` no namespace `tekton-pipelines`
- Evento: `push`

## Raspberry Pi (produção física)

Substitui `make kind-up`. Restante idêntico.

**Pré-requisito:** ajustar `KUBECONFIG_KIND` no `.env` para o kubeconfig gerado pelo Ansible.

```sh
# [RPi físico]
ansible-playbook ansible/site.yml   # instala K3s + nginx-ingress, salva kubeconfig local

# [máquina local — mesmas automações]
make kind-secrets          # (necessário env: GITHUB_TOKEN, TUNNEL_TOKEN)
make flux-bootstrap        # (necessário env: GITHUB_TOKEN, GITHUB_USER, GITHUB_REPO)
make kind-wait-controllers
make kind-wait
make flux-status
```

## Teardown

```sh
make teardown
```
