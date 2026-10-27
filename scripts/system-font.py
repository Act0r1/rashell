#!/usr/bin/env python3

from __future__ import annotations

import argparse
from collections.abc import Callable
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from xml.sax.saxutils import escape


GSETTINGS_KEYS = ("font-name", "document-font-name")
GTK_FILES = ("gtk-3.0/settings.ini", "gtk-4.0/settings.ini")
QT_FILES = ("qt5ct/qt5ct.conf", "qt6ct/qt6ct.conf")
KDE_KEYS = {
    "General": ("font", "menuFont", "toolBarFont", "smallestReadableFont"),
    "WM": ("activeFont",),
}
FONTCONFIG_FILE = "fontconfig/conf.d/50-rashell-font.conf"


def sized_family(spec: str, family: str) -> str:
    """Swap the family in a Pango spec like 'Roboto Flex 11', keeping the size."""
    match = re.fullmatch(r"(.+?)\s+(\d+(?:\.\d+)?)", spec.strip())
    return f"{family} {match.group(2)}" if match else family


def qfont_family(value: str, family: str) -> str:
    """Swap the family in a serialized QFont like '"Roboto Flex,11,-1,..."'."""
    quoted = value.startswith('"') and value.endswith('"')
    fields = (value[1:-1] if quoted else value).split(",", 1)
    serialized = family if len(fields) == 1 else f"{family},{fields[1]}"
    return f'"{serialized}"' if quoted else serialized


def replace_ini(text: str, keys: dict[str, tuple[str, ...]], transform: Callable[[str], str]) -> str:
    """Rewrite existing `key=value` lines in the given sections, leaving everything else intact."""
    section = ""
    lines: list[str] = []
    for line in text.splitlines(keepends=True):
        header = re.fullmatch(r"\[([^\]]+)\]\s*", line)
        if header:
            section = header.group(1)
        entry = re.fullmatch(r"([^=\s]+)=(.*?)(\r?\n?)", line)
        if entry and entry.group(1) in keys.get(section, ()):
            line = f"{entry.group(1)}={transform(entry.group(2))}{entry.group(3)}"
        lines.append(line)
    return "".join(lines)


def fontconfig_document(family: str, fallback: str | None) -> str:
    """Make the family the sans-serif default, optionally backed by a fallback for missing glyphs."""
    name = escape(family)
    rules = [
        "  <alias binding=\"strong\">\n"
        "    <family>sans-serif</family>\n"
        f"    <prefer><family>{name}</family></prefer>\n"
        "  </alias>\n"
    ]
    if fallback:
        rules.append(
            "  <alias binding=\"same\">\n"
            f"    <family>{name}</family>\n"
            f"    <accept><family>{escape(fallback)}</family></accept>\n"
            "  </alias>\n"
        )
    return (
        "<?xml version=\"1.0\"?>\n"
        "<!DOCTYPE fontconfig SYSTEM \"urn:fontconfig:fonts.dtd\">\n"
        "<!-- Managed by Rashell. Changes are overwritten when the font changes. -->\n"
        "<fontconfig>\n" + "".join(rules) + "</fontconfig>\n"
    )


def write_changed(target: Path, content: str) -> bool:
    if target.is_file() and target.read_text(encoding="utf-8") == content:
        return False
    mode = target.stat().st_mode & 0o777 if target.exists() else 0o644
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=target.parent,
                                         prefix=f".{target.name}.", delete=False) as stream:
            temporary = Path(stream.name)
            os.fchmod(stream.fileno(), mode)
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return True


def rewrite(target: Path, keys: dict[str, tuple[str, ...]], transform: Callable[[str], str]) -> None:
    if target.is_file():
        write_changed(target, replace_ini(target.read_text(encoding="utf-8"), keys, transform))


def sync_gsettings(family: str) -> None:
    if shutil.which("gsettings") is None:
        return
    for key in GSETTINGS_KEYS:
        current = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", key],
                                 check=True, capture_output=True, text=True).stdout.strip()
        spec = sized_family(current.strip("'"), family)
        if spec != current.strip("'"):
            subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", key, spec],
                           check=True, capture_output=True, text=True)


def sync(family: str, fallback: str | None, config_home: Path) -> None:
    sync_gsettings(family)
    for name in GTK_FILES:
        rewrite(config_home / name, {"Settings": ("gtk-font-name",)}, lambda spec: sized_family(spec, family))
    for name in QT_FILES:
        rewrite(config_home / name, {"Fonts": ("general",)}, lambda value: qfont_family(value, family))
    rewrite(config_home / "kdeglobals", KDE_KEYS, lambda value: qfont_family(value, family))
    target = config_home / FONTCONFIG_FILE
    target.parent.mkdir(parents=True, exist_ok=True)
    write_changed(target, fontconfig_document(family, fallback))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--family", required=True)
    parser.add_argument("--fallback")
    parser.add_argument("--config-home", type=Path, required=True)
    args = parser.parse_args()
    try:
        if not args.config_home.is_absolute():
            raise ValueError("The config home must be absolute")
        if not args.family.strip():
            raise ValueError("The font family is empty")
        sync(args.family.strip(), (args.fallback or "").strip() or None, args.config_home)
    except (OSError, UnicodeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"System font: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
