# Tekton CI/CD para rpi-nginx-hello

Este diretório contém os manifests Tekton para buildar e publicar a imagem do projeto `rpi-nginx-hello` no Harbor, com trigger via GitHub.

## Estrutura
- **task-build-push.yaml**: Task que faz build/push da imagem com Kaniko.
- **pipeline.yaml**: Pipeline que executa a task.
- **github-binding.yaml**: Binding de parâmetros do webhook do GitHub.
- **trigger-template.yaml**: Define como criar um PipelineRun a partir do webhook.
- **event-listener.yaml**: Ouve webhooks do GitHub e dispara o pipeline.

## Pré-requisitos
- Tekton Pipelines e Triggers instalados no cluster
- PVC chamado `tekton-workspace-pvc` para workspace
- Secret Docker para o Harbor (`.dockerconfigjson`) no namespace Tekton
- ServiceAccount `tekton-triggers-sa` com acesso ao secret

## Como aplicar
```sh
kubectl apply -f task-build-push.yaml
kubectl apply -f pipeline.yaml
kubectl apply -f github-binding.yaml
kubectl apply -f trigger-template.yaml
kubectl apply -f event-listener.yaml
```

## Como funciona
1. Um push no GitHub dispara um webhook para o EventListener.
2. O TriggerBinding extrai info do push (SHA, repo, etc).
3. O TriggerTemplate cria um PipelineRun que builda e publica a imagem no Harbor.

## Customização
- Edite o valor do parâmetro `IMAGE` em `github-binding.yaml` para apontar para seu Harbor.
- Adapte o nome do PVC se necessário.

## Dica
Você pode copiar a pasta `tekton` para outros projetos, mudando apenas o nome da imagem e pipeline.
