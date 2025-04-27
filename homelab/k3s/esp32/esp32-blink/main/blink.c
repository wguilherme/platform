#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"

// Lista de GPIOs comuns para LEDs onboard
const int gpios[] = {2, 5, 16, 13, 21, 22};
const int num_gpios = sizeof(gpios) / sizeof(gpios[0]);

void app_main(void)
{
    printf("Iniciando aplicação...\n");
    
    // Configurar todas as GPIOs como saída
    for (int i = 0; i < num_gpios; i++) {
        gpio_set_direction(gpios[i], GPIO_MODE_OUTPUT);
    }
    
    int current_gpio = 0;
    
    while (1) {
        printf("\nTestando GPIO %d\n", gpios[current_gpio]);
        
        // Piscar 4 vezes na GPIO atual
        for (int i = 0; i < 4; i++) {
            gpio_set_level(gpios[current_gpio], 0);  // LED ON
            vTaskDelay(1000 / portTICK_PERIOD_MS);   // 1 segundo ligado
            
            gpio_set_level(gpios[current_gpio], 1);  // LED OFF
            vTaskDelay(1000 / portTICK_PERIOD_MS);   // 1 segundo desligado
        }
        
        // Mudar para próxima GPIO
        current_gpio = (current_gpio + 1) % num_gpios;
        
        // Pequena pausa entre GPIOs
        vTaskDelay(2000 / portTICK_PERIOD_MS);  // 2 segundos de pausa
    }
}