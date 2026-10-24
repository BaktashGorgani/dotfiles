import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / ".chezmoitemplates/pipx-maintenance.sh"
JEDI = ROOT / ".chezmoitemplates/mason-jedi.lua"


class PipxMaintenanceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="python tools ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "mock-bin"
        self.bin.mkdir()
        self.venvs = self.root / "custom venvs"
        self.apps = self.root / "custom apps"
        self.apps.mkdir()
        self.calls = self.root / "calls"
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "MOCK_ROOT": str(self.root),
            "MOCK_OS": "Linux",
        }
        self.write_executable(self.bin / "uname", '#!/bin/bash\nprintf "%s\\n" "$MOCK_OS"\n')
        self.python = self.root / "python/bin/python3"
        self.write_executable(self.python, '#!/bin/bash\nprintf "3.14\\n"\n')
        self.pipx = self.root / "pipx/bin/pipx"
        self.write_executable(self.pipx, """#!/usr/bin/python3
import os
from pathlib import Path
import sys
root = Path(os.environ["MOCK_ROOT"])
args = sys.argv[1:]
if args[0] == "environment":
    print(root / ("custom venvs" if args[-1] == "PIPX_LOCAL_VENVS" else "custom apps"))
    sys.exit(0)
with (root / "calls").open("a") as stream:
    stream.write(" ".join(args) + "\\n")
if os.environ.get("FAIL") == args[0]:
    sys.exit(1)
if args[0] in ("install", "reinstall"):
    package = args[-1]
    target = root / "custom venvs" / package / "bin"
    target.mkdir(parents=True, exist_ok=True)
    interpreter = target / "python"
    if interpreter.is_symlink():
        interpreter.unlink()
    interpreter.write_text('#!/bin/bash\\nprintf "3.14\\\\n"\\n')
    interpreter.chmod(0o755)
    app = root / "custom apps" / package
    app.write_text("#!/bin/bash\\nexit 0\\n")
    app.chmod(0o755)
if os.environ.get("BREAK_AFTER_UPGRADE") and args[0] == "upgrade":
    (root / "custom apps" / args[-1]).write_text("#!/bin/bash\\nexit 1\\n")
""".replace("#!/usr/bin/python3", f"#!{sys.executable}", 1))
        self.write_executable(self.bin / "brew", """#!/bin/bash
[[ "$1" == --prefix ]] || exit 1
printf '%s/%s\\n' "$MOCK_ROOT" "$2"
""")
        # Redirect fixed Linux paths only in the test copy; never invoke real pipx.
        self.helper = self.root / "helper.sh"
        self.helper.write_text(
            HELPER.read_text()
            .replace("/usr/bin/python3", str(self.python))
            .replace("/usr/bin/pipx", str(self.pipx))
            .replace(f"python={self.python}", f"python={json.dumps(str(self.python))}")
            .replace(f"pipx_bin={self.pipx}", f"pipx_bin={json.dumps(str(self.pipx))}")
        )

    @staticmethod
    def write_executable(path, content):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        path.chmod(0o755)

    def run_helper(self, mode="install", packages=("mypy",), **env):
        return subprocess.run(
            ["bash", "-euc", 'source "$1"; shift; maintain_pipx "$@"',
             "test", str(self.helper), mode, *packages],
            env={**self.env, **env}, capture_output=True, text=True, timeout=20,
        )

    def commands(self):
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def test_missing_then_healthy_is_noop(self):
        self.assertEqual(self.run_helper().returncode, 0)
        before = self.commands()
        self.assertTrue(before[0].startswith("install --python "))
        self.assertEqual(self.run_helper().returncode, 0)
        self.assertEqual(self.commands(), before)

    def test_broken_and_old_interpreters_are_rebuilt(self):
        for version in (None, "3.13"):
            with self.subTest(version=version):
                self.assertEqual(self.run_helper().returncode, 0)
                python = self.venvs / "mypy/bin/python"
                if version is None:
                    python.unlink()
                    python.symlink_to(self.root / "removed-python")
                else:
                    python.write_text(f'#!/bin/bash\nprintf "{version}\\n"\n')
                self.assertEqual(self.run_helper().returncode, 0)
                self.assertTrue(self.commands()[-1].startswith("reinstall --python "))

    def test_broken_launcher_is_rebuilt(self):
        self.assertEqual(self.run_helper().returncode, 0)
        (self.apps / "mypy").write_text("#!/missing/python\n")
        self.assertEqual(self.run_helper().returncode, 0)
        self.assertTrue(self.commands()[-1].startswith("reinstall "))

    def test_update_repairs_first_and_only_upgrades_declared_packages(self):
        (self.venvs / "mypy").mkdir(parents=True)
        (self.venvs / "unmanaged").mkdir()
        result = self.run_helper("update")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.commands()[0].startswith("reinstall "))
        self.assertEqual(self.commands()[1], "upgrade --include-injected mypy")
        self.assertFalse(any("unmanaged" in cmd for cmd in self.commands()))

    def test_errors_propagate(self):
        for failure in ("install", "upgrade", "reinstall"):
            with self.subTest(failure=failure):
                if failure == "reinstall":
                    (self.venvs / "broken").mkdir(parents=True, exist_ok=True)
                    (self.venvs / "broken/bin/python").unlink(missing_ok=True)
                result = self.run_helper("update", ("broken",), FAIL=failure)
                self.assertNotEqual(result.returncode, 0)

    def test_post_upgrade_failure_is_detected(self):
        result = self.run_helper("update", BREAK_AFTER_UPGRADE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("failed verification", result.stderr)

    def test_macos_uses_brew_prefixes_with_spaces(self):
        result = self.run_helper(MOCK_OS="Darwin")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(self.python), self.commands()[0])

    def test_unsupported_os_fails(self):
        result = self.run_helper(MOCK_OS="FreeBSD")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unsupported OS", result.stderr)


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi is required")
class TemplateTests(unittest.TestCase):
    def test_both_scripts_render_and_parse_on_linux_and_macos(self):
        for system in ("linux", "darwin"):
            for name in ("run_onchange_install-packages.sh.tmpl", "run_update-packages.sh.tmpl"):
                with self.subTest(system=system, script=name):
                    source = '{{ $_ := set .chezmoi "os" "' + system + '" }}\n'
                    source += (ROOT / name).read_text()
                    rendered = subprocess.run(
                        ["chezmoi", "--source", str(ROOT), "execute-template"],
                        input=source, capture_output=True, text=True, check=True,
                    ).stdout
                    subprocess.run(["bash", "-n"], input=rendered, text=True, check=True)
                    self.assertIn("maintain_pipx ", rendered)
                    if system == "darwin":
                        self.assertNotIn("sudo dnf", rendered)


@unittest.skipUnless(shutil.which("nvim"), "Neovim is required")
class MasonTests(unittest.TestCase):
    def test_health_repair_and_failure_paths(self):
        for scenario in (
            "healthy", "broken", "missing", "install-failure", "uninstall-failure",
            "busy", "refresh-failure", "missing-module",
        ):
            with self.subTest(scenario=scenario), tempfile.TemporaryDirectory() as directory:
                script = Path(directory) / "test.lua"
                script.write_text("""
local scenario = vim.env.TEST_SCENARIO
local healthy = scenario == "healthy"
local uninstalled, installed = false, false
local package = {
    is_installing = function() return scenario == "busy" end,
    is_installed = function() return scenario ~= "missing" end,
    uninstall = function(_, _, callback)
        uninstalled = true
        callback(scenario ~= "uninstall-failure", "uninstall error")
    end,
}
_G.package.loaded["mason-registry"] = {
    refresh = function() return scenario ~= "refresh-failure" end,
    get_package = function() return package end,
}
_G.package.loaded["mason.settings"] = { current = { install_root_dir = "/mock/mason" } }
_G.package.loaded["mason.api.command"] = {
    MasonInstall = function()
        installed = true
        healthy = scenario ~= "install-failure"
    end,
}
_G.package.loaded["mason-core.async"] = {
    run_blocking = function(fn) fn() end,
    wait = function(fn)
        local result
        fn(function(...) result = {...} end)
        return unpack(result)
    end,
}
vim.system = function(argv)
    assert(argv[1] == "/mock/mason/bin/jedi-language-server")
    return { wait = function() return { code = healthy and 0 or 1 } end }
end
if scenario == "missing-module" then
    _G.package.loaded["mason.settings"] = nil
    _G.package.preload["mason.settings"] = function() error("Mason unavailable") end
end
dofile(vim.env.TEST_HELPER)
if scenario == "healthy" then
    assert(not installed and not uninstalled)
elseif scenario == "broken" then
    assert(installed and uninstalled)
elseif scenario == "missing" then
    assert(installed and not uninstalled)
end
""")
                result = subprocess.run(
                    ["nvim", "--clean", "--headless", "-l", str(script)],
                    env={**os.environ, "TEST_SCENARIO": scenario, "TEST_HELPER": str(JEDI)},
                    capture_output=True, text=True, timeout=20,
                )
                expected_success = scenario in ("healthy", "broken", "missing")
                self.assertEqual(result.returncode == 0, expected_success, result.stderr)


if __name__ == "__main__":
    unittest.main()
