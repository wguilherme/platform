#ifndef CONFIG_H
#define CONFIG_H

// ========================================
// CONFIGURAÇÕES WI-FI
// ========================================
#define WIFI_SSID "SuaRedeWiFi"
#define WIFI_PASSWORD "SuaSenhaWiFi"

// ========================================
// CONFIGURAÇÕES DO DISPOSITIVO
// ========================================
#define DEVICE_HOSTNAME "esp32-garagem"
#define WEB_SERVER_PORT 80

// ========================================
// CONFIGURAÇÕES OTA (Over-The-Air)
// ========================================
#define OTA_PASSWORD "senhaOTA123"
#define OTA_PORT 3232

// ========================================
// CONFIGURAÇÕES HOMEKIT
// ========================================
#define HOMEKIT_PASSWORD "111-11-111"  // Formato: XXX-XX-XXX
#define HOMEKIT_SETUP_ID "1QJ8"
#define HOMEKIT_DEVICE_NAME "ESP32 Garagem"
#define HOMEKIT_MANUFACTURER "Seu Nome"
#define HOMEKIT_MODEL "ESP32-WROOM"
#define HOMEKIT_SERIAL "001"
#define HOMEKIT_FIRMWARE "1.0"

// ========================================
// CONFIGURAÇÕES DE HARDWARE
// ========================================
#define RELAY_GPIO 2
#define RELAY_ON_STATE LOW
#define RELAY_OFF_STATE HIGH
#define RELAY_PULSE_DURATION 1000  // milissegundos

#endif