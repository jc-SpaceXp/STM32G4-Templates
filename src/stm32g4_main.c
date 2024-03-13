#include "stm32g4_main.h"
#include "gpio_g431.h"

#include "libopencm3/stm32/rcc.h"
#include "libopencm3/stm32/gpio.h"

int main (void)
{
	gpio_setup();

	int i;
	for (;;) {
		gpio_clear(LED_PORT, LED_PIN);
		for (i = 0; i < 1500000; i++) {
			__asm__("nop");
		}
		gpio_set(LED_PORT, LED_PIN);
		for (i = 0; i < 500000; i++) {
			__asm__("nop");
		}
	}

	return 0;
}
