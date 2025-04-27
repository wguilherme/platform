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

# Limpa build anterior e sdkconfig
rm -rf build/
rm -f sdkconfig

# Gera sdkconfig com as configurações corretas
idf.py set-target esp32

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

# Faz o flash com configurações específicas
echo "Fazendo flash do ESP32..."
python -m esptool --chip esp32 --port "$SERIAL_PORT" --baud 460800 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 40m --flash_size 4MB 0x1000 build/bootloader/bootloader.bin 0x8000 build/partition_table/partition-table.bin 0x10000 build/blink.bin

if [ $? -ne 0 ]; then
    echo "Erro no flash!"
    exit 1
fi

# Abre o monitor serial
echo "Abrindo monitor serial..."
idf.py -p "$SERIAL_PORT" monitor 