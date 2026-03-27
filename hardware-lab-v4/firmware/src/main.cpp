#include <Arduino.h>

// Firmware de verificação do pipeline Tekton CI/CD
// Relé conectado ao GPIO23 (3v3 + GND)
#define FIRMWARE_VERSION "1.1.0"
#define RELAY_PIN 23

void setup() {
  Serial.begin(115200);
  delay(1000);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  Serial.println("\n================================");
  Serial.println("  ESP32 WROOM - Tekton CI/CD   ");
  Serial.printf ("  Version: %s\n", FIRMWARE_VERSION);
  Serial.println("  Relay: GPIO23               ");
  Serial.println("================================\n");
}

void loop() {
  Serial.printf("[v%s] relay ON\n", FIRMWARE_VERSION);
  digitalWrite(RELAY_PIN, HIGH);
  delay(1000);
  Serial.printf("[v%s] relay OFF\n", FIRMWARE_VERSION);
  digitalWrite(RELAY_PIN, LOW);
  delay(1000);
}
