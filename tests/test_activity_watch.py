import contextlib
import io
import json
import runpy
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import call, patch

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "private_dot_local/bin/executable_activity-watch"


class ActivityWatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.data = self.root / "activity-watch"
        self.namespace = runpy.run_path(str(CLI))
        self.main = self.namespace["main"]
        self.globals = self.main.__globals__
        self.globals["DATA_DIR"] = self.data
        self.globals["STATE_FILE"] = self.data / "last-checked.txt"
        self.window = self.globals["WINDOW_SERVICE"]
        self.timer = self.globals["HISTORY_TIMER"]
        self.history = self.globals["HISTORY_SERVICE"]
        self.output = io.StringIO()
        stack = contextlib.ExitStack()
        self.addCleanup(stack.close)
        stack.enter_context(contextlib.redirect_stdout(self.output))
        stack.enter_context(contextlib.redirect_stderr(io.StringIO()))

    def file(self, name, content="record"):
        path = self.data / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def test_no_arguments_and_help_have_no_side_effects(self):
        with patch("subprocess.run") as run:
            self.assertEqual(self.main([]), 0)
            with self.assertRaises(SystemExit) as result:
                self.main(["--help"])
            self.assertEqual(result.exception.code, 0)
        run.assert_not_called()
        self.assertIn("--delete", self.output.getvalue())
        self.assertFalse(self.data.exists())

    def test_invalid_arguments_are_rejected_before_side_effects(self):
        for args in (
            ["--mark-read"], ["--pause", "--mark-read"],
            ["--resume", "--mark-read"], ["--delete", "--mark-read"],
            ["--check", "--delete"], ["--pause", "--resume"],
            ["--unknown"], ["--che"],
        ):
            with self.subTest(args=args), patch("subprocess.run") as run:
                with self.assertRaises(SystemExit) as result:
                    self.main(args)
                self.assertEqual(result.exception.code, 2)
                run.assert_not_called()

    def test_check_is_read_only_and_mark_read_filters_older_records(self):
        self.file("alerts/day.log", "2020-01-01T00:00:00+00:00 ALERT: removed\n")
        self.file("window-logs/day.jsonl", json.dumps({
            "ts": "2020-01-01T00:00:00+00:00",
            "event": "title_changed", "title": "Example tab",
        }) + "\n")
        with patch("subprocess.run") as run:
            self.assertEqual(self.main(["--check"]), 0)
            self.assertIn("Example tab", self.output.getvalue())
            self.assertIn("ALERT: removed", self.output.getvalue())
            self.assertFalse((self.data / "last-checked.txt").exists())
            self.assertEqual(self.main(["--check", "--mark-read"]), 0)
            checkpoint = (self.data / "last-checked.txt").read_text()
            self.output.seek(0)
            self.output.truncate()
            self.assertEqual(self.main(["--check"]), 0)
            self.assertNotIn("Example tab", self.output.getvalue())
            self.assertEqual((self.data / "last-checked.txt").read_text(), checkpoint)
            run.assert_not_called()

    def test_pause_and_resume_control_only_collection_units(self):
        with patch("subprocess.run") as run:
            self.assertEqual(self.main(["--pause"]), 0)
            self.assertEqual(self.main(["--resume"]), 0)
        self.assertEqual(run.call_args_list, [
            call(["systemctl", "--user", "disable", "--now", self.window, self.timer],
                 check=True, capture_output=True, text=True),
            call(["systemctl", "--user", "stop", self.history],
                 check=True, capture_output=True, text=True),
            call(["systemctl", "--user", "enable", "--now", self.window, self.timer],
                 check=True, capture_output=True, text=True),
        ])

    def test_delete_preserves_other_files_and_restores_active_collectors(self):
        paths = [self.file(name) for name in (
            "alerts/day.log", "window-logs/day.jsonl",
            "history-snapshots/day.txt", "last-checked.txt",
        )]
        unrelated = self.file("alerts/notes.txt", "keep")
        chrome = self.root / "History"
        chrome.write_text("Chrome data")
        with patch("subprocess.run", return_value=subprocess.CompletedProcess([], 0)) as run:
            self.assertEqual(self.main(["--delete"]), 0)
        self.assertTrue(all(not path.exists() for path in paths))
        self.assertEqual(unrelated.read_text(), "keep")
        self.assertEqual(chrome.read_text(), "Chrome data")
        self.assertEqual(run.call_args_list[-2].args[0], [
            "systemctl", "--user", "stop", self.timer, self.window, self.history,
        ])
        self.assertEqual(run.call_args_list[-1].args[0], [
            "systemctl", "--user", "start", self.window, self.timer,
        ])

    def test_delete_while_paused_does_not_start_collectors(self):
        def systemctl(args, **kwargs):
            return subprocess.CompletedProcess(args, 3 if "is-active" in args else 0)

        with patch("subprocess.run", side_effect=systemctl) as run:
            self.assertEqual(self.main(["--delete"]), 0)
        self.assertFalse(any("start" in item.args[0] for item in run.call_args_list))

    def test_symlinked_data_directories_are_rejected(self):
        outside = self.root / "outside"
        outside.mkdir()
        protected = outside / "day.log"
        protected.write_text("keep")
        self.data.mkdir()
        (self.data / "alerts").symlink_to(outside, target_is_directory=True)
        with patch("subprocess.run") as run:
            self.assertEqual(self.main(["--delete"]), 1)
            run.assert_not_called()
        self.assertEqual(protected.read_text(), "keep")

    def test_delete_restores_only_the_previously_active_collector(self):
        def systemctl(args, **kwargs):
            code = 3 if "is-active" in args and args[-1] == self.timer else 0
            return subprocess.CompletedProcess(args, code)

        with patch("subprocess.run", side_effect=systemctl) as run:
            self.assertEqual(self.main(["--delete"]), 0)
        self.assertEqual(run.call_args_list[-1].args[0], [
            "systemctl", "--user", "start", self.window,
        ])

    @unittest.skipUnless(shutil.which("zsh"), "zsh is required")
    def test_zsh_aliases_expand_to_expected_arguments(self):
        result = subprocess.run(
            ["zsh", "-f", "-c",
             'source "$1"\n'
             'function activity-watch { print -r -- "$*"; }\n'
             'eval "activity-watch-check --mark-read"\n'
             'eval "activity-watch-pause"\n'
             'eval "activity-watch-resume"\n'
             'eval "activity-watch-delete"\n',
             "test", str(ROOT / "dot_zsh_custom/aliases.zsh")],
            capture_output=True, text=True, check=True,
        )
        self.assertEqual(result.stdout.splitlines(), [
            "--check --mark-read", "--pause", "--resume", "--delete",
        ])

    def test_linked_log_is_unlinked_without_deleting_target(self):
        outside = self.root / "outside"
        outside.write_text("keep")
        (self.data / "alerts").mkdir(parents=True)
        link = self.data / "alerts/day.log"
        link.symlink_to(outside)
        with patch("subprocess.run", return_value=subprocess.CompletedProcess([], 0)):
            self.assertEqual(self.main(["--delete"]), 0)
        self.assertFalse(link.is_symlink())
        self.assertEqual(outside.read_text(), "keep")

    def test_failed_stop_does_not_delete_data_and_restores_collectors(self):
        record = self.file("alerts/day.log")

        def systemctl(args, **kwargs):
            if "stop" in args:
                raise subprocess.CalledProcessError(1, args, stderr="stop failed")
            return subprocess.CompletedProcess(args, 0)

        with patch("subprocess.run", side_effect=systemctl) as run:
            self.assertEqual(self.main(["--delete"]), 1)
        self.assertTrue(record.exists())
        self.assertIn("start", run.call_args_list[-1].args[0])

    def test_failed_deletion_still_restores_collectors(self):
        self.file("alerts/day.log")
        with patch("subprocess.run", return_value=subprocess.CompletedProcess([], 0)) as run:
            with patch.object(Path, "unlink", side_effect=PermissionError("denied")):
                self.assertEqual(self.main(["--delete"]), 1)
        self.assertIn("start", run.call_args_list[-1].args[0])

    def test_failed_state_query_aborts_before_stop_or_delete(self):
        record = self.file("alerts/day.log")
        with patch("subprocess.run", return_value=subprocess.CompletedProcess(
            [], 1, stdout="", stderr="cannot connect",
        )) as run:
            self.assertEqual(self.main(["--delete"]), 1)
        self.assertEqual(run.call_count, 1)
        self.assertTrue(record.exists())


if __name__ == "__main__":
    unittest.main()
