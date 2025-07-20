#!/bin/bash

# Configurações do ESP32
PORT="/dev/cu.usbserial-0001"
BAUD_RATE="921600"
FLASH_MODE="dio"
FLASH_FREQ="40m"
FLASH_SIZE="4MB"

# Caminhos dos arquivos compilados (ajuste se necessário)
FIRMWARE_DIR=".pio/build/esp32dev"
BOOTLOADER="$FIRMWARE_DIR/bootloader.bin"
PARTITIONS="$FIRMWARE_DIR/partitions.bin"
APP="$FIRMWARE_DIR/firmware.bin"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== ESP32 Web Server Flash Tool ===${NC}"
echo ""

# Verifica se esptool está instalado
if ! command -v esptool.py &> /dev/null; then
    echo -e "${RED}Erro: esptool.py não encontrado!${NC}"
    echo "Instale com: pip install esptool"
    exit 1
fi

# Verifica se a porta existe
if [ ! -e "$PORT" ]; then
    echo -e "${RED}Erro: Porta $PORT não encontrada!${NC}"
    echo "Portas disponíveis:"
    ls /dev/cu.* | grep -E "(usb|SLAB)"
    exit 1
fi

# Compila o projeto se não existir firmware
if [ ! -f "$APP" ]; then
    echo -e "${YELLOW}Firmware não encontrado. Compilando projeto...${NC}"
    
    if command -v pio &> /dev/null; then
        pio run -e esp32dev
    else
        echo -e "${RED}Erro: PlatformIO não instalado!${NC}"
        echo "Instale com: pip install platformio"
        exit 1
    fi
fi

# Verifica se os arquivos existem após compilação
if [ ! -f "$BOOTLOADER" ] || [ ! -f "$PARTITIONS" ] || [ ! -f "$APP" ]; then
    echo -e "${RED}Erro: Arquivos de firmware não encontrados!${NC}"
    echo "Verifique se a compilação foi bem sucedida."
    exit 1
fi

echo -e "${GREEN}Iniciando flash do ESP32...${NC}"
echo "Porta: $PORT"
echo "Velocidade: $BAUD_RATE"
echo ""

# Flash do ESP32
esptool.py \
    --chip esp32 \
    --port "$PORT" \
    --baud "$BAUD_RATE" \
    --before default_reset \
    --after hard_reset \
    write_flash -z \
    --flash_mode "$FLASH_MODE" \
    --flash_freq "$FLASH_FREQ" \
    --flash_size "$FLASH_SIZE" \
    0x1000 "$BOOTLOADER" \
    0x8000 "$PARTITIONS" \
    0x10000 "$APP"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Flash concluído com sucesso!${NC}"
    echo ""
    echo -e "${YELLOW}Para monitorar o serial:${NC}"
    echo "pio device monitor -p $PORT -b 115200"
else
    echo ""
    echo -e "${RED}✗ Erro durante o flash!${NC}"
    exit 1
fi