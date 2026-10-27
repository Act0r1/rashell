#!/usr/bin/env python3

from __future__ import annotations

from collections.abc import Callable, Iterable, Mapping
import json
from pathlib import Path
import subprocess
import sys
from typing import TypedDict, cast


class Workspace(TypedDict):
    id: int


class Client(TypedDict):
    pid: int
    workspace: Workspace


class PwInfo(TypedDict, total=False):
    props: dict[str, str | int]


class PwObject(TypedDict, total=False):
    id: int
    type: str
    info: PwInfo | None


PID_KEYS = ("application.process.id", "pipewire.sec.pid")


def parent_pid(pid: int, proc: Path = Path("/proc")) -> int | None:
    """Read the parent pid from /proc/<pid>/stat; the comm field may contain spaces or parens."""
    try:
        stat = (proc / str(pid) / "stat").read_text()
    except OSError:
        return None
    fields = stat[stat.rfind(")") + 2:].split()
    return int(fields[1]) if len(fields) > 1 else None


def window_workspaces(clients: Iterable[Client]) -> dict[int, set[int]]:
    """Map each window-owning pid to the workspaces its windows are on."""
    result: dict[int, set[int]] = {}
    for client in clients:
        result.setdefault(int(client["pid"]), set()).add(int(client["workspace"]["id"]))
    return result


def stream_pids(objects: list[PwObject]) -> dict[int, int]:
    """Map each audio output stream node to its process id, falling back to its client's pid."""
    props = {obj.get("id", -1): (obj.get("info") or {}).get("props") or {} for obj in objects}
    result: dict[int, int] = {}
    for obj in objects:
        node_id = obj.get("id", -1)
        node = props[node_id]
        if not obj.get("type", "").endswith(":Node") or node.get("media.class") != "Stream/Output/Audio":
            continue
        client = props.get(int(node.get("client.id", -1)), {})
        for source, key in ((node, PID_KEYS[0]), (client, PID_KEYS[0]), (client, PID_KEYS[1])):
            if key in source:
                result[node_id] = int(source[key])
                break
    return result


def owner_workspaces(
    pid: int,
    windows: Mapping[int, set[int]],
    parent: Callable[[int], int | None] = parent_pid,
) -> list[int]:
    """Workspaces of the nearest ancestor (or self) of pid that owns a window."""
    seen: set[int] = set()
    current: int | None = pid
    while current is not None and current > 1 and current not in seen:
        if current in windows:
            return sorted(windows[current])
        seen.add(current)
        current = parent(current)
    return []


def run_json(command: list[str]) -> object:
    return json.loads(subprocess.run(command, check=True, capture_output=True, text=True).stdout)


def main() -> int:
    """Print {stream node id: [workspace ids]} for every audio output stream."""
    windows = window_workspaces(cast(list[Client], run_json(["hyprctl", "clients", "-j"])))
    streams = stream_pids(cast(list[PwObject], run_json(["pw-dump"])))
    print(json.dumps({node_id: owner_workspaces(pid, windows) for node_id, pid in streams.items()}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
