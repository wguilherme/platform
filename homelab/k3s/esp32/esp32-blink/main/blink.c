#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"

#define MAX_GPIO 30

void app_main(void)
{
    printf("Iniciando aplicação...\n");
    
    // Configurar todas as GPIOs como saída
    for (int i = 0; i <= MAX_GPIO; i++) {
        gpio_set_direction(i, GPIO_MODE_OUTPUT);
    }
    
    int current_gpio = 0;
    
    while (1) {
        printf("\nTestando GPIO %d\n", current_gpio);
        
        // Piscar 4 vezes na GPIO atual
        for (int i = 0; i < 4; i++) {
            gpio_set_level(current_gpio, 0);  // LED ON
            printf("GPIO %d: ON (piscada %d)\n", current_gpio, i + 1);
            vTaskDelay(500 / portTICK_PERIOD_MS);
            
            gpio_set_level(current_gpio, 1);  // LED OFF
            printf("GPIO %d: OFF (piscada %d)\n", current_gpio, i + 1);
            vTaskDelay(500 / portTICK_PERIOD_MS);
        }
        
        // Mudar para próxima GPIO
        current_gpio = (current_gpio + 1) % (MAX_GPIO + 1);
        
        // Pequena pausa entre GPIOs
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}