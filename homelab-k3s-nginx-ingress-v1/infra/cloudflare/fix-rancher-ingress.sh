kubectl patch ingress rancher -n cattle-system --type=merge -p '
{
  "spec": {
    "rules": [
      {
        "host": "rancherv2.phantombyte.uk",
        "http": {
          "paths": [
            {
              "path": "/",
              "pathType": "ImplementationSpecific",
              "backend": {
                "service": {
                  "name": "rancher",
                  "port": {
                    "number": 443
                  }
                }
              }
            }
          ]
        }
      }
    ]
  },
  "metadata": {
    "annotations": {
      "nginx.ingress.kubernetes.io/backend-protocol": "HTTPS"
    }
  }
}'