#include "app.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include "main.h"  /* HAL, LD1_Pin / LD1_GPIO_Port, Error_Handler() */
#include "usart.h" /* extern UART_HandleTypeDef huart3; */

/* P0 Blinky: toggle LD1 (PB0) and print "Hello <n>" on USART3 (ST-LINK VCP).
 * HAL_Delay and blocking UART TX are fine here because P0 has no control path.
 * From P1 on, the control step moves to a timer ISR and this pattern is banned there.
 */

#define BLINK_PERIOD_MS    500u
#define UART_TX_TIMEOUT_MS 100u

static uint32_t hello_count;

static void app_print(const char *s, size_t len)
{
    if (HAL_UART_Transmit(&huart3, (uint8_t *)s, (uint16_t)len, UART_TX_TIMEOUT_MS) != HAL_OK) {
        Error_Handler();
    }
}

void app_init(void)
{
    static const char banner[] = "P0 blinky boot\r\n";

    hello_count = 0u;
    app_print(banner, sizeof banner - 1u);
}

void app_loop(void)
{
    char line[32];
    int n = snprintf(line, sizeof line, "Hello %lu\r\n", (unsigned long)hello_count++);

    if (n > 0) {
        app_print(line, (size_t)n);
    }
    HAL_GPIO_TogglePin(LD1_GPIO_Port, LD1_Pin);
    HAL_Delay(BLINK_PERIOD_MS);
}