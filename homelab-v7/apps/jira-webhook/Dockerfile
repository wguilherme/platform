FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY main.go .
RUN go mod init jira-webhook && go build -o jira-webhook .

FROM alpine:3.19
COPY --from=builder /app/jira-webhook /jira-webhook
ENTRYPOINT ["/jira-webhook"]
