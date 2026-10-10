# P{{N}}: {{Title}}

> Status: 🚧 in progress | ✅ done (`p{{N}}-done`) · Time spent: ~__ h

## 1. Goal
<!-- One paragraph: what this project teaches and what the closed loop does. -->

## 2. Platform
| Item | Value |
|---|---|
| SYSCLK / timer clock | ___ MHz / ___ MHz (from CubeMX, see `fw/p{{N}}_*/CUBEMX.md`) |
| Control Ts | ___ ms (TIMx, PSC=___, ARR=___) |
| Plant link | USART2 ↔ socket :4321 (Renode) / VCP (HW) |
| Renode | version ___, overlay `renode/p{{N}}_overlay.repl` |
| Plant FMU | `Lab.___`, CS, CVODE, validated max err ___ ([run](results/)) |
| Plant I/O contract | inputs: ___ [unit, range] · outputs: ___ [unit, range] |

## 3. Features used
| Tool | Feature | Where |
|---|---|---|
| Renode | | [file#Lx](...) |
| OpenModelica | | |
| Robot | | |
| Control | | |
| STM32 | | |

## 4. How to run
```sh
make fw   P=p{{N}}
make fmu  P=p{{N}}
make test P=p{{N}} TAGS=smoke          # Renode
make hw   P=p{{N}}                     # macOS host, board attached
```

## 5. Results
<!-- Every number links to a dated run folder in results/. Label the level: MIL / SIL / Renode / HW. -->
| Metric | Requirement | MIL | Renode | HW |
|---|---|---|---|---|
| | | | | |

![](results/YYYY-MM-DD_desc/plot.png)

## 6. Problems hit
<!-- symptom → root cause → fix (link) → lesson. The most valuable section. -->
- **<symptom>**: cause → fix ([link]). *Lesson:* ...

## 7. What I'd do differently
<!-- Written by me, not generated. -->

## 8. 🎓 Steps (done by hand)
- [ ] ...
