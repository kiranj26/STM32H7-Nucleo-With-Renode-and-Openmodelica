---
name: cubemx-regen
description: Verify a CubeMX (re)generation - USER CODE preserved, app/ still wired, CMake still builds with the shared toolchain, diff of generated changes summarized, Renode still boots. Use right after the owner presses GENERATE CODE.
argument-hint: "<N>"
---

# After CubeMX generation: P$ARGUMENTS

1. **What changed:** `git status --short fw/pN_*` and `git diff --stat fw/pN_*`. Summarize the generated changes by area (clock, a new peripheral init, NVIC, CMake source lists). Flag anything surprising, such as changed clock values or new middleware.
2. **USER CODE preserved:** `git diff fw/pN_*/Core` must not show any removed lines inside `USER CODE BEGIN/END` blocks. If code was lost, restore it from git right away (`git checkout -p`) and tell the owner that "Keep User Code" was probably off.
3. **Wiring intact:**
   - `main.c` still calls `app_init()` / `app_loop()` in the USER CODE blocks.
   - The root `CMakeLists.txt` user sections still add `app/*.c` and `../common/**` sources and include paths.
   - `cmake/gcc-arm-none-eabi.cmake` or the shared `fw/cmake/arm-gcc-toolchain.cmake` is still used.
4. **Build:** `make fw P=pN`, then `arm-none-eabi-size` on the ELF. Compare against the last size noted in the project README, and explain big jumps (for example newly enabled middleware).
5. **Emulation smoke:** `make test P=pN TAGS=smoke`. If boot now hangs, it's very likely a new clock or peripheral poll; hand off to the `renode-triage` skill.
6. **Record:** if the `.ioc` change was meaningful, update `fw/pN_*/CUBEMX.md` and the README "Platform" section. Suggest a commit message: `build(pN): regenerate CubeMX - <what changed>`.
