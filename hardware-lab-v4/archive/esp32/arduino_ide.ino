#include <WiFi.h>
#include <ESPmDNS.h>
#include <ArduinoOTA.h>

#define WIFI_SSID        "Withney"
#define WIFI_PASSWORD    "230399wg"
#define DEVICE_HOSTNAME  "esp32-base"
#define OTA_PASSWORD     "ota123"
#define OTA_PORT         3232

void setupWifi() {
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("Conectando ao WiFi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println();
    Serial.printf("IP: %s\n", WiFi.localIP().toString().c_str());
}

void setupOTA() {
    ArduinoOTA.setPort(OTA_PORT);
    ArduinoOTA.setHostname(DEVICE_HOSTNAME);
    ArduinoOTA.setPassword(OTA_PASSWORD);
    ArduinoOTA.onStart([]() { Serial.println("OTA: iniciando..."); });
    ArduinoOTA.onEnd([]()   { Serial.println("OTA: concluido!"); });
    ArduinoOTA.onError([](ota_error_t e) { Serial.printf("OTA erro [%u]\n", e); });
    ArduinoOTA.begin();
    Serial.printf("OTA pronto: %s.local:%d\n", DEVICE_HOSTNAME, OTA_PORT);
}

void setup() {
    Serial.begin(115200);
    setupWifi();
    setupOTA();
    MDNS.begin(DEVICE_HOSTNAME);
    Serial.println("Pronto. Aguardando deploy via OTA.");
}

void loop() {
    ArduinoOTA.handle();
}
