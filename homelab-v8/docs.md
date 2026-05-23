# ── 0. PRÉ-REQUISITOS ─────────────────────────────────────────────────────────
brew install kind kubectl flux

# Variáveis obrigatórias
export GITHUB_TOKEN=ghp_...       # token com repo scope
export GITHUB_USER=wguilherme

# ── 1. CRIAR CLUSTER + FLUX BOOTSTRAP ────────────────────────────────────────
make -f homelab-v8/hack/automations/kind.mk kind
# cria cluster, instala ingress-nginx, faz flux bootstrap

export KUBECONFIG=~/.kube/kind-homelab-v8

# ── 2. AGUARDAR CONTROLLERS PRONTOS ──────────────────────────────────────────
flux get kustomization infrastructure-controllers --watch
# esperar READY=True antes de continuar

# ── 3. CRIAR SECRETS (plain — sem kubeseal no Kind) ───────────────────────────

# Tekton: GitHub webhook validation
kubectl create secret generic github-webhook-secret \
  --namespace tekton-pipelines \
  --from-literal=token=qualquer-string-local

# Cloudflare tunnel (dummy para Kind — tunnel não funciona localmente)
kubectl create namespace cloudflare
kubectl create secret generic tunnel-credentials \
  --namespace cloudflare \
  --from-literal=credentials.json='{}'

# ── 4. AGUARDAR INFRA COMPLETA ────────────────────────────────────────────────
flux get kustomizations -A --watch
# esperar infrastructure e apps READY=True

# ── 5. VERIFICAR STATUS GERAL ─────────────────────────────────────────────────
flux get kustomizations -A
flux get helmreleases -A
kubectl get pods -A --field-selector=status.phase!=Running

# ── 6. TESTAR nginx-hello ─────────────────────────────────────────────────────
kubectl port-forward svc/nginx-hello 8081:80 -n default &
curl http://localhost:8081
# deve retornar página nginx

# ── 7. TESTAR Zot registry ───────────────────────────────────────────────────
kubectl port-forward svc/zot 5000:5000 -n zot &
curl http://localhost:5000/v2/
# deve retornar {}

# ── 8. TESTAR Tekton (CI manual) ──────────────────────────────────────────────
# push imagem de teste para Zot local
docker build -t localhost:5000/go-hello:test homelab-v8/apps/go-hello/src/
docker push localhost:5000/go-hello:test

# disparar TaskRun manualmente (sem precisar de webhook GitHub)
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: go-hello-ci-manual-
  namespace: tekton-pipelines
spec:
  taskRef:
    name: go-hello-ci
  params:
    - name: image-repo
      value: localhost:5000/go-hello
  workspaces:
    - name: source
      emptyDir: {}
EOF

# acompanhar log
kubectl get taskruns -n tekton-pipelines -w

# ── 9. TEKTON DASHBOARD ───────────────────────────────────────────────────────
kubectl port-forward svc/tekton-dashboard 9097:9097 -n tekton-pipelines &
open http://localhost:9097

# ── 10. TESTAR go-hello deploy ────────────────────────────────────────────────
# atualizar imagem no deployment para a tag gerada no passo 8
kubectl set image deployment/go-hello go-hello=localhost:5000/go-hello:test -n default
kubectl port-forward svc/go-hello 8082:80 -n default &
curl http://localhost:8082
# deve retornar: Hello World! vdev

# ── 11. LIMPAR ────────────────────────────────────────────────────────────────
make -f homelab-v8/hack/automations/kind.mk kind-clean
