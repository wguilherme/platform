#!/bin/bash

# Caminho do ESP-IDF (ajuste se necessário)
ESP_IDF_PATH=~/esp/esp-idf

# Caminho do dispositivo serial (ajuste se necessário)
SERIAL_PORT=${1:-/dev/ttyUSB0}

# Nome do arquivo .c (deve estar em main/)
C_FILE=${2:-blink.c}

# Exporta o ambiente do ESP-IDF
. $ESP_IDF_PATH/export.sh

# Garante que estamos na pasta do projeto
cd "$(dirname "$0")"

# Gera sdkconfig se não existir
if [ ! -f sdkconfig ]; then
    idf.py set-target esp32
fi

# Garante que o arquivo .c está em main/
if [ ! -f main/$C_FILE ]; then
    echo "Arquivo main/$C_FILE não encontrado!"
    exit 1
fi

# Builda o projeto
idf.py build
if [ $? -ne 0 ]; then
    echo "Erro na build!"
    exit 1
fi

# Faz o flash e abre o monitor
idf.py -p "$SERIAL_PORT" flash monitor 