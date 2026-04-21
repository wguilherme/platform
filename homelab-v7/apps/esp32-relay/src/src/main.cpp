#include <Arduino.h>

#define FIRMWARE_VERSION "1.3.0"
#define RELAY_PIN 23
#define RELAY_DELAY_INTERVAL 15000
#define SERIAL_BOOT_DELAY 2000

void setup() {
  Serial.begin(115200);
  delay(SERIAL_BOOT_DELAY);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
}

void loop() {
  Serial.printf("[v%s] relay ON\n", FIRMWARE_VERSION);
  digitalWrite(RELAY_PIN, HIGH);
  delay(RELAY_DELAY_INTERVAL);

  Serial.printf("[v%s] relay OFF\n", FIRMWARE_VERSION);
  digitalWrite(RELAY_PIN, LOW);
  delay(RELAY_DELAY_INTERVAL);
}
