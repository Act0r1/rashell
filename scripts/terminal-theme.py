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
    "borderInteractive", "danger", "textOnDanger", "accentSecondary",
    "dangerText", "borderControl", "success", "warning", "info",
)
SYNTAX_ROLES = (
    "comment", "string", "keyword", "function", "type", "number",
    "constant", "variable", "operator", "punctuation",
)
BASE16_KEYS = {f"base{index:02X}" for index in range(16)}
SETTING_KEYS = (
    "background", "foreground", "cursor-color", "cursor-text",
    "selection-background", "selection-foreground", "split-divider-color",
    "unfocused-split-fill", "search-background", "search-foreground",
    "search-selected-background", "search-selected-foreground",
)


@dataclass(frozen=True)
class TerminalScheme:
    base16: dict[str, str]
    ansi: list[str]
    settings: dict[str, str]


@dataclass(frozen=True)
class Theme:
    name: str
    kind: str
    palette: dict[str, str]
    syntax: dict[str, str]
    terminal: TerminalScheme


def color_map(value: object, expected: set[str], label: str) -> dict[str, str]:
    if not isinstance(value, dict):
        raise ValueError(f"Invalid {label}")
    result: dict[str, str] = {}
    for key, color in cast(dict[object, object], value).items():
        if not isinstance(key, str) or not isinstance(color, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
            raise ValueError(f"Invalid {label} color")
        result[key] = color.lower()
    if set(result) != expected:
        raise ValueError(f"Incomplete {label}")
    return result


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
        if kind not in ("dark", "light"):
            raise ValueError(f"Invalid theme: {theme_id}")
        palette = color_map(theme.get("palette"), set(PALETTE_KEYS), f"{theme_id} palette")
        syntax = color_map(theme.get("syntax"), set(SYNTAX_ROLES), f"{theme_id} syntax")
        raw_terminal = theme.get("terminal")
        if not isinstance(raw_terminal, dict):
            raise ValueError(f"Invalid terminal theme: {theme_id}")
        terminal = cast(dict[str, object], raw_terminal)
        base16 = color_map(terminal.get("base16"), BASE16_KEYS, f"{theme_id} base16")
        raw_ansi = terminal.get("ansi")
        if not isinstance(raw_ansi, list) or len(raw_ansi) != 16:
            raise ValueError(f"Invalid {theme_id} ansi")
        ansi_map = color_map({str(index): color for index, color in enumerate(cast(list[object], raw_ansi))},
                             {str(index) for index in range(16)}, f"{theme_id} ansi")
        ansi = [ansi_map[str(index)] for index in range(16)]
        settings = color_map(terminal.get("settings"), set(SETTING_KEYS), f"{theme_id} settings")
        return Theme(theme_id, cast(str, kind), palette,
                     syntax, TerminalScheme(base16, ansi, settings))
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


def ghostty_config(scheme: TerminalScheme, ansi: list[str]) -> str:
    settings = dict(scheme.settings)
    settings["minimum-contrast"] = "4.5"
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
        base = theme.terminal.base16
        background = theme.terminal.settings["background"]
        raw = theme.terminal.ansi
        ansi = [raw[0]] + [readable(color, background, theme.kind) for color in raw[1:]]
        ansi[8] = readable(blend(background, raw[8], 0.5), background, theme.kind)
        settings = dict(theme.terminal.settings)
        settings["minimum-contrast"] = "4.5"
        document = {"name": theme.name, "kind": theme.kind,
                    "palette": theme.palette, "base16": base, "ansi": ansi,
                    "syntax": theme.syntax, "settings": settings}
        write_changed(output / "terminal-palette.json", json.dumps(document, indent=2) + "\n")
        changed = write_changed(output / "ghostty.conf", ghostty_config(theme.terminal, ansi))
        if changed and arguments.reload_ghostty:
            reload_ghostty()
    except (OSError, UnicodeError, ValueError, KeyError) as error:
        print(f"Terminal theme: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
