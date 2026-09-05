#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
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
    template = (CORE / "telegram-base.tdesktop-palette").read_text(encoding="utf-8")
    return Template(template).substitute(colors)


def write_palette(output: Path, content: str) -> None:
    if not output.is_absolute():
        raise ValueError("The output path must be absolute")
    if output.is_file() and output.read_text(encoding="utf-8") == content:
        return
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
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
        content = render_palette(load_palette(arguments.theme))
        output = Path(arguments.output)
        write_palette(output, content)
    except (OSError, UnicodeError, ValueError, KeyError) as error:
        print(f"Telegram theme: {error}", file=sys.stderr)
        return 1
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
