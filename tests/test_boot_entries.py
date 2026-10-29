import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOOK = ROOT / ".chezmoitemplates/fedora-boot-entries.install"
INSTALLER = ROOT / "run_onchange_after_setup-fedora-boot-entries.sh.tmpl"
MACHINE = "a" * 32
OLD = "7.2.5-200.fc44.x86_64"
NEW = "7.2.11-200.fc44.x86_64"


class BootEntryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="boot entries ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.boot = self.root / "boot"
        self.entries = self.boot / "loader/entries"
        self.entries.mkdir(parents=True)
        self.archive = self.boot / "loader/entries-archive"
        self.os_release = self.root / "os-release"
        self.os_release.write_text("ID=fedora\nVERSION_ID=44\n")
        self.machine_id = self.root / "machine-id"
        self.machine_id.write_text(MACHINE + "\n")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        grub = self.bin / "grub2-editenv"
        grub.write_text(
            '#!/bin/bash\n[[ "${FAIL_GRUB:-}" != 1 ]] || exit 1\n'
            'printf "%s\\n" "$@" > "$GRUB_CALLS"\n'
        )
        grub.chmod(0o755)
        self.hook = self.root / "hook"
        # Redirect every privileged path in the test copy, not the real hook.
        source = HOOK.read_text()
        for original, replacement in (
            ("/etc/os-release", self.os_release),
            ("/etc/machine-id", self.machine_id),
            ("/run/lock/local-boot-entries.lock", self.root / "lock"),
        ):
            source = source.replace(original, f'"{replacement}"')
        source = source.replace("entries=/boot/loader/entries", f'entries="{self.entries}"')
        source = source.replace(
            "archive=/boot/loader/entries-archive", f'archive="{self.archive}"'
        )
        source = source.replace('"/boot$', f'"{self.boot}$')
        source = source.replace(
            "export PATH=/usr/sbin:/usr/bin:/sbin:/bin",
            f'export PATH="{self.bin}:/usr/sbin:/usr/bin:/sbin:/bin"',
        )
        self.hook.write_text(source)
        self.env = {**os.environ, "GRUB_CALLS": str(self.root / "grub-calls")}

    def entry(self, version, machine=MACHINE, images=True):
        entry = self.entries / f"{machine}-{version}.conf"
        entry.write_text(
            f"title Fedora Linux ({version}) 44 (Sway)\n"
            f"version {version}\nlinux /vmlinuz-{version}\n"
            f"initrd /initramfs-{version}.img $tuned_initrd\n"
            "options root=UUID=test ro quiet $tuned_params\n"
            "grub_users $grub_users\ngrub_arg --unrestricted\ngrub_class fedora\n"
        )
        if images:
            (self.boot / f"vmlinuz-{version}").write_text("kernel")
            (self.boot / f"initramfs-{version}.img").write_text("initrd")
        return entry

    def run_hook(self, action="add", version=NEW, **env):
        return subprocess.run(
            ["bash", str(self.hook), action, version],
            env={**self.env, **env}, capture_output=True, text=True, timeout=10,
        )

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_archives_old_and_rescue_and_preserves_other_fields(self):
        old = self.entry(OLD)
        new = self.entry(NEW)
        rescue = self.entry("0-rescue")
        original = new.read_text()
        self.assert_success(self.run_hook())
        self.assertEqual(list(self.entries.iterdir()), [new])
        self.assertEqual(new.read_text().splitlines()[0], "title Fedora Linux 44 7.2.11")
        self.assertEqual(new.read_text().splitlines()[1:], original.splitlines()[1:])
        self.assertEqual((self.archive / "originals" / new.name).read_text(), original)
        archived = list(self.archive.glob("[0-9]*/*.conf"))
        self.assertEqual({p.name for p in archived}, {old.name, rescue.name})
        self.assertEqual((self.archive.stat().st_mode & 0o777), 0o700)
        self.assertIn(f"saved_entry={MACHINE}-{NEW}", (self.root / "grub-calls").read_text())

    def test_repeated_runs_do_not_create_batches_or_overwrite_archives(self):
        self.entry(OLD)
        self.entry(NEW)
        self.assert_success(self.run_hook())
        first = list(self.archive.glob("[0-9]*/*.conf"))[0]
        content = first.read_text()
        self.assert_success(self.run_hook("refresh"))
        self.assertEqual(len(list(self.archive.glob("[0-9]*"))), 1)
        self.entry(OLD).write_text(content + "# reinstalled\n")
        self.assert_success(self.run_hook(version=OLD))
        self.assertEqual(len(list(self.archive.glob("[0-9]*"))), 2)
        self.assertEqual(first.read_text(), content)
        self.assertTrue((self.entries / f"{MACHINE}-{NEW}.conf").exists())

    def test_reports_original_and_renamed_titles(self):
        self.entry(NEW)
        result = self.run_hook()
        self.assert_success(result)
        self.assertIn(
            f"Original boot entry title: Fedora Linux ({NEW}) 44 (Sway)\n"
            "Renamed boot entry title: Fedora Linux 44 7.2.11\n",
            result.stdout,
        )

    def test_refresh_does_not_report_a_rename_when_title_is_unchanged(self):
        self.entry(NEW)
        self.assert_success(self.run_hook())
        result = self.run_hook("refresh")
        self.assert_success(result)
        self.assertNotIn("Original boot entry title:", result.stdout)
        self.assertNotIn("Renamed boot entry title:", result.stdout)

    def test_reports_current_title_instead_of_first_seen_backup_title(self):
        new = self.entry(NEW)
        original = new.read_text()
        self.assert_success(self.run_hook())
        new.write_text(new.read_text().replace(
            "title Fedora Linux 44 7.2.11", "title Custom title with 100% battery"
        ))
        result = self.run_hook()
        self.assert_success(result)
        self.assertIn(
            "Original boot entry title: Custom title with 100% battery\n",
            result.stdout,
        )
        self.assertIn("Renamed boot entry title: Fedora Linux 44 7.2.11\n", result.stdout)
        self.assertEqual((self.archive / "originals" / new.name).read_text(), original)

    def test_foreign_custom_and_symlink_entries_are_untouched(self):
        self.entry(NEW)
        foreign = self.entry(OLD, machine="b" * 32)
        custom = self.entry(OLD + "+debug")
        target = self.root / "external.conf"
        target.write_text("untouched")
        link = self.entries / f"{MACHINE}-{OLD}.conf"
        link.symlink_to(target)
        self.assert_success(self.run_hook())
        self.assertTrue(foreign.exists())
        self.assertTrue(custom.exists())
        self.assertTrue(link.is_symlink())
        self.assertEqual(target.read_text(), "untouched")

    def test_missing_empty_or_unexpected_images_abort_without_archiving(self):
        old = self.entry(OLD)
        new = self.entry(NEW)
        image = self.boot / f"initramfs-{NEW}.img"
        for problem in ("missing", "empty", "unexpected", "wrong-version"):
            with self.subTest(problem=problem):
                self.entry(NEW)
                if problem == "missing":
                    image.unlink()
                elif problem == "empty":
                    image.write_text("")
                elif problem == "unexpected":
                    new.write_text(new.read_text().replace(f"/vmlinuz-{NEW}", "/unexpected"))
                else:
                    new.write_text(new.read_text().replace(f"version {NEW}", f"version {OLD}"))
                self.assertNotEqual(self.run_hook().returncode, 0)
                self.assertTrue(old.exists())
                self.assertFalse(self.archive.exists())
                self.assertFalse((self.root / "grub-calls").exists())

    def test_failed_default_update_does_not_archive(self):
        old = self.entry(OLD)
        self.entry(NEW)
        self.assertNotEqual(self.run_hook(FAIL_GRUB="1").returncode, 0)
        self.assertTrue(old.exists())
        self.assertFalse(list(self.archive.glob("[0-9]*")))

    def test_newest_original_is_not_overwritten_by_refresh_or_reinstall(self):
        new = self.entry(NEW)
        original = new.read_text()
        self.assert_success(self.run_hook())
        backup = self.archive / "originals" / new.name
        self.assertEqual(backup.read_text(), original)
        self.assert_success(self.run_hook("refresh"))
        self.assertEqual(backup.read_text(), original)
        new.write_text(new.read_text() + "# regenerated entry\n")
        self.assert_success(self.run_hook())
        self.assertEqual(backup.read_text(), original)
        self.assertFalse(list(self.archive.glob("[0-9]*")))
        self.assertEqual(list((self.archive / "originals").iterdir()), [backup])

    def test_original_survives_when_its_active_entry_is_later_archived(self):
        new = self.entry(NEW)
        original = new.read_text()
        self.assert_success(self.run_hook())
        newer = self.entry("7.2.12-200.fc44.x86_64")
        newer_original = newer.read_text()
        self.assert_success(self.run_hook(version="7.2.12-200.fc44.x86_64"))
        self.assertEqual((self.archive / "originals" / new.name).read_text(), original)
        self.assertEqual(
            (self.archive / "originals" / newer.name).read_text(), newer_original
        )
        self.assertFalse(new.exists())
        self.assertTrue(newer.exists())
        archived = list(self.archive.glob(f"[0-9]*/{new.name}"))
        self.assertEqual(len(archived), 1)
        self.assertTrue(archived[0].read_text().startswith("title Fedora Linux 44 7.2.11\n"))

    def test_failed_backup_leaves_active_entries_unchanged_and_cleans_tempfile(self):
        old = self.entry(OLD)
        new = self.entry(NEW)
        original = new.read_text()
        cp = self.bin / "cp"
        cp.write_text('#!/bin/bash\nprintf partial > "${@: -1}"\nexit 1\n')
        cp.chmod(0o755)
        self.assertNotEqual(self.run_hook().returncode, 0)
        self.assertEqual(new.read_text(), original)
        self.assertTrue(old.exists())
        self.assertEqual(list((self.archive / "originals").iterdir()), [])
        self.assertFalse((self.root / "grub-calls").exists())

    def test_remove_and_unknown_events_do_nothing(self):
        old = self.entry(OLD)
        self.entry(NEW)
        for action in ("remove", "inspect"):
            self.assert_success(self.run_hook(action))
        self.assertTrue(old.exists())
        self.assertFalse(self.archive.exists())

    def test_no_standard_entries_is_noop(self):
        rescue = self.entry("0-rescue")
        self.assert_success(self.run_hook("refresh"))
        self.assertTrue(rescue.exists())
        self.assertFalse(self.archive.exists())

    def test_non_fedora_is_noop(self):
        self.os_release.write_text("ID=debian\nVERSION_ID=13\n")
        old = self.entry(OLD)
        self.entry(NEW)
        self.assert_success(self.run_hook())
        self.assertTrue(old.exists())
        self.assertFalse(self.archive.exists())


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi is required")
class InstallerTemplateTests(unittest.TestCase):
    def test_platform_guards_and_shell_syntax(self):
        for system, distro in (("linux", "fedora"), ("linux", "debian"), ("darwin", "")):
            with self.subTest(system=system, distro=distro):
                source = (
                    '{{ $_ := set .chezmoi "os" "' + system + '" }}\n'
                    '{{ $_ := set .chezmoi "osRelease" (dict "id" "' + distro + '") }}\n'
                    + INSTALLER.read_text()
                )
                result = subprocess.run(
                    ["chezmoi", "--source", str(ROOT), "execute-template"],
                    input=source, capture_output=True, text=True, check=True,
                )
                subprocess.run(["bash", "-n"], input=result.stdout, text=True, check=True)
                self.assertEqual("sudo install" in result.stdout, distro == "fedora")
                if distro == "fedora":
                    self.assertIn(HOOK.read_text().strip(), result.stdout)


if __name__ == "__main__":
    unittest.main()
