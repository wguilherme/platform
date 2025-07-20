# Hardware Lab v3 - ESPHome Garage Controller

Controlador de garagem inteligente usando ESPHome com integração HomeKit.

## 📋 Características

- **Plataforma**: ESP32-WROOM-32
- **Framework**: ESPHome (YAML declarativo)
- **Controle**: Relé GPIO para acionamento do portão
- **Interface**: Web server com CSS/JS customizado
- **Integração**: HomeKit via Home Assistant ou bridges diretos
- **Atualizações**: OTA (Over-The-Air)
- **Configuração**: Arquivo YAML simples e declarativo

## 🚀 Vantagens sobre v1 e v2

### Comparação com hardware-lab-v1 (Arduino C++)
- ✅ Configuração declarativa vs código C++
- ✅ Interface web incluída e customizável
- ✅ OTA updates automáticos
- ✅ Integração HomeKit mais simples
- ✅ Logs e diagnósticos integrados
- ✅ Sem necessidade de gerenciar bibliotecas manualmente

### Comparação com hardware-lab-v2 (Modular C++)
- ✅ Menos linhas de código (YAML vs C++ modular)
- ✅ Configuração mais legível e manutenível
- ✅ Menos propenso a erros de compilação
- ✅ Comunidade ESPHome ativa
- ✅ Templates prontos para dispositivos comuns

## 🏗️ Estrutura do Projeto

```
hardware-lab-v3/
├── esphome/
│   ├── garage-controller.yaml     # Configuração principal
│   ├── secrets.yaml              # Credenciais (não commitar)
│   ├── secrets.example.yaml      # Template de credenciais
│   └── custom/
│       ├── garage_interface.css  # CSS customizado
│       └── garage_interface.js   # JavaScript customizado
└── docs/
    ├── README.md                 # Este arquivo
    ├── SETUP.md                  # Guia de instalação
    └── HOMEKIT.md               # Integração HomeKit
```

## 🔧 Hardware Necessário

- **ESP32-WROOM-32** ou similar
- **Módulo relé** (5V/3.3V compatível)
- **Fonte de alimentação** (micro USB ou externa)
- **Jumpers** para conexões
- **Opcional**: Reed switch para sensor de posição da porta

## 📟 Pinout

```
GPIO21 - Relé (saída)
GPIO2  - LED de status (built-in)
GPIO12 - Sensor da porta (opcional, INPUT_PULLUP)
```

## 🌐 Opções de Integração HomeKit

### 1. Via Home Assistant (Recomendado)
```yaml
# configuration.yaml do Home Assistant
esphome:

homekit:
  filter:
    include_entities:
      - cover.portao_garagem
```

### 2. ESPHomeKit Bridge (Direto)
```bash
# Instalar e executar bridge
./esphomekit -pin 12345678
```

### 3. Homebridge Plugin
```json
{
  "platform": "esphome",
  "devices": [
    {
      "host": "garagem-esp32.local",
      "password": "api_password",
      "port": 6053
    }
  ]
}
```

## 🎨 Interface Web

A interface web está disponível em:
- **Local**: `http://garagem-esp32.local`
- **IP direto**: `http://192.168.x.x` (IP do dispositivo)

### Recursos da Interface
- Design responsivo para mobile e desktop
- Confirmação para ações críticas
- Auto-refresh a cada 30 segundos
- Feedback visual para ações
- Suporte a dark mode
- Atalhos de teclado (Space/Enter para acionar, Ctrl+R para refresh)

## 📱 Controle

### Entidades Disponíveis
- **Portão Garagem** (cover) - Controle principal HomeKit
- **Relé Garagem** (switch) - Controle direto do relé
- **Pulso Garagem** (switch) - Acionamento temporizado
- **Acionar Portão** (button) - Botão de ação

### Sensores
- **Sinal WiFi** - Força do sinal
- **Tempo Ligado** - Uptime do dispositivo
- **Status WiFi** - Estado da conexão
- **IP Address** - Endereço IP atual
- **MAC Address** - Endereço MAC

## 🔐 Segurança

- Senhas configuráveis para API e OTA
- Fallback access point para recuperação
- Interface web protegida (opcional)
- Confirmação para ações críticas

## 📊 Monitoramento

- Logs detalhados via serial e web
- Sensores de sistema (WiFi, uptime, IP)
- Status de conectividade
- Diagnósticos automáticos

## 🔄 Atualizações

### OTA (Over-The-Air)
```bash
# Via ESPHome CLI
esphome run garage-controller.yaml --device garagem-esp32.local
```

### Via Interface Web
1. Acesse `http://garagem-esp32.local`
2. Clique em "Update" (se disponível)
3. Upload do firmware compilado

## 🐛 Troubleshooting

### Não conecta no WiFi
1. Verifique credenciais em `secrets.yaml`
2. Conecte no fallback AP: "Garagem-ESP32-Fallback"
3. Configure WiFi via captive portal

### Interface web não carrega
1. Verifique se está na mesma rede
2. Tente acessar por IP direto
3. Verifique logs via serial

### HomeKit não detecta
1. Verifique se Home Assistant está configurado
2. Confirme que a API está habilitada
3. Restart do Home Assistant

## 📚 Recursos Úteis

- [Documentação ESPHome](https://esphome.io/)
- [Cookbook - Garage Door](https://esphome.io/cookbook/garage-door.html)
- [Web Server Component](https://esphome.io/components/web_server.html)
- [Cover Component](https://esphome.io/components/cover/template.html)

## 🤝 Contribuição

Este projeto faz parte do hardware-lab e segue as melhores práticas de ESPHome. Para contribuições:

1. Fork o projeto
2. Crie uma branch para sua feature
3. Teste thoroughly
4. Envie um PR com descrição detalhada

## 📄 Licença

MIT License - veja arquivo LICENSE para detalhes.