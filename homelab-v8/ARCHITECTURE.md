# homelab-v8 — Arquitetura

## Visão geral

GitOps + CI/CD rodando em Kind (local) e K3s (prod ARM64).  
Flux gerencia toda infraestrutura e apps. Tekton faz build + push. Zot é o registry OCI.  
Cloudflare Tunnel expõe serviços externamente sem IP público.

---

## Ambientes

| | Kind (local) | K3s (prod) |
|---|---|---|
| Arch | amd64 (Mac) | ARM64 (Raspberry Pi) |
| StorageClass | `standard` | `local-path` |
| Secrets | plain `kubectl create secret` | Sealed Secrets (kubeseal) |
| Imagens locais | `kind load docker-image` + `imagePullPolicy: Never` | Tekton → Zot → Flux |
| DNS | Cloudflare Tunnel + Public Hostnames | igual |
| KUBECONFIG | `~/.kube/local/brainylabs/config.infra` | mesmo path |

---

## Domínio

`*.wguilherme.com` — gerenciado no Cloudflare.  
Subdomínios relevantes:
- `hello.wguilherme.com` → nginx-hello (teste)
- `api.wguilherme.com` → platform-agent-backend
- `registry.wguilherme.com` → Zot OCI registry (prod)

---

## Estrutura do repositório

```
homelab-v8/
├── Makefile                          # entry point: include hack/automations/core.mk
├── .env                              # gitignored — valores reais
├── .env.example                      # template
├── .tool-versions                    # versões asdf: kubectl, flux2, kind
│
├── hack/automations/                 # automação Make modular
│   ├── core.mk                       # carrega .env + inclui todos os .mk
│   ├── kind.mk                       # cluster lifecycle + kubeconfig + secrets
│   ├── flux.mk                       # bootstrap + status
│   ├── cloudflare.mk                 # helm install tunnel
│   ├── tekton.mk                     # dashboard + taskrun manual
│   ├── apps.mk                       # build/load/deploy apps locais
│   └── test.mk                       # smoke tests
│
├── flux/clusters/homelab/            # ponto de entrada do Flux
│   ├── infrastructure.yaml           # Kustomizations: infrastructure-controllers + infrastructure
│   ├── apps.yaml                     # Kustomization: apps
│   └── flux-system/                  # gerado pelo flux bootstrap
│
├── infrastructure/
│   ├── controllers/                  # camada 1: HelmRepositories + Sealed Secrets controller
│   ├── sources/
│   │   ├── helmrepositories.yaml     # ingress-nginx, sealed-secrets, cloudflare, zot
│   │   └── gitrepositories.yaml      # repos externos (ex: platform-agent)
│   ├── nginx-ingress/                # HelmRelease
│   ├── sealed-secrets/               # HelmRelease
│   ├── cloudflare-tunnel/            # HelmRelease + values.yaml
│   ├── zot/                          # HelmRelease + values.yaml (registry OCI)
│   ├── tekton/
│   │   ├── install/                  # Tekton Pipelines + Triggers + Dashboard (remote manifests)
│   │   └── config/                   # EventListener, RBAC, PVC workspace
│   └── apps/kustomization.yaml       # agrega todos os componentes acima
│
└── apps/
    ├── homelab/kustomization.yaml    # agrega todos os apps
    ├── nginx-hello/devops/           # app estático (sem CI)
    ├── go-hello/                     # app interno: src/ + devops/ completo com CI
    └── platform-agent/devops/        # app externo: só devops/ (src no repo brainyboxdev/platform-agent)
```

---

## Flux — camadas GitOps

```
flux-system (GitRepository: github.com/wguilherme/platform, branch: main)
    │
    ├── infrastructure-controllers    (camada 1)
    │   └── infrastructure/controllers/
    │       └── HelmRepositories + Sealed Secrets controller
    │
    ├── infrastructure                (camada 2, depende de controllers)
    │   └── infrastructure/apps/
    │       ├── sources (HelmRepositories + GitRepositories)
    │       ├── nginx-ingress
    │       ├── sealed-secrets
    │       ├── cloudflare-tunnel
    │       ├── zot
    │       └── tekton
    │
    └── apps                          (camada 3, depende de infrastructure)
        └── apps/homelab/
            ├── nginx-hello
            ├── go-hello              → também tem flux-kustomization.yaml próprio
            └── platform-agent        → também tem flux-kustomization.yaml próprio
```

**Regra:** cada app com CI tem seu próprio `flux-kustomization.yaml` que aponta para `devops/deploy/`. O `apps/homelab/kustomization.yaml` só agrega os recursos Flux (imagerepository, imagepolicy, etc.).

---

## CI/CD — Tekton

**Fluxo por app:**
```
git push → GitHub webhook
    │
    ▼
Tekton EventListener (namespace: tekton-pipelines)
    │  TriggerBinding extrai body.after (SHA)
    │  TriggerTemplate cria TaskRun
    ▼
Task: clone → kaniko build → push Zot
    │  tag: YYYYMMDDHHMMSS-<sha8>  (ex: 20260519-abc12345)
    ▼
Zot registry (registry.wguilherme.com)
    │
    ▼
Flux ImageRepository (scan a cada 1m)
    │  ImagePolicy: alphabetical asc, filtro ^\d{14}-[a-f0-9]{8}$
    ▼
Flux ImageUpdateAutomation
    │  atualiza deployment.yaml no Git + commit
    ▼
Flux Kustomization reconcilia → rollout no cluster
```

**Componentes Tekton por app:**
- `ci/task.yaml` — Task com steps: clone + build-push (kaniko)
- `ci/trigger.yaml` — TriggerBinding + TriggerTemplate

---

## Padrão de app (interno — código no mesmo repo)

```
apps/<app-name>/
├── src/                    # código fonte + Dockerfile
└── devops/
    ├── ci/
    │   ├── task.yaml
    │   └── trigger.yaml
    ├── deploy/
    │   ├── deployment.yaml  # anotação: # {"$imagepolicy": "flux-system:<app-name>"}
    │   ├── service.yaml
    │   ├── ingress.yaml
    │   └── kustomization.yaml
    ├── imagerepository.yaml
    ├── imagepolicy.yaml
    ├── imageupdate.yaml
    ├── flux-kustomization.yaml
    └── kustomization.yaml
```

---

## Padrão de app (externo — monorepo separado)

**No repo externo** (ex: `github.com/brainyboxdev/platform-agent`):
```
devops/<app-name>/ci/
├── task.yaml       # repo-url aponta pro repo externo
└── trigger.yaml
```

**No homelab-v8** (só ops, sem src):
```
apps/<app-name>/devops/
├── deploy/
│   ├── deployment.yaml   # imagePullPolicy: Never (Kind) ou IfNotPresent (K3s)
│   ├── service.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
├── imagerepository.yaml
├── imagepolicy.yaml
├── imageupdate.yaml
├── flux-kustomization.yaml
└── kustomization.yaml
```

**GitRepository** em `infrastructure/sources/gitrepositories.yaml` aponta pro repo externo (usado pelo Tekton Task no clone step, não pelo Flux diretamente — Flux segue o `flux-system` GitRepository para os manifestos).

**Exemplo:** `platform-agent-backend`
- Fonte: `github.com/brainyboxdev/platform-agent` (monorepo)
- Dockerfile em: `backend/Dockerfile`
- `app-dir` param do Tekton: `backend`
- Registry: `registry.wguilherme.com/platform-agent-backend`
- Ingress: `api.wguilherme.com`

---

## Secrets

### Kind (local)
Plain secrets criados via `make kind-secrets` (target em `kind.mk`):
- `tekton-pipelines/github-webhook-secret` — token webhook local
- `cloudflare/tunnel-credentials` — dummy `{}`

Secrets de app criados manualmente ou via target em `apps.mk`:
```bash
kubectl create secret generic platform-agent-secrets \
  --namespace default --from-literal=KEY=value ...
```

### K3s (prod)
Sealed Secrets: encriptar com `kubeseal`, commitar `sealed-secret.yaml`.
```bash
kubeseal --format yaml \
  --kubeconfig ~/.kube/local/brainylabs/config.infra \
  < /tmp/plain-secret.yaml \
  > apps/<app>/devops/deploy/sealed-secret.yaml
```
**Atenção:** Kind recria chave a cada `kind-down/up` — sealed secrets de Kind não funcionam no K3s e vice-versa.

---

## Makefile — comandos principais

```bash
# Setup completo (Kind)
make setup                        # kind-up + flux-bootstrap + secrets + wait

# Lifecycle
make kind-up                      # sobe cluster
make kind-down                    # destrói cluster
make kind-kubeconfig              # extrai kubeconfig isolado
make flux-bootstrap               # flux bootstrap github

# Cloudflare
make cloudflare-setup             # repo + secret + helm install
make cloudflare-status

# Apps locais (kind-load)
make platform-agent-build         # docker build
make platform-agent-load          # kind load docker-image
make platform-agent-deploy        # kubectl apply -k
make platform-agent-up            # build + load + deploy

# Observabilidade
make tekton-dashboard             # port-forward 9097
make kind-status
make flux-status
```

**Variáveis obrigatórias** (`.env`):
```
GITHUB_TOKEN=ghp_...
TUNNEL_TOKEN=eyJ...
```

**Variáveis opcionais** (têm default nos `.mk`):
```
KUBECONFIG_KIND=~/.kube/local/brainylabs/config.infra
CLUSTER_NAME=homelab-v8
GITHUB_USER=wguilherme
GITHUB_REPO=platform
GITHUB_BRANCH=main
```

---

## Cloudflare Tunnel

- Chart: `cloudflare/cloudflare-tunnel-remote` v0.1.2
- Autenticação: `TUNNEL_TOKEN` (remote-managed — roteamento configurado no dashboard CF)
- Roteamento: CF Dashboard → Zero Trust → Tunnels → Public Hostnames
- `*.wguilherme.com` → `http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80`
- DNS: CNAME `tunnelID.cfargotunnel.com` (criado manualmente ou via dashboard)

---

## Convenções

- Namespace padrão apps: `default`
- Namespace Tekton: `tekton-pipelines`
- Namespace Cloudflare: `cloudflare`
- Namespace Zot: `zot`
- Tag de imagem: `YYYYMMDDHHMMSS-<sha8>` — alphabetical sort = newest
- `imagePullPolicy: Never` em Kind, `IfNotPresent` em K3s
- StorageClass `standard` em Kind, `local-path` em K3s
- Flux image automation faz commit com author `flux-image-automation <flux@wguilherme.com>`
- Cada app tem `flux-kustomization.yaml` próprio — não depende só do `apps/homelab/kustomization.yaml`
- Monorepos externos: CI fica no repo externo em `devops/<app-name>/ci/`, ops fica no homelab-v8

---

## Arquivos-chave

| Arquivo | Função |
|---|---|
| `hack/automations/core.mk` | Entry point Make: carrega `.env` + todos módulos |
| `flux/clusters/homelab/infrastructure.yaml` | Define as 2 camadas de infra do Flux |
| `flux/clusters/homelab/apps.yaml` | Kustomization raiz dos apps |
| `infrastructure/apps/kustomization.yaml` | Agrega todos componentes de infra |
| `apps/homelab/kustomization.yaml` | Agrega todos apps |
| `infrastructure/sources/gitrepositories.yaml` | GitRepositories de repos externos |
| `apps/<app>/devops/flux-kustomization.yaml` | Flux Kustomization por app |
| `apps/<app>/devops/deploy/deployment.yaml` | Anotação `$imagepolicy` para Image Automation |
| `.env.example` | Template de todas envs necessárias |
| `.tool-versions` | Versões pinadas: kubectl, flux2, kind |
