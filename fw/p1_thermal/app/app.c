#include "app.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include "main.h"  /* HAL, LD1_Pin / LD1_GPIO_Port, Error_Handler() */
#include "tim.h"   /* extern TIM_HandleTypeDef htim6; */
#include "usart.h" /* extern UART_HandleTypeDef huart3; */

/* P1 Thermal chamber: TIM6 ticks at Ts (1 s, CUBEMX.md §3); the control step will run in that ISR.
 * Control path rule (CLAUDE.md hard rule 3): the ISR does only short, non-blocking work and hands
 * results to app_loop() through volatile variables. All UART printing happens in app_loop().
 * Why: a blocking HAL_UART_Transmit (~0.9 ms per line at 115200) inside the TIM6 ISR (priority 2)
 * would hold off the USART2 RX ISR (priority 3) and overrun the plant link.
 */

#define UART_TX_TIMEOUT_MS 100u

/* Written only by the TIM6 ISR, read by app_loop(). A 32-bit aligned read/write is atomic on the M7. */
static volatile uint32_t tick_count;

static void app_print(const char *s, size_t len)
{
    if (HAL_UART_Transmit(&huart3, (uint8_t *)s, (uint16_t)len, UART_TX_TIMEOUT_MS) != HAL_OK) {
        Error_Handler();
    }
}

void app_init(void)
{
    static const char banner[] = "P1 thermal boot\r\n";

    tick_count = 0u;
    app_print(banner, sizeof banner - 1u);

    /* HAL_TIM_Base_Init() forces an update event (EGR.UG) to load PSC/ARR, which also sets UIF.
     * Clear it, or the first interrupt fires immediately instead of one Ts after start. */
    __HAL_TIM_CLEAR_FLAG(&htim6, TIM_FLAG_UPDATE);
    if (HAL_TIM_Base_Start_IT(&htim6) != HAL_OK) {
        Error_Handler();
    }
}

void app_loop(void)
{
    static uint32_t ticks_seen;
    uint32_t now = tick_count; /* one snapshot, so the compare and the print agree */

    if (now != ticks_seen) {
        char line[32];
        int n = snprintf(line, sizeof line, "Hello %lu\r\n", (unsigned long)now);

        ticks_seen = now;
        if (n > 0) {
            app_print(line, (size_t)n);
        }
    }
}

/* Runs in TIM6 interrupt context every Ts. Keep it short: no printf, no HAL_Delay, no blocking I/O.
 * The PID step goes here in milestone 4. */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    if (htim->Instance == TIM6) {
        tick_count++;
        HAL_GPIO_TogglePin(LD1_GPIO_Port, LD1_Pin);
    }
}
