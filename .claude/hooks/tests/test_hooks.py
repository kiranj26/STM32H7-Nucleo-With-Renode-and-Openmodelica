"""Tests for .claude/hooks. Run: python3 -m unittest discover -s .claude/hooks/tests -v

Each test builds a throwaway git repo, points CLAUDE_PROJECT_DIR at it, and pipes a
hook event (JSON) into the hook script, asserting on the exit code (0 allow, 2 block).
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

HOOKS = Path(__file__).resolve().parents[1]

MAIN_C = textwrap.dedent(
    """\
    #include "main.h"
    /* USER CODE BEGIN Includes */
    #include "app.h"
    /* USER CODE END Includes */
    int main(void)
    {
      HAL_Init();
      /* USER CODE BEGIN 2 */
      app_init();
      /* USER CODE END 2 */
      while (1) {}
    }
    """
)


class HookTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self._tmp.name).resolve()
        subprocess.run(["git", "init", "-q"], cwd=self.repo, check=True)
        core = self.repo / "fw/p0_blinky/Core/Src"
        core.mkdir(parents=True)
        (core / "main.c").write_text(MAIN_C)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def run_hook(self, script: str, event: dict) -> subprocess.CompletedProcess:
        env = dict(os.environ, CLAUDE_PROJECT_DIR=str(self.repo))
        return subprocess.run(
            [sys.executable, str(HOOKS / script)],
            input=json.dumps(event),
            capture_output=True,
            text=True,
            env=env,
        )

    def p(self, rel: str) -> str:
        return str(self.repo / rel)


class GuardGeneratedCode(HookTestCase):
    S = "guard_generated_code.py"
    MAIN = "fw/p0_blinky/Core/Src/main.c"

    def edit(self, old: str, new: str, rel: str = MAIN, **extra) -> subprocess.CompletedProcess:
        ti = {"file_path": self.p(rel), "old_string": old, "new_string": new, **extra}
        return self.run_hook(self.S, {"tool_name": "Edit", "tool_input": ti})

    def test_edit_inside_user_code_allowed(self):
        self.assertEqual(self.edit("app_init();", "app_init();\n  app_run();").returncode, 0)

    def test_edit_outside_user_code_blocked(self):
        r = self.edit("HAL_Init();", "HAL_Init(); SystemClock_Config();")
        self.assertEqual(r.returncode, 2)
        self.assertIn("outside a USER CODE block", r.stderr)

    def test_edit_touching_markers_blocked(self):
        self.assertEqual(self.edit("/* USER CODE END 2 */", "").returncode, 2)

    def test_write_over_generated_file_blocked(self):
        r = self.run_hook(self.S, {"tool_name": "Write", "tool_input": {"file_path": self.p(self.MAIN), "content": "x"}})
        self.assertEqual(r.returncode, 2)

    def test_new_file_in_core_blocked(self):
        r = self.run_hook(
            self.S,
            {"tool_name": "Write", "tool_input": {"file_path": self.p("fw/p0_blinky/Core/Src/new.c"), "content": "x"}},
        )
        self.assertEqual(r.returncode, 2)

    def test_drivers_and_ioc_blocked(self):
        for rel in ("fw/p0_blinky/Drivers/STM32H7xx_HAL_Driver/Src/x.c", "fw/p0_blinky/p0_blinky.ioc",
                    "fw/p0_blinky/cmake/stm32cubemx/CMakeLists.txt"):
            r = self.run_hook(self.S, {"tool_name": "Write", "tool_input": {"file_path": self.p(rel), "content": ""}})
            self.assertEqual(r.returncode, 2, rel)

    def test_app_and_common_allowed(self):
        for rel in ("fw/p0_blinky/app/app.c", "fw/common/ctrl/pid.c", "tools/labkit/fmu.py"):
            r = self.run_hook(self.S, {"tool_name": "Write", "tool_input": {"file_path": self.p(rel), "content": ""}})
            self.assertEqual(r.returncode, 0, rel)

    def test_multiedit_checks_every_edit(self):
        ti = {"file_path": self.p(self.MAIN), "edits": [
            {"old_string": "app_init();", "new_string": "app_init(); "},
            {"old_string": "HAL_Init();", "new_string": "HAL_Init(); "},
        ]}
        self.assertEqual(self.run_hook(self.S, {"tool_name": "MultiEdit", "tool_input": ti}).returncode, 2)

    def test_garbage_input_allows(self):
        env = dict(os.environ, CLAUDE_PROJECT_DIR=str(self.repo))
        r = subprocess.run([sys.executable, str(HOOKS / self.S)], input="not json", capture_output=True,
                           text=True, env=env)
        self.assertEqual(r.returncode, 0)


class GuardResults(HookTestCase):
    S = "guard_results.py"
    REL = "projects/p1_thermal/results/report.html"

    def write(self) -> subprocess.CompletedProcess:
        return self.run_hook(self.S, {"tool_name": "Write", "tool_input": {"file_path": self.p(self.REL), "content": "x"}})

    def test_new_result_allowed(self):
        self.assertEqual(self.write().returncode, 0)

    def test_overwrite_tracked_result_blocked(self):
        f = self.repo / self.REL
        f.parent.mkdir(parents=True)
        f.write_text("old")
        subprocess.run(["git", "add", self.REL], cwd=self.repo, check=True)
        self.assertEqual(self.write().returncode, 2)


class GuardBash(HookTestCase):
    S = "guard_bash.py"

    def bash(self, cmd: str) -> int:
        return self.run_hook(self.S, {"tool_name": "Bash", "tool_input": {"command": cmd}}).returncode

    def test_blocked(self):
        for cmd in ("git push --force origin main", "git push -f", "rm -rf projects/p1_thermal/results",
                    "st-flash erase", "sed -i 's/a/b/' fw/p0_blinky/p0_blinky.ioc", "make fw && sleep 30"):
            self.assertEqual(self.bash(cmd), 2, cmd)

    def test_allowed(self):
        for cmd in ("git push origin pN/x", "make test P=p1 TAGS=smoke", "rm -rf build", "sleep 1",
                    "st-flash write build/p0.bin 0x8000000"):
            self.assertEqual(self.bash(cmd), 0, cmd)


class CtrlHalFree(HookTestCase):
    S = "ctrl_hal_free.py"

    def post(self, body: str) -> subprocess.CompletedProcess:
        f = self.repo / "fw/common/ctrl/pid.c"
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(body)
        return self.run_hook(self.S, {"tool_name": "Write", "tool_input": {"file_path": str(f)}})

    def test_portable_code_ok(self):
        self.assertEqual(self.post('#include <stdint.h>\n#include "pid.h"\nfloat pid_step(void);\n').returncode, 0)

    def test_hal_include_reported(self):
        r = self.post('#include "stm32h7xx_hal.h"\n')
        self.assertEqual(r.returncode, 2)
        self.assertIn("HAL/CMSIS include", r.stderr)

    def test_register_access_reported(self):
        self.assertEqual(self.post("void f(void){ TIM1->CCR1 = 3; }\n").returncode, 2)


class SessionContext(HookTestCase):
    def test_prints_context(self):
        r = self.run_hook("session_context.py", {})
        self.assertEqual(r.returncode, 0)
        self.assertIn("[session] environment:", r.stdout)


if __name__ == "__main__":
    unittest.main()
