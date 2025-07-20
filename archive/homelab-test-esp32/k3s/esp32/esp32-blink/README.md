# ESP32 Blink Example

Este projeto é um exemplo simples para piscar o LED conectado à GPIO2 do ESP32 usando o ESP-IDF.

## Requisitos

- ESP-IDF instalado e configurado
- ESP32 conectado via USB
- Raspberry Pi 4B com Ubuntu Server

## Instruções

1. **Clone o repositório** (se ainda não tiver feito):
   ```sh
   git clone https://github.com/wguilherme/platform.git
   cd platform/homelab/k3s/esp32/esp32-blink
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

## Automação do Build e Flash (script flash_esp32.sh)

Para facilitar o processo de build e gravação do firmware no ESP32, você pode usar o script `flash_esp32.sh` que já está na pasta deste projeto.

### Passos para usar a automação

1. **Dê permissão de execução ao script:**
   ```sh
   chmod +x flash_esp32.sh
   ```

2. **Execute o script:**
   ```sh
   ./flash_esp32.sh [porta_serial] [arquivo.c]
   ```
   - Se não informar argumentos, o script usará `/dev/ttyUSB0` e `blink.c` por padrão.
   - Exemplo customizado:
     ```sh
     ./flash_esp32.sh /dev/ttyACM0 meu_codigo.c
     ```

3. **O script irá:**
   - Exportar o ambiente do ESP-IDF.
   - Gerar o `sdkconfig` se não existir.
   - Buildar o projeto.
   - Gravar o firmware e abrir o monitor serial.

## Referências

- [ESP-IDF Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [ESP32 GPIO Reference](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/gpio.html) 


 <!-- ESP32-D0WDQ6. -->