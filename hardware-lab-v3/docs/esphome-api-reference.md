# ESPHome API Reference - garagem-esp32.local

## Visão Geral

O ESPHome expõe duas APIs principais:

1. **API Nativa** (porta 6053) - Protocolo binário para Home Assistant
2. **Web API** (porta 80) - HTTP REST para integração externa

## Web API HTTP REST (Porta 80)

### Base URL
```
http://garagem-esp32.local
```

## Endpoints Disponíveis

### 📊 **Sensores (GET)**

#### Sinal WiFi
```http
GET /sensor/sinal_wifi
```
**Resposta:**
```json
{
  "id": "sensor-sinal_wifi",
  "value": -46,
  "state": "-46 dBm"
}
```

#### Tempo Ligado
```http
GET /sensor/tempo_ligado
```
**Resposta:**
```json
{
  "id": "sensor-tempo_ligado", 
  "value": 123.45,
  "state": "123.45 h"
}
```

#### Sistema Info
```http
GET /text_sensor/sistema_info
```
**Resposta:**
```json
{
  "id": "text_sensor-sistema_info",
  "value": "Device: ESP32 Garage Controller v1.0",
  "state": "Device: ESP32 Garage Controller v1.0"
}
```

### 🚪 **Cover (Portão)**

#### Status do Portão
```http
GET /cover/portao_garagem
```

#### Abrir Portão
```http
POST /cover/portao_garagem/open
```

#### Fechar Portão  
```http
POST /cover/portao_garagem/close
```

#### Parar Portão
```http
POST /cover/portao_garagem/stop
```

### 🔘 **Botões (POST)**

#### Abrir Portão (Pulso Garagem)
```http
GET /button/pulso_garagem
POST /button/pulso_garagem/press
```

#### Reiniciar ESP32
```http
POST /button/reiniciar_esp32/press
```

### 🔌 **Switches (GET/POST)**

#### Relé da Garagem
```http
GET /switch/rele_garagem
POST /switch/rele_garagem/turn_on
POST /switch/rele_garagem/turn_off
POST /switch/rele_garagem/toggle
```

### 📡 **Sensores Binários**

#### Status WiFi
```http
GET /binary_sensor/status_wifi
```

## Exemplos de Uso

### 1. Verificar Status do Sistema
```bash
# Sinal WiFi
curl http://garagem-esp32.local/sensor/sinal_wifi

# Tempo online
curl http://garagem-esp32.local/sensor/tempo_ligado

# Info do sistema
curl http://garagem-esp32.local/text_sensor/sistema_info
```

### 2. Controlar o Portão
```bash
# Abrir portão
curl -X POST http://garagem-esp32.local/cover/portao_garagem/open

# Fechar portão  
curl -X POST http://garagem-esp32.local/cover/portao_garagem/close

# Pulso direto
curl -X POST http://garagem-esp32.local/button/pulso_garagem/press
```

### 3. Controlar Relé Diretamente
```bash
# Ligar relé
curl -X POST http://garagem-esp32.local/switch/rele_garagem/turn_on

# Desligar relé
curl -X POST http://garagem-esp32.local/switch/rele_garagem/turn_off

# Toggle
curl -X POST http://garagem-esp32.local/switch/rele_garagem/toggle
```

### 4. Reiniciar ESP32
```bash
curl -X POST http://garagem-esp32.local/button/reiniciar_esp32/press
```

## Integração com N8N

### Webhook para Monitoramento
```javascript
// Node HTTP Request em N8N
{
  "method": "GET",
  "url": "http://garagem-esp32.local/sensor/sinal_wifi",
  "responseFormat": "json"
}
```

### Trigger por Status
```javascript
// Verificar se WiFi está fraco
const signal = $json.value;
if (signal < -70) {
  return [{
    "alert": "WiFi signal weak",
    "value": signal
  }];
}
```

### Ação de Controle
```javascript
// Acionar portão via N8N
{
  "method": "POST", 
  "url": "http://garagem-esp32.local/button/pulso_garagem/press"
}
```

## API Nativa ESPHome (Porta 6053)

A API nativa usa protocolo binário e é acessada pelo Home Assistant automaticamente.

### Configuração
```yaml
api:
  password: esp32_garagem_api
  port: 6053
```

### Entidades Expostas
- `cover.portao_garagem`
- `button.pulso_garagem` 
- `switch.rele_garagem`
- `sensor.sinal_wifi`
- `sensor.tempo_ligado`
- `binary_sensor.status_wifi`
- `button.reiniciar_esp32`

## Descoberta Automática

### Como descobrir novos endpoints

1. **Listar entidades via web interface:**
   ```
   http://garagem-esp32.local
   ```

2. **Padrão de URLs:**
   ```
   /{entity_type}/{entity_name}
   /{entity_type}/{entity_name}/{action}
   ```

3. **Tipos de entidade:**
   - `sensor` - GET apenas
   - `text_sensor` - GET apenas  
   - `binary_sensor` - GET apenas
   - `switch` - GET, POST (turn_on, turn_off, toggle)
   - `button` - GET, POST (press)
   - `cover` - GET, POST (open, close, stop)

## Monitoramento e Debug

### Logs
```bash
# Via ESPHome Dashboard
docker-compose logs -f esphome

# Via serial (se conectado USB)
esphome logs garage-controller.yaml
```

### Status HTTP
- **200**: Sucesso
- **404**: Entidade não encontrada  
- **500**: Erro interno

### Headers Recomendados
```http
Content-Type: application/json
Accept: application/json
```

## Limitações

1. **Sem autenticação** na API HTTP
2. **Sem rate limiting** 
3. **Sem documentação** OpenAPI/Swagger
4. **Protocolo simples** (não RESTful completo)
5. **Dependente da configuração** YAML

## Segurança

⚠️ **A API HTTP não tem autenticação**. Para produção:

1. **Configure firewall** para rede local apenas
2. **Use a API nativa** com senha via Home Assistant  
3. **Configure HTTPS** se necessário
4. **Monitore acessos** via logs