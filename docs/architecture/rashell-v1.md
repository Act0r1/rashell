# Rashell first coherent version — architecture specification

**Status:** Planning-only for umbrella issue #1. This defines implementation targets; nothing is claimed complete.

## Product statement and boundary

Rashell is a small personal Quickshell/QML shell for one user on **Hyprland + PipeWire**. It provides a dependable multi-monitor top bar and compact task panels for frequent desktop orientation and audio control.

Rashell owns its surfaces, three built-in dark themes, panel lifecycle, validated shell composition, and narrow fixed IPC. Hyprland remains authoritative for workspace/window policy; PipeWire remains authoritative for audio devices and state.

It is not a distro, desktop environment, launcher, notification daemon, settings product, compositor abstraction, system theme manager, or extension platform.

## Canonical terminology

- **Core:** shell-owned composition, outputs, configuration, diagnostics, theme, overlays, fixed IPC methods, and `PanelCoordinator`.
- **Module:** a first-party desktop feature: `rashell.workspaces`, `rashell.clock`, or `rashell.audio`.
- **Panel:** an anchored interactive task surface supplied by a module and hosted by core.
- **Overlay:** non-interactive OSD or Rashell feedback surface; it does not occupy the panel slot.
- **Extension:** a possible future trusted-local third-party contribution.
- **Plugin:** legacy prototype wording only; not product terminology.

## Included workflows

1. **Orient and switch workspace**
   - Show the fixed workspace IDs `1…6`, occupied state, and the active workspace for each bar's mapped monitor.
   - Clicking a workspace requests activation using Hyprland's global semantics; an ID active elsewhere may focus its current monitor.
   - Render subsequent Hyprland state; do not predict success locally or move workspaces between monitors.

2. **Read time and inspect date**
   - A physically centered clock opens a calendar.
   - Calendar shows current month, today, and previous/next month navigation only.
   - No selectable dates, events, agenda, reminders, or settings.

3. **Control audio**
   - Show truthful output volume/mute state.
   - Audio panel controls output volume/mute/device selection and, when available, input volume/mute/device selection.
   - No per-application stream state, controls, placeholders, or reserved space.

## Surface model and `PanelCoordinator`

| Surface | Instances | Owner | Focus |
|---|---:|---|---|
| Three-zone bar | One per output | Core | No normal keyboard focus |
| Module bar views | One per configured bar slot | Module | No normal keyboard focus |
| Anchored panel | At most one globally | `PanelCoordinator` | Focus scope while open |
| Volume OSD | One presentation | Core | Click-through |
| Rashell feedback overlay | One presentation | Core | Click-through |

`PanelCoordinator` is the sole authority for panel state: active module/panel ID, anchor instance, target output, invocation source, and captured external focus.

Required behavior:

- Core owns one `PopupWindow` with `grabFocus: true`; modules supply content only.
- Closed trigger opens on its exact bar output and anchor.
- Same active trigger closes. Coordinator state clears one event-loop turn after compositor-driven outside dismissal so the opener click cannot immediately reopen it.
- A different trigger hides the old panel before showing the replacement; two panels are never visible simultaneously.
- The same module invoked from another output hides, changes anchor, and shows on the new output.
- Escape, close button, compositor-driven outside dismissal, anchor loss, output loss, or module failure closes.
- Escape/close/toggle restores the captured application when valid; outside dismissal never reclaims focus.
- Panel bounds clamp within its target output and never intentionally straddle outputs.
- OSD and feedback overlays may coexist with a panel.

Panels receive focus on open. Support `Tab`/`Shift+Tab`, arrows for lists/sliders, `Enter`/`Space`, and `Escape`. Do not add Vim aliases in this version.

## Multi-monitor rules

- Every connected output gets the identical configured three-zone composition.
- Center content remains at the physical output midpoint; side content compacts or elides before moving the clock.
- Workspace state is shared from Hyprland, but each bar highlights the workspace active on its mapped Hyprland monitor. Activation retains Hyprland's global behavior.
- Audio and clock state are shared globally; changes update all relevant bars.
- Bar-triggered panels and direct-adjustment overlays use the invoking output.
- Keyboard/IPC panel actions target the focused Hyprland output; if unavailable, use the mapped Hyprland monitor with the lowest monitor ID.
- No per-monitor configuration, remembered-output routing, or explicit output-name IPC arguments.
- Output removal destroys its bar and closes/hides transient surfaces on that output; surfaces never migrate.

## Core, modules, and state

Core creates state once at the shell root:

- `WorkspaceState`: Hyprland observation and workspace-focus requests.
- `ClockState`: current local time.
- `AudioState`: PipeWire observation and audio operations.
- `ConfigStore`, `IpcBridge`, `PanelCoordinator`, diagnostics, OSD, and feedback overlay.

Module bar views are presentations over shared state. They must not create their own PipeWire/Hyprland trackers or popup windows.

Modules own domain presentation and panel content; core owns window/surface policy. Core must not acquire audio policy, workspace policy, calendar behavior, notification-daemon ownership, or a generic extension framework.

## Module operations and fixed IPC

Pointer and keyboard controls call narrow first-party module methods directly. There is no generic action registry, discovery API, structured-result protocol, or compatibility promise.

One fixed `IpcHandler` target, `rashell`, exposes only:

```text
audioPanelToggle()
calendarPanelToggle()
panelClose()
outputVolumeAdjust(delta)
outputMuteToggle()
```

Rules:

- Device selection and absolute slider values are panel-internal module operations.
- Workspace bindings invoke Hyprland directly; Rashell installs no bindings and exposes no workspace IPC method.
- IPC success means validated arguments and current preconditions were accepted and the request was issued. UI changes only from subsequently observed Hyprland/PipeWire state.
- No arbitrary shell commands, QML evaluation, generic payload endpoint, output override, or destructive session action.
- Detectable panel failures remain inline. Detectable failures outside a panel use Rashell feedback for three seconds.
- Direct external/bar output-volume changes show the OSD only after the observed volume or mute state changes. Changes within the open audio panel do not show the OSD.

## Configuration

Configuration is one user-owned UTF-8 JSON file selected once at startup:

1. absolute `RASHELL_CONFIG`;
2. an existing `$XDG_CONFIG_HOME/rashell/config.json` (defaulting to `~/.config/rashell/config.json`);
3. checkout-local `config.json`.

A relative `RASHELL_CONFIG` is diagnosed and ignored. Once a path is selected, Rashell does not switch to a newly created higher-priority file until restart. An absolute selected path that is missing or invalid does not fall through; Rashell starts from compiled defaults and continues watching it.

Version 1 schema:

```json
{
  "version": 1,
  "theme": "ember",
  "bar": {
    "left": ["rashell.workspaces"],
    "center": ["rashell.clock"],
    "right": ["rashell.audio"]
  }
}
```

Validation and reload:

- Path selection happens only at startup.
- `version` must equal integer `1`.
- `theme` is required and must be `ember`, `raven`, or `jade`.
- All zones are required arrays of known first-party IDs.
- An ID may appear only once across all zones.
- Parse, schema, type, duplicate, and unknown-ID errors reject the complete candidate.
- Valid changes atomically replace the effective snapshot.
- Before the first valid load, an invalid or missing selected file uses compiled defaults while remaining watched.
- After a valid load, invalid, truncated, deleted, or unsupported hot reloads retain the in-memory last-known-good snapshot; no cache is persisted.
- Rashell never rewrites, repairs, merges, includes, migrates, or formats the file.
- There is no settings UI, module settings namespace, arbitrary color override, per-monitor override, or configuration executable content.

## Visual system summary

Use one fixed visual grammar with three built-in semantic dark palettes in `Theme.qml`: `ember` (amber, default), `raven` (periwinkle), and `jade` (green). All share:

- near-black background, normal, and raised surfaces;
- warm off-white primary text and readable muted text;
- amber for active/current/progress/focus, used sparingly;
- danger styling plus readable text for errors;
- monospace typography;
- 1 px borders, 2 px radii, dense but usable controls;
- 44 px bar, 12 px top gutter, 36 px horizontal gutter;
- 10 px trigger-to-panel gap; 12 px panel edge clamp;
- no blur, gradients, shadows, glass, spring motion, runtime themes, or palette generation;
- optional transition durations set to zero in the first coherent version.

Interaction state must distinguish hover, focus, selected/current, disabled, loading, and error. Important state always has a non-color cue: occupied workspaces include `+`, selected devices include `IN USE`, and mute/unavailable states include text. Selected-plus-focused controls retain both indicators.

Acceptance requires functional text contrast ≥4.5:1, focus and functional boundaries ≥3:1, hit regions ≥28×28 logical pixels, accessible names/roles/state/value for focusable controls, and keyboard/clipping checks at 1× and 2× scaling in an 800×600 logical viewport. Long device labels elide visually while retaining their full accessible name. Panels remain dismissible during loading, empty, unavailable, and error states.

With no output device, audio shows `No output devices` and close only—no percentage, slider, mute, or device rows. With no input device, the entire input section is omitted. Unavailable direct operations use feedback, never an OSD.

## Exact scope

### Included

- Multi-monitor three-zone bar.
- Output-local workspace highlighting and direct focus requests.
- Geometrically centered clock and month-reference calendar.
- Output and available-input audio controls.
- One global `PanelCoordinator`.
- Pointer and basic conventional keyboard support.
- Allowlisted actions/IPC for included work.
- Volume OSD and non-interactive Rashell feedback overlay for detectable failures only.
- Fixed semantic visual system with three config-selectable built-in themes.
- Validated JSON configuration with last-known-good hot reload.
- Honest loading, empty, disconnect, and module-error states.

### Deferred

- Per-application audio streams/mixing.
- Launcher, command palette, dashboard, or quick settings.
- Notification daemon/history/DND.
- Brightness, network, Bluetooth, battery, session, lock, power, or polkit UI.
- Settings UI, visual layout editing, migrations, config layers, and per-monitor layouts.
- Public extensions, discovery, user plugin directories, manifests, marketplace, installation, updates, or compatibility guarantees.
- Light mode, external/user-defined themes, arbitrary palette overrides, and whole-system theming.
- Cross-compositor support and Hyprland policy ownership.

## Recommended QML tree

```text
shell.qml
core/
  ConfigStore.qml
  BuiltinModuleRegistry.qml
  IpcBridge.qml
  PanelCoordinator.qml
  Diagnostics.qml
  Theme.qml
  ui/
    PanelFrame.qml
    FocusableControl.qml
    DeviceRow.qml
    LevelSlider.qml
bar/
  Bar.qml
  BarZone.qml
  ModuleSlot.qml
surfaces/
  AnchoredPanelHost.qml
  VolumeOsd.qml
  FeedbackOverlay.qml
modules/
  workspaces/
    WorkspaceState.qml
    WorkspaceBar.qml
  clock/
    ClockState.qml
    ClockBar.qml
    CalendarPanel.qml
  audio/
    AudioState.qml
    AudioBar.qml
    AudioPanel.qml
```

`BuiltinModuleRegistry.qml` is a static mapping of the three first-party IDs to bar and panel components. Do not scan filesystem manifests or user directories in this version.

## Data flow

```text
ConfigStore → validated effective config → Bar / ModuleSlot composition
Hyprland → WorkspaceState → WorkspaceBar
PipeWire → AudioState → AudioBar + AudioPanel
Clock timer/locale → ClockState → ClockBar + CalendarPanel

Bar/panel input → first-party module method → observed domain state
Fixed IPC method → validated panel/audio operation → observed state
Module panel request → PanelCoordinator → AnchoredPanelHost
Observed direct volume change → VolumeOsd
Detected panel error → inline error
Detected outside-panel action/config error → Diagnostics → FeedbackOverlay
Module load error → persistent slot placeholder + logging
```

Domain adapters update UI only from observed Hyprland/PipeWire state. UI requests are commands, not competing sources of truth.

## Implementation sequence

1. Establish `Theme.qml` tokens, the `ember`/`raven`/`jade` palettes, and reusable panel/control primitives.
2. Implement `ConfigStore` v1 validation, defaults, diagnostics, and last-known-good reload.
3. Replace dynamic plugin discovery with static built-in module resolution.
4. Build per-output `Bar` composition with independent physical center anchoring.
5. Move workspace observation/actions into one root `WorkspaceState`.
6. Move PipeWire observation/actions into one root `AudioState`.
7. Add `PanelCoordinator` and `AnchoredPanelHost`; remove module-owned popup lifecycle.
8. Implement calendar panel, then audio panel including honest device/error states.
9. Add fixed IPC methods, OSD, precise feedback behavior, and output-loss handling.
10. Verify configuration reload, panel replacement/dismissal, keyboard flow, and multi-monitor routing before expanding scope.

## Detailed local decisions

- [Product boundary](product-boundary.md)
- [Surface and navigation model](surface-navigation.md)
- [Configuration boundary](configuration.md)
- [Core/modules/extensions](core-modules-extensions.md)
- [Visual system](visual-system.md)
- [Consistency corrections](consistency-review.md)
- [Low-fidelity prototype validation](low-fidelity-prototype.md)
- [Implementation handoff](implementation-handoff.md)
- [Noctalia research](../research/noctalia-architecture-patterns.md)
- [Omarchy research](../research/omarchy-ui-patterns.md)

## Issue #1 closing summary

Rashell’s first coherent version is planned as a narrow, multi-monitor Hyprland/PipeWire control shell: three first-party modules, one globally coordinated anchored panel, shared root state, three built-in semantic dark themes, validated JSON composition, five fixed IPC methods, and proportional overlays. Stream mixing, public extensions, settings, notifications, launchers, and broader desktop ownership remain deferred.