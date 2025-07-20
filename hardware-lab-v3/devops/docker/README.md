# Home Assistant + ESPHome Docker Setup

Esta configuração Docker permite executar o Home Assistant para consumir e gerenciar o dispositivo ESPHome de controle da garagem, além de outros dispositivos que você possa adicionar.

## Estrutura de Arquivos

```
devops/docker/
├── docker-compose.yml           # Configuração principal do Docker Compose
├── .env                        # Variáveis de ambiente
├── start.sh                    # Script de inicialização
├── README.md                   # Esta documentação
└── homeassistant/              # Configurações do Home Assistant
    ├── configuration.yaml      # Configuração principal
    ├── automations.yaml        # Automações
    ├── scripts.yaml            # Scripts
    ├── scenes.yaml             # Cenas
    ├── groups.yaml             # Grupos
    └── customize.yaml          # Customizações
```

## Pré-requisitos

- Docker e Docker Compose instalados
- ESP32 da garagem funcionando (garagem-esp32.local)
- Rede local configurada
- Portas 8123 e 6052 disponíveis

## Configuração Rápida

### 1. Iniciar os Serviços

```bash
cd devops/docker
./start.sh
```

Ou manualmente:

```bash
docker-compose up -d
```

### 2. Acessar o Home Assistant

- **URL**: http://localhost:8123
- **Setup inicial**: Siga o assistente de configuração
- **Criar usuário**: Defina usuário e senha do administrador

### 3. Integrar o ESP32

1. Vá em **Settings** > **Devices & Services**
2. Clique em **Add Integration**
3. Procure por **ESPHome**
4. Configure:
   - **Host**: `garagem-esp32.local`
   - **Port**: `6053` (API port)
   - **Password**: `esp32_garagem_api`

## Serviços Incluídos

### Home Assistant (Porta 8123)

**Funcionalidades configuradas:**

- **Dashboard principal** com controles da garagem
- **Automações** para notificações e auto-fechamento
- **Scripts** para ações seguras
- **Cenas** para diferentes modos de operação
- **Integração HomeKit** (opcional)
- **Descoberta automática** de dispositivos ESPHome

### ESPHome Dashboard (Porta 6052)

**Para gerenciamento de dispositivos:**

- **Compilar** e fazer **upload OTA**
- **Monitorar logs** em tempo real
- **Editar configurações** YAML
- **Adicionar novos dispositivos**

## Configurações Principais

### Automações Incluídas

1. **Notificação de Ações**: Notifica quando garagem for acionada
2. **Auto Fechar**: Fecha automaticamente após tempo configurado
3. **Alerta Garagem Aberta**: Avisa se ficar aberta muito tempo
4. **Log de Atividades**: Registra todas as ações

### Scripts Disponíveis

1. **Acionar com Confirmação**: Pulso com log e notificação
2. **Fechar com Segurança**: Fechamento com verificações
3. **Abrir Garagem**: Abertura com notificação
4. **Verificar Sistema**: Status de todos os componentes
5. **Reiniciar ESP32**: Restart remoto do dispositivo

### Cenas Configuradas

1. **Chegando em Casa**: Auto-fechar ativado (5 min)
2. **Saindo de Casa**: Auto-fechar desativado
3. **Modo Noturno**: Auto-fechar rápido (2 min)
4. **Modo Segurança**: Auto-fechar muito rápido (1 min)
5. **Modo Manutenção**: Todos os automatismos desativados

## Entidades do ESP32 no Home Assistant

Após a integração, você terá acesso a:

- **`cover.portao_garagem`**: Controle do portão (abrir/fechar)
- **`button.pulso_garagem`**: Botão de pulso
- **`switch.rele_garagem`**: Controle direto do relé
- **`sensor.sinal_wifi`**: Força do sinal WiFi
- **`sensor.tempo_ligado`**: Tempo online do ESP32
- **`button.reiniciar_esp32`**: Reiniciar dispositivo

## Adicionando Novos Dispositivos ESPHome

### 1. Pelo ESPHome Dashboard

1. Acesse http://localhost:6052
2. Clique em **+ New Device**
3. Configure o novo dispositivo
4. Compile e faça upload

### 2. Pelo Home Assistant

1. Vá em **Settings** > **Devices & Services**
2. O dispositivo aparecerá automaticamente se estiver na mesma rede
3. Clique em **Configure** e forneça a senha da API

### 3. Estrutura de Arquivos

Coloque os arquivos YAML na pasta `../../esphome/`:

```
esphome/
├── garage-controller.yaml      # Controle da garagem (existente)
├── sensor-temperature.yaml     # Novo sensor de temperatura
├── smart-switch.yaml          # Nova tomada inteligente
└── secrets.yaml               # Credenciais compartilhadas
```

## Configuração de Notificações

### Mobile App (Recomendado)

1. Instale o app "Home Assistant" no seu celular
2. Configure a conexão com seu servidor
3. As notificações funcionarão automaticamente

### Telegram (Alternativo)

Adicione no `configuration.yaml`:

```yaml
telegram_bot:
  - platform: polling
    api_key: "SEU_BOT_TOKEN"
    allowed_chat_ids:
      - SEU_CHAT_ID

notify:
  - name: telegram
    platform: telegram
    chat_id: SEU_CHAT_ID
```

## Backup e Restauração

### Backup Automático

```bash
# Backup completo
docker run --rm -v hardware-lab-v3_homeassistant_data:/data -v $(pwd):/backup alpine tar czf /backup/ha-backup-$(date +%Y%m%d).tar.gz -C /data .

# Backup das configurações
tar -czf ha-config-backup-$(date +%Y%m%d).tar.gz homeassistant/
```

### Restauração

```bash
# Restaurar volume
docker run --rm -v hardware-lab-v3_homeassistant_data:/data -v $(pwd):/backup alpine tar xzf /backup/ha-backup-YYYYMMDD.tar.gz -C /data

# Restaurar configurações
tar -xzf ha-config-backup-YYYYMMDD.tar.gz
```

## Troubleshooting

### Home Assistant não inicia

```bash
# Verificar logs
docker-compose logs homeassistant

# Verificar configuração
docker exec -it homeassistant-garagem hass --script check_config
```

### ESP32 não é detectado

```bash
# Testar conectividade
ping garagem-esp32.local

# Verificar logs ESPHome
docker-compose logs esphome

# Verificar porta API (6053)
telnet garagem-esp32.local 6053
```

### Erro de integração ESPHome

1. Verifique se as senhas estão corretas
2. Confirme que o ESP32 está online
3. Reinicie a integração em **Settings** > **Devices & Services**

### Performance

```bash
# Monitorar recursos
docker stats

# Limpar logs antigos
docker-compose exec homeassistant rm -rf /config/home-assistant.log.*
```

## Comandos Úteis

```bash
# Iniciar serviços
docker-compose up -d

# Parar serviços
docker-compose down

# Reiniciar apenas Home Assistant
docker-compose restart homeassistant

# Entrar no container do Home Assistant
docker exec -it homeassistant-garagem /bin/bash

# Verificar configuração
docker exec -it homeassistant-garagem hass --script check_config

# Ver logs em tempo real
docker-compose logs -f homeassistant

# Atualizar para versão mais recente
docker-compose pull && docker-compose up -d
```

## Segurança

### Configuração de Firewall

```bash
# Permitir acesso apenas da rede local
sudo ufw allow from 192.168.1.0/24 to any port 8123
sudo ufw allow from 192.168.1.0/24 to any port 6052
```

### HTTPS (Recomendado para acesso externo)

Adicione no `configuration.yaml`:

```yaml
http:
  ssl_certificate: /ssl/fullchain.pem
  ssl_key: /ssl/privkey.pem
```

## Monitoramento

### Logs importantes a monitorar

1. **Conexões ESP32**: Falhas de comunicação
2. **Automações**: Execução incorreta
3. **Performance**: Uso de CPU/memória
4. **Segurança**: Tentativas de acesso

### Métricas de sistema

O Home Assistant inclui sensores de:
- Uso de CPU
- Uso de memória
- Espaço em disco
- Tempo de resposta

## Expansão Futura

### Integração com outros sistemas

- **Apple HomeKit**: Já configurado
- **Google Assistant**: Adicionar integração
- **Amazon Alexa**: Configurar skill
- **MQTT**: Para dispositivos não-ESPHome

### Dispositivos sugeridos para adicionar

1. **Sensores de temperatura/umidade**
2. **Câmeras de segurança**
3. **Tomadas inteligentes**
4. **Sensores de movimento**
5. **Controle de iluminação**

## Suporte

Para problemas específicos:

- **Home Assistant**: https://community.home-assistant.io/
- **ESPHome**: https://esphome.io/
- **Docker**: https://docs.docker.com/