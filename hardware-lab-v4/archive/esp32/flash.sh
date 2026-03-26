#!/bin/bash

PORT="/dev/cu.usbserial-0001"
BAUD="115200"
BUILD_DIR=".pio/build/usb"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== hardware-lab-v4 | Primeiro Flash (USB) ===${NC}"
echo -e "${YELLOW}IMPORTANTE: Faca BOOT+RESET antes de continuar.${NC}"
echo ""

if [ ! -e "$PORT" ]; then
    echo -e "${RED}Porta $PORT nao encontrada.${NC}"
    ls /dev/cu.* 2>/dev/null | grep -Ev "Bluetooth|debug-console|wlan-debug|BeatsFitPro"
    exit 1
fi

if ! command -v pio &> /dev/null; then
    echo -e "${RED}PlatformIO nao encontrado: pip install platformio${NC}"
    exit 1
fi

echo -e "${YELLOW}Compilando...${NC}"
pio run -e usb
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Erro na compilacao.${NC}"
    exit 1
fi

echo -e "${YELLOW}Fazendo upload (--before no-reset)...${NC}"
esptool --chip esp32 \
    --port "$PORT" \
    --baud "$BAUD" \
    --before no-reset \
    --after hard-reset \
    write-flash -z \
    --flash-mode dio \
    --flash-freq 40m \
    --flash-size 4MB \
    0x1000  "$BUILD_DIR/bootloader.bin" \
    0x8000  "$BUILD_DIR/partitions.bin" \
    0x10000 "$BUILD_DIR/firmware.bin"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Flash concluido!${NC}"
    echo -e "${YELLOW}Proximos deploys: make deploy (via WiFi)${NC}"
else
    echo -e "${RED}✗ Erro no flash.${NC}"
    exit 1
fi
