*** Settings ***
Documentation     P1 Thermal chamber: requirements-style tests on Renode (TARGET:hw from milestone 7).
...               Run:  make test P=p1 [TAGS=smoke]
...               renode-test injects its own Suite Setup/Teardown and a per-test `Reset Emulation`,
...               so each test starts with `Boot Project` (same pattern as P0, tests/common/renode.resource).
...               Timeouts and timestamps are VIRTUAL time; thresholds are requirements (CLAUDE.md rule 7).
Resource          ${CURDIR}/../../../tests/common/renode.resource
Force Tags        p1    renode

*** Variables ***
${PROJECT}           p1_thermal
${BOOT_TIMEOUT_S}    1
${TS_MS}             1000.0    # control tick: TIM6 PSC 19999, ARR 9999 at 200 MHz (fw/p1_thermal/CUBEMX.md §3)
${TS_TOL_MS}         1.0       # UART TX is near-instant in Renode; the tick itself should be exact

*** Test Cases ***
Firmware Boots To Main Loop
    [Documentation]    REQ-P1-01: the boot banner appears within 1 s virtual after reset,
    ...                i.e. clock/power setup and peripheral init do not hang in emulation.
    [Tags]    smoke
    Boot Project    ${PROJECT}
    Wait For Line On Uart    P1 thermal boot    timeout=${BOOT_TIMEOUT_S}

Control Tick Runs At Ts
    [Documentation]    REQ-P1-02: TIM6 update interrupts arrive every Ts = 1000 ms ± 1 ms virtual
    ...                (mean over Hello 1..3). Also checks that Renode's RCC model re-times TIM6 to the
    ...                200 MHz the firmware configures, not the .repl's 250 MHz start value
    ...                (250 MHz would give 800 ms).
    Boot Project    ${PROJECT}
    ${t1}=    Virtual Time Of Line    Hello 1    timeout=2
    ${t3}=    Virtual Time Of Line    Hello 3    timeout=3
    ${period_ms}=    Evaluate    (${t3} - ${t1}) / 2
    Log    period_ms=${period_ms} (Hello 1 at ${t1} ms, Hello 3 at ${t3} ms)    console=True
    Should Be True    abs(${period_ms} - ${TS_MS}) <= ${TS_TOL_MS}
    ...    msg=tick period ${period_ms} ms is outside ${TS_MS} ± ${TS_TOL_MS} ms
