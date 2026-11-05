import configparser
import json
import os
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "private_dot_local/bin/executable_fedora-release-check"
GUIDE = "https://docs.fedoraproject.org/en-US/quick-docs/upgrading-fedora-offline/"


class FedoraReleaseCheckTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.os_release = self.root / "os-release"
        self.os_release.write_text('ID=fedora\nVERSION_ID="44"\n')
        self.script = self.root / "check"
        self.script.write_text(
            SCRIPT.read_text().replace("/etc/os-release", str(self.os_release))
        )
        self.releases = self.root / "releases.json"
        self.releases.write_text(json.dumps([
            {"version": "44"}, {"version": "45"}, {"version": "45"},
            {"version": "46 Beta"}, {"version": "Rawhide"},
        ]))
        self.state = self.root / "state/fedora-release-check/last-notified"
        self.calls = self.root / "notifications"
        self.opened = self.root / "opened"
        self.mock("curl", '[[ ${FAIL_CURL:-0} == 0 ]] || exit 22\ncat "$RELEASES"')
        self.mock("notify-send", (
            '[[ ${FAIL_NOTIFY:-0} == 0 ]] || exit 1\n'
            'printf "%s\\n" "$@" >> "$CALLS"\n'
            'printf "%s\\n" "${ACTION:-}"'
        ))
        self.mock("systemd-run", 'printf "%s\\n" "$@" > "$OPENED"')
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "XDG_STATE_HOME": str(self.root / "state"),
            "RELEASES": str(self.releases),
            "CALLS": str(self.calls),
            "OPENED": str(self.opened),
            "ACTION": "",
        }

    def mock(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\nset -eu\n" + body + "\n")
        path.chmod(0o755)

    def run_check(self, **env):
        return subprocess.run(
            ["bash", str(self.script)], env={**self.env, **env},
            capture_output=True, text=True, timeout=10,
        )

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_notification_has_action_and_opens_requested_url(self):
        self.assert_success(self.run_check(ACTION="default"))
        self.assertIn("--action=default=Open upgrade guide", self.calls.read_text())
        self.assertIn("Fedora 45 is available", self.calls.read_text())
        self.assertEqual(self.opened.read_text().splitlines(), [
            "--user", "--collect", "--quiet", "--no-block", "/usr/bin/xdg-open", GUIDE,
        ])
        self.assertEqual(self.state.read_text().split()[0], "45")

    def test_dismissal_does_not_open_browser_or_suppress_next_check(self):
        self.assert_success(self.run_check())
        self.assertFalse(self.opened.exists())
        calls = self.calls.read_text()
        self.assert_success(self.run_check())
        self.assertEqual(self.calls.read_text(), calls + calls)

    def test_recent_notification_does_not_suppress_login_or_daily_checks(self):
        self.state.parent.mkdir(parents=True)
        self.state.write_text(f"45 {int(time.time())}\n")
        self.assert_success(self.run_check())
        self.assertTrue(self.calls.exists())

    def test_new_release_is_not_suppressed_by_previous_release_state(self):
        self.state.parent.mkdir(parents=True)
        self.state.write_text(f"44 {int(time.time())}\n")
        self.assert_success(self.run_check())
        self.assertTrue(self.calls.exists())

    def test_numeric_comparison_not_lexical(self):
        self.os_release.write_text("ID=fedora\nVERSION_ID=99\n")
        self.releases.write_text('[{"version":"99"},{"version":"100"}]')
        self.assert_success(self.run_check())
        self.assertIn("Fedora 100 is available", self.calls.read_text())

    def test_no_notification_when_current_or_ahead_of_stable(self):
        for version in ("45", "46"):
            with self.subTest(version=version):
                self.os_release.write_text(f"ID=fedora\nVERSION_ID={version}\n")
                self.assert_success(self.run_check())
                self.assertFalse(self.calls.exists())

    def test_network_invalid_json_empty_and_notification_failures_preserve_state(self):
        self.state.parent.mkdir(parents=True)
        original = "44 1\n"
        self.state.write_text(original)
        for data, env in (
            ('[{"version":"45"}]', {"FAIL_CURL": "1"}),
            ("not json", {}),
            ("[]", {}),
            ('[{"version":"46 Beta"}]', {}),
            ('[{"version":"45"}]', {"FAIL_NOTIFY": "1"}),
        ):
            with self.subTest(data=data, env=env):
                self.releases.write_text(data)
                self.assertNotEqual(self.run_check(**env).returncode, 0)
                self.assertEqual(self.state.read_text(), original)

    def test_corrupt_state_does_not_suppress_notification(self):
        self.state.parent.mkdir(parents=True)
        self.state.write_text("45 invalid\n")
        self.assert_success(self.run_check())
        self.assertTrue(self.calls.exists())

    def test_other_distributions_are_ignored(self):
        self.os_release.write_text("ID=debian\nVERSION_ID=13\n")
        self.assert_success(self.run_check(FAIL_CURL="1"))
        self.assertFalse(self.calls.exists())


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi is required")
class FedoraReleaseIntegrationTests(unittest.TestCase):
    def test_timer_runs_after_each_graphical_login_and_daily(self):
        timer = configparser.ConfigParser()
        timer.read(ROOT / "private_dot_config/systemd/user/fedora-release-check.timer")
        self.assertEqual(timer["Unit"]["PartOf"], "graphical-session.target")
        self.assertEqual(timer["Install"]["WantedBy"], "graphical-session.target")
        self.assertEqual(timer["Timer"]["OnActiveSec"], "30s")
        self.assertEqual(timer["Timer"]["OnUnitActiveSec"], "1d")
        self.assertEqual(timer["Timer"]["AccuracySec"], "1s")
        for obsolete in ("OnCalendar", "OnStartupSec", "RandomizedDelaySec", "Persistent"):
            self.assertNotIn(obsolete, timer["Timer"])
        service = configparser.ConfigParser(interpolation=None)
        service.read(ROOT / "private_dot_config/systemd/user/fedora-release-check.service")
        self.assertEqual(service["Unit"]["PartOf"], "graphical-session.target")

    def render(self, filename, system, distro, hostname="fresh-pc"):
        source = (
            '{{ $_ := set .chezmoi "os" "' + system + '" }}\n'
            '{{ $_ := set .chezmoi "osRelease" (dict "id" "' + distro + '") }}\n'
            '{{ $_ := set .chezmoi "hostname" "' + hostname + '" }}\n'
            + (ROOT / filename).read_text()
        )
        return subprocess.run(
            ["chezmoi", "--source", str(ROOT), "execute-template"],
            input=source, capture_output=True, text=True, check=True,
        ).stdout

    def test_fresh_fedora_host_installs_dependencies_and_full_desktop(self):
        rendered = self.render("run_onchange_install-packages.sh.tmpl", "linux", "fedora")
        subprocess.run(["bash", "-n"], input=rendered, text=True, check=True)
        install = next(
            line for line in rendered.splitlines() if "sudo dnf install -y" in line
        )
        for package in (
            "bash", "coreutils", "curl", "dunst", "jq", "libnotify",
            "systemd", "util-linux", "xdg-utils",
        ):
            self.assertIn(f'"{package}"', install)
        self.assertIn("dnf copr enable -y sdegler/hyprland", rendered)
        self.assertIn("dnf copr enable -y tofik/nwg-shell", rendered)
        self.assertIn("rpmfusion-free-release", rendered)
        self.assertIn("/etc/yum.repos.d/docker-ce-stable.repo", rendered)
        self.assertIn('"hyprland"', rendered)
        self.assertIn("flatpak install -y --noninteractive --app flathub", rendered)
        self.assertIn("re.sonny.Junction", rendered)

    def test_fedora_templates_are_identical_across_hostnames(self):
        for filename in (
            "run_onchange_install-packages.sh.tmpl", "run_update-packages.sh.tmpl",
            "run_onchange_after_setup-systemd-units.sh.tmpl", "dot_lessfilter.tmpl",
        ):
            with self.subTest(filename=filename):
                fresh = self.render(filename, "linux", "fedora")
                current = self.render(filename, "linux", "fedora", "baky-fedora-pc")
                self.assertEqual(fresh, current)
                subprocess.run(["bash", "-n"], input=fresh, text=True, check=True)

    def test_updates_and_less_fallback_keep_platform_guards(self):
        for system, distro in (("linux", "fedora"), ("linux", "debian"), ("darwin", "")):
            with self.subTest(system=system, distro=distro):
                update = self.render("run_update-packages.sh.tmpl", system, distro)
                self.assertEqual("sudo dnf update -y" in update, distro == "fedora")
                self.assertEqual("flatpak update -y" in update, distro == "fedora")
                preview = self.render("dot_lessfilter.tmpl", system, distro)
                self.assertEqual(
                    'lesspipe.sh "$1" | bat --color=always' in preview,
                    distro == "fedora" or system == "darwin",
                )

    def test_timer_enable_and_dependency_install_are_fedora_only(self):
        for system, distro in (("linux", "fedora"), ("linux", "debian"), ("darwin", "")):
            with self.subTest(system=system, distro=distro):
                setup = self.render("run_onchange_after_setup-systemd-units.sh.tmpl", system, distro)
                subprocess.run(["sh", "-n"], input=setup, text=True, check=True)
                self.assertEqual(
                    "reenable --now fedora-release-check.timer" in setup, distro == "fedora"
                )
                install = self.render("run_onchange_install-packages.sh.tmpl", system, distro)
                self.assertEqual("sudo dnf install" in install, distro == "fedora")
                ignored = self.render(".chezmoiignore", system, distro).splitlines()
                self.assertEqual(".local/bin/fedora-release-check" in ignored, system != "linux")
                self.assertEqual(".config/systemd" in ignored, system != "linux")


if __name__ == "__main__":
    unittest.main()
