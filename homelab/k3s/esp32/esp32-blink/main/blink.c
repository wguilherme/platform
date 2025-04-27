#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "driver/ledc.h"

#define LED_GPIO 25  // Usando apenas GPIO 25 para teste

// Configuração do PWM
#define LEDC_TIMER              LEDC_TIMER_0
#define LEDC_MODE               LEDC_LOW_SPEED_MODE
#define LEDC_CHANNEL            LEDC_CHANNEL_0
#define LEDC_DUTY_RES          LEDC_TIMER_8_BIT // 8 bits = 0-255
#define LEDC_FREQUENCY          5000             // 5kHz
#define LEDC_DUTY_MAX          255              // Máximo duty cycle

void app_main(void)
{
    // Configurar timer PWM
    ledc_timer_config_t ledc_timer = {
        .speed_mode = LEDC_MODE,
        .timer_num = LEDC_TIMER,
        .duty_resolution = LEDC_DUTY_RES,
        .freq_hz = LEDC_FREQUENCY,
        .clk_cfg = LEDC_AUTO_CLK
    };
    ledc_timer_config(&ledc_timer);
    
    // Configurar canal PWM
    ledc_channel_config_t ledc_channel = {
        .speed_mode = LEDC_MODE,
        .channel = LEDC_CHANNEL,
        .timer_sel = LEDC_TIMER,
        .intr_type = LEDC_INTR_DISABLE,
        .gpio_num = LED_GPIO,
        .duty = LEDC_DUTY_MAX,  // Intensidade máxima
        .hpoint = 0
    };
    ledc_channel_config(&ledc_channel);
    
    // Manter o LED ligado indefinidamente
    while (1) {
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}