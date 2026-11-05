import json
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKUP = ROOT / "private_dot_config/rclone/create_encrypted_private_rclone.conf.age"
DUMMY_CONFIG = "[dummy]\ntype = drive\ntoken = dummy-test-value\n"
SECRET_BACKUPS = (
    ("private_dot_ssh/encrypted_private_id_rsa.age", ".ssh/id_rsa"),
    ("private_dot_ssh/encrypted_private_config.age", ".ssh/config"),
    ("dot_zsh_custom/encrypted_private_secrets.zsh.age", ".zsh_custom/secrets.zsh"),
    ("dot_zsh_custom/encrypted_private_secret_aliases.zsh.age", ".zsh_custom/secret_aliases.zsh"),
)


@unittest.skipUnless(
    all(shutil.which(tool) for tool in ("chezmoi", "age", "age-keygen")),
    "chezmoi and age are required",
)
class RcloneBackupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="rclone-backup-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.control = self.root / "control"
        self.control.mkdir()
        self.source = self.root / "source"
        self.destination = self.root / "home"
        self.destination.mkdir()
        self.target = self.destination / ".config/rclone/rclone.conf"
        self.encrypted = self.source / BACKUP.relative_to(ROOT)
        self.encrypted.parent.mkdir(parents=True)
        self.identity = self.control / "test-identity"
        subprocess.run(
            ["age-keygen", "--output", str(self.identity)],
            capture_output=True, check=True,
        )
        recipient = subprocess.check_output(
            ["age-keygen", "-y", str(self.identity)], text=True,
        ).strip()
        self.recipient = recipient
        subprocess.run(
            ["age", "--armor", "--recipient", recipient, "--output", str(self.encrypted)],
            input=DUMMY_CONFIG, text=True, capture_output=True, check=True,
        )
        self.config = self.control / "chezmoi.toml"
        self.config.write_text(
            'encryption = "age"\n[age]\n'
            f"identity = {json.dumps(str(self.identity))}\n"
            f"recipient = {json.dumps(recipient)}\n"
        )
        self.command = [
            "chezmoi", "--config", str(self.config),
            "--source", str(self.source), "--destination", str(self.destination),
            "--persistent-state", str(self.control / "state.boltdb"),
            "--cache", str(self.control / "cache"),
        ]
        self.env = {**os.environ, "PAGER": "cat"}

    def apply(self):
        return subprocess.run(
            [*self.command, "apply", "--exclude", "scripts"],
            env=self.env, capture_output=True, text=True, timeout=10, check=True,
        )

    def test_repository_backup_is_age_encrypted_and_restore_once_private(self):
        self.assertTrue(BACKUP.is_file())
        header = BACKUP.read_bytes()
        self.assertTrue(
            header.startswith(b"-----BEGIN AGE ENCRYPTED FILE-----")
            or header.startswith(b"age-encryption.org/v1\n")
        )
        sources = [
            path for path in BACKUP.parent.iterdir()
            if path.is_file() and "rclone.conf" in path.name
        ]
        self.assertEqual(sources, [BACKUP])

    def test_missing_config_is_restored_with_private_permissions(self):
        self.apply()
        self.assertEqual(self.target.read_text(), DUMMY_CONFIG)
        self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o600)

    def test_existing_config_and_rotated_tokens_are_not_overwritten(self):
        self.apply()
        current = DUMMY_CONFIG.replace("dummy-test-value", "rotated-dummy-test-value")
        self.target.write_text(current)
        self.apply()
        self.assertEqual(self.target.read_text(), current)
        self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o600)

    def test_documented_refresh_keeps_create_encrypted_private_attributes(self):
        self.apply()
        current = DUMMY_CONFIG.replace("dummy-test-value", "refreshed-dummy-test-value")
        self.target.write_text(current)
        subprocess.run(
            [*self.command, "add", "--create", "--encrypt", str(self.target)],
            env=self.env, capture_output=True, text=True, timeout=10, check=True,
        )
        # Only dummy credentials are decrypted in this isolated fixture.
        decrypted = subprocess.check_output(
            ["age", "--decrypt", "--identity", str(self.identity), str(self.encrypted)],
            text=True,
        )
        self.assertEqual(decrypted, current)
        self.assertEqual(list(self.encrypted.parent.iterdir()), [self.encrypted])

    def test_ssh_and_shell_sources_are_encrypted_and_private(self):
        for source, _ in SECRET_BACKUPS:
            with self.subTest(source=source):
                path = ROOT / source
                self.assertTrue(path.is_file())
                self.assertIn("encrypted_private_", path.name)
                header = path.read_bytes()
                self.assertTrue(
                    header.startswith(b"-----BEGIN AGE ENCRYPTED FILE-----")
                    or header.startswith(b"age-encryption.org/v1\n")
                )
        for obsolete in (
            "dot_zsh_custom/encrypted_secrets.zsh.age",
            "dot_zsh_custom/encrypted_secret_aliases.zsh.age",
            "private_dot_ssh/id_rsa", "private_dot_ssh/config",
            "dot_zsh_custom/secrets.zsh", "dot_zsh_custom/secret_aliases.zsh",
        ):
            self.assertFalse((ROOT / obsolete).exists(), obsolete)
        self.assertTrue((ROOT / "private_dot_ssh/id_rsa.pub").is_file())

    def test_ssh_and_shell_restore_with_owner_only_permissions(self):
        for source, _ in SECRET_BACKUPS:
            encrypted = self.source / source
            encrypted.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(
                ["age", "--armor", "--recipient", self.recipient, "--output", str(encrypted)],
                input="dummy-secret-fixture\n", text=True, capture_output=True, check=True,
            )
        public_key = self.source / "private_dot_ssh/id_rsa.pub"
        public_key.write_text("dummy-public-key-fixture\n")
        self.apply()
        for _, target in SECRET_BACKUPS:
            restored = self.destination / target
            self.assertEqual(restored.read_text(), "dummy-secret-fixture\n")
            self.assertEqual(stat.S_IMODE(restored.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE((self.destination / ".ssh").stat().st_mode), 0o700)
        restored_public = self.destination / ".ssh/id_rsa.pub"
        self.assertEqual(stat.S_IMODE(restored_public.stat().st_mode), 0o644)
        self.assertEqual(restored_public.read_text(), "dummy-public-key-fixture\n")


if __name__ == "__main__":
    unittest.main()
