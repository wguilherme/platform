# Guia de Instalação - ESPHome Garage Controller

Este guia detalha como instalar e configurar o controlador de garagem usando ESPHome.

## 📋 Pré-requisitos

### Software
- [ESPHome](https://esphome.io/guides/installing_esphome.html)
- [Python 3.7+](https://www.python.org/downloads/)
- Editor de texto (VS Code recomendado)

### Hardware
- ESP32-WROOM-32 ou compatível
- Módulo relé 1 canal (5V ou 3.3V)
- Fonte de alimentação (micro USB ou 5V externa)
- Jumpers dupont
- Protoboard (opcional)

## 🔧 Instalação do ESPHome

### Opção 1: Via pip (Recomendado)
```bash
pip install esphome
```

### Opção 2: Via Docker
```bash
docker pull esphome/esphome
```

### Opção 3: Via Home Assistant Add-on
1. Acesse Supervisor > Add-on Store
2. Procure por "ESPHome"
3. Instale e inicie

## 🔌 Conexões de Hardware

### Pinout ESP32
```
ESP32           Relé Module
GPIO21     ->   IN (Signal)
3.3V       ->   VCC
GND        ->   GND

ESP32           LED Status (opcional)
GPIO2      ->   LED interno (built-in)

ESP32           Sensor Porta (opcional)
GPIO12     ->   Reed Switch
3.3V       ->   Reed Switch (outro terminal)
```

### Diagrama de Conexão
```
[ESP32]                    [Relé]                    [Motor Garagem]
GPIO21 ---------> IN       NO ---------> Terminal +
3.3V   ---------> VCC      COM ---------> Terminal -
GND    ---------> GND      NC (não usado)
```

## 📁 Configuração de Arquivos

### 1. Clone/Copie os arquivos
```bash
cd hardware-lab-v3/esphome/
```

### 2. Configure credenciais
```bash
cp secrets.example.yaml secrets.yaml
nano secrets.yaml
```

Edite com suas credenciais:
```yaml
wifi_ssid: "Sua_Rede_WiFi"
wifi_password: "sua_senha_wifi"
ap_password: "senha_fallback"
api_password: "senha_api_esphome"
ota_password: "senha_ota_update"
```

### 3. Ajuste configurações (se necessário)
Edite `garage-controller.yaml` para ajustar:
- GPIOs utilizados
- Nome do dispositivo
- Configurações específicas

## 🚀 Primeira Instalação

### 1. Conecte o ESP32 via USB
```bash
# Verifique a porta serial
ls /dev/cu.* | grep usb
# ou no Linux/WSL
ls /dev/ttyUSB*
```

### 2. Compile e faça upload
```bash
# Entre no diretório
cd hardware-lab-v3/esphome/

# Compile e upload via USB
esphome run garage-controller.yaml
```

### 3. Monitore os logs
```bash
esphome logs garage-controller.yaml
```

## 📱 Configuração WiFi

### Primeira Conexão
1. O ESP32 criará um hotspot "Garagem-ESP32-Fallback"
2. Conecte-se com senha configurada em `secrets.yaml`
3. Navegue para `192.168.4.1`
4. Configure sua rede WiFi

### Verificação de Conectividade
```bash
# Ping para testar conectividade
ping garagem-esp32.local

# Acesse interface web
open http://garagem-esp32.local
```

## 🔄 Atualizações Futuras (OTA)

Após primeira instalação USB, use OTA:

```bash
# Upload via WiFi
esphome run garage-controller.yaml --device garagem-esp32.local

# Ou especifique IP diretamente
esphome run garage-controller.yaml --device 192.168.1.100
```

## 🏠 Integração Home Assistant

### 1. Descoberta Automática
1. Vá para **Configurações** > **Integrações**
2. ESPHome deve aparecer automaticamente
3. Clique em **Configurar**
4. Digite a senha da API

### 2. Configuração Manual
1. **Configurações** > **Integrações** > **Adicionar Integração**
2. Procure por "ESPHome"
3. Digite: `garagem-esp32.local` ou IP
4. Digite senha da API

### 3. Expor para HomeKit
Adicione ao `configuration.yaml`:
```yaml
homekit:
  filter:
    include_entities:
      - cover.portao_garagem
      - switch.rele_garagem
      - sensor.sinal_wifi
```

## 🔐 Configuração HomeKit Direto

### Opção 1: ESPHomeKit Bridge
```bash
# Instalar Go (se não tiver)
brew install go  # macOS
# ou apt install golang-go  # Ubuntu

# Clonar e compilar
git clone https://github.com/pteich/esphomekit
cd esphomekit
go build

# Executar bridge
./esphomekit -pin 12345678
```

### Opção 2: Homebridge Plugin
```bash
# Instalar Homebridge
npm install -g homebridge

# Instalar plugin ESPHome
npm install -g homebridge-esphome-ts

# Configurar plugin
nano ~/.homebridge/config.json
```

Adicione ao config.json:
```json
{
  "platforms": [
    {
      "platform": "esphome",
      "devices": [
        {
          "host": "garagem-esp32.local",
          "password": "senha_api_esphome",
          "port": 6053
        }
      ]
    }
  ]
}
```

## 🎨 Customização da Interface

### CSS Personalizado
Edite `custom/garage_interface.css` para:
- Alterar cores e temas
- Modificar layout
- Adicionar animações

### JavaScript Personalizado
Edite `custom/garage_interface.js` para:
- Adicionar funcionalidades
- Modificar comportamentos
- Integrar com outros sistemas

### Recarregar Customizações
```bash
# Recompile após mudanças em CSS/JS
esphome run garage-controller.yaml --device garagem-esp32.local
```

## 🐛 Solução de Problemas

### Não Compila
```bash
# Limpar cache
esphome clean garage-controller.yaml

# Verificar sintaxe
esphome config garage-controller.yaml

# Verbose compilation
esphome run garage-controller.yaml --verbose
```

### Não Conecta WiFi
1. Verifique credenciais em `secrets.yaml`
2. Confirme que rede é 2.4GHz (ESP32 não suporta 5GHz)
3. Verifique logs: `esphome logs garage-controller.yaml`

### OTA Falha
```bash
# Forçar via USB se OTA falhar
esphome run garage-controller.yaml --upload-port /dev/cu.usbserial-0001

# Verificar se dispositivo está online
ping garagem-esp32.local
```

### Interface Web Não Carrega
1. Confirme que `web_server` está habilitado no YAML
2. Verifique firewall/rede
3. Tente IP direto ao invés de `.local`
4. Verifique logs para erros

### HomeKit Não Detecta
1. Confirme que dispositivos estão na mesma rede
2. Reinicie Home Assistant ou bridge
3. Verifique configuração de filtros
4. Teste API manualmente: `curl http://garagem-esp32.local/cover/portao_garagem`

## 📊 Monitoramento

### Logs em Tempo Real
```bash
esphome logs garage-controller.yaml --device garagem-esp32.local
```

### Status via curl
```bash
# Status geral
curl http://garagem-esp32.local/text_sensor/sistema_info

# Status específico
curl http://garagem-esp32.local/sensor/sinal_wifi
```

### Diagnóstico de Rede
```bash
# Verificar conectividade
nmap -p 80,6053 garagem-esp32.local

# Testar mDNS
avahi-browse -a  # Linux
dns-sd -B _http._tcp  # macOS
```

## 🔄 Backup e Restauração

### Backup de Configuração
```bash
# Salvar configuração atual
esphome config garage-controller.yaml > backup_$(date +%Y%m%d).yaml

# Backup completo da pasta
tar -czf esphome_backup_$(date +%Y%m%d).tar.gz ../esphome/
```

### Restauração de Firmware
```bash
# Se dispositivo não responde, flash via USB
esphome run garage-controller.yaml --upload-port /dev/cu.usbserial-0001
```

## 🚀 Próximos Passos

1. **Teste todas as funcionalidades**
2. **Configure automações no Home Assistant**
3. **Adicione sensor de posição da porta (opcional)**
4. **Configure notificações**
5. **Integre com outros dispositivos**

Para dúvidas adicionais, consulte:
- [Documentação ESPHome](https://esphome.io/)
- [Comunidade Home Assistant](https://community.home-assistant.io/)
- [GitHub ESPHome](https://github.com/esphome/esphome)