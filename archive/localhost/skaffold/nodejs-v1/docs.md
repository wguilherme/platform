
## criar cluster k3d
k3d cluster create dev-cluster --registry-create k3d-registry.localhost:5000 --api-port 6550 -p 8080:80@loadbalancer --agents 1 --kubeconfig-update-default=false

## exportar kubeconfig
k3d kubeconfig write dev-cluster --output /Users/withneyguilherme/.kube/k3d/config.skaffold1

## rodar o skaffold passando um kubeconfig especifico
env KUBECONFIG=/Users/withneyguilherme/.kube/k3d/config.skaffold1 skaffold dev


## o comando abaixo funcionou, aprentemente
 skaffold dev --kubeconfig /Users/withneyguilherme/.kube/lima/config.k3s1 --default-repo=dev.local





v2
docker container run -d --name registry.local -v local_registry:/var/lib/registry --restart always -p 5001:5000 registry:2
mkdir -p /Users/withneyguilherme/.k3d
k3d cluster create dev-cluster --api-port 6550 -p 8080:80@loadbalancer --agents 1 --volume /Users/withneyguilherme/.k3d/registries.yaml:/etc/rancher/k3s/registries.yaml --kubeconfig-update-default=false
k3d kubeconfig write dev-cluster --output /Users/withneyguilherme/.kube/k3d/config.skaffold1
docker network connect k3d-dev-cluster registry.local
sudo sh -c 'echo "127.0.0.1 registry.local" >> /etc/hosts'



v3
# setup
skaffold config set --kube-context k3d-dev-cluster local-cluster true

k3d cluster create dev-cluster --api-port 6550 -p 8080:80@loadbalancer --agents 1 --kubeconfig-update-default=false

k3d kubeconfig write dev-cluster --output /Users/withneyguilherme/.kube/k3d/config.skaffold1

env KUBECONFIG=/Users/withneyguilherme/.kube/k3d/config.skaffold1 skaffold dev

# verify
kubectl --kubeconfig /Users/withneyguilherme/.kube/k3d/config.skaffold1 get pods -n nodejs-v1


src/**/* -> Apenas sync (definido no sync.manual)
k8s/*.yaml -> Apenas reaplica (definido no manifests.rawYaml)
Todos os outros arquivos -> Causam rebuild