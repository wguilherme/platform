limactl start --name=k3s k3s.yaml ou lima start k3s.yaml
limactl shell k3s
mkdir -p ~/.kube
limactl shell k3s sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config

limactl stop k3s
limactl delete k3s