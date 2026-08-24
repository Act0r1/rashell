# Rashell

A personal Quickshell desktop shell inspired by ravens.

## First milestone

- Multi-monitor top bar
- Amber-on-black visual system
- Manifest-based built-in and user plugins
- Hyprland workspaces
- Clock and calendar
- PipeWire volume and direct output/input device selection

## Run

```bash
quickshell -p /home/yeager/Personal/rashell
```

Rashell requires Quickshell 0.3.1 or newer, Hyprland, and PipeWire.

## Plugins

Built-in plugins live in `plugins/`. User plugins live in `~/.config/rashell/plugins/<plugin-id>/`. Both use the same manifest:

```json
{
  "schemaVersion": 1,
  "id": "example.plugin",
  "name": "Example",
  "version": "0.1.0",
  "kinds": ["bar-widget"],
  "entryPoints": {
    "barWidget": "BarWidget.qml"
  }
}
```

Add the plugin ID to a section in `config.json`, then restart Rashell. Plugins are trusted QML and run with the current user's permissions.
