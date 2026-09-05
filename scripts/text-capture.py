import argparse
import json
import os
import re
import select
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from types import FrameType


@dataclass(frozen=True)
class Capabilities:
    ocrAvailable: bool
    dictationAvailable: bool
    ocrReason: str
    dictationReason: str
    modelPath: str
    language: str


def capabilities() -> Capabilities:
    data_home = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    configured = os.environ.get("RASHELL_WHISPER_MODEL") or os.environ.get("WHISPER_MODEL")
    model = Path(configured).expanduser() if configured else data_home / "whisper.cpp/ggml-large-v3-turbo.bin"
    if not configured and not model.is_file():
        model = next(iter(sorted((data_home / "whisper.cpp").glob("ggml-*.bin"))), model)
    ocr_missing = [tool for tool in ("grim", "slurp", "tesseract", "wl-copy") if not shutil.which(tool)]
    dictation_missing = [tool for tool in ("pw-record", "whisper-cli", "wl-copy") if not shutil.which(tool)]
    model_valid = model.is_absolute() and model.is_file() and os.access(model, os.R_OK) and model.stat().st_size > 0
    ocr_reason = "Missing tools: " + ", ".join(ocr_missing) if ocr_missing else "Local OCR with Tesseract"
    dictation_reason = "Missing tools: " + ", ".join(dictation_missing) if dictation_missing else ""
    if not model_valid:
        dictation_reason = (dictation_reason + ". " if dictation_reason else "") + "Set RASHELL_WHISPER_MODEL to an existing local model file"
    language = os.environ.get("WHISPER_LANGUAGE", "ru")
    return Capabilities(not ocr_missing, not dictation_missing and model_valid, ocr_reason,
                        dictation_reason or "Local Whisper · " + language, str(model), language)


def emit(event: str, message: str = "") -> None:
    print(json.dumps({"event": event, "message": message}), flush=True)


class Cancelled(Exception):
    pass


class Capture:
    def __init__(self, directory: Path) -> None:
        self.directory = directory
        self.child: subprocess.Popen[bytes] | None = None
        self.cancelled = False
        self.stop_requested = False
        self.commit_requested = False
        self.input_buffer = b""

    def signal_cancel(self, signum: int, frame: FrameType | None) -> None:
        self.cancelled = True

    def commands(self, timeout: float = 0.05) -> None:
        ready, _, _ = select.select([sys.stdin], [], [], timeout)
        if ready:
            chunk = os.read(sys.stdin.fileno(), 4096)
            if not chunk:
                self.cancelled = True
            self.input_buffer += chunk
            while b"\n" in self.input_buffer:
                command, self.input_buffer = self.input_buffer.split(b"\n", 1)
                if command.strip() == b"cancel":
                    self.cancelled = True
                elif command.strip() == b"stop":
                    self.stop_requested = True
                elif command.strip() == b"commit":
                    self.commit_requested = True
        if self.cancelled:
            raise Cancelled()

    def terminate_child(self, graceful: bool = False) -> None:
        if self.child is None or self.child.poll() is not None:
            return
        self.child.send_signal(signal.SIGINT if graceful else signal.SIGTERM)
        try:
            self.child.wait(timeout=3)
        except subprocess.TimeoutExpired:
            self.child.kill()
            self.child.wait()

    def run(self, argv: list[str], output: Path, timeout: float = 120, recorder: bool = False) -> int:
        self.commands(0)
        with output.open("wb") as stdout, (self.directory / "stderr.log").open("wb") as stderr:
            self.child = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
            started = time.monotonic()
            if recorder:
                emit("recording", "Recording microphone · Stop to transcribe")
            while self.child.poll() is None:
                self.commands()
                if recorder and self.stop_requested:
                    self.terminate_child(graceful=True)
                    break
                if time.monotonic() - started > timeout:
                    raise RuntimeError("Recording time limit reached; capture discarded" if recorder else "Local processing timed out")
            code = self.child.wait()
            self.commands(0)
            return code

    def require_success(self, code: int, message: str) -> None:
        if code != 0:
            raise RuntimeError(message)

    def ocr(self) -> str:
        emit("status", "Select an area · Escape cancels")
        selection = self.directory / "selection.txt"
        code = self.run(["slurp"], selection, timeout=300)
        geometry = selection.read_text().strip()
        if code != 0 or not geometry:
            raise Cancelled()
        if not re.fullmatch(r"-?\d+,-?\d+ \d+x\d+", geometry):
            raise RuntimeError("Invalid selection geometry")
        screenshot = self.directory / "capture.png"
        self.require_success(self.run(["grim", "-g", geometry, str(screenshot)], self.directory / "grim.log"), "Could not capture the selected area")
        emit("status", "Recognizing text locally…")
        text_file = self.directory / "ocr.txt"
        self.require_success(self.run(["tesseract", str(screenshot), "stdout", "-l", os.environ.get("RASHELL_OCR_LANGUAGE", "eng")], text_file), "OCR failed; check the configured Tesseract language")
        return text_file.read_text().strip()

    def dictate(self, config: Capabilities) -> str:
        audio = self.directory / "recording.wav"
        code = self.run(["pw-record", "--rate", "16000", "--channels", "1", "--format", "s16", str(audio)], self.directory / "recording.log", timeout=600, recorder=True)
        if not self.stop_requested or code not in (0, -signal.SIGINT, 128 + signal.SIGINT):
            raise RuntimeError("Microphone recording failed; check the default PipeWire input")
        if not audio.is_file() or audio.stat().st_size <= 44:
            raise RuntimeError("No microphone audio was recorded")
        emit("processing", "Transcribing locally…")
        output_base = self.directory / "transcript"
        self.require_success(self.run(["whisper-cli", "-m", config.modelPath, "-l", config.language,
                                       "-f", str(audio), "-otxt", "-of", str(output_base), "-np"],
                                      self.directory / "whisper.log", timeout=600), "Local Whisper transcription failed")
        output = output_base.with_suffix(".txt")
        if not output.is_file():
            raise RuntimeError("Whisper did not produce a transcript")
        return output.read_text().strip()

    def copy(self, text: str) -> None:
        if not text or text.strip().casefold() in ("[blank_audio]", "[silence]"):
            raise RuntimeError("No text recognized; clipboard unchanged")
        self.commands(0)
        self.commit_requested = False
        emit("ready-to-copy", "Ready to copy recognized text")
        deadline = time.monotonic() + 10
        while not self.commit_requested:
            self.commands()
            if time.monotonic() > deadline:
                raise RuntimeError("Clipboard confirmation timed out; clipboard unchanged")
        emit("committing", "Copying recognized text…")
        copied = self.directory / "clipboard.txt"
        copied.write_text(text)
        with copied.open("rb") as source, (self.directory / "clipboard.log").open("wb") as stderr:
            self.child = subprocess.Popen(["wl-copy", "--type", "text/plain;charset=utf-8"], stdin=source, stdout=subprocess.DEVNULL, stderr=stderr)
            try:
                code = self.child.wait(timeout=10)
            except subprocess.TimeoutExpired as exc:
                raise RuntimeError("Clipboard did not respond") from exc
        self.require_success(code, "Could not copy recognized text")
        emit("completed", "Recognized text copied to clipboard")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", nargs="?", default="probe", choices=("probe", "ocr", "dictation"))
    parser.add_argument("--probe", action="store_true")
    args = parser.parse_args()
    if args.probe:
        args.action = "probe"
    config = capabilities()
    if args.action == "probe":
        print(json.dumps(asdict(config)))
        return 0
    if args.action == "ocr" and not config.ocrAvailable:
        emit("failed", config.ocrReason)
        return 1
    if args.action == "dictation" and not config.dictationAvailable:
        emit("failed", config.dictationReason)
        return 1
    with tempfile.TemporaryDirectory(prefix="rashell-text-") as directory:
        capture = Capture(Path(directory))
        signal.signal(signal.SIGTERM, capture.signal_cancel)
        signal.signal(signal.SIGINT, capture.signal_cancel)
        try:
            text = capture.ocr() if args.action == "ocr" else capture.dictate(config)
            capture.copy(text)
            return 0
        except Cancelled:
            capture.terminate_child()
            emit("cancelled", "Cancelled · clipboard unchanged")
            return 10
        except (OSError, RuntimeError, UnicodeError) as error:
            capture.terminate_child()
            emit("failed", str(error))
            return 1
        finally:
            capture.terminate_child()


if __name__ == "__main__":
    raise SystemExit(main())
