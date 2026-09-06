#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import re
import select
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import uuid
from collections.abc import Callable
from contextlib import ExitStack
from pathlib import Path
from types import FrameType
from typing import BinaryIO
from urllib.error import HTTPError, URLError
from urllib.parse import unquote, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

MAX_IMAGE_BYTES = 256 * 1024 * 1024
IMAGE_TIMEOUT_SECONDS = 15
IMAGE_DEADLINE_SECONDS = 120
MAX_REDIRECTS = 5
PROGRESS_PREFIX = "__RASHELL_PROGRESS__"
TITLE_PREFIX = "__RASHELL_TITLE__"
FILE_PREFIX = "__RASHELL_FILE__"
IMAGE_PROGRESS_PREFIX = "__RASHELL_IMAGE_PROGRESS__"
IMAGE_RESULT_PREFIX = "__RASHELL_IMAGE_RESULT__"


class Cancelled(Exception):
    pass


class DownloadError(Exception):
    def __init__(self, code: str, message: str, path: Path | None = None) -> None:
        super().__init__(message)
        self.code = code
        self.path = path


class LimitedRedirectHandler(HTTPRedirectHandler):
    def __init__(self) -> None:
        super().__init__()
        self.redirects = 0

    def redirect_request(
        self,
        request: Request,
        file_pointer: object,
        code: int,
        message: str,
        headers: object,
        new_url: str,
    ) -> Request | None:
        self.redirects += 1
        if self.redirects > MAX_REDIRECTS:
            raise HTTPError(new_url, 508, "Too many redirects", headers, file_pointer)
        parsed = urlsplit(new_url)
        if parsed.scheme not in {"http", "https"}:
            raise HTTPError(
                new_url, 400, "Unsupported redirect scheme", headers, file_pointer
            )
        return super().redirect_request(
            request, file_pointer, code, message, headers, new_url
        )


def emit(event: str, **values: object) -> None:
    print(json.dumps({"event": event, **values}, ensure_ascii=False), flush=True)


def image_type(header: bytes) -> tuple[str, str] | None:
    if header.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png", ".png"
    if header.startswith(b"\xff\xd8\xff"):
        return "image/jpeg", ".jpg"
    if header.startswith((b"GIF87a", b"GIF89a")):
        return "image/gif", ".gif"
    if len(header) >= 12 and header.startswith(b"RIFF") and header[8:12] == b"WEBP":
        return "image/webp", ".webp"
    if header.startswith(b"BM"):
        return "image/bmp", ".bmp"
    if header.startswith((b"II*\x00", b"MM\x00*")):
        return "image/tiff", ".tiff"
    if (
        len(header) >= 12
        and header[4:8] == b"ftyp"
        and header[8:12] in {b"avif", b"avis"}
    ):
        return "image/avif", ".avif"
    return None


def safe_image_name(url: str, suffix: str) -> str:
    candidate = unquote(Path(urlsplit(url).path).name)
    stem = Path(candidate).stem if candidate else "image"
    stem = re.sub(r"[\x00-\x1f/\\]+", "_", stem).strip(" .")
    return (stem[:120] or "image") + suffix


def cache_directory() -> Path:
    configured = os.environ.get("XDG_CACHE_HOME")
    root = (
        Path(configured)
        if configured and Path(configured).is_absolute()
        else Path.home() / ".cache"
    )
    downloads = root / "rashell" / "downloads"
    downloads.mkdir(parents=True, exist_ok=True)
    return downloads.resolve()


def fetch_image_worker(url: str, output: Path) -> int:
    request = Request(
        url,
        headers={
            "Accept": "image/avif,image/webp,image/png,image/jpeg,image/gif,image/*;q=0.8,*/*;q=0.1",
            "User-Agent": "rashell-media-downloader/1.0",
        },
    )
    opener = build_opener(LimitedRedirectHandler())
    started = time.monotonic()
    recognized = False
    try:
        with opener.open(request, timeout=IMAGE_TIMEOUT_SECONDS) as response:
            declared_length = response.headers.get("Content-Length")
            total = (
                int(declared_length)
                if declared_length and declared_length.isdigit()
                else None
            )
            first = response.read(32)
            detected = image_type(first)
            if detected is None:
                return 20
            recognized = True
            if total is not None and total > MAX_IMAGE_BYTES:
                return 21
            mime, suffix = detected
            downloaded = len(first)
            if downloaded > MAX_IMAGE_BYTES:
                return 21
            with output.open("wb") as destination:
                destination.write(first)
                print(f"{IMAGE_PROGRESS_PREFIX}{downloaded}\t{total or ''}", flush=True)
                while True:
                    if time.monotonic() - started > IMAGE_DEADLINE_SECONDS:
                        return 21
                    chunk = response.read(256 * 1024)
                    if not chunk:
                        break
                    downloaded += len(chunk)
                    if downloaded > MAX_IMAGE_BYTES:
                        return 21
                    destination.write(chunk)
                    print(
                        f"{IMAGE_PROGRESS_PREFIX}{downloaded}\t{total or ''}",
                        flush=True,
                    )
            if total is not None and downloaded != total:
                return 21
            result: dict[str, object] = {
                "path": str(output),
                "mime": mime,
                "suffix": suffix,
                "title": Path(safe_image_name(response.geturl(), suffix)).stem,
                "url": response.geturl(),
            }
            print(
                IMAGE_RESULT_PREFIX + json.dumps(result, ensure_ascii=False), flush=True
            )
            return 0
    except (HTTPError, URLError, TimeoutError, OSError, ValueError):
        return 21 if recognized else 20


class Controller:
    def __init__(self) -> None:
        self.cancelled = False
        self.stdin_open = True
        self.input_buffer = b""
        self.child: subprocess.Popen[bytes] | None = None

    def request_cancel(self, signum: int, frame: FrameType | None) -> None:
        self.cancelled = True

    def poll_commands(self, timeout: float) -> None:
        readers: list[object] = []
        if self.stdin_open:
            readers.append(sys.stdin)
        if readers:
            ready, _, _ = select.select(readers, [], [], timeout)
            if ready:
                chunk = os.read(sys.stdin.fileno(), 4096)
                if not chunk:
                    self.stdin_open = False
                    self.cancelled = True
                else:
                    self.input_buffer += chunk
                    while b"\n" in self.input_buffer:
                        command, self.input_buffer = self.input_buffer.split(b"\n", 1)
                        if command.strip().lower() == b"cancel":
                            self.cancelled = True
        elif timeout:
            time.sleep(timeout)
        if self.cancelled:
            raise Cancelled()

    def terminate_child(self) -> None:
        child = self.child
        if child is None or child.poll() is not None:
            return
        try:
            os.killpg(child.pid, signal.SIGTERM)
        except ProcessLookupError:
            return
        try:
            child.wait(timeout=3)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(child.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            child.wait()

    def run_lines(self, argv: list[str], consume: Callable[[str], None]) -> int:
        self.poll_commands(0)
        child = subprocess.Popen(
            argv,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        self.child = child
        if child.stdout is None:
            raise DownloadError(
                "process_failed", f"Could not read output from {argv[0]}"
            )
        descriptor = child.stdout.fileno()
        buffer = b""
        try:
            while child.poll() is None:
                readers: list[object] = [child.stdout]
                if self.stdin_open:
                    readers.append(sys.stdin)
                ready, _, _ = select.select(readers, [], [], 0.1)
                if self.stdin_open and sys.stdin in ready:
                    self.poll_commands(0)
                if child.stdout in ready:
                    chunk = os.read(descriptor, 65536)
                    if chunk:
                        buffer += chunk
                        while b"\n" in buffer:
                            raw, buffer = buffer.split(b"\n", 1)
                            consume(raw.decode("utf-8", errors="replace").rstrip("\r"))
                if self.cancelled:
                    raise Cancelled()
            remainder = os.read(descriptor, 65536)
            buffer += remainder
            for raw in buffer.splitlines():
                consume(raw.decode("utf-8", errors="replace"))
            return child.wait()
        finally:
            if child.poll() is None:
                self.terminate_child()
            self.child = None


def parse_number(raw: str) -> float | None:
    if not raw or raw == "NA":
        return None
    try:
        return float(raw)
    except ValueError:
        return None


def parse_integer(raw: str) -> int | None:
    number = parse_number(raw)
    return int(number) if number is not None else None


def try_direct_image(
    url: str, working: Path, controller: Controller
) -> dict[str, object] | None:
    temporary = working / "image.part"
    result: dict[str, object] | None = None

    def consume(line: str) -> None:
        nonlocal result
        if line.startswith(IMAGE_PROGRESS_PREFIX):
            fields = line.removeprefix(IMAGE_PROGRESS_PREFIX).split("\t")
            downloaded = parse_integer(fields[0]) if fields else None
            total = parse_integer(fields[1]) if len(fields) > 1 else None
            percent = (
                downloaded * 100 / total if downloaded is not None and total else None
            )
            emit(
                "progress",
                percent=percent,
                downloaded_bytes=downloaded,
                total_bytes=total,
                speed_bytes_per_second=None,
                eta_seconds=None,
            )
        elif line.startswith(IMAGE_RESULT_PREFIX):
            value = json.loads(line.removeprefix(IMAGE_RESULT_PREFIX))
            if isinstance(value, dict):
                result = value

    code = controller.run_lines(
        [
            sys.executable,
            str(Path(__file__).resolve()),
            "__fetch-image",
            url,
            str(temporary),
        ],
        consume,
    )
    if code == 20:
        temporary.unlink(missing_ok=True)
        return None
    if code != 0 or result is None:
        temporary.unlink(missing_ok=True)
        raise DownloadError(
            "image_download_failed", "Image download exceeded its size or time limit"
        )
    return result


def download_media(url: str, working: Path, controller: Controller) -> tuple[Path, str]:
    missing = [tool for tool in ("yt-dlp", "ffmpeg") if shutil.which(tool) is None]
    if missing:
        raise DownloadError(
            "missing_tool", "Missing required tool: " + ", ".join(missing)
        )
    title = ""
    final_path: Path | None = None
    recent_output: list[str] = []
    processing_emitted = False

    def consume(line: str) -> None:
        nonlocal title, final_path, processing_emitted
        if line.startswith(PROGRESS_PREFIX):
            fields = line.removeprefix(PROGRESS_PREFIX).split("\t")
            downloaded = parse_integer(fields[0]) if fields else None
            total = parse_integer(fields[1]) if len(fields) > 1 else None
            speed = parse_number(fields[2]) if len(fields) > 2 else None
            eta = parse_number(fields[3]) if len(fields) > 3 else None
            percent = (
                downloaded * 100 / total if downloaded is not None and total else None
            )
            emit(
                "progress",
                percent=percent,
                downloaded_bytes=downloaded,
                total_bytes=total,
                speed_bytes_per_second=speed,
                eta_seconds=eta,
            )
            return
        if line.startswith(TITLE_PREFIX):
            raw = line.removeprefix(TITLE_PREFIX)
            try:
                value = json.loads(raw)
                title = value if isinstance(value, str) else str(value)
            except json.JSONDecodeError:
                title = raw
            emit("metadata", title=title)
            return
        if line.startswith(FILE_PREFIX):
            raw = line.removeprefix(FILE_PREFIX)
            try:
                value = json.loads(raw)
                if isinstance(value, str):
                    final_path = Path(value)
            except json.JSONDecodeError:
                final_path = Path(raw)
            return
        if not processing_emitted and line.startswith(
            ("[Merger]", "[VideoRemuxer]", "[Fixup", "[ExtractAudio]")
        ):
            processing_emitted = True
            emit("processing", message="Finalizing media")
        clean = line.strip()
        if clean:
            recent_output.append(clean)
            del recent_output[:-8]

    template = str(working / "%(title).160B [%(id)s].%(ext)s")
    argv = [
        "yt-dlp",
        "--ignore-config",
        "--no-playlist",
        "--playlist-items",
        "1",
        "--no-overwrites",
        "--no-colors",
        "--newline",
        "--progress",
        "--progress-template",
        f"download:{PROGRESS_PREFIX}%(progress.downloaded_bytes)s\t%(progress.total_bytes,progress.total_bytes_estimate)s\t%(progress.speed)s\t%(progress.eta)s",
        "--print",
        f"before_dl:{TITLE_PREFIX}%(title)j",
        "--print",
        f"after_move:{FILE_PREFIX}%(filepath)j",
        "--format",
        "bv*+ba/b",
        "--merge-output-format",
        "mp4",
        "--remux-video",
        "mp4",
        "--output",
        template,
        url,
    ]
    code = controller.run_lines(argv, consume)
    if code != 0:
        detail = (
            recent_output[-1] if recent_output else f"yt-dlp exited with status {code}"
        )
        raise DownloadError("download_failed", detail)
    if final_path is None:
        raise DownloadError(
            "final_path_missing", "Downloader did not report the finalized file"
        )
    resolved = final_path.resolve(strict=True)
    if not resolved.is_relative_to(working.resolve()) or not resolved.is_file():
        raise DownloadError(
            "invalid_final_path", "Downloader reported an invalid finalized file"
        )
    return resolved, title or resolved.stem


def promote(source: Path, downloads: Path, name: str | None = None) -> Path:
    destination_directory = downloads / uuid.uuid4().hex
    destination_directory.mkdir(mode=0o700)
    destination = destination_directory / (name or source.name)
    try:
        shutil.move(str(source), destination)
    except OSError:
        destination_directory.rmdir()
        raise
    return destination.resolve(strict=True)


def saved_mime_and_kind(path: Path) -> tuple[str, str]:
    with path.open("rb") as source:
        detected = image_type(source.read(32))
    if detected is not None:
        mime = detected[0]
        return mime, "file" if mime == "image/gif" else "image"
    return mimetypes.guess_type(path.name)[0] or "application/octet-stream", "file"


def clipboard_mime(saved_mime: str, kind: str) -> str:
    return "image/png" if kind == "image" else "text/uri-list"


def convert_image(path: Path, controller: Controller, directory: Path) -> Path:
    executable = shutil.which("ffmpeg")
    if executable is None:
        raise DownloadError("missing_tool", "Missing required tool: ffmpeg", path)
    output = directory / "clipboard.png"
    recent_output: list[str] = []

    def consume(line: str) -> None:
        clean = line.strip()
        if clean:
            recent_output.append(clean)
            del recent_output[:-4]

    emit("processing", message="Preparing image")
    code = controller.run_lines(
        [
            executable,
            "-hide_banner",
            "-loglevel",
            "error",
            "-nostdin",
            "-y",
            "-i",
            str(path),
            "-frames:v",
            "1",
            str(output),
        ],
        consume,
    )
    if code != 0:
        detail = (
            recent_output[-1] if recent_output else f"ffmpeg exited with status {code}"
        )
        raise DownloadError("image_conversion_failed", detail, path)
    if not output.is_file():
        raise DownloadError(
            "image_conversion_failed", "Image conversion produced no output", path
        )
    with output.open("rb") as converted:
        detected = image_type(converted.read(32))
    if detected is None or detected[0] != "image/png":
        raise DownloadError(
            "image_conversion_failed",
            "Image conversion produced invalid PNG data",
            path,
        )
    return output


def read_process_error(error_file: BinaryIO) -> str:
    error_file.seek(0)
    raw = error_file.read()
    return raw.decode("utf-8", errors="replace").strip()


def copy_to_clipboard(
    path: Path, saved_mime: str, kind: str, controller: Controller
) -> None:
    executable = shutil.which("wl-copy")
    if executable is None:
        raise DownloadError("missing_tool", "Missing required tool: wl-copy", path)
    with tempfile.TemporaryFile() as errors, ExitStack() as sources:
        child: subprocess.Popen[bytes] | None = None
        if kind == "image":
            clipboard_path = path
            if saved_mime != "image/png":
                conversion_directory = Path(
                    sources.enter_context(
                        tempfile.TemporaryDirectory(prefix="rashell-clipboard-")
                    )
                )
                clipboard_path = convert_image(path, controller, conversion_directory)
            source = sources.enter_context(clipboard_path.open("rb"))
        else:
            source = sources.enter_context(tempfile.TemporaryFile())
            source.write((path.as_uri() + "\r\n").encode("utf-8"))
            source.seek(0)
        try:
            controller.poll_commands(0)
            child = subprocess.Popen(
                [executable, "--type", clipboard_mime(saved_mime, kind)],
                stdin=source,
                stdout=subprocess.DEVNULL,
                stderr=errors,
                start_new_session=True,
            )
            controller.child = child
            started = time.monotonic()
            while child.poll() is None:
                controller.poll_commands(0.05)
                if time.monotonic() - started > 15:
                    controller.terminate_child()
                    raise DownloadError(
                        "clipboard_failed", "Clipboard command timed out", path
                    )
            code = child.wait()
            controller.child = None
            if code != 0:
                detail = (
                    read_process_error(errors) or f"wl-copy exited with status {code}"
                )
                raise DownloadError("clipboard_failed", detail, path)
        finally:
            if child is not None and child.poll() is None:
                controller.terminate_child()
            controller.child = None


def validate_url(url: str) -> str:
    parsed = urlsplit(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise DownloadError("invalid_url", "URL must use HTTP or HTTPS")
    return url


def handle_probe() -> int:
    tools = {
        "yt_dlp": shutil.which("yt-dlp") is not None,
        "ffmpeg": shutil.which("ffmpeg") is not None,
        "wl_copy": shutil.which("wl-copy") is not None,
        "magick": shutil.which("magick") is not None,
    }
    capabilities = {
        "video": tools["yt_dlp"] and tools["ffmpeg"],
        "image": True,
        "clipboard": tools["wl_copy"],
        "image_conversion": tools["magick"],
    }
    emit(
        "probe",
        ok=capabilities["video"] and capabilities["clipboard"],
        tools=tools,
        capabilities=capabilities,
    )
    return 0


def handle_copy(raw_path: str, controller: Controller) -> int:
    path = Path(raw_path)
    if not path.is_absolute():
        raise DownloadError("invalid_path", "Clipboard path must be absolute")
    try:
        resolved = path.resolve(strict=True)
    except OSError as error:
        raise DownloadError("invalid_path", f"File does not exist: {path}") from error
    if not resolved.is_file():
        raise DownloadError("invalid_path", f"Not a regular file: {resolved}")
    mime, kind = saved_mime_and_kind(resolved)
    copied_mime = clipboard_mime(mime, kind)
    emit("started", path=str(resolved))
    copy_to_clipboard(resolved, mime, kind, controller)
    emit("clipboard", ok=True, path=str(resolved), mime=copied_mime)
    emit(
        "done",
        ok=True,
        path=str(resolved),
        mime=mime,
        kind=kind,
        title=resolved.stem,
        clipboard_ok=True,
    )
    return 0


def handle_download(raw_url: str, controller: Controller) -> int:
    url = validate_url(raw_url)
    if shutil.which("wl-copy") is None:
        raise DownloadError("missing_tool", "Missing required tool: wl-copy")
    downloads = cache_directory()
    working = Path(tempfile.mkdtemp(prefix=".download-", dir=downloads))
    saved: Path | None = None
    emit("started", url=url)
    try:
        image = try_direct_image(url, working, controller)
        if image is not None:
            source = Path(str(image["path"])).resolve(strict=True)
            suffix = str(image["suffix"])
            title = str(image["title"])
            saved = promote(
                source, downloads, safe_image_name(str(image["url"]), suffix)
            )
            mime = str(image["mime"])
            kind = "file" if mime == "image/gif" else "image"
            emit("metadata", title=title)
        else:
            source, title = download_media(url, working, controller)
            saved = promote(source, downloads)
            mime = mimetypes.guess_type(saved.name)[0] or "application/octet-stream"
            kind = "file"
        emit("saved", path=str(saved), mime=mime, kind=kind, title=title)
        copied_mime = clipboard_mime(mime, kind)
        try:
            copy_to_clipboard(saved, mime, kind, controller)
        except DownloadError as error:
            emit(
                "clipboard",
                ok=False,
                path=str(saved),
                mime=copied_mime,
                message=str(error),
            )
            raise
        emit("clipboard", ok=True, path=str(saved), mime=copied_mime)
        emit(
            "done",
            ok=True,
            path=str(saved),
            mime=mime,
            kind=kind,
            title=title,
            clipboard_ok=True,
        )
        return 0
    finally:
        shutil.rmtree(working, ignore_errors=True)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="action", required=True)
    subparsers.add_parser("probe")
    download = subparsers.add_parser("download")
    download.add_argument("url")
    copy = subparsers.add_parser("copy")
    copy.add_argument("path")
    return parser


def main() -> int:
    if len(sys.argv) == 4 and sys.argv[1] == "__fetch-image":
        return fetch_image_worker(sys.argv[2], Path(sys.argv[3]))
    args = build_parser().parse_args()
    controller = Controller()
    signal.signal(signal.SIGTERM, controller.request_cancel)
    signal.signal(signal.SIGINT, controller.request_cancel)
    try:
        if args.action == "probe":
            return handle_probe()
        if args.action == "copy":
            return handle_copy(args.path, controller)
        return handle_download(args.url, controller)
    except Cancelled:
        controller.terminate_child()
        emit("cancelled", ok=False, message="Cancelled")
        return 130
    except DownloadError as error:
        controller.terminate_child()
        values: dict[str, object] = {
            "ok": False,
            "code": error.code,
            "message": str(error),
        }
        if error.path is not None:
            values["path"] = str(error.path)
        emit("error", **values)
        return 1
    except (OSError, ValueError, json.JSONDecodeError) as error:
        controller.terminate_child()
        emit("error", ok=False, code="internal_error", message=str(error))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
