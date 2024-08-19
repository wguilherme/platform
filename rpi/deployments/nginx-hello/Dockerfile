# Estágio de build
FROM golang:1.22.4 as builder

WORKDIR /app

COPY go.mod ./

RUN go mod download

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM gcr.io/distroless/static-debian12

WORKDIR /

COPY --from=builder /app/main .

USER nonroot:nonroot

CMD ["/main"]