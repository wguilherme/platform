# rpi-nginx-hello

Aplicação Go de exemplo para rodar no Raspberry Pi/Kubernetes.

## Como rodar localmente

```sh
go run main.go
# Ou
GOOS=linux GOARCH=arm64 go build -o server main.go
./server
```

## Como buildar imagem Docker

```sh
docker build -t rpi-nginx-hello:latest .
```

## Como acessar

A aplicação sobe em `:8080`.

```
curl http://localhost:8080/
```

## Estrutura
- `main.go`: Código principal
- `go.mod`: Dependências
- `Dockerfile`: Build multi-stage para imagem enxuta
