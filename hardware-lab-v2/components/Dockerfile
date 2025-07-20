FROM python:3.9-slim

WORKDIR /app

# Instalar dependências
RUN apt-get update && \
    apt-get install -y curl git python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Instalar PlatformIO Core
RUN pip install platformio

# Instalar PySerial e Flask
RUN pip install pyserial flask

# Copiar arquivos
COPY app.py /app/
COPY esp32_project /app/esp32_project
COPY entrypoint.sh /app/

# Permissões de execução
RUN chmod +x /app/entrypoint.sh

# Expor porta da API
EXPOSE 8080

# Variável de ambiente para a porta do ESP32
ENV ESP32_PORT=/dev/ttyUSB0

# Iniciar aplicação
ENTRYPOINT ["/app/entrypoint.sh"]