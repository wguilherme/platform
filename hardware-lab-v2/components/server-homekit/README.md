# ESP32 Web Server - Controle de Garagem

Projeto para ESP32-WROOM-32 com servidor web para controle de relé, integração com Apple HomeKit e atualização OTA (Over-The-Air).


## Estrutura do Projeto

```txt
  src/
  ├── main.cpp                    # Arquivo principal (limpo e organizado)
  ├── config.h                    # Configurações centralizadas
  ├── hardware/
  │   ├── RelayController.h       # Controle do relé
  │   └── RelayController.cpp
  ├── webserver/
  │   ├── WebServerManager.h      # Servidor web + interface
  │   └── WebServerManager.cpp
  ├── homekit/
  │   ├── HomeKitManager.h        # Gerenciador HomeKit
  │   ├── HomeKitManager.cpp
  │   ├── DEV_Relay.h            # Dispositivo relé HomeKit
  │   └── DEV_GarageDoor.h       # Dispositivo portão HomeKit
  └── utils/
      ├── OTAManager.h           # Gerenciador OTA
      └── OTAManager.cpp
```

## Configuração Inicial

1. **Copie o arquivo de configuração:**
```bash
cp src/config.example.h src/config.h
```

2. **Edite `src/config.h` com suas credenciais:**
- Wi-Fi (SSID e senha)
- Senha OTA para atualizações sem fio
- Configurações do HomeKit
- Ajustes de hardware (GPIO do relé, etc.)

**IMPORTANTE:** O arquivo `config.h` está no `.gitignore` e não será commitado.

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
# Upload via USB
pio run -e esp32dev -t upload

# Upload via WiFi/OTA
pio run -e esp32dev_ota -t upload
```

## Monitor Serial

```bash
# Monitor serial padrão
pio device monitor

# Ou especifique a porta (macOS)
pio device monitor -p /dev/cu.SLAB_USBtoUART -b 115200
```

## Recursos

- **Interface Web**: Acesse `http://esp32-garagem.local` ou pelo IP
- **Apple HomeKit**: Adicione com o código configurado em `config.h`
- **OTA Updates**: Atualize o firmware via Wi-Fi após o primeiro upload
- **Controle de Relé**: Toggle e modo pulso para portão de garagem

## Especificações ESP32-WROOM-32

- CPU: Dual-core 240MHz
- RAM: 520KB SRAM
- Flash: 4MB
- WiFi: 802.11 b/g/n
- Bluetooth: 4.2 BR/EDR + BLE
- GPIOs: 34 pinos