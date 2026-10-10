---
paths:
  - ".devcontainer/**"
  - ".github/workflows/**"
  - "Makefile"
  - "requirements*.txt"
---

# Dev environment and CI rules

- **One image.** `.devcontainer/Dockerfile` is the toolchain for local work and for CI (`linux/amd64`). The CI workflow runs inside that image, not a hand-rolled runner setup.
- **Pin everything:** Ubuntu base digest or tag, OpenModelica version, Renode version, Arm GNU Toolchain version, and Python packages (in `requirements.txt` with `==`). When upgrading one, record it in `docs/dev-environment.md` with the date.
- **The Makefile is the interface.** CI calls the same `make` targets developers use. A new workflow step that isn't a `make` target is a smell.
- **Host-only targets** (`make hw`) detect that they're running in a container and fail with a clear message.
- **CI stages:**
  1. `make lint unit`
  2. `make fw` for all projects
  3. `make fmu`
  4. `make test TAGS=smoke`
  5. Upload `build/robot/**` and plots as artifacts

  Nightly runs add `TAGS=long`.
- **Caching:** cache the CMake build directory and the FMU outputs, keyed by file hashes. Don't cache Renode snapshots across commits.
- **CI time:** keep the smoke stage under 10 minutes. If it grows, move tests to `long` rather than accept a slow pipeline.
