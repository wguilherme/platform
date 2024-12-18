FROM node:18

WORKDIR /app

# Copiar apenas os arquivos de dependências primeiro
COPY package*.json ./
RUN npm install

# Copiar o resto dos arquivos
COPY . .

EXPOSE 3000

# Usar node com watch mode
CMD ["node", "--watch", "src/index.js"]