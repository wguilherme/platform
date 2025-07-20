# Integração HomeKit - ESPHome Garage Controller

Este guia detalha as diferentes opções para integrar o controlador de garagem com Apple HomeKit.

## 🍎 Visão Geral das Opções

### 1. Via Home Assistant (Mais Popular)
- ✅ Configuração mais simples
- ✅ Interface gráfica para configuração
- ✅ Suporte completo a automações
- ✅ Logs e diagnósticos integrados
- ❌ Requer Home Assistant rodando 24/7

### 2. ESPHomeKit Bridge (Direto)
- ✅ Sem dependência do Home Assistant
- ✅ Leve e eficiente
- ✅ Conexão direta ESP32 ↔ HomeKit
- ❌ Configuração via linha de comando
- ❌ Recursos limitados comparado ao HA

### 3. Homebridge Plugin (Alternativa)
- ✅ Ecossistema Homebridge estabelecido
- ✅ Muitos plugins disponíveis
- ✅ Interface web para configuração
- ❌ Node.js e setup mais complexo

## 🏠 Opção 1: Home Assistant (Recomendado)

### Instalação do Home Assistant

#### Docker (Recomendado)
```bash
# Criar diretório de configuração
mkdir -p /opt/homeassistant/config

# Executar container
docker run -d \
  --name homeassistant \
  --privileged \
  --restart=unless-stopped \
  -e TZ=America/Sao_Paulo \
  -v /opt/homeassistant/config:/config \
  -v /run/dbus:/run/dbus:ro \
  --network=host \
  ghcr.io/home-assistant/home-assistant:stable
```

#### Raspberry Pi OS
```bash
# Instalação via script oficial
curl -fsSL https://get.home-assistant.io | bash
```

### Configuração ESPHome no Home Assistant

#### 1. Instalar Add-on ESPHome (HAOS)
1. **Supervisor** > **Add-on Store**
2. Procurar "ESPHome"
3. **Instalar** e **Iniciar**

#### 2. Adicionar Integração ESPHome
1. **Configurações** > **Dispositivos e Serviços**
2. **Adicionar Integração** > "ESPHome"
3. Host: `garagem-esp32.local`
4. Porta: `6053` (padrão)
5. Senha: valor de `api_password` do secrets.yaml

### Configuração HomeKit no Home Assistant

#### configuration.yaml
```yaml
# Habilitar descoberta
default_config:

# Configuração HomeKit
homekit:
  advertise_ip: 192.168.1.100  # IP do Home Assistant
  port: 21063
  filter:
    include_domains:
      - cover
    include_entities:
      - cover.portao_garagem
      - switch.rele_garagem
      - sensor.sinal_wifi
      - sensor.tempo_ligado
  entity_config:
    cover.portao_garagem:
      name: "Portão da Garagem"
      device_class: garage_door
    switch.rele_garagem:
      name: "Relé Garagem"
      type: switch
```

#### Reiniciar e Adicionar ao iPhone
1. **Desenvolvedor** > **Verificar Configuração**
2. **Reiniciar** Home Assistant
3. Abrir app **Casa** no iPhone/iPad
4. **Adicionar Acessório** > **Mais Opções**
5. Selecionar "Home Assistant Bridge"
6. Código de pareamento será exibido nos logs do HA

### Logs do Código de Pareamento
```bash
# Verificar logs do HomeKit
grep -i homekit /opt/homeassistant/config/home-assistant.log

# Ou via interface web
# Configurações > Logs > Filtrar por "homekit"
```

## 🔗 Opção 2: ESPHomeKit Bridge

### Instalação

#### macOS
```bash
# Instalar Go
brew install go

# Clonar projeto
git clone https://github.com/pteich/esphomekit
cd esphomekit

# Compilar
make build
```

#### Linux
```bash
# Instalar Go
sudo apt update
sudo apt install golang-go

# Clonar e compilar
git clone https://github.com/pteich/esphomekit
cd esphomekit
go build -o esphomekit main.go
```

#### Raspberry Pi
```bash
# Compilar para ARM
make build-arm
```

### Configuração

#### 1. Configurar ESPHome
Certifique-se que o ESP32 tem estas configurações:
```yaml
# garage-controller.yaml
api:
  password: !secret api_password
  port: 6053

# Opcional: MQTT para backup
# mqtt:
#   broker: !secret mqtt_broker
#   username: !secret mqtt_username
#   password: !secret mqtt_password
```

#### 2. Executar Bridge
```bash
# Executar com PIN específico
./esphomekit -pin 12345678

# Ou definir dispositivos manualmente
./esphomekit -pin 12345678 -devices garagem-esp32.local:6053
```

#### 3. Adicionar ao HomeKit
1. Abrir app **Casa**
2. **Adicionar Acessório**
3. **Mais Opções**
4. Selecionar "ESPHomeKit Bridge"
5. Inserir PIN: `12345678`

### Script de Inicialização (Systemd)
```bash
# Criar arquivo de serviço
sudo nano /etc/systemd/system/esphomekit.service
```

```ini
[Unit]
Description=ESPHomeKit Bridge
After=network.target

[Service]
Type=simple
User=pi
ExecStart=/home/pi/esphomekit/esphomekit -pin 12345678
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# Habilitar e iniciar
sudo systemctl enable esphomekit
sudo systemctl start esphomekit
sudo systemctl status esphomekit
```

## 🌉 Opção 3: Homebridge

### Instalação

#### Node.js e Homebridge
```bash
# Instalar Node.js (via NodeSource)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar Homebridge
sudo npm install -g homebridge

# Instalar plugin ESPHome
sudo npm install -g homebridge-esphome-ts
```

### Configuração

#### config.json
```bash
# Criar diretório de configuração
mkdir -p ~/.homebridge

# Editar configuração
nano ~/.homebridge/config.json
```

```json
{
  "bridge": {
    "name": "Homebridge",
    "username": "CC:22:3D:E3:CE:30",
    "port": 51826,
    "pin": "031-45-154"
  },
  "accessories": [],
  "platforms": [
    {
      "platform": "esphome",
      "name": "ESPHome",
      "devices": [
        {
          "host": "garagem-esp32.local",
          "password": "senha_api_esphome",
          "port": 6053,
          "name": "Garage Controller"
        }
      ]
    }
  ]
}
```

#### Executar Homebridge
```bash
# Primeira execução
homebridge

# Como serviço
sudo npm install -g homebridge-service-utils
sudo homebridge-service-install
```

### Interface Web (Opcional)
```bash
# Instalar UI
sudo npm install -g homebridge-config-ui-x

# Adicionar ao config.json
nano ~/.homebridge/config.json
```

```json
{
  "platforms": [
    {
      "name": "Config",
      "port": 8080,
      "platform": "config"
    }
  ]
}
```

Acesse: `http://localhost:8080`

## 📱 Configuração no iPhone/iPad

### Adicionar Ponte HomeKit

#### Via Código QR
1. Abrir app **Casa**
2. **Adicionar Acessório**
3. **Escanear Código**
4. Apontar para código QR do bridge

#### Via Código Manual
1. **Adicionar Acessório**
2. **Inserir código manualmente**
3. Digite o PIN de 8 dígitos
4. Confirmar adição

### Configurar Controles

#### Atribuir à Sala
1. Selecionar "Portão da Garagem"
2. **Configurações** > **Localização**
3. Escolher sala (ex: "Garagem")

#### Criar Automações
1. **Automação** > **Criar Automação**
2. **Quando chegarem pessoas**
3. Selecionar "Portão da Garagem"
4. **Abrir** quando chegarem

#### Adicionar à Control Center
1. **Configurações** > **Central de Controle**
2. **Personalizar Controles**
3. Adicionar **Casa**

## 🔐 Segurança e Melhores Práticas

### Senhas Fortes
```yaml
# secrets.yaml - Use senhas complexas
api_password: "MinhaS3nh4Sup3rS3gur4!"
ota_password: "OutraS3nh4C0mpl3x4@"
```

### Rede Isolada (Opcional)
```bash
# Criar VLAN para IoT devices
# Configurar no seu roteador:
# VLAN 10: 192.168.10.0/24 (IoT)
# VLAN 1:  192.168.1.0/24  (Devices principais)
```

### Firewall Rules
```bash
# Permitir apenas portas necessárias
# HomeKit: 5353 (mDNS), 21063 (Home Assistant)
# ESPHome: 6053 (API), 80 (Web)
```

### Monitoramento
```yaml
# Adicionar notificações de falha
binary_sensor:
  - platform: status
    name: "ESP32 Status"
    on_press:
      - homeassistant.service:
          service: notify.mobile_app_iphone
          data:
            message: "ESP32 Garage Controller offline!"
```

## 🔧 Troubleshooting HomeKit

### Device Não Aparece
1. **Verificar rede**: Todos na mesma VLAN?
2. **Firewall**: Portas bloqueadas?
3. **mDNS**: Funcionando? (`avahi-browse -a`)
4. **Logs**: Erros no bridge?

### Código de Pareamento Inválido
1. **Regenerar código** no bridge
2. **Resetar configuração HomeKit** no device
3. **Restart** do bridge

### Controle Não Responde
1. **Status API**: `curl http://garagem-esp32.local/status`
2. **Conectividade**: `ping garagem-esp32.local`
3. **Logs ESPHome**: `esphome logs garage-controller.yaml`

### Performance Lenta
1. **Intervalo de atualização**: Reduzir no YAML
2. **Rede WiFi**: Sinal forte?
3. **Bridge overload**: Muitos devices?

## 📊 Comparação de Performance

| Método | Latência | Recursos | Complexidade | Confiabilidade |
|--------|----------|----------|--------------|----------------|
| Home Assistant | ~200ms | Alto | Baixa | ⭐⭐⭐⭐⭐ |
| ESPHomeKit | ~100ms | Baixo | Média | ⭐⭐⭐⭐ |
| Homebridge | ~150ms | Médio | Alta | ⭐⭐⭐ |

## 🚀 Dicas Avançadas

### Múltiplos Devices
```yaml
# Agrupar múltiplos ESP32s
homekit:
  filter:
    include_entity_globs:
      - cover.*_garagem
      - switch.*_garage
```

### Scenes Personalizadas
```yaml
# configuration.yaml
scene:
  - name: "Sair de Casa"
    entities:
      cover.portao_garagem: open
      light.garagem: off
```

### Notificações Inteligentes
```yaml
automation:
  - alias: "Portão aberto à noite"
    trigger:
      platform: state
      entity_id: cover.portao_garagem
      to: 'open'
    condition:
      condition: time
      after: '22:00:00'
    action:
      - service: notify.mobile_app_iphone
        data:
          message: "⚠️ Portão da garagem aberto às {{ now().strftime('%H:%M') }}"
```

Para mais configurações avançadas, consulte a [documentação oficial do HomeKit](https://www.home-assistant.io/integrations/homekit/).