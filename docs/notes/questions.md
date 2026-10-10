# Open questions

Questions that came up during work, with the date. The `explain` skill answers them and links the note.

| Date | Question | Project | Answered in |
|---|---|---|---|
| 2026-10-10 | Is the NUCLEO-H743ZI2 HSE (ST-LINK MCO) really ≈ 8.1 MHz? My `Hello` period is 1.3 % short. What does UM2407 promise? | P0 | open: test with MCO1 on PA8 or HSI A/B |
| 2026-10-10 | Does Renode's SysTick rate come from the platform `.repl` or from the firmware's RCC writes? | P0 | open: check in milestone 5 |
| 2026-10-10 | Why is the APB timer clock 2× PCLK (TIMPRE), and when is it equal to PCLK? | P0 | answered in session; no note yet |
| 2026-10-10 | Why HSE **bypass** and not crystal on this board? | P0 | answered in session; no note yet |
