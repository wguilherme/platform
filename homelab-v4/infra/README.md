# Infraestrutura Homelab v4


### Como executar o build/push CI

kubectl apply -f homelab-v4/tekton/task-build-push.yaml
kubectl apply -f homelab-v4/tekton/pipeline-build-rpi-nginx-hello.yaml
kubectl apply -f homelab-v4/tekton/pipelinerun-build-rpi-nginx-hello.yaml


### deploy da aplicação:
kubectl apply -f homelab-v4/deployments/rpi-nginx-hello/

