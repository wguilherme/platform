FROM oven/bun:1.2-alpine AS base
WORKDIR /app

COPY index.ts .

EXPOSE 8080
CMD ["bun", "run", "index.ts"]
