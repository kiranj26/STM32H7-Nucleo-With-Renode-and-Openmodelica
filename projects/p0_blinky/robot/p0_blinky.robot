*** Settings ***
Documentation     P0 Blinky: requirements-style tests. Target selected with --variable TARGET:renode|hw|sil|mil
Resource          ${RENODEKEYWORDS}
Resource          ${CURDIR}/../../../tests/common/renode.resource
Suite Setup       Start Project Target    p0_blinky
Suite Teardown    Stop Project Target
Test Teardown     Collect Run Evidence
Force Tags        p0

*** Variables ***
${TARGET}         renode
${UART}           sysbus.usart3
${BOOT_TIMEOUT_S}    5

*** Test Cases ***
Firmware Boots And Reports Hello
    [Tags]    smoke
    Wait For Line On Uart    Hello    timeout=${BOOT_TIMEOUT_S}
