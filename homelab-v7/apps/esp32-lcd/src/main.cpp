#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// Endereço 0x27, 16 colunas e 2 linhas
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Função para o efeito de digitar
void escreverLCD(int linha, String texto, int velocidade) {
  lcd.setCursor(0, linha);
  for (int i = 0; i < texto.length(); i++) {
    lcd.print(texto[i]); // Imprime uma letra por vez
    delay(velocidade);    // Espera (em milissegundos) entre as letras
  }
}

void setup() {
  Wire.begin(21, 22);
  lcd.init();
  lcd.backlight();
  lcd.clear();

  // Escreve na linha 0 (primeira), velocidade 150ms por letra
  escreverLCD(0, "Esp32 Online", 150);
  
  delay(500); // Pausa entre as linhas
  
  // Escreve na linha 1 (segunda), velocidade 100ms por letra
  escreverLCD(1, "System initialized!", 100);
}

void loop() {
  // O loop fica vazio para a mensagem não repetir sem parar
}