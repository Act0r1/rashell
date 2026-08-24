# Rashell

A personal Quickshell desktop shell for Hyprland, built around the controls used on this machine.

## Current shell

- Full-width framed bar with workspaces, clock, MPRIS media, screenshot, keyboard layout, system tray, notifications, CPU, PipeWire volume, token usage, control center, and update status
- Searchable application launcher with clipboard history
- Notification daemon, popup, bounded history, and do-not-disturb mode
- PipeWire output/input controls with direct device selection and volume OSD
- Media panel with artwork, seek, and playback controls
- Control center with Wi-Fi, Bluetooth, wallpaper access, capture, audio, system status, lock, suspend, and confirmed power actions
- Wallpaper ownership, calendar, session controls, and Hyprland workspace switching
- Last-known-good JSON configuration reload
- Built-in `ember`, `raven`, and `jade` themes

The documents under [`docs/architecture`](docs/architecture/) describe the original minimal baseline. The current shell intentionally supersedes that boundary with a fixed set of first-party daily-use features.

## Screenshots

| Desktop | Launcher | Control center |
|---|---|---|
| ![Desktop](docs/screenshots/pass2/desktop.webp) | ![Launcher](docs/screenshots/pass2/launcher.webp) | ![Control center](docs/screenshots/pass2/control.webp) |

| Audio | Calendar |
|---|---|
| ![Audio](docs/screenshots/pass2/audio.webp) | ![Calendar](docs/screenshots/pass2/calendar.webp) |

## Run

```bash
quickshell -p /home/yeager/Personal/rashell
```

This machine currently uses the compatible user-local runtime:

```bash
~/.local/opt/rashell-runtime/quickshell -c rashell -d
```

Rashell requires Quickshell 0.3.1 or newer, Hyprland, PipeWire, NetworkManager, BlueZ, `jq`, `cliphist`, `grim`, and `wl-copy`. The token and update widgets use the existing local token-meter helper and `checkupdates`.

## Configuration

Edit `config.json` or provide an absolute path with `RASHELL_CONFIG`. Theme names are `ember`, `raven`, and `jade`.

## IPC

```bash
quickshell -c rashell ipc call rashell launcherToggle
quickshell -c rashell ipc call rashell controlCenterToggle
quickshell -c rashell ipc call rashell audioPanelToggle
quickshell -c rashell ipc call rashell calendarPanelToggle
```

## Test

```bash
python -m unittest discover -s tests -p 'test_*.py' -v
tests/smoke.sh
```

Noctalia-derived interaction patterns are acknowledged in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
