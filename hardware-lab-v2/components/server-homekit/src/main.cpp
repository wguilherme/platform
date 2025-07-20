#include <Arduino.h>
#include <WiFi.h>

const char* WIFI_SSID = "Withney";
const char* WIFI_PASSWORD = "230399wg";

void setup() {
    Serial.begin(115200);
    delay(1000);
    
    Serial.println("\n=== TESTE SIMPLES DE WIFI ===");
    Serial.printf("Tentando conectar a: %s\n", WIFI_SSID);
    
    WiFi.mode(WIFI_STA);
    WiFi.disconnect(true);
    delay(100);
    
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi conectado!");
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("\nFalha ao conectar!");
        Serial.printf("Status: %d\n", WiFi.status());
    }
}

void loop() {
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("Ainda conectado!");
    } else {
        Serial.println("Desconectado!");
    }
    delay(5000);
}