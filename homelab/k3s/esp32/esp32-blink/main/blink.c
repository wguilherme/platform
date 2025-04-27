#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "driver/ledc.h"

// Lista de GPIOs comuns para LEDs onboard
const int gpios[] = {2, 5, 16, 13, 21, 22};
const int num_gpios = sizeof(gpios) / sizeof(gpios[0]);

// Configuração do PWM
#define LEDC_TIMER              LEDC_TIMER_0
#define LEDC_MODE               LEDC_LOW_SPEED_MODE
#define LEDC_CHANNEL            LEDC_CHANNEL_0
#define LEDC_DUTY_RES          LEDC_TIMER_8_BIT // 8 bits = 0-255
#define LEDC_FREQUENCY          5000             // 5kHz
#define LEDC_DUTY_MAX          255              // Máximo duty cycle

void app_main(void)
{
    printf("Iniciando aplicação...\n");
    
    // Configurar timer PWM
    ledc_timer_config_t ledc_timer = {
        .speed_mode = LEDC_MODE,
        .timer_num = LEDC_TIMER,
        .duty_resolution = LEDC_DUTY_RES,
        .freq_hz = LEDC_FREQUENCY,
        .clk_cfg = LEDC_AUTO_CLK
    };
    ledc_timer_config(&ledc_timer);
    
    int current_gpio = 0;
    
    while (1) {
        printf("\nTestando GPIO %d\n", gpios[current_gpio]);
        
        // Configurar canal PWM para a GPIO atual
        ledc_channel_config_t ledc_channel = {
            .speed_mode = LEDC_MODE,
            .channel = LEDC_CHANNEL,
            .timer_sel = LEDC_TIMER,
            .intr_type = LEDC_INTR_DISABLE,
            .gpio_num = gpios[current_gpio],
            .duty = 0,
            .hpoint = 0
        };
        ledc_channel_config(&ledc_channel);
        
        // Piscar 4 vezes com diferentes intensidades
        for (int i = 0; i < 4; i++) {
            // Aumentar intensidade gradualmente
            for (int duty = 0; duty <= LEDC_DUTY_MAX; duty += 5) {
                ledc_set_duty(LEDC_MODE, LEDC_CHANNEL, duty);
                ledc_update_duty(LEDC_MODE, LEDC_CHANNEL);
                vTaskDelay(10 / portTICK_PERIOD_MS);
            }
            
            // Diminuir intensidade gradualmente
            for (int duty = LEDC_DUTY_MAX; duty >= 0; duty -= 5) {
                ledc_set_duty(LEDC_MODE, LEDC_CHANNEL, duty);
                ledc_update_duty(LEDC_MODE, LEDC_CHANNEL);
                vTaskDelay(10 / portTICK_PERIOD_MS);
            }
        }
        
        // Mudar para próxima GPIO
        current_gpio = (current_gpio + 1) % num_gpios;
        
        // Pequena pausa entre GPIOs
        vTaskDelay(2000 / portTICK_PERIOD_MS);
    }
}