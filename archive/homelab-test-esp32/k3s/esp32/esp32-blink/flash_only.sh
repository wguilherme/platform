#!/bin/bash

# Configurações
BINARY_URL=${1:-"https://github.com/seu-repo/releases/latest/download/firmware.bin"}
SERIAL_PORT=${2:-"/dev/ttyUSB0"}

# Download do binário
echo "Baixando firmware de $BINARY_URL..."
wget -O firmware.bin "$BINARY_URL"

# Verifica se o download foi bem sucedido
if [ ! -f firmware.bin ]; then
    echo "Erro: Falha no download do firmware"
    exit 1
fi

# Flash do ESP32
echo "Gravando firmware no ESP32..."
esptool.py --chip esp32 --port "$SERIAL_PORT" --baud 115200 \
    --before default_reset --after hard_reset write_flash \
    -z --flash_mode dio --flash_freq 40m --flash_size detect \
    0x10000 firmware.bin

# Verifica resultado
if [ $? -eq 0 ]; then
    echo "Flash concluído com sucesso!"
else
    echo "Erro durante o flash"
    exit 1
fi 