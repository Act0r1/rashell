from collections.abc import Callable
import json
import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import time
import unittest

ROOT = Path(__file__).parents[1]
SCRIPT = ROOT / "scripts/screen-capture.sh"


def wait_until(predicate: Callable[[], bool], timeout: float = 3.0) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.02)
    raise AssertionError("condition was not reached before timeout")


class ScreenshotTest(unittest.TestCase):
    def test_capture_config_and_panel_contract(self) -> None:
        config = json.loads((ROOT / "config.json").read_text())
        self.assertEqual(config["captureDirectory"], "~/Pictures/Screenshots")

        panel = (ROOT / "modules/system/ScreenshotPanel.qml").read_text()
        self.assertIn('root.captureState.start("screenshot"', panel)
        self.assertIn('root.captureState.start("annotate"', panel)
        self.assertIn('"record",', panel)
        self.assertIn('root.captureState.captureMode === "region"', panel)
        self.assertIn('root.captureState.captureMode === "output"', panel)
        self.assertIn('root.captureState.audioMode === "system"', panel)
        self.assertIn('root.captureState.audioMode === "microphone"', panel)
        self.assertIn('root.captureState.audioMode === "both"', panel)
        self.assertIn("root.captureState.pause()", panel)
        self.assertIn("root.captureState.resume()", panel)
        self.assertIn("root.captureState.stop()", panel)
        self.assertIn("FolderDialog", panel)

    def test_region_selection_is_started_and_shown(self) -> None:
        panel = (ROOT / "modules/system/ScreenshotPanel.qml").read_text()
        state = (ROOT / "modules/system/ScreenshotState.qml").read_text()
        script = SCRIPT.read_text()

        self.assertIn('root.captureState.selectArea("region", root.outputName)', panel)
        self.assertIn('"Selected region: " + root.captureState.captureSelection', panel)
        self.assertIn('function selectArea(mode, outputName)', state)
        self.assertIn('root.captureSelection = String(selectionProcess.stdout.text || "").trim()', state)
        self.assertIn('select-region)', script)

    def test_region_selector_returns_the_chosen_geometry(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binaries = root / "bin"
            runtime = root / "runtime"
            binaries.mkdir()
            runtime.mkdir()
            (binaries / "slurp").write_text("#!/usr/bin/env bash\nprintf '10,20 300x200\\n'\n")
            (binaries / "slurp").chmod(0o755)

            environment = os.environ.copy()
            environment["PATH"] = f"{binaries}:{environment['PATH']}"
            environment["XDG_RUNTIME_DIR"] = str(runtime)
            result = subprocess.run(
                [str(SCRIPT), "select-region"],
                env=environment,
                check=True,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.stdout.strip(), "10,20 300x200")

    def test_record_uses_preselected_region_without_reopening_selector(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binaries = root / "bin"
            runtime = root / "runtime"
            binaries.mkdir()
            runtime.mkdir()
            arguments_marker = root / "arguments"
            selector_marker = root / "selector"

            (binaries / "slurp").write_text("#!/usr/bin/env bash\ntouch \"$SELECTOR_MARKER\"\nexit 1\n")
            (binaries / "wf-recorder").write_text(textwrap.dedent("""\
                #!/usr/bin/env bash
                printf '%s\n' "$*" > "$ARGUMENTS_MARKER"
                while [[ "$1" != "-f" ]]; do shift; done
                printf video > "$2"
            """))
            (binaries / "notify-send").write_text("#!/usr/bin/env bash\nexit 0\n")
            for binary in binaries.iterdir():
                binary.chmod(0o755)

            environment = os.environ.copy()
            environment["PATH"] = f"{binaries}:{environment['PATH']}"
            environment["XDG_RUNTIME_DIR"] = str(runtime)
            environment["ARGUMENTS_MARKER"] = str(arguments_marker)
            environment["SELECTOR_MARKER"] = str(selector_marker)
            subprocess.run(
                [str(SCRIPT), "record", str(root / "captures"), "region", "none", "10,20 300x200"],
                env=environment,
                check=True,
                capture_output=True,
                text=True,
            )

            self.assertIn("--geometry 10,20 300x200", arguments_marker.read_text())
            self.assertFalse(selector_marker.exists())

    def test_capture_commands_are_not_detached_from_the_bar(self) -> None:
        bar = (ROOT / "modules/system/ScreenshotBar.qml").read_text()
        self.assertIn('root.coordinator.toggle(', bar)
        self.assertNotIn("execDetached", bar)

    def test_capture_script_checks_required_tools_and_saves_all_formats(self) -> None:
        script = (ROOT / "scripts/screen-capture.sh").read_text()
        self.assertIn("require grim", script)
        self.assertIn("require slurp", script)
        self.assertIn("satty", script)
        self.assertIn("wf-recorder", script)
        self.assertIn("run_selector -o -r -f '%o'", script)
        self.assertIn('recorder_args+=(--audio="$system_source")', script)
        self.assertIn('recorder_args+=(--audio="$microphone_source")', script)
        self.assertIn('recorder_args+=(--audio="${mix_name}.monitor")', script)
        self.assertIn('pactl load-module module-null-sink', script)
        self.assertIn('pactl unload-module', script)
        self.assertIn('kill -STOP "$recorder_pid"', script)
        self.assertIn('kill -CONT "$recorder_pid"', script)
        self.assertIn('kill -INT "$recorder_pid"', script)
        self.assertIn('kill -TERM "$selector_pid"', script)
        self.assertIn('wl-copy --type image/png', script)

    def test_audio_modes_pass_the_selected_pipewire_source(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binaries = root / "bin"
            runtime = root / "runtime"
            binaries.mkdir()
            runtime.mkdir()
            arguments_marker = root / "arguments"
            pactl_marker = root / "pactl"

            (binaries / "slurp").write_text("#!/usr/bin/env bash\nprintf '0,0 100x100\\n'\n")
            (binaries / "notify-send").write_text("#!/usr/bin/env bash\nexit 0\n")
            (binaries / "wf-recorder").write_text(textwrap.dedent("""\
                #!/usr/bin/env bash
                printf '%s\\n' "$*" > "$ARGUMENTS_MARKER"
                while [[ "$1" != "-f" ]]; do shift; done
                printf video > "$2"
            """))
            (binaries / "pactl").write_text(textwrap.dedent("""\
                #!/usr/bin/env bash
                printf '%s\\n' "$*" >> "$PACTL_MARKER"
                case "$1 $2" in
                    "get-default-source ") printf 'mic.source\\n' ;;
                    "get-default-sink ") printf 'speaker.sink\\n' ;;
                    "list short") printf '1\\tspeaker.sink.monitor\\n' ;;
                    "load-module module-null-sink") printf '41\\n' ;;
                    "load-module module-loopback") printf '42\\n' ;;
                esac
            """))
            for binary in binaries.iterdir():
                binary.chmod(0o755)

            environment = os.environ.copy()
            environment["PATH"] = f"{binaries}:{environment['PATH']}"
            environment["XDG_RUNTIME_DIR"] = str(runtime)
            environment["ARGUMENTS_MARKER"] = str(arguments_marker)
            environment["PACTL_MARKER"] = str(pactl_marker)
            expected_sources = {
                "microphone": "--audio=mic.source",
                "system": "--audio=speaker.sink.monitor",
                "both": f"--audio=rashell_capture_mix_{os.getuid()}_",
            }

            for mode, expected_source in expected_sources.items():
                with self.subTest(mode=mode):
                    subprocess.run(
                        [str(SCRIPT), "record", str(root / mode), "region", mode],
                        env=environment,
                        check=True,
                        capture_output=True,
                        text=True,
                    )
                    self.assertIn(expected_source, arguments_marker.read_text())

            unloads = [line for line in pactl_marker.read_text().splitlines() if line.startswith("unload-module")]
            self.assertEqual(len(unloads), 3)

    def test_pause_resume_and_stop_control_the_recorder_process(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binaries = root / "bin"
            runtime = root / "runtime"
            captures = root / "captures"
            binaries.mkdir()
            runtime.mkdir()

            (binaries / "slurp").write_text("#!/usr/bin/env bash\nprintf '0,0 100x100\\n'\n")
            (binaries / "notify-send").write_text("#!/usr/bin/env bash\nexit 0\n")
            (binaries / "wf-recorder").write_text(textwrap.dedent("""\
                #!/usr/bin/env python3
                import ctypes
                from pathlib import Path
                import signal
                import sys
                import time

                ctypes.CDLL(None).prctl(15, b"wf-recorder", 0, 0, 0)
                output = Path(sys.argv[sys.argv.index("-f") + 1])
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_bytes(b"video")
                signal.signal(signal.SIGINT, lambda _signal, _frame: sys.exit(0))
                while True:
                    time.sleep(0.05)
            """))
            for binary in binaries.iterdir():
                binary.chmod(0o755)

            environment = os.environ.copy()
            environment["PATH"] = f"{binaries}:{environment['PATH']}"
            environment["XDG_RUNTIME_DIR"] = str(runtime)
            recording = subprocess.Popen(
                [str(SCRIPT), "record", str(captures), "region", "none"],
                env=environment,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            pid_file = runtime / f"rashell-screen-recorder-{os.getuid()}.pid"
            wait_until(pid_file.exists)
            recorder_pid = int(pid_file.read_text())

            subprocess.run([str(SCRIPT), "pause"], env=environment, check=True)
            wait_until(lambda: Path(f"/proc/{recorder_pid}/status").read_text().split("State:", 1)[1].lstrip().startswith("T"))
            subprocess.run([str(SCRIPT), "resume"], env=environment, check=True)
            wait_until(lambda: not Path(f"/proc/{recorder_pid}/status").read_text().split("State:", 1)[1].lstrip().startswith("T"))
            subprocess.run([str(SCRIPT), "pause"], env=environment, check=True)
            subprocess.run([str(SCRIPT), "stop"], env=environment, check=True)

            stdout, stderr = recording.communicate(timeout=3)
            self.assertEqual(recording.returncode, 0, stderr)
            self.assertIn("recording_", stdout)
            self.assertFalse(pid_file.exists())

    def test_stop_during_region_selection_prevents_recording(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binaries = root / "bin"
            runtime = root / "runtime"
            binaries.mkdir()
            runtime.mkdir()
            recorder_marker = root / "recorder-started"

            (binaries / "slurp").write_text(textwrap.dedent("""\
                #!/usr/bin/env python3
                import ctypes
                import time

                ctypes.CDLL(None).prctl(15, b"slurp", 0, 0, 0)
                while True:
                    time.sleep(0.05)
            """))
            (binaries / "wf-recorder").write_text(
                "#!/usr/bin/env bash\ntouch \"$RECORDER_MARKER\"\nexit 0\n"
            )
            for binary in binaries.iterdir():
                binary.chmod(0o755)

            environment = os.environ.copy()
            environment["PATH"] = f"{binaries}:{environment['PATH']}"
            environment["XDG_RUNTIME_DIR"] = str(runtime)
            environment["RECORDER_MARKER"] = str(recorder_marker)
            recording = subprocess.Popen(
                [str(SCRIPT), "record", str(root / "captures"), "region", "none"],
                env=environment,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            selector_file = runtime / f"rashell-screen-selector-{os.getuid()}.pid"
            wait_until(selector_file.exists)
            subprocess.run([str(SCRIPT), "stop"], env=environment, check=True)

            recording.communicate(timeout=3)
            self.assertEqual(recording.returncode, 10)
            self.assertFalse(recorder_marker.exists())
            self.assertFalse(selector_file.exists())


if __name__ == "__main__":
    unittest.main()
