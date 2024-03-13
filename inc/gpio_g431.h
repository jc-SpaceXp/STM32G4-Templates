#ifndef GPIO_G431_H
#define GPIO_G431_H

// PB8 is LD2 (user LED) on Nucleo STM32G431KB
#define LED_PORT GPIOB
#define LED_PIN  GPIO8

void gpio_setup(void);

#endif /* GPIO_G431_H */
