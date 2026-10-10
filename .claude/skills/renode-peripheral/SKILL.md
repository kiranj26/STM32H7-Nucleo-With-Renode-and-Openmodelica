---
name: renode-peripheral
description: Scaffold a custom Renode peripheral (C# preferred, Python for prototypes) for the STM32H743 - register map from RM0433, overlay .repl wiring with IRQ, a hook for the co-sim orchestrator to inject plant values, and a Robot test proving it works. Use in P3+ (encoder, ADC, PWM capture, sensors).
argument-hint: "<N> <PeripheralName> <base address> [irq]"
---

# New Renode peripheral: $ARGUMENTS

This is a core 🎓 skill (P3). Unless the owner asks for the full code, produce the **skeleton plus the register table**, and let the owner fill in the behavior.

## 1. Spec first
Write `projects/pN_*/renode/peripherals/<Name>.md` with:
- **Purpose and the plant signal it carries:** for example encoder count ← FMU shaft angle.
- **Register table:** offset, name, reset value, access, and the fields the firmware actually uses. Source it from RM0433 (section number) and the HAL code that touches it (`grep` the `Drivers/` HAL source for the register names).
- **Interrupts:** which events raise which IRQ line (number from the H743 vector table).
- **Injection interface:** how the orchestrator sets the plant value. For example, a public method `SetPosition(double rad)` callable as `sysbus.encoder SetPosition 1.57` from the monitor or `pyrenode3`.

## 2. Skeleton (C#)
`projects/pN_*/renode/peripherals/<Name>.cs`:
- `public class <Name> : BasicDoubleWordPeripheral, IKnownSize` with `Size => 0x400`
- `DefineRegisters()` using `Registers.X.Define(this, resetValue)` with `.WithValueField` / `.WithFlag`, plus `valueProviderCallback` and `writeCallback`
- `public GPIO IRQ { get; }` if it interrupts
- an injection method, with a doc comment
- a header comment with the RM0433 references

A Python peripheral is the alternative for prototypes: `projects/pN_*/renode/peripherals/<name>.py` with `if request.isRead: ...`. Note in the README why you moved to C# later (speed, typed registers, IRQ support).

## 3. Wire it
In `pN_overlay.repl`:
```
<name>: Peripherals.<Namespace>.<Name> @ sysbus <base>
    IRQ -> nvic@<irq>
```
In `pN.resc`, load the C# file before the platform: `include @projects/pN_*/renode/peripherals/<Name>.cs`. If the address collides with an upstream model (for example a TIMx you're replacing), say how you handle it: unregister, or use a different instance.

## 4. Prove it
Add a Robot test, tagged `smoke pN peripheral`, that:
1. boots,
2. injects a value through the monitor (`Execute Command    sysbus.<name> Set... <v>`),
3. checks the firmware reports the matching value on USART3 (`Wait For Line On Uart`).

## 5. Record
Update the project README "Features used" (custom peripheral, overlay, IRQ wiring) and `docs/feature-checklist.md`.
