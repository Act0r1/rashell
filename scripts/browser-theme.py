#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from typing import cast


CATALOG = Path(__file__).resolve().parent.parent / "core" / "themes.json"
BRAVE_POLICY_DIR = Path("/etc/brave/policies/managed")
COLOR_ROLES = {
    "frame": "background",
    "frame_inactive": "background",
    "toolbar": "surface",
    "toolbar_text": "text",
    "toolbar_button_icon": "textMuted",
    "tab_text": "text",
    "background_tab": "background",
    "background_tab_inactive": "background",
    "tab_background_text": "textMuted",
    "tab_background_text_inactive": "textMuted",
    "bookmark_text": "text",
    "omnibox_background": "surfaceRaised",
    "omnibox_text": "text",
    "ntp_background": "background",
    "ntp_text": "text",
    "ntp_link": "accent",
    "ntp_header": "borderControl",
    "button_background": "surfaceRaised",
}


def load_palette(theme_id: str) -> tuple[str, dict[str, str]]:
    catalog: object = json.loads(CATALOG.read_text(encoding="utf-8"))
    if not isinstance(catalog, list):
        raise ValueError("Invalid theme catalog")
    for entry in cast(list[object], catalog):
        if not isinstance(entry, dict) or entry.get("id") != theme_id:
            continue
        palette = entry.get("palette")
        name = entry.get("name")
        if not isinstance(palette, dict) or not isinstance(name, str):
            raise ValueError("Invalid theme")
        colors: dict[str, str] = {}
        for role in set(COLOR_ROLES.values()):
            color = palette.get(role)
            if not isinstance(color, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
                raise ValueError(f"Invalid {role} color")
            colors[role] = color.lower()
        return name, colors
    raise ValueError(f"Unknown theme: {theme_id}")


def manifest(theme_id: str) -> dict[str, object]:
    name, palette = load_palette(theme_id)
    colors = {
        target: [int(palette[role][index:index + 2], 16) for index in (1, 3, 5)]
        for target, role in COLOR_ROLES.items()
    }
    return {
        "manifest_version": 3,
        "version": "1.0.0",
        "name": f"Rashell — {name}",
        "description": f"{name} colors for the browser, matching Rashell.",
        "theme": {"colors": colors},
    }


def write_changed(target: Path, data: dict[str, object]) -> bool:
    content = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
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


def sync_brave(theme_id: str) -> None:
    _, palette = load_palette(theme_id)
    if not BRAVE_POLICY_DIR.is_dir():
        raise ValueError(f"Brave policy directory is unavailable: {BRAVE_POLICY_DIR}")
    legacy = BRAVE_POLICY_DIR / "ii-theme.json"
    target = legacy if legacy.exists() else BRAVE_POLICY_DIR / "rashell-theme.json"
    data: object = json.loads(target.read_text(encoding="utf-8")) if target.exists() else {}
    if not isinstance(data, dict):
        raise ValueError(f"Invalid Brave policy: {target}")
    policy = cast(dict[str, object], data)
    policy["BrowserThemeColor"] = palette["background"]
    write_changed(target, policy)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--theme", required=True)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--sync-brave", action="store_true")
    args = parser.parse_args()
    if args.output_dir is None and not args.sync_brave:
        parser.error("provide --output-dir or --sync-brave")
    try:
        if args.output_dir is not None:
            if not args.output_dir.is_absolute():
                raise ValueError("The output directory must be absolute")
            document = manifest(args.theme)
            args.output_dir.mkdir(parents=True, exist_ok=True)
            write_changed(args.output_dir / "manifest.json", document)
        if args.sync_brave:
            sync_brave(args.theme)
    except (OSError, UnicodeError, ValueError) as error:
        print(f"Browser theme: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
