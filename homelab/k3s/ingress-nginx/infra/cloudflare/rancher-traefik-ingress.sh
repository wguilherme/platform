kubectl apply -f - <<EOF
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: rancher
  namespace: cattle-system
spec:
  entryPoints:
    - web
    - websecure
  routes:
    - match: Host(\`rancher.phantombyte.uk\`)
      kind: Rule
      services:
        - name: rancher
          port: 80
          passHostHeader: true
      middlewares:
        - name: rancher-headers
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rancher-headers
  namespace: cattle-system
spec:
  headers:
    customRequestHeaders:
      X-Forwarded-Proto: "https"
EOF