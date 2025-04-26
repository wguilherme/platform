# Docker Registry Oficial - Protegido com Autenticação Básica (Nginx)

Esta pasta contém manifestos para rodar o Docker Registry com proteção de autenticação básica via Nginx (proxy reverso).

## Como funciona a arquitetura

- **registry**: Deployment/pod do Docker Registry, roda na porta 5000, NÃO é exposto diretamente ao mundo externo.
- **registry-nginx**: Deployment/pod do Nginx, roda na porta 8080, faz proxy para o `registry` e exige autenticação básica.
- **Ingress**: Expõe o serviço `registry-nginx` para o domínio externo (ex: `registry.phantombyte.uk`).

Assim, todo acesso externo ao registry é autenticado e protegido pelo Nginx.

## Como aplicar tudo

```sh
# Gere o arquivo htpasswd (exemplo para usuário admin):
htpasswd -nbB admin sua_senha > htpasswd
kubectl create secret generic registry-htpasswd -n registry --from-file=htpasswd=htpasswd

# Aplique todos os recursos:
kubectl apply -k .
```

## Como testar

1. **Sem autenticação (deve retornar 401):**
   ```sh
   curl -v https://registry.phantombyte.uk/v2/_catalog
   ```
2. **Com autenticação (deve retornar JSON):**
   ```sh
   curl -v -u admin:sua_senha https://registry.phantombyte.uk/v2/_catalog
   ```
3. **No Docker CLI:**
   ```sh
   docker login registry.phantombyte.uk
   # Informe usuário e senha
   ```

## Dicas e troubleshooting
- Sempre verifique se ambos os pods (`registry` e `registry-nginx`) estão `Running`:
  ```sh
  kubectl get pods -n registry
  ```
- O Ingress deve apontar para o serviço `registry-nginx` na porta 8080.
- Se alterar o htpasswd, atualize a secret e reinicie o deployment do Nginx:
  ```sh
  kubectl delete secret registry-htpasswd -n registry
  kubectl create secret generic registry-htpasswd -n registry --from-file=htpasswd=htpasswd
  kubectl rollout restart deployment registry-nginx -n registry
  ```

## Arquivos importantes
- `deployment.yaml`: Docker Registry (backend)
- `nginx-auth.yaml`: Deployment e Service do Nginx proxy (frontend)
- `nginx-configmap.yaml`: ConfigMap com o arquivo de configuração do Nginx.
- `htpasswd.example`: Exemplo de arquivo htpasswd.
- `README.md`: Este guia.

---

**Agora, só quem tiver usuário e senha consegue dar push/pull no seu registry!**

Se quiser proteger ainda mais (ex: limitar IP, integrar com OIDC), consulte a documentação do Nginx ou peça ajuda aqui.
