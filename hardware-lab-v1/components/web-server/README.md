cd homelab/k3s/esp32/web-server && ./flash.sh

# ESP32 Web Server - Controle de Garagem

Projeto para ESP32-WROOM-32 com servidor web para controle de relé.

## Pinout ESP32-WROOM-32

GPIOs recomendados para OUTPUT (relé):
- GPIO 2 (LED interno)
- GPIO 4, 5, 12, 13, 14, 15
- GPIO 16, 17, 18, 19
- GPIO 21, 22, 23
- GPIO 25, 26, 27
- GPIO 32, 33

Evite usar:
- GPIO 0: Boot mode
- GPIO 6-11: Flash SPI
- GPIO 34-39: Apenas INPUT

## Compilar e Upload

```bash
# Com PlatformIO
pio run -e esp32dev -t upload

# Ou use o script
./flash.sh
```

## Monitor Serial

```bash
pio device monitor -p /dev/cu.SLAB_USBtoUART -b 115200
```

## Especificações ESP32-WROOM-32

- CPU: Dual-core 240MHz
- RAM: 520KB SRAM
- Flash: 4MB
- WiFi: 802.11 b/g/n
- Bluetooth: 4.2 BR/EDR + BLE
- GPIOs: 34 pinos