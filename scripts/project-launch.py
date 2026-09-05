#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import NoReturn
from urllib.parse import urlsplit


@dataclass(frozen=True)
class Project:
    name: str
    path: Path
    commands: tuple[tuple[str, ...], ...]
    url: str | None


def fail(message: str) -> NoReturn:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def required_string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"Invalid project {field}")
    return value


def parse_project(raw: str) -> Project:
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as error:
        fail(f"Invalid project data: {error.msg}")

    if not isinstance(value, dict):
        fail("Invalid project data")

    name = required_string(value.get("name"), "name")
    path = Path(required_string(value.get("path"), "path"))
    if not path.is_absolute():
        fail(f"Project path must be absolute: {path}")

    raw_commands = value.get("commands")
    if not isinstance(raw_commands, list):
        fail(f"Invalid commands for {name}")

    commands: list[tuple[str, ...]] = []
    for index, raw_command in enumerate(raw_commands, start=1):
        if not isinstance(raw_command, list) or not raw_command:
            fail(f"Command {index} for {name} must be a nonempty argv array")
        if not all(isinstance(argument, str) for argument in raw_command):
            fail(f"Command {index} for {name} contains a non-string argument")
        command = tuple(raw_command)
        if not command[0].strip():
            fail(f"Command {index} for {name} has an empty executable")
        commands.append(command)

    raw_url = value.get("url")
    url: str | None = None
    if raw_url is not None:
        if not isinstance(raw_url, str):
            fail(f"Invalid URL for {name}")
        parsed_url = urlsplit(raw_url)
        if parsed_url.scheme not in {"http", "https"} or not parsed_url.netloc:
            fail(f"Invalid URL for {name}")
        url = raw_url

    if not commands and url is None:
        fail(f"Project {name} has no command or URL")
    return Project(name=name, path=path, commands=tuple(commands), url=url)


def executable_exists(executable: str, cwd: Path) -> bool:
    if "/" not in executable:
        return shutil.which(executable) is not None
    candidate = Path(executable)
    if not candidate.is_absolute():
        candidate = cwd / candidate
    return candidate.is_file() and os.access(candidate, os.X_OK)


def main() -> None:
    if len(sys.argv) != 1:
        fail("Project data must be provided on standard input")

    project = parse_project(sys.stdin.readline())
    if not project.path.is_dir():
        fail(f"Project directory does not exist: {project.path}")

    launches = list(project.commands)
    if project.url is not None:
        launches.append(("xdg-open", project.url))

    for command in launches:
        if not executable_exists(command[0], project.path):
            fail(f"Executable not found: {command[0]}")

    for command in launches:
        try:
            subprocess.Popen(
                command,
                cwd=project.path,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        except OSError as error:
            fail(f"Could not start {command[0]}: {error}")

    print(json.dumps({"launched": project.name}))


if __name__ == "__main__":
    main()
