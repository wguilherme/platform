FROM golang:1.22.4

WORKDIR /usr/src/app

COPY go.mod ./
COPY go.sum ./
RUN go mod download && go mod verify

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -v -o /usr/local/bin/app ./...

CMD ["app"]