*** Settings ***
Documentation     P1 Thermal chamber: requirements-style tests on Renode (TARGET:hw from milestone 7).
...               Run:  make test P=p1 [TAGS=smoke]
...               renode-test injects its own Suite Setup/Teardown and a per-test `Reset Emulation`,
...               so each test starts with `Boot Project` (same pattern as P0, tests/common/renode.resource).
...               Timeouts and timestamps are VIRTUAL time; thresholds are requirements (CLAUDE.md rule 7).
...               Stub: fails until fw/p1_thermal exists and prints "Hello" (CubeMX first).
Resource          ${CURDIR}/../../../tests/common/renode.resource
Force Tags        p1    renode

*** Variables ***
${PROJECT}           p1_thermal
${BOOT_TIMEOUT_S}    1

*** Test Cases ***
Firmware Boots And Reports Hello
    [Documentation]    REQ-P1-01: the firmware reaches its main loop in Renode.
    [Tags]    smoke
    Boot Project    ${PROJECT}
    Wait For Line On Uart    Hello    timeout=${BOOT_TIMEOUT_S}
