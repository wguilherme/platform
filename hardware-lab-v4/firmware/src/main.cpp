#include <Arduino.h>

// Firmware de verificação do pipeline Tekton CI/CD
// Para confirmar o deploy: LED pisca + mensagem na serial
#define FIRMWARE_VERSION "1.0.0"

void setup() {
  Serial.begin(115200);
  delay(1000);
  pinMode(LED_BUILTIN, OUTPUT);

  Serial.println("\n================================");
  Serial.println("  ESP32 WROOM - Tekton CI/CD   ");
  Serial.printf ("  Version: %s\n", FIRMWARE_VERSION);
  Serial.println("================================\n");
}

void loop() {
  Serial.printf("[v%s] tick\n", FIRMWARE_VERSION);
  digitalWrite(LED_BUILTIN, HIGH);
  delay(1000);
  digitalWrite(LED_BUILTIN, LOW);
  delay(1000);
}
