void setup() {
  Serial.begin(9600); // Mude para 9600
  delay(2000);
  Serial.println("=== TESTE ESP32 ===");
  Serial.println("ESP32 iniciado!");
  
  pinMode(2, OUTPUT);
}

void loop() {
  digitalWrite(2, HIGH);
  Serial.println("LED ligado");
  delay(1000);
  
  digitalWrite(2, LOW);
  Serial.println("LED desligado");
  delay(1000);
}