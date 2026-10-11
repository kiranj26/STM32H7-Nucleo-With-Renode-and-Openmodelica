#!/usr/bin/env bash
# make doctor: print every tool version this repo depends on; exit 1 if any is missing.
# Runs on both sides; on the macOS host the container-only tools are expected to be missing.
set -u

side="macOS host"
[ -n "${IN_DEVCONTAINER:-}" ] && side="devcontainer"
echo "doctor: running on the ${side} ($(uname -sm))"

fail=0
check() { # check <label> <command...>
    local label=$1; shift
    local out
    # No pipe here: the exit status must be the tool's, not that of `head`
    if out=$("$@" 2>&1) && [ -n "$out" ]; then
        printf '  %-20s %s\n' "$label" "${out%%$'\n'*}"
    else
        printf '  %-20s MISSING\n' "$label"
        fail=1
    fi
}

check arm-none-eabi-gcc arm-none-eabi-gcc --version
check cmake             cmake --version
check ninja             ninja --version
check clang-format      clang-format --version
check python            python --version
check omc               omc --version
check renode            renode --version
check renode-test       sh -c 'command -v renode-test'
# `robot --version` exits non-zero by design, so ask the module instead
check robotframework    python -c 'import robot; print("Robot Framework", robot.__version__)'
check fmpy              python -c 'import fmpy; print("FMPy", fmpy.__version__)'
check OMPython          python -c 'import OMPython, importlib.metadata as m; print("OMPython", m.version("OMPython"))'

# The Modelica Standard Library must load in EXACTLY the pinned version. "It loads" is not
# enough: OMC accepts 4.1.0 for a 4.0.0 request. The pin is read from the Dockerfile (one source).
dockerfile="$(dirname "$0")/../.devcontainer/Dockerfile"
want=$(sed -n 's/^ARG MSL_VERSION=\([0-9.]*\).*/\1/p' "$dockerfile" 2>/dev/null)
msl=$(mktemp --suffix=.mos 2>/dev/null || mktemp)
printf 'loadModel(Modelica, {"%s"});\ngetVersion(Modelica);\n' "$want" > "$msl"
got=$(command -v omc >/dev/null && omc "$msl" 2>/dev/null | sed -n 2p | tr -d '"')
if [ -n "$want" ] && [ "$got" = "$want" ]; then
    printf '  %-20s %s\n' "MSL" "Modelica $got (pinned $want)"
else
    printf '  %-20s %s\n' "MSL" "MISMATCH: loaded '${got:-none}', pinned '${want:-?}'"
    fail=1
fi
rm -f "$msl"

if [ "$fail" -ne 0 ]; then
    echo "doctor: some tools are missing"
    [ "$side" = "macOS host" ] && echo "doctor: (expected on the host for omc/renode/robot; run inside the devcontainer)"
fi
exit "$fail"
