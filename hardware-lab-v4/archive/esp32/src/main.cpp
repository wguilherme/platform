#include <Arduino.h>
#include <WiFi.h>
#include <ESPmDNS.h>
#include <ArduinoOTA.h>
#include "config.h"

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
