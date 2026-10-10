---
name: flash-board
description: Flash a project's ELF to the physical Nucleo-H743ZI2 from the macOS host and capture its VCP output, or run the Robot suite with TARGET:hw. Hardware-touching - only when the owner explicitly asks.
argument-hint: "<N> [robot]"
disable-model-invocation: true
---

# Flash and run P$ARGUMENTS on the Nucleo-H743ZI2

**Host only.** If `/.dockerenv` exists, stop: there's no USB in the container. Tell the owner to run this from a macOS terminal session.

1. **Board present:** `st-info --probe`. Expect an STM32H7x series chip with flash size 2048k. If nothing is found, check the USB cable (data, not charge-only), CN1 jumpers, and ST-LINK firmware.
2. **Artifact:** the ELF built in the container (`build/fw/pN_*/pN_*.elf`; the build folder is shared through the bind mount). Make a `.bin` with `arm-none-eabi-objcopy -O binary`, or let `make hw` do it.
3. **Flash:** `make hw P=pN`, or directly: `st-flash --reset write build/fw/pN_*/pN_*.bin 0x08000000`. Never use `erase` (a hook blocks it).
4. **Serial port:** `ls /dev/cu.usbmodem*`. Use `$NUCLEO_SERIAL_PORT` from `settings.local.json` if it's set.
5. **Capture output:** `python3 -m serial.tools.miniterm $PORT 115200` (interactive). For non-interactive capture, use a short pyserial script that reads for N seconds and saves to `build/hw/pN_<date>.log`.
6. **Robot on hardware:** `robot --variable TARGET:hw --variable SERIAL:$PORT --include hw -d build/robot/pN_hw projects/pN_*/robot/`.
7. **Record:** put the results in the project README "Results" under a **HW** heading with the date and board serial. Anything that differs from Renode is a learning item: add it to "Problems hit", for example cache effects or real timing.
