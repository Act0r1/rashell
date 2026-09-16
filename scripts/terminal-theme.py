#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import re
import signal
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import cast


CORE = Path(__file__).resolve().parent.parent / "core"
PALETTE_KEYS = (
    "background", "surface", "surfaceRaised", "accent", "accentMuted",
    "text", "textMuted", "textDisabled", "textOnAccent", "border",
    "borderInteractive", "danger", "textOnDanger",
)


@dataclass(frozen=True)
class Theme:
    name: str
    kind: str
    palette: dict[str, str]


def load_theme(theme_id: str) -> Theme:
    raw: object = json.loads((CORE / "themes.json").read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        raise ValueError("The theme catalog must contain a list")
    for item in cast(list[object], raw):
        if not isinstance(item, dict):
            raise ValueError("The theme catalog contains an invalid theme")
        theme = cast(dict[str, object], item)
        if theme.get("id") != theme_id:
            continue
        kind = theme.get("kind")
        raw_palette = theme.get("palette")
        if kind not in ("dark", "light") or not isinstance(raw_palette, dict):
            raise ValueError(f"Invalid theme: {theme_id}")
        palette: dict[str, str] = {}
        for key, value in cast(dict[str, object], raw_palette).items():
            if not isinstance(value, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
                raise ValueError(f"Invalid {key} color for {theme_id}")
            palette[key] = value.lower()
        if not all(key in palette for key in PALETTE_KEYS):
            raise ValueError(f"Incomplete palette for {theme_id}")
        return Theme(theme_id, cast(str, kind), palette)
    raise ValueError(f"Unknown theme: {theme_id}")


def blend(first: str, second: str, amount: float) -> str:
    channels = (
        round(int(first[index:index + 2], 16) * (1 - amount)
              + int(second[index:index + 2], 16) * amount)
        for index in (1, 3, 5)
    )
    return "#" + "".join(f"{channel:02x}" for channel in channels)


def luminance(color: str) -> float:
    channels = [int(color[index:index + 2], 16) / 255 for index in (1, 3, 5)]
    linear = [value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
              for value in channels]
    return sum(value * weight for value, weight in zip(linear, (0.2126, 0.7152, 0.0722)))


def readable(color: str, background: str, kind: str) -> str:
    background_luminance = luminance(background)
    target = "#ffffff" if kind == "dark" else "#000000"
    for step in range(101):
        candidate = blend(color, target, step / 100)
        low, high = sorted((luminance(candidate), background_luminance))
        if (high + 0.05) / (low + 0.05) >= 4.5:
            return candidate
    return target


def base16(theme: Theme) -> dict[str, str]:
    palette = theme.palette
    semantic = (
        ("#e5a16b", "#dfc26b", "#93c780", "#78c6cd", "#c18fa3")
        if theme.kind == "dark" else
        ("#995122", "#856500", "#39703b", "#24717b", "#8b5067")
    )
    orange, yellow, green, cyan, brown = (
        readable(blend(color, palette["accent"], 0.06), palette["background"], theme.kind)
        for color in semantic
    )
    colors = (
        palette["background"], palette["surface"], palette["surfaceRaised"],
        palette["textMuted"], palette["textMuted"], palette["text"],
        palette["text"], palette["text"], palette["danger"], orange, yellow,
        green, cyan,
        readable(palette["accent"], palette["background"], theme.kind),
        readable(palette["accentMuted"], palette["background"], theme.kind), brown,
    )
    return {f"base{index:02X}": color for index, color in enumerate(colors)}


def ansi_colors(theme: Theme, base: dict[str, str]) -> list[str]:
    normal = [base[key] for key in ("base00", "base08", "base0B", "base0A",
                                     "base0D", "base0E", "base0C", "base05")]
    bright = [base["base03"]] + [
        readable(blend(color, theme.palette["text"], 0.12), base["base00"], theme.kind)
        for color in normal[1:7]
    ] + [base["base07"]]
    return normal + bright


def ghostty_config(theme: Theme, base: dict[str, str], ansi: list[str]) -> str:
    palette = theme.palette
    settings = {
        "background": palette["background"],
        "foreground": palette["text"],
        "cursor-color": base["base0D"],
        "cursor-text": palette["background"],
        "selection-background": palette["surfaceRaised"],
        "selection-foreground": palette["text"],
        "split-divider-color": palette["accent"],
        "unfocused-split-fill": palette["background"],
        "search-background": base["base0A"],
        "search-foreground": palette["background"],
        "search-selected-background": base["base0D"],
        "search-selected-foreground": palette["background"],
    }
    return "\n".join(
        [f"{key} = {value}" for key, value in settings.items()]
        + [f"palette = {index}={color}" for index, color in enumerate(ansi)]
    ) + "\n"


def write_changed(output: Path, content: str) -> bool:
    encoded = content.encode("utf-8")
    if output.is_file() and output.read_bytes() == encoded:
        return False
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(mode="wb", dir=output.parent,
                                         prefix=f".{output.name}.", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(encoded)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, output)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return True


def reload_ghostty() -> None:
    expected = Path("/usr/bin/ghostty").resolve()
    for process in Path("/proc").iterdir():
        if not process.name.isdigit():
            continue
        descriptor: int | None = None
        try:
            if process.stat().st_uid != os.getuid():
                continue
            descriptor = os.pidfd_open(int(process.name))
            if (process / "exe").resolve() != expected:
                continue
            environment = dict(item.split(b"=", 1) for item in
                               (process / "environ").read_bytes().split(b"\0") if b"=" in item)
            desktop = (environment.get(b"XDG_CURRENT_DESKTOP")
                       or environment.get(b"XDG_SESSION_DESKTOP", b"")).lower().split(b":")
            hyprland = b"hyprland" in desktop and b"niri" not in desktop
            if desktop == [b""]:
                hyprland = bool(environment.get(b"HYPRLAND_INSTANCE_SIGNATURE")) and not environment.get(b"NIRI_SOCKET")
            if not hyprland or environment.get(b"RASHELL_TERMINAL_SESSION") != b"rashell":
                continue
            status = (process / "status").read_text()
            caught = re.search(r"^SigCgt:\s*([0-9a-fA-F]+)$", status, re.MULTILINE)
            if caught and int(caught[1], 16) & (1 << (signal.SIGUSR2 - 1)):
                signal.pidfd_send_signal(descriptor, signal.SIGUSR2)
        except (FileNotFoundError, ProcessLookupError, PermissionError):
            continue
        finally:
            if descriptor is not None:
                os.close(descriptor)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--theme", required=True)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--reload-ghostty", action="store_true")
    arguments = parser.parse_args()
    try:
        output: Path = arguments.output_dir
        if not output.is_absolute():
            raise ValueError("The output directory must be absolute")
        theme = load_theme(arguments.theme)
        base = base16(theme)
        ansi = ansi_colors(theme, base)
        document = {"name": theme.name, "kind": theme.kind,
                    "palette": theme.palette, "base16": base, "ansi": ansi}
        write_changed(output / "terminal-palette.json", json.dumps(document, indent=2) + "\n")
        changed = write_changed(output / "ghostty.conf", ghostty_config(theme, base, ansi))
        if changed and arguments.reload_ghostty:
            reload_ghostty()
    except (OSError, UnicodeError, ValueError, KeyError) as error:
        print(f"Terminal theme: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
