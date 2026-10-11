*** Settings ***
Documentation     Shared keywords for project suites, run with `renode-test` (Renode 1.17.0) via `make test`.
...               renode-test injects Renode's own Suite Setup/Teardown and a per-test
...               `Reset Emulation`, so suites must NOT define their own Test Setup; each
...               test calls `Boot Project` as its first step instead.
...               All timeouts and timestamps here are VIRTUAL time (CLAUDE.md hard rule 4).
Library           OperatingSystem
Library           String

*** Variables ***
${UART}           sysbus.usart3    # ST-LINK VCP on the NUCLEO-H743ZI2

*** Keywords ***
Boot Project
    [Documentation]    Load projects/<project>/renode/<pN>.resc (platform + overlay + canonical ELF)
    ...                and attach a terminal tester to the console UART.
    ...                The Renode server does not run in the repo root, so the repo root is added
    ...                to Renode's search path; then the repo-relative @paths in .resc files resolve.
    [Arguments]    ${project}    ${uart}=${UART}
    ${repo}=    Normalize Path    ${CURDIR}/../..
    ${pn}=    Fetch From Left    ${project}    _
    Execute Command    path add @${repo}
    Execute Command    include @projects/${project}/renode/${pn}.resc
    Create Terminal Tester    ${uart}

Virtual Time Of Line
    [Documentation]    Wait for a UART line and return its virtual timestamp in milliseconds.
    [Arguments]    ${line}    ${timeout}
    ${result}=    Wait For Line On Uart    ${line}    timeout=${timeout}
    RETURN    ${result.Timestamp}
