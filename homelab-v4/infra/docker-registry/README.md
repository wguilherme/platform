# Docker Registry Oficial - Repositório de Imagens Leve para K3s/Raspberry Pi

Esta pasta contém os manifestos e instruções para rodar o Docker Registry oficial, ideal para ambientes de borda/homelab.

## Instalação rápida (Kubernetes)

```sh
kubectl apply -k .
```

- O registry ficará disponível em `registry.phantombyte.uk` (ajuste o domínio conforme necessário).
- Para autenticação, use um proxy reverso (Nginx, Traefik) ou configure autenticação básica.

Consulte a documentação oficial para configurações avançadas:
- https://hub.docker.com/_/registry
- https://docs.docker.com/registry/deploying/

---

## Como testar se está funcionando

### 1. Verifique os pods e o serviço
```sh
kubectl get pods -n registry
kubectl get svc -n registry
kubectl get ingress -n registry
```

Todos os pods devem estar `Running` e o serviço/ingress deve aparecer na lista.

### 2. Teste localmente (dentro do cluster)
```sh
kubectl run curl --rm -it --image=alpine --restart=Never -n registry -- sh
# Dentro do pod:
apk add curl
curl http://registry:5000/v2/_catalog
```

### 3. Teste externo (via domínio)
```sh
curl -k https://registry.phantombyte.uk/v2/_catalog
```
(Substitua pelo domínio configurado e adicione `-k` se estiver usando TLS self-signed.)

### 4. Faça push/pull de imagem
```sh
docker login registry.phantombyte.uk
# (informe usuário/senha se configurou auth)
docker tag nginx registry.phantombyte.uk/nginx:test
docker push registry.phantombyte.uk/nginx:test
docker pull registry.phantombyte.uk/nginx:test
```

Se todos esses passos funcionarem, seu registry está pronto para uso!
