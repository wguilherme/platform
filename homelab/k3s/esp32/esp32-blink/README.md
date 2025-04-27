# ESP32 Blink Example

Este projeto é um exemplo simples para piscar o LED conectado à GPIO2 do ESP32 usando o ESP-IDF.

## Requisitos

- ESP-IDF instalado e configurado
- ESP32 conectado via USB
- Raspberry Pi 4B com Ubuntu Server

## Instruções

1. **Clone o repositório** (se ainda não tiver feito):
   ```sh
   git clone <URL_DO_REPOSITÓRIO>
   cd homelab/k3s/esp32/esp32-blink
   ```

2. **Exporte o ambiente do ESP-IDF**:
   ```sh
   . ~/esp/esp-idf/export.sh
   ```

3. **Configure o alvo** (apenas na primeira vez):
   ```sh
   idf.py set-target esp32
   ```

4. **Compile o projeto**:
   ```sh
   idf.py build
   ```

5. **Conecte o ESP32** via USB e grave o firmware:
   ```sh
   idf.py -p /dev/ttyUSB0 flash monitor
   ```
   > **Nota**: Se o dispositivo estiver em outro caminho, substitua `/dev/ttyUSB0` pelo caminho correto.

6. **Verifique o LED**:
   - O LED conectado à GPIO2 do ESP32 deve piscar a cada 500ms.

## Estrutura do Projeto

- `main/blink.c`: Código fonte do exemplo
- `CMakeLists.txt`: Configuração do projeto
- `main/CMakeLists.txt`: Configuração do componente
- `sdkconfig.defaults`: Configurações padrão (opcional)

## Solução de Problemas

- **Dispositivo não encontrado**: Verifique se o ESP32 está conectado e se o driver USB-Serial está carregado:
  ```sh
  lsusb
  ls /dev/ttyUSB*
  ```
- **Erro de permissão**: Adicione seu usuário ao grupo `dialout`:
  ```sh
  sudo usermod -aG dialout $USER
  sudo reboot
  ```

## Referências

- [ESP-IDF Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [ESP32 GPIO Reference](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html) 