#include "gpio_g431.h"

#include "libopencm3/stm32/rcc.h"
#include "libopencm3/stm32/gpio.h"

void gpio_setup(void)
{
	rcc_periph_clock_enable(RCC_GPIOB);

	gpio_mode_setup(LED_PORT, GPIO_MODE_OUTPUT
	               , GPIO_PUPD_PULLDOWN, LED_PIN);
}
