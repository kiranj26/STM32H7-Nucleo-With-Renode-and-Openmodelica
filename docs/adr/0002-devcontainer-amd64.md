# ADR-0002: Single amd64 devcontainer; hardware work on the macOS host

- **Status:** Accepted
- **Date:** 2026-10-10
- **Project:** P0

## Context
The host is an Apple Silicon Mac. OpenModelica has no maintained native macOS build. CI (GitHub Actions `ubuntu-latest`) is x86_64. Docker on macOS can't pass USB devices through, so the ST-LINK can't be reached from a container.

## Decision
All tools except CubeMX and hardware access live in one pinned `linux/amd64` devcontainer image (OpenModelica, Renode, arm-gcc, CMake, Python 3.11, Robot, FMPy, OMPython), run under Rosetta through OrbStack or Colima. CI uses the same image. CubeMX, flashing, and serial access run natively on macOS. The Makefile is the shared interface, and host-only targets (`make hw`) refuse to run in the container.

## Alternatives considered
- **Hybrid** (native Renode and arm-gcc, only OpenModelica in Docker): faster firmware iteration, but two environments drift apart, and CI differs from local.
- **Ubuntu arm64 VM (UTM):** a full Linux, but it doesn't match CI, and there's less package coverage for arm64.
- **arm64 container:** native speed, but package support for OMC and Renode on arm64 is less certain. Revisit later.

## Consequences
- **Easier:** identical local and CI behavior; one place to pin versions.
- **Harder:** Rosetta slows emulation and simulation; two "sides" to keep in mind (the `session_context` hook reports which one).
- **Revisit when:** OMC and Renode arm64 Linux packages are solid, then switch the image architecture.
