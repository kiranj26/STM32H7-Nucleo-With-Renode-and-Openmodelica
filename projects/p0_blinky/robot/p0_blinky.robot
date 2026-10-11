*** Settings ***
Documentation     P0 Blinky: the canonical ELF (build/fw/p0_blinky, built by `make fw` in the
...               devcontainer) on Renode's STM32H743 platform plus the P0 overlay.
...               Run:  make test P=p0 [TAGS=smoke]
...               Timeouts and timestamps are VIRTUAL time; thresholds are requirements
...               (CLAUDE.md hard rule 7: change one only with a written reason).
Resource          ${CURDIR}/../../../tests/common/renode.resource
Force Tags        p0    renode

*** Variables ***
${PROJECT}             p0_blinky
${HELLO_PERIOD_MS}     501.0    # HAL_Delay(500) waits 501 SysTick ticks (stm32h7xx_hal.c:411-413)
${PERIOD_TOL_MS}       1.0      # UART TX is near-instant in Renode; 1 ms = one SysTick tick
${DBGMCU_IDCODE}       0x20030450    # rev V (REV_ID 0x2003), DEV_ID 0x450: the real board

*** Test Cases ***
Firmware Boots To Main Loop
    [Documentation]    REQ-P0-01: the boot banner appears within 1 s virtual after reset,
    ...                i.e. clock/power setup does not hang in emulation.
    [Tags]    smoke
    Boot Project    ${PROJECT}
    Wait For Line On Uart    P0 blinky boot    timeout=1

Hello Counter Increments
    [Documentation]    REQ-P0-02: `Hello 0`, `Hello 1`, `Hello 2` appear in order on USART3.
    [Tags]    smoke
    Boot Project    ${PROJECT}
    Wait For Line On Uart    Hello 0    timeout=1
    Wait For Line On Uart    Hello 1    timeout=1
    Wait For Line On Uart    Hello 2    timeout=1

Emulated Chip Identifies As Revision V
    [Documentation]    REQ-P0-03: the P0 overlay is active, so DBGMCU_IDC reads like the
    ...                NUCLEO-H743ZI2 (rev V) and SystemInit skips the rev-Y errata path.
    [Tags]    smoke
    Boot Project    ${PROJECT}
    ${idcode}=    Execute Command    sysbus ReadDoubleWord 0x5C001000
    ${idcode}=    Strip String    ${idcode}
    Should Be Equal As Integers    ${idcode}    ${DBGMCU_IDCODE}

Hello Period Matches HAL_Delay
    [Documentation]    REQ-P0-04: mean period over Hello 1..5 is 501 ms ± 1 ms virtual.
    ...                Renode's RCC model derives the SysTick rate from the firmware's PLL
    ...                writes (not the .repl's 480 MHz), so this is the "ideal clock" reference
    ...                for the HW measurement (495.1 ms on the board, ~1.3 % fast).
    Boot Project    ${PROJECT}
    ${t1}=    Virtual Time Of Line    Hello 1    timeout=1
    ${t5}=    Virtual Time Of Line    Hello 5    timeout=3
    ${period_ms}=    Evaluate    (${t5} - ${t1}) / 4
    Log    period_ms=${period_ms} (Hello 1 at ${t1} ms, Hello 5 at ${t5} ms)    console=True
    Should Be True    abs(${period_ms} - ${HELLO_PERIOD_MS}) <= ${PERIOD_TOL_MS}
    ...    msg=period ${period_ms} ms is outside ${HELLO_PERIOD_MS} ± ${PERIOD_TOL_MS} ms

LD1 Toggles Between Hello Lines
    [Documentation]    REQ-P0-05: LD1 (PB0) changes state once per Hello line, i.e. the
    ...                blinky really drives the GPIO, checked via GPIOB ODR bit 0.
    [Tags]    smoke
    Boot Project    ${PROJECT}
    Wait For Line On Uart    Hello 1    timeout=1
    ${odr_1}=    Execute Command    sysbus ReadDoubleWord 0x58020414
    ${odr_1}=    Strip String    ${odr_1}
    Wait For Line On Uart    Hello 2    timeout=1
    ${odr_2}=    Execute Command    sysbus ReadDoubleWord 0x58020414
    ${odr_2}=    Strip String    ${odr_2}
    Log    GPIOB ODR after Hello 1 = ${odr_1}, after Hello 2 = ${odr_2}    console=True
    Should Be True    (${odr_1} ^ ${odr_2}) & 1
    ...    msg=PB0 (LD1) did not toggle between Hello 1 and Hello 2 (ODR ${odr_1} -> ${odr_2})
