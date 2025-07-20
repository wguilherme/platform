#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>

// configs/vars
const char* WIFI_SSID = "";
const char* WIFI_PASSWORD = "";

const int RELAY_GPIO = 2;
const int RELAY_ON_STATE = LOW;
const int RELAY_OFF_STATE = HIGH;

const int WEB_SERVER_PORT = 80;
const char* HOSTNAME = "esp32-garagem"; // mapping mDNS (rede local)


WebServer server(WEB_SERVER_PORT);

bool relayState = false;

const char* htmlPage = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Automação Garagem</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .container {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            padding: 40px;
            max-width: 450px;
            width: 100%;
            text-align: center;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .header {
            margin-bottom: 30px;
        }
        
        .header h1 {
            color: #333;
            font-size: 2.2em;
            font-weight: 700;
            margin-bottom: 10px;
            text-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .header .subtitle {
            color: #666;
            font-size: 1.1em;
            font-weight: 300;
        }
        
        .status-card {
            background: #fff;
            border-radius: 15px;
            padding: 25px;
            margin: 25px 0;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
            border: 2px solid transparent;
            transition: all 0.3s ease;
        }
        
        .status-card.on {
            border-color: #4CAF50;
            background: linear-gradient(135deg, #4CAF50, #45a049);
            color: white;
        }
        
        .status-card.off {
            border-color: #f44336;
            background: linear-gradient(135deg, #f44336, #da190b);
            color: white;
        }
        
        .status-icon {
            font-size: 3em;
            margin-bottom: 10px;
        }
        
        .status-text {
            font-size: 1.4em;
            font-weight: 600;
            margin-bottom: 5px;
        }
        
        .status-detail {
            font-size: 1em;
            opacity: 0.9;
        }
        
        .controls {
            display: flex;
            flex-direction: column;
            gap: 15px;
            margin: 30px 0;
        }
        
        .btn {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 18px 25px;
            border-radius: 12px;
            font-size: 1.1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
        }
        
        .btn:active {
            transform: translateY(0);
        }
        
        .btn-toggle {
            background: linear-gradient(135deg, #2196F3, #1976D2);
        }
        
        .btn-pulse {
            background: linear-gradient(135deg, #FF9800, #F57C00);
        }
        
        .info-panel {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            padding: 20px;
            margin-top: 30px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .info-panel h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 1.1em;
        }
        
        .info-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 0;
            border-bottom: 1px solid rgba(0, 0, 0, 0.1);
            font-size: 0.9em;
        }
        
        .info-item:last-child {
            border-bottom: none;
        }
        
        .info-label {
            color: #666;
            font-weight: 500;
        }
        
        .info-value {
            color: #333;
            font-weight: 600;
            font-family: monospace;
        }
        
        .footer {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid rgba(0, 0, 0, 0.1);
            color: #666;
            font-size: 0.85em;
        }
        
        .pulse {
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }
        
        @media (max-width: 480px) {
            .container {
                padding: 25px;
                margin: 10px;
            }
            
            .header h1 {
                font-size: 1.8em;
            }
            
            .controls {
                gap: 12px;
            }
            
            .btn {
                padding: 15px 20px;
                font-size: 1em;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏠 Automação Garagem</h1>
            <p class="subtitle">Controle Inteligente ESP32</p>
        </div>
        
        <div id="status" class="status-card">
            <div class="status-icon">⚡</div>
            <div class="status-text">Carregando...</div>
            <div class="status-detail">Verificando status do sistema</div>
        </div>
        
        <div class="controls">
            <button class="btn btn-toggle" onclick="toggleRelay()">
                🔄 Alternar Relé
            </button>
            <button class="btn btn-pulse" onclick="pulseRelay()">
                🚪 Abrir Portão
            </button>
        </div>
        
        <div class="info-panel">
            <h3>📊 Informações do Sistema</h3>
            <div id="network-info">
                <div class="info-item">
                    <span class="info-label">Status:</span>
                    <span class="info-value">Carregando...</span>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>Desenvolvido por <strong>Withney Guilherme</strong></p>
            <p>ESP32 Home Automation System</p>
        </div>
    </div>

    <script>
        function updateStatus() {
            fetch('/status')
                .then(response => response.json())
                .then(data => {
                    const statusCard = document.getElementById('status');
                    const isOn = data.relay;
                    
                    statusCard.className = 'status-card ' + (isOn ? 'on' : 'off');
                    statusCard.innerHTML = `
                        <div class="status-icon">${isOn ? '🟢' : '🔴'}</div>
                        <div class="status-text">Relé ${isOn ? 'Ligado' : 'Desligado'}</div>
                        <div class="status-detail">${isOn ? 'Sistema ativo' : 'Sistema inativo'}</div>
                    `;
                    
                    const networkInfo = document.getElementById('network-info');
                    networkInfo.innerHTML = `
                        <div class="info-item">
                            <span class="info-label">IP:</span>
                            <span class="info-value">${data.ip}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Hostname:</span>
                            <span class="info-value">${data.hostname}.local</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">MAC:</span>
                            <span class="info-value">${data.mac}</span>
                        </div>
                        <div class="info-item">
                            <span class="info-label">Status:</span>
                            <span class="info-value">Online</span>
                        </div>
                    `;
                })
                .catch(error => {
                    console.error('Erro ao atualizar status:', error);
                    const statusCard = document.getElementById('status');
                    statusCard.className = 'status-card off';
                    statusCard.innerHTML = `
                        <div class="status-icon">⚠️</div>
                        <div class="status-text">Erro de Conexão</div>
                        <div class="status-detail">Verifique a conexão</div>
                    `;
                });
        }

        function toggleRelay() {
            const btn = document.querySelector('.btn-toggle');
            btn.classList.add('pulse');
            
            fetch('/toggle', { method: 'POST' })
                .then(() => {
                    updateStatus();
                    setTimeout(() => btn.classList.remove('pulse'), 1000);
                })
                .catch(error => {
                    console.error('Erro ao alternar relé:', error);
                    btn.classList.remove('pulse');
                });
        }

        function pulseRelay() {
            const btn = document.querySelector('.btn-pulse');
            btn.classList.add('pulse');
            
            fetch('/pulse', { method: 'POST' })
                .then(() => {
                    updateStatus();
                    setTimeout(() => btn.classList.remove('pulse'), 1000);
                })
                .catch(error => {
                    console.error('Erro ao pulsar relé:', error);
                    btn.classList.remove('pulse');
                });
        }

        setInterval(updateStatus, 2000);
        updateStatus();
    </script>
</body>
</html>
)rawliteral";

// Declarações das funções
void handleRoot();
void handleStatus();
void handleToggle();
void handlePulse();

void setup() {
    Serial.begin(115200);
    
    // Configura GPIO do relé
    pinMode(RELAY_GPIO, OUTPUT);
    digitalWrite(RELAY_GPIO, RELAY_OFF_STATE);
    
    // Conecta ao WiFi
    Serial.print("Conectando ao WiFi");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    
    Serial.println("");
    Serial.println("WiFi conectado!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    
    // Configura mDNS
    if (MDNS.begin(HOSTNAME)) {
        Serial.println("mDNS iniciado");
        Serial.print("Acesse: http://");
        Serial.print(HOSTNAME);
        Serial.println(".local");
        
        // Anuncia o serviço HTTP
        MDNS.addService("http", "tcp", 80);
    } else {
        Serial.println("Erro ao iniciar mDNS!");
    }
    
    // Configura rotas do servidor web
    server.on("/", handleRoot);
    server.on("/status", handleStatus);
    server.on("/toggle", HTTP_POST, handleToggle);
    server.on("/pulse", HTTP_POST, handlePulse);
    
    server.begin();
    Serial.println("Servidor HTTP iniciado");
    Serial.println("=====================================");
    Serial.print("Acesse por IP: http://");
    Serial.println(WiFi.localIP());
    Serial.print("Acesse por nome: http://");
    Serial.print(HOSTNAME);
    Serial.println(".local");
    Serial.println("=====================================");
}

void loop() {
    server.handleClient();
}

void handleRoot() {
    server.send(200, "text/html", htmlPage);
}

void handleStatus() {
    String json = "{";
    json += "\"relay\":" + String(relayState ? "true" : "false") + ",";
    json += "\"ip\":\"" + WiFi.localIP().toString() + "\",";
    json += "\"hostname\":\"" + String(HOSTNAME) + "\",";
    json += "\"mac\":\"" + WiFi.macAddress() + "\"";
    json += "}";
    server.send(200, "application/json", json);
}

void handleToggle() {
    relayState = !relayState;
    digitalWrite(RELAY_GPIO, relayState ? RELAY_ON_STATE : RELAY_OFF_STATE);
    Serial.println("Relé alternado: " + String(relayState ? "ON" : "OFF"));
    server.send(200, "text/plain", "OK");
}

void handlePulse() {
    digitalWrite(RELAY_GPIO, RELAY_ON_STATE);
    Serial.println("Pulso iniciado");
    delay(1000); // 1 segundo
    digitalWrite(RELAY_GPIO, RELAY_OFF_STATE);
    relayState = false;
    Serial.println("Pulso finalizado");
    server.send(200, "text/plain", "OK");
}