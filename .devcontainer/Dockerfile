# syntax=docker/dockerfile:1
# H7 lab devcontainer: ONE pinned linux/amd64 image for local work and CI (ADR-0002).
# Holds everything except CubeMX, flashing and serial (those stay on the macOS host).
#
# Build from the repo root (the context must contain requirements.txt):
#   docker build --platform linux/amd64 -f .devcontainer/Dockerfile -t h7lab .
#
# Layers are ordered from least to most frequently changed, so editing
# requirements.txt does not re-download OpenModelica or Renode.
# Every version below is pinned; record changes in docs/dev-environment.md.

# uv: Python installer/resolver (copied in as a single static binary)
FROM ghcr.io/astral-sh/uv:0.12.20 AS uv

# The constant --platform is deliberate (BuildKit warns FromPlatformFlagConstDisallowed):
# ADR-0002 requires amd64 everywhere, and this stops an accidental arm64 build on the Mac.
FROM --platform=linux/amd64 ubuntu:22.04@sha256:5ec03bb3441e8b0bf3b4f9cd4629a1ae763010dc3035bb8da3ae6cf026486401

# rel2 = compiler build arm-15.180, the same build as the macOS host cask.
# Mac and Linux .bin still differ (libc_nano.a member order differs per host
# package), so the container-built ELF is the canonical firmware.
ARG ARM_GNU_VERSION=15.3.rel2
ARG ARM_GNU_SHA256=0662b2f01e0cd8b951fd110911d339c35b05998c68a12b3530bbbb4bf6c7874e
ARG OMC_VERSION=1.27.1
ARG MSL_VERSION=4.0.0
ARG RENODE_VERSION=1.17.0
ARG RENODE_SHA256=4ba7c68b59e2447f188ef4b4b112fcccd2802582c460beedceb63b84e5605a5f
ARG PYTHON_VERSION=3.11

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# --- Base tools ------------------------------------------------------------
# build-essential: host gcc for `make unit` (ctrl/ host tests, P1+)
# clang-format: C style check; libicu70: needed by Renode's .NET runtime
# netcat-openbsd: read a Renode UART socket terminal from a shell
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg xz-utils \
        git make build-essential clang-format \
        libicu70 netcat-openbsd file less \
    && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory /work

# --- Arm GNU Toolchain (same compiler build as the macOS host) ---------------
RUN curl -fsSL -o /tmp/arm.tar.xz \
        "https://gitlab.arm.com/api/v4/projects/tooling%2Fgnu-toolchains-for-arm/packages/generic/gnu-toolchain/${ARM_GNU_VERSION}/arm-gnu-toolchain-${ARM_GNU_VERSION}-x86_64-arm-none-eabi.tar.xz" \
    && echo "${ARM_GNU_SHA256}  /tmp/arm.tar.xz" | sha256sum -c - \
    && mkdir -p /opt/arm-gnu \
    && tar -xJf /tmp/arm.tar.xz -C /opt/arm-gnu --strip-components=1 \
    && rm /tmp/arm.tar.xz

# --- OpenModelica (versioned release repo, not the moving "stable" channel) -
RUN curl -fsSL https://build.openmodelica.org/apt/openmodelica.asc \
        | gpg --dearmor -o /usr/share/keyrings/openmodelica-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/omc/builds/linux/releases/${OMC_VERSION}/ jammy release" \
        > /etc/apt/sources.list.d/openmodelica.list \
    && apt-get update && apt-get install -y --no-install-recommends omc \
    && rm -rf /var/lib/apt/lists/*

# Modelica Standard Library via OMC's package manager (fails the build if it can't install)
RUN printf 'installPackage(Modelica, "%s"); getErrorString();\n' "${MSL_VERSION}" > /tmp/msl.mos \
    && omc /tmp/msl.mos | tee /tmp/msl.out \
    && grep -q '^true' /tmp/msl.out \
    && rm /tmp/msl.mos /tmp/msl.out

# --- Renode (portable build: self-contained .NET, includes renode-test) ------
RUN curl -fsSL -o /tmp/renode.tar.gz \
        "https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode-${RENODE_VERSION}.linux-portable.tar.gz" \
    && echo "${RENODE_SHA256}  /tmp/renode.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/renode \
    && tar -xzf /tmp/renode.tar.gz -C /opt/renode --strip-components=1 \
    && rm /tmp/renode.tar.gz

# --- Python 3.11 venv (uv-managed interpreter; jammy itself ships 3.10) ------
COPY --from=uv /uv /usr/local/bin/uv
ENV UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_PYTHON_PREFERENCE=only-managed \
    UV_LINK_MODE=copy
RUN uv venv --python "${PYTHON_VERSION}" /opt/venv
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --python /opt/venv/bin/python --no-cache -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# --- Environment -----------------------------------------------------------
# IN_DEVCONTAINER lets the Makefile know which side it runs on (make hw refuses here).
ENV PATH="/opt/venv/bin:/opt/arm-gnu/bin:/opt/renode:${PATH}" \
    VIRTUAL_ENV=/opt/venv \
    IN_DEVCONTAINER=1

WORKDIR /work
CMD ["bash"]
