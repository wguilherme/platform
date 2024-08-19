FROM golang:1.22.4 as builder

WORKDIR /app

COPY go.mod .
COPY main.go .

RUN go mod download

RUN go build -o main .

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/main .

CMD ["./main"]