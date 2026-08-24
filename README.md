# Rashell

A personal Quickshell desktop shell inspired by ravens.

## Status

The current QML is a prototype. The implementation-ready direction is defined in [`docs/architecture/rashell-v1.md`](docs/architecture/rashell-v1.md).

The prototype demonstrates:

- Multi-monitor top bar
- Amber-on-black visual system
- Hyprland workspaces
- Clock and calendar
- PipeWire volume and direct output/input device selection
- Experimental manifest-based loading

The `plugins/` directory and user-plugin discovery are prototype experiments, not a supported extension API. The first coherent version uses first-party modules only.

## Run the prototype

```bash
quickshell -p /home/yeager/Personal/rashell
```

Rashell requires Quickshell 0.3.1 or newer, Hyprland, and PipeWire.
