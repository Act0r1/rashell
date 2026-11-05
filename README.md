# Rashell

A personal Quickshell desktop shell for Hyprland, built around the controls used on this machine.

## Current shell

- Full-width framed bar with workspaces, current weather, clock, MPRIS media, screenshot, keyboard layout, system tray, Bluetooth, notifications, CPU, PipeWire volume, token usage, control center, and update status
- Searchable application launcher with clipboard history
- Notification daemon, popup, bounded history, and do-not-disturb mode
- PipeWire output/input controls with direct device selection and volume OSD
- Media panel with artwork, seek, and playback controls
- Control center with Wi-Fi, a Bluetooth device panel, wallpaper access, capture, audio, system status, lock, suspend, and confirmed power actions
- Wallpaper ownership, calendar, session controls, and Hyprland workspace switching
- Last-known-good JSON configuration reload
- Nine built-in dark themes: `raven`, `dusk`, `tokyonight`, `tokyostorm`, `ayu-dark`, `ayu-mirage`, `kanagawa-dragon`, `oxocarbon`, and `rose-pine`

Most documents under [`docs/architecture`](docs/architecture/) describe the original minimal baseline. The [visual system reference](docs/architecture/visual-system.md) documents the current tokens and primitives. The current shell extends the baseline with first-party daily-use features.

## Screenshots

| Desktop | Launcher | Control center |
|---|---|---|
| ![Desktop](docs/screenshots/pass2/desktop.webp) | ![Launcher](docs/screenshots/pass2/launcher.webp) | ![Control center](docs/screenshots/pass2/control.webp) |

| Audio | Calendar |
|---|---|
| ![Audio](docs/screenshots/pass2/audio.webp) | ![Calendar](docs/screenshots/pass2/calendar.webp) |

## Run and remove

```bash
just start       # link and start Rashell, replacing a running instance
just stop        # stop Rashell
just uninstall   # stop Rashell and remove the Quickshell symlink
just install     # recreate the safe Quickshell symlink
```

`just run` and `just remove` are equivalent convenience recipes. The recipes use the compatible user-local Quickshell runtime by default; override it with `RASHELL_QUICKSHELL` when needed.

Rashell requires Quickshell 0.3.1 or newer, Hyprland, PipeWire, NetworkManager, BlueZ, `curl`, `jq`, `cliphist`, `grim`, `slurp`, `satty`, `wf-recorder`, and `wl-copy`. System-audio recording also requires `pactl`. The weather widget refreshes Celsius conditions from wttr.in every 30 minutes. Click it to open the animated conditions panel and choose a city; leave the city empty for automatic IP-based location. The token widget uses the bundled `scripts/token-meter` helper; the update widget uses `checkupdates`.

## Configuration

Edit `config.json` or provide an absolute path with `RASHELL_CONFIG`. `ayu-dark` is the default theme.

```bash
just themes
just theme ayu-dark
just theme raven
just theme dusk
just theme tokyonight
just theme tokyostorm
just theme ayu-mirage
just theme kanagawa-dragon
just theme oxocarbon
just theme rose-pine
```

Theme changes hot-reload while Rashell is running. Set `captureDirectory` in `config.json` to choose where screenshots, edited screenshots, and videos are saved.

## IPC

```bash
quickshell -c rashell ipc call rashell launcherToggle
quickshell -c rashell ipc call rashell controlCenterToggle
quickshell -c rashell ipc call rashell bluetoothPanelToggle
quickshell -c rashell ipc call rashell audioPanelToggle
quickshell -c rashell ipc call rashell weatherPanelToggle
quickshell -c rashell ipc call rashell calendarPanelToggle
```

## Test

```bash
python -m unittest discover -s tests -p 'test_*.py' -v
tests/smoke.sh
```
