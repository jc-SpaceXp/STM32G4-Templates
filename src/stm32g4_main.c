#include "stm32g4_main.h"
#include "gpio_g431.h"

#include "FreeRTOS.h"
#include "task.h"
#include "libopencm3/stm32/rcc.h"
#include "libopencm3/stm32/gpio.h"

// Must define when using a non-zero config for stack overflow
void vApplicationStackOverflowHook(
         xTaskHandle pxTask __attribute((unused))
         , char *pcTaskName __attribute((unused)))
{
	for (;;) {
		// do nothing
	}
}


static void task1(void *args __attribute((unused)))
{
	for (;;) {
		gpio_toggle(LED_PORT, LED_PIN);
		vTaskDelay(pdMS_TO_TICKS(500));
	}
}


int main (void)
{
	rcc_set_hpre(RCC_CFGR_HPRE_DIV2); // HCLK = SYSCLK / 2 (16 MHz / 2)

	gpio_setup();

	xTaskCreate(task1, "Flash_LED", 100, NULL, configMAX_PRIORITIES-1, NULL);
	vTaskStartScheduler();

	for (;;) {
		// FreeRTOS should never let us execute or return from main
	}

	return 0;
}
