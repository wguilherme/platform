#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"


const int gpios[] = {2, 5, 16, 13, 21, 22};
const int num_gpios = sizeof(gpios) / sizeof(gpios[0]);

void app_main(void)
{
    printf("Iniciando aplicação...\n");
    

    for (int i = 0; i < num_gpios; i++) {
        gpio_set_direction(gpios[i], GPIO_MODE_OUTPUT);
        printf("GPIO %d configurada como saída\n", gpios[i]);
    }
    
    int current_gpio = 0;
    
    while (1) {

        printf("\nTestando GPIO %d\n", gpios[current_gpio]);
        
        
        for (int i = 0; i < 4; i++) {
            gpio_set_level(gpios[current_gpio], 0);  // LED ON
            printf("GPIO %d: ON\n", gpios[current_gpio]);
            vTaskDelay(250 / portTICK_PERIOD_MS);
            
            gpio_set_level(gpios[current_gpio], 1);  // LED OFF
            printf("GPIO %d: OFF\n", gpios[current_gpio]);
            vTaskDelay(250 / portTICK_PERIOD_MS);
        }
        
        current_gpio = (current_gpio + 1) % num_gpios;
        
    }
}