#!/usr/bin/env python3

from __future__ import annotations

import argparse
import io
import json
import os
import re
import struct
import sys
import tempfile
import zipfile
import zlib
from pathlib import Path
from string import Template
from typing import cast


CORE = Path(__file__).resolve().parent.parent / "core"
PALETTE_KEYS = (
    "background",
    "surface",
    "surfaceRaised",
    "accent",
    "accentMuted",
    "text",
    "textMuted",
    "textDisabled",
    "textOnAccent",
    "border",
    "borderInteractive",
    "danger",
    "textOnDanger",
)


def load_palette(theme_id: str) -> dict[str, str]:
    raw: object = json.loads((CORE / "themes.json").read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        raise ValueError("The theme catalog must contain a list")
    for item in cast(list[object], raw):
        if not isinstance(item, dict):
            raise ValueError("The theme catalog contains an invalid theme")
        theme = cast(dict[str, object], item)
        if theme.get("id") != theme_id:
            continue
        raw_palette = theme.get("palette")
        if not isinstance(raw_palette, dict):
            raise ValueError(f"Invalid palette for {theme_id}")
        palette = cast(dict[str, object], raw_palette)
        result: dict[str, str] = {}
        for key in PALETTE_KEYS:
            value = palette.get(key)
            if not isinstance(value, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
                raise ValueError(f"Invalid {key} color for {theme_id}")
            result[key] = value.lower()
        return result
    raise ValueError(f"Unknown theme: {theme_id}")


def blend(first: str, second: str, amount: float) -> str:
    channels = (
        round(int(first[index:index + 2], 16) * (1 - amount)
              + int(second[index:index + 2], 16) * amount)
        for index in (1, 3, 5)
    )
    return "#" + "".join(f"{channel:02x}" for channel in channels)


def render_palette(palette: dict[str, str]) -> str:
    colors = palette | {
        "hover": blend(palette["surfaceRaised"], palette["accent"], 0.10),
        "ripple": blend(palette["surfaceRaised"], palette["accent"], 0.18),
        "outgoing": blend(palette["surfaceRaised"], palette["accent"], 0.10),
        "selected": blend(palette["surfaceRaised"], palette["accent"], 0.24),
        "accentHover": blend(palette["accent"], palette["background"], 0.08),
        "accentRipple": blend(palette["accent"], palette["background"], 0.16),
        "dangerHover": blend(palette["surface"], palette["danger"], 0.12),
        "dangerRipple": blend(palette["surface"], palette["danger"], 0.20),
    }
    peer_colors = {
        "peer1": "#c03d33",
        "peer2": "#4fad2d",
        "peer3": "#d09306",
        "peer5": "#8544d6",
        "peer6": "#cd4073",
        "peer7": "#2996ad",
        "peer8": "#ce671b",
    }
    colors.update({
        key: blend(value, palette["text"], 0.22)
        for key, value in peer_colors.items()
    })
    template = (CORE / "telegram-base.tdesktop-palette").read_text(encoding="utf-8")
    return Template(template).substitute(colors)


def png_chunk(kind: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data))
    )


def solid_background(color: str) -> bytes:
    size = 64
    row = b"\x00" + bytes.fromhex(color[1:]) * size
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(row * size))
        + png_chunk(b"IEND", b"")
    )


def render_theme(palette: dict[str, str], suffix: str) -> bytes:
    colors = render_palette(palette).encode("utf-8")
    if suffix.lower() == ".tdesktop-palette":
        return colors
    if suffix.lower() != ".tdesktop-theme":
        raise ValueError("The output must end in .tdesktop-theme or .tdesktop-palette")
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w") as archive:
        for name, content in (
            ("colors.tdesktop-palette", colors),
            ("background.png", solid_background(palette["background"])),
        ):
            member = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            member.compress_type = zipfile.ZIP_STORED
            archive.writestr(member, content)
    return buffer.getvalue()


def write_theme(output: Path, content: bytes) -> None:
    if not output.is_absolute():
        raise ValueError("The output path must be absolute")
    if output.is_file() and output.read_bytes() == content:
        return
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=output.parent,
            prefix=f".{output.name}.",
            delete=False,
        ) as stream:
            temporary = Path(stream.name)
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, output)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--theme", required=True)
    parser.add_argument("--output", required=True)
    arguments = parser.parse_args()
    try:
        output = Path(arguments.output)
        content = render_theme(load_palette(arguments.theme), output.suffix)
        write_theme(output, content)
    except (OSError, UnicodeError, ValueError, KeyError) as error:
        print(f"Telegram theme: {error}", file=sys.stderr)
        return 1
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
