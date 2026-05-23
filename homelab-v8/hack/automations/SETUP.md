# Setup — homelab-v8 no Kind

## Pré-requisito

```sh
cp homelab-v8/.env.example homelab-v8/.env
# preencher GITHUB_TOKEN e TUNNEL_TOKEN
```

## Ordem de execução

```sh
make kind-up               # 1. sobe cluster Kind
make kind-secrets          # 2. cria secrets no cluster  (necessário env: GITHUB_TOKEN, TUNNEL_TOKEN)
make flux-bootstrap        # 3. instala Flux + dispara reconciliação de toda infra via GitOps  (necessário env: GITHUB_TOKEN, GITHUB_USER, GITHUB_REPO)
make kind-wait-controllers # 4. aguarda nginx-ingress + infrastructure-controllers ficarem Ready
make kind-wait             # 5. aguarda infrastructure (zot, tekton, cloudflare) + apps
make flux-status           # 6. confirma tudo True
```

> Flux sobe automaticamente: nginx-ingress · zot · tekton · cloudflare-tunnel

## Webhook GitHub (manual, uma vez)

Após o cluster estar Ready:
- URL: `https://tekton-webhook.brainylabs.com.br`
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
