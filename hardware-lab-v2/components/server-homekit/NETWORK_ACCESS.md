# Acesso Profissional ao ESP32 Web Server

## Métodos de Acesso

### 1. Acesso via mDNS (Recomendado)
```
http://esp32-garagem.local
```
- Funciona em macOS, Linux (com Avahi) e Windows (com Bonjour)
- Não depende do IP dinâmico
- Nome persistente e memorável

### 2. Acesso via IP
O IP será mostrado no Monitor Serial ao iniciar o ESP32:
```bash
pio device monitor -p /dev/cu.SLAB_USBtoUART -b 115200
```

### 3. Descoberta na Rede

#### macOS/Linux:
```bash
# Descobrir dispositivos mDNS
dns-sd -B _http._tcp

# Resolver hostname para IP
dns-sd -G v4 esp32-garagem.local

# Scan de rede (requer nmap)
nmap -sn 10.3.152.0/24 | grep -B2 "Espressif"
```

#### Informações do Dispositivo:
- MAC Address: `3c:61:05:14:8c:98`
- Hostname: `esp32-garagem`
- Porta: 80 (HTTP)

## Configuração de IP Estático (Opcional)

### No Roteador:
1. Acesse configurações DHCP do roteador
2. Adicione reserva de IP:
   - MAC: `3c:61:05:14:8c:98`
   - IP: Escolha um IP fixo (ex: 10.3.152.100)

### No ESP32:
```cpp
// Adicionar antes de WiFi.begin()
IPAddress local_IP(10, 3, 152, 100);
IPAddress gateway(10, 3, 152, 1);
IPAddress subnet(255, 255, 255, 0);
WiFi.config(local_IP, gateway, subnet);
```

## Integração com Home Assistant

```yaml
switch:
  - platform: rest
    name: "Portão Garagem"
    resource: http://esp32-garagem.local/toggle
    method: POST
    
binary_sensor:
  - platform: rest
    name: "Status Portão"
    resource: http://esp32-garagem.local/status
    value_template: "{{ value_json.relay }}"
```

## Troubleshooting

### mDNS não funciona:
1. Verifique se o serviço está rodando:
   - macOS: Bonjour está sempre ativo
   - Linux: `sudo systemctl status avahi-daemon`
   - Windows: Instale Bonjour Print Services

2. Teste descoberta:
   ```bash
   ping esp32-garagem.local
   ```

### Monitoramento
A página web mostra automaticamente:
- IP atual
- Hostname
- MAC Address

Acesse a página e veja no rodapé as informações de rede.