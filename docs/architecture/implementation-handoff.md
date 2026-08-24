# Issue #10 — First Coherent Version Implementation Handoff

**Status:** Implementation-ready specification  
**Implementation status:** Planning only; no implementation is claimed  
**Scope authority:** Resolved documents under `docs/research/` and `docs/architecture/`

Where documents differ:

- **first coherent version** is the only version term.
- `consistency-review.md` governs normalized vocabulary, interaction scope, monitor routing, keyboard scope, and deferred functionality.
- The later resolved `configuration.md` decision governs configuration selection and supersedes the consistency review’s earlier XDG-only recommendation.
- Audio streams, Vim keys, explicit monitor IPC arguments, public plugins/extensions, launcher infrastructure, and notification ownership remain excluded.

---

## 1. Version statement

Rashell’s **first coherent version** is one Quickshell process providing:

- one identical three-zone top bar per connected output;
- monitor-aware Hyprland workspace display with Hyprland-global activation semantics;
- one geometrically centered clock per bar;
- one pure month-reference calendar;
- shared PipeWire output/input state and controls;
- one global `PanelCoordinator`;
- pointer and conventional keyboard operation;
- a narrow internal action router and fixed IPC bridge;
- a volume OSD and Rashell-only feedback overlay;
- one validated, hot-reloaded JSON configuration with in-memory last-known-good retention;
- one fixed, accessible visual grammar with `ember`, `raven`, and `jade` built-in dark themes.

It is coherent when every included surface completes its task, all state has one authority, monitor behavior is deterministic, unavailable state is honest, and no deferred product is represented by placeholder UI or generalized infrastructure.

---

## 2. Fixed scope

### Included

#### Runtime and composition

- One long-running Quickshell/QML process.
- Dynamic creation and removal of one bar per connected output.
- Identical configured left, center, and right module composition on every output.
- Static first-party module catalog:
  - `rashell.workspaces`
  - `rashell.clock`
  - `rashell.audio`
- Root-owned shared domain state; bar instances are views only.
- Targeted runtime diagnostics and visible module-load placeholders.

#### Workspaces

- Code-owned first-version workspace IDs: `1` through `6`.
- The ID set is identical on every output and is not configurable in JSON.
- Hyprland remains authoritative for:
  - focused workspace per output;
  - occupied versus empty state;
  - whether a focus request succeeds.
- Primary click requests workspace activation using Hyprland's global semantics; an ID active elsewhere may focus its current monitor.
- Workspace bindings invoke Hyprland directly; Rashell exposes no workspace IPC method.
- No optimistic focus state: UI updates only from Hyprland’s reported state.

#### Clock and calendar

- Shared local clock state.
- Clock remains geometrically centered on each output.
- Minute-resolution time plus abbreviated weekday/date.
- Calendar panel containing:
  - current displayed month;
  - weekday headings;
  - today highlight;
  - previous month;
  - next month;
  - visible close control.
- Every fresh opening resets the calendar to the current month.
- Calendar days are non-selectable reference text.

#### Audio

- Shared PipeWire state, constructed once.
- Output:
  - current volume;
  - mute state;
  - slider adjustment;
  - direct incremental adjustment;
  - default output-device selection.
- Input, when available:
  - current volume;
  - mute state;
  - slider adjustment;
  - default input-device selection.
- Explicit states for:
  - initial loading;
  - ready;
  - ready with no output devices;
  - disconnected/reconnecting after previously becoming ready;
  - module error.
- Device disappearance and default-device changes update all bars and the open panel.
- Volume range: `0%` through `150%`.
- Keyboard, wheel, and direct action step: `5` percentage points.

#### Panels and focus

- One global `PanelCoordinator`.
- At most one calendar or audio panel active across the process.
- Bar invocation anchors to that exact trigger and output.
- Core owns one `PopupWindow` with `grabFocus: true`.
- Keyboard/IPC invocation uses:
  1. focused Hyprland output;
  2. otherwise the mapped Hyprland monitor with the lowest monitor ID.
- Same trigger toggles its panel closed; compositor-driven outside dismissal clears coordinator state one event-loop turn later so the opener click cannot immediately reopen it.
- Same module invoked from another output hides, updates its anchor, and shows there.
- Another module hides the old panel before showing the replacement; two panels are never visible simultaneously.
- Escape, close control, compositor-driven outside dismissal, anchor loss, output loss, or module failure closes the panel.
- Escape/close/toggle restores a valid captured application; outside dismissal never reclaims focus.

#### Feedback

- Bottom-centered volume OSD for direct output-volume or output-mute actions.
- Lower-right Rashell feedback overlay for detectable Rashell-originated failures.
- Both overlays are:
  - click-through;
  - non-interactive;
  - non-focus-stealing;
  - independent of the panel slot.
- Panel-originated failures remain inline; module-load failures use a persistent slot placeholder plus logging.
- Invalid configuration uses logging plus one three-second overlay when the error state changes.
- Generic success confirmations are absent.
- OSD appears only after an observed output-volume/mute change and expires approximately `1.2` seconds after the latest update.

#### Configuration

One strict JSON version-1 document configuring only bar composition:

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

Selection order, evaluated once at startup:

1. `RASHELL_CONFIG`, only when it is an absolute path;
2. `$XDG_CONFIG_HOME/rashell/config.json`, defaulting to `~/.config/rashell/config.json`, when it exists;
3. checkout-local `config.json`;
4. in-code defaults if no path is selected.

A relative `RASHELL_CONFIG` is diagnosed and ignored. An absolute selected path does not fall through merely because it is missing or invalid, and a newly created higher-priority path is not selected until restart.

Validation requires:

- top-level object;
- integer `version` equal to `1`;
- `theme` equal to `ember`, `raven`, or `jade`;
- exactly one `bar` object;
- required `left`, `center`, and `right` arrays;
- only the three known first-party IDs;
- string entries only;
- no ID repeated across zones;
- no unknown top-level or bar fields.

An included ID may be omitted to disable that module. A disabled module’s panel and domain actions are unavailable.

Startup behavior:

- no valid configuration loaded yet: use in-code defaults and report the error;
- missing or invalid selected file: use defaults, report the cause, and keep watching that selected path;
- valid file: atomically replace the effective snapshot.

Reload behavior after a valid snapshot exists:

- malformed, invalid, unsupported, truncated, or deleted file preserves the current in-memory last-known-good snapshot;
- no default reset;
- no partial application;
- targeted diagnostic and feedback;
- the next valid save atomically replaces the snapshot and clears the diagnostic.

Rashell never writes, repairs, reformats, merges, or migrates configuration.

---

## 3. Fixed non-scope

The **first coherent version** must not contain:

- per-application PipeWire stream discovery, controls, empty states, headings, placeholders, or reserved layout;
- public extensions, plugins, manifests, user-directory scanning, marketplace, installer, updater, SDK, compatibility promise, lifecycle API, or sandbox claim;
- launcher, command palette, global menu, dashboard, or quick-settings center;
- freedesktop notification daemon, notification history, DND, notification actions, or grouping;
- settings UI, visual bar editor, or app-managed configuration writes;
- Vim navigation aliases: `j`, `k`, `h`, or `l`;
- per-monitor configuration or explicit monitor-name IPC arguments;
- most-recently-used output tracking;
- external/user-defined themes, theme picker UI, light mode, generated palettes, arbitrary color overrides, or per-module styling;
- workspace naming policy, keybinding installation, window placement, or other Hyprland policy;
- brightness, network, Bluetooth, battery, session, lock, power, reminder, clipboard, capture, or application-management surfaces;
- multi-file config, includes, migrations, executable config, or persisted last-known-good cache;
- generalized action discovery, event bus, service locator, or future-surface framework;
- process-crash isolation claims for in-process QML.

The legacy `plugins/` name is prototype terminology only. Implementation must use **module** for first-party features.

---

## 4. Implementation architecture

### Ownership model

```text
ShellRoot
├── ConfigStore
├── Diagnostics
├── HyprlandAdapter
│   └── WorkspaceState
├── PipeWireAdapter
│   └── AudioState
├── ClockState
├── IpcBridge
├── PanelCoordinator
│   └── PanelHost
├── BarManager
│   └── BarWindow × connected outputs
│       └── first-party ModuleSlot views
├── VolumeOsd
└── FeedbackOverlay
```

### Architectural invariants

1. `shell.qml` is the only composition root.
2. Quickshell, Hyprland, and PipeWire adapters are created once.
3. No bar widget creates a PipeWire tracker, timer, panel window, IPC handler, or config watcher.
4. `PanelCoordinator` is the only authority for active panel state.
5. Module panel content never creates or owns `PopupWindow`.
6. OSD and feedback overlays never enter the panel slot.
7. `ModuleCatalog` is static and contains exactly three first-party IDs.
8. Module loading performs no filesystem scan and starts no shell process.
9. Hyprland and PipeWire reported state is authoritative; views do not invent successful state.
10. Configuration replacement is atomic.
11. The center bar zone is positioned from the output midpoint, not from remaining row width.
12. An existing transient surface never migrates after its output disappears.

### External adapters

#### `HyprlandAdapter`

Owns all direct interaction with Quickshell’s Hyprland service:

- output-to-Hyprland-monitor mapping;
- focused output resolution;
- workspace lookup;
- active workspace per output;
- occupied state;
- validated focus request;
- service availability.

`WorkspaceState` presents normalized state to views and retains no competing focus value.

#### `PipeWireAdapter`

Owns all direct interaction with `Quickshell.Services.Pipewire`:

- `Pipewire.ready`;
- nodes and one root-level `PwObjectTracker`;
- default output and input;
- preferred default selection;
- node labels;
- volume and mute mutations.

`AudioState` derives:

```text
loading       Pipewire has never reported ready
ready         Pipewire is ready and a usable output exists
no-output     Pipewire is ready but no usable output exists
disconnected  Pipewire was ready and is no longer ready
error         module/adapter failed
```

Streams are filtered out before state reaches any view.

---

## 5. Concrete target tree

```text
rashell/
├── shell.qml
├── config.json
│
├── core/
│   ├── qmldir
│   ├── Theme.qml
│   ├── ConfigStore.qml
│   ├── Diagnostics.qml
│   ├── ModuleCatalog.qml
│   └── IpcBridge.qml
│
├── core/panels/
│   ├── qmldir
│   ├── PanelCoordinator.qml
│   ├── PanelHost.qml
│   └── PanelFrame.qml
│
├── integrations/
│   ├── qmldir
│   ├── HyprlandAdapter.qml
│   └── PipeWireAdapter.qml
│
├── bar/
│   ├── qmldir
│   ├── BarManager.qml
│   ├── BarWindow.qml
│   └── ModuleSlot.qml
│
├── modules/workspaces/
│   ├── qmldir
│   ├── WorkspaceState.qml
│   └── WorkspaceBar.qml
│
├── modules/clock/
│   ├── qmldir
│   ├── ClockState.qml
│   ├── CalendarModel.qml
│   ├── ClockBar.qml
│   └── CalendarPanel.qml
│
├── modules/audio/
│   ├── qmldir
│   ├── AudioState.qml
│   ├── AudioBar.qml
│   ├── AudioPanel.qml
│   ├── VolumeControl.qml
│   └── DeviceList.qml
│
├── ui/
│   ├── qmldir
│   ├── FocusFrame.qml
│   ├── ActionButton.qml
│   ├── CompactButton.qml
│   ├── LevelSlider.qml
│   ├── StatusPlaceholder.qml
│   └── ErrorMessage.qml
│
├── overlays/
│   ├── qmldir
│   ├── VolumeOsd.qml
│   └── FeedbackOverlay.qml
│
└── tests/
    ├── unit/
    │   ├── tst_ConfigStore.qml
    │   ├── tst_WorkspaceState.qml
    │   ├── tst_CalendarModel.qml
    │   ├── tst_AudioState.qml
    │   ├── tst_IpcBridge.qml
    │   └── tst_PanelCoordinator.qml
    ├── fixtures/
    │   ├── FakeHyprlandAdapter.qml
    │   ├── FakePipeWireAdapter.qml
    │   └── FakeOutput.qml
    └── manual/
        └── acceptance.md
```

### Prototype disposition

The target implementation removes or replaces:

- `core/PluginRegistry.qml`;
- `bar/PluginSlot.qml`;
- `plugins/*/manifest.json`;
- runtime Bash scanning;
- automatic `~/.config/rashell/plugins` creation;
- module-owned `PopupWindow`;
- per-widget clock timers;
- per-widget PipeWire tracking;
- the `APPLICATION STREAMS` prototype section.

The module source may be moved from `plugins/` incrementally, but the completed version must have no runtime dependency on the legacy plugin system.

---

## 6. Module operations and fixed IPC

Pointer and keyboard controls call narrow first-party module methods directly. There is no `ActionRouter`, generic action registry, discovery API, structured result protocol, or compatibility promise.

One `IpcHandler` target, `rashell`, exposes only:

```text
audioPanelToggle()
calendarPanelToggle()
panelClose()
outputVolumeAdjust(real delta)
outputMuteToggle()
```

Rules:

- Device selection and absolute slider values are panel-internal module operations.
- Workspace bindings invoke Hyprland directly. Rashell installs no bindings and exposes no workspace IPC method.
- No generic payload endpoint, arbitrary command execution, output-name parameter, or destructive session action.
- IPC panel and direct audio actions resolve the focused Hyprland output, otherwise the mapped Hyprland monitor with the lowest monitor ID.
- IPC success means arguments and current preconditions were accepted and the request was issued; UI updates only from subsequently observed state.
- Detectable failures include invalid arguments, unavailable integration/node, rejected config, IPC errors, and module-loader errors. Do not promise mutation-failure reporting unavailable from Quickshell APIs.
- Volume clamps to `0.0…1.5`; direct increments use `0.05`.

---

## 7. Ordered vertical slices

## Slice 1 — Valid runtime, configuration, and one bar per output

### Deliverables

- `ShellRoot`, `ConfigStore`, `Diagnostics`, `Theme` with three built-in palettes, static `ModuleCatalog`.
- Config path selection, complete validation, defaults, watch, and last-known-good behavior.
- `BarManager` and `BarWindow`.
- Physical center anchoring independent from side-zone widths.
- Static module slots with loading/error placeholders.
- Removal of runtime plugin scanning.

### Slice acceptance

- Starting with no user config renders the default three-zone composition.
- A valid XDG or absolute `RASHELL_CONFIG` file is selected according to precedence.
- An invalid startup file renders defaults and reports the cause.
- A valid reload changes all bars and the selected built-in theme atomically.
- An invalid reload leaves all bars unchanged.
- Connecting a second output creates exactly one additional bar.
- Unequal side widths do not move the center zone.
- No Bash process runs and no plugin directory is created.

---

## Slice 2 — Multi-monitor workspace workflow

### Deliverables

- `HyprlandAdapter`, `WorkspaceState`, `WorkspaceBar`.
- Shared workspace truth with output-local focus calculation.
- Focus action and feedback for known failures.
- Loading, unavailable, occupied, empty, focused, and module-error views.

### Slice acceptance

- Every bar shows IDs `1…6` in the same order.
- Output A and output B may highlight different active IDs simultaneously.
- Occupied state is consistent across bars.
- Clicking workspace `N` sends one validated Hyprland request.
- The UI changes focus only after Hyprland reports it.
- Hyprland unavailability disables controls and shows `WORKSPACES UNAVAILABLE`.
- The view changes only after Hyprland reports new state; Rashell does not claim to observe dispatcher success or failure.

---

## Slice 3 — PanelCoordinator proven by calendar

### Deliverables

- `PanelCoordinator`, `PanelHost`, `PanelFrame`.
- Shared focus, close, outside-interaction, anchor, replacement, and output-loss policy.
- `ClockState`, `CalendarModel`, `ClockBar`, `CalendarPanel`.
- Pointer and basic keyboard calendar navigation.

### Slice acceptance

- Clicking a clock opens one calendar beneath that clock on the same output.
- Clicking the same clock closes it.
- Clicking a clock on another output hides the panel, changes anchor, and shows it there rather than toggling closed.
- A keyboard/IPC invocation targets the focused output or the mapped Hyprland monitor with the lowest monitor ID.
- Every fresh opening displays the current month.
- Previous and next modify only the displayed month.
- Today has both amber styling and a non-color cue.
- Calendar days have no hover, press, selection, or activation behavior.
- Escape, outside interaction, and the close control dismiss the panel.
- Removing the target output closes the panel without migration.

---

## Slice 4 — Shared audio state and honest bar status

### Deliverables

- `PipeWireAdapter`, one root-level `PwObjectTracker`, `AudioState`, `AudioBar`.
- Stream filtering.
- Loading, ready, no-output, disconnected, and error states.
- Shared updates across all bar instances.
- Wheel-based output-volume adjustment through the audio module.

### Slice acceptance

- Every audio bar displays the same reported output volume and mute state.
- `Pipewire.ready === false` before first readiness shows `AUDIO ...`.
- Ready with no output shows `AUDIO UNAVAILABLE`, never `VOL 0%`.
- Loss of readiness after successful connection shows disconnected/reconnecting state.
- Muted state includes `MUTE`; color alone is insufficient.
- External PipeWire changes update every bar.
- Scrolling adjusts by five percentage points and clamps to `0…150%`.
- No stream node enters the module state or UI.

---

## Slice 5 — Complete audio panel

### Deliverables

- `AudioPanel`, `VolumeControl`, `DeviceList`.
- Output slider, mute, current-device marker, and output selection.
- Input controls only when input devices exist.
- Inline action errors.
- Stable controls during loading/disconnection.
- Device disappearance and focus repair.

### Slice acceptance

- Audio opens through `PanelCoordinator`, not a module-owned window.
- Opening audio hides calendar before showing audio; both are never visible simultaneously.
- The output slider, mute, and device list call shared audio-module operations.
- The selected device shows both selection styling and `IN USE`.
- Input section is absent when no input devices exist.
- One input or output remains explicitly marked `IN USE`.
- Disconnecting the selected device removes its row immediately.
- If another default is reported, that row becomes selected.
- If no output remains, show `No output devices` and close only; percentage, slider, mute, and device rows are absent.
- If PipeWire disconnects while open, panel chrome and close remain usable.
- Failed panel operations show inline errors and leave the panel open.
- No application-stream heading, state, control, or blank reserved area exists.

---

## Slice 6 — Keyboard, fixed IPC, OSD, and feedback

### Deliverables

- First-party module operations shared by pointer and keyboard controls.
- Fixed five-method `IpcBridge`.
- Panel keyboard focus order.
- Volume OSD.
- Rashell feedback overlay.
- Focus restoration by close reason.

### Slice acceptance

- The normal bar does not take keyboard focus.
- Opening a panel establishes one keyboard focus scope.
- `Tab`/`Shift+Tab` follow visual order.
- Arrow keys operate sliders and device lists.
- `Enter`/`Space` activate buttons and selected device rows.
- Escape closes from every panel state.
- No Vim aliases are installed.
- IPC toggles/closes panels and performs output-volume/output-mute actions; workspace bindings target Hyprland directly.
- Direct bar-wheel and IPC output-volume actions show the OSD on the resolved origin output.
- Changes inside the open audio panel do not show the OSD.
- OSD updates in place and expires about `1.2` seconds after the latest action.
- Invalid or unavailable direct actions show feedback instead of a false meter.
- Panel errors remain inline.
- Outside focus closes without stealing focus back.
- Escape, close control, and trigger toggle restore the previously focused valid application.
- Panel replacement hides the old panel before showing the new one; both are never visible simultaneously.

---

## Slice 7 — Visual, accessibility, and failure hardening

### Deliverables

- Final semantic tokens and reusable control states.
- Accessible names, roles, values, and state text.
- Scaling and constrained-output adaptation.
- Module/configuration failure placeholders and diagnostics.
- Completed automated and manual acceptance suite.

### Slice acceptance

- No included component uses private raw palette colors.
- Focus, hover, pressed, active, selected, disabled, loading, and error remain distinguishable.
- Text and controls meet contrast requirements.
- Controls remain usable at compositor scaling.
- Long device labels elide visually but expose complete accessible names.
- Panels scroll or adapt rather than clipping.
- Optional transition durations are zero in the first coherent version.
- A module loader failure preserves its labelled slot and leaves unrelated modules usable.
- OSD or feedback failure never blocks the underlying action.
- No deferred surface or placeholder appears.

---

## 8. Exact acceptance checks

### Runtime

- [ ] One Rashell process owns all bars, panels, adapters, IPC, and overlays.
- [ ] Startup produces no repeated service trackers or timers per output.
- [ ] First-party module IDs resolve statically.
- [ ] No plugin manifest, directory scan, `mkdir`, Bash process, or user plugin path is used.
- [ ] A configured module load failure produces a compact labelled error placeholder.
- [ ] Unrelated bars and modules remain usable after a contained loader/configuration error.
- [ ] No process-crash isolation claim is made.

### Multi-monitor bar

- [ ] Connected output count equals bar-window count.
- [ ] Every bar uses the same effective config snapshot and module order.
- [ ] Bar height is `44 px`.
- [ ] Bar top gutter is `12 px`; horizontal margins are `36 px`.
- [ ] Center content’s midpoint equals the output midpoint within one physical pixel after scaling.
- [ ] Side-zone growth compacts or elides before moving the clock.
- [ ] Disconnecting an output destroys only its bar and affected overlays/panel.

### Workspaces

- [ ] IDs `1…6` appear on every default bar.
- [ ] Focus is calculated per output.
- [ ] Occupied workspaces include a non-color marker such as `+`; empty and focused remain distinct.
- [ ] Hover never masquerades as focus.
- [ ] Click requests Hyprland-global activation; workspace IPC is absent.
- [ ] Unknown fixed IDs and unavailable Hyprland perform no dispatch.
- [ ] State changes only from Hyprland’s reported update.

### PanelCoordinator

- [ ] `activePanelId`, output, and anchor have one global owner.
- [ ] Zero or one anchored panel is visible.
- [ ] Same exact trigger toggles closed.
- [ ] Same module on another output hides, changes anchor, and shows there.
- [ ] Different panel hides the old one before showing the replacement; never two visible.
- [ ] Panel never intentionally straddles outputs and remains at least `12 px` inside target bounds.
- [ ] Anchor or target-output loss closes rather than migrates.
- [ ] `grabFocus: true` compositor dismissal cannot immediately close-and-reopen from one trigger click.
- [ ] One application click dismisses without Rashell reclaiming focus.
- [ ] Escape/close/toggle restore a captured valid application.
- [ ] Every close path clears coordinator state according to its reason.

### Calendar

- [ ] Preferred size is `360 × 390 px`, clamped or adapted as necessary.
- [ ] Fresh opening resets to the current month.
- [ ] Previous/next month changes keep the panel open.
- [ ] Today is highlighted only when present in the displayed month.
- [ ] Dates are not focusable or selectable.
- [ ] No agenda, event, reminder, scheduling, or status-detail UI exists.

### Audio

- [ ] Preferred width is `460 px`, with content-driven height.
- [ ] Output range is `0…150%`; direct step is `5%`.
- [ ] Output volume, mute, and selected device reflect PipeWire truth.
- [ ] Input controls appear only when input devices exist.
- [ ] Streams are excluded by `isStream` before rendering.
- [ ] Loading is distinct from ready-with-no-output.
- [ ] Disconnected/reconnecting is distinct from valid zero volume.
- [ ] Device disappearance removes stale rows and repairs focus.
- [ ] No output shows `No output devices` plus close only; no percentage, slider, mute, or device rows.
- [ ] No input omits the entire input section.
- [ ] Unavailable requests do not show an OSD or optimistic successful state.
- [ ] No per-application stream code or UI exists.

### Mouse and basic keyboard

- [ ] All primary operations have visible pointer controls.
- [ ] Panel controls have at least `28 × 28 px` hit areas.
- [ ] Selectable rows are `40 px` high.
- [ ] Tab order follows visual order.
- [ ] Arrow keys operate lists and sliders.
- [ ] Enter and Space activate.
- [ ] Escape always dismisses, including loading, empty, disconnected, and error states.
- [ ] Hover-only actions and Vim aliases are absent.

### OSD and feedback

- [ ] OSD is bottom-centered about `48 px` above the usable bottom edge.
- [ ] OSD is shown only after an observed state change caused by a direct Rashell output-volume/mute request.
- [ ] External PipeWire changes alone do not summon it.
- [ ] Panel-originated volume changes do not summon it.
- [ ] Detectable outside-panel failures show lower-right feedback for three seconds and stack above a colliding OSD with a `12 px` gap.
- [ ] Invalid config shows one overlay when its error state changes; module-load errors use slot placeholder plus logging.
- [ ] Generic success confirmations are absent.
- [ ] Both overlays are click-through and non-focus-stealing.
- [ ] Output removal hides affected overlays without migration.
- [ ] There is no notification history, action, grouping, or DND behavior.

### Configuration

- [ ] Selection precedence matches the fixed startup rule and does not switch paths during the process lifetime.
- [ ] Relative `RASHELL_CONFIG` is ignored with a targeted warning; an absolute missing/invalid path does not fall through.
- [ ] Version, complete schema, allowed IDs, and duplicate placement are validated before commit.
- [ ] Invalid startup uses defaults.
- [ ] Invalid reload preserves the in-memory last-known-good snapshot.
- [ ] A later valid reload clears the error and replaces all bars atomically.
- [ ] Rashell never writes the selected file.
- [ ] No per-monitor, arbitrary-color, workspace, audio, or calendar configuration fields exist.

### Visual and accessibility

Required fixed values:

- [ ] `ember`, `raven`, and `jade` each provide complete near-black semantic palettes.
- [ ] `ember` uses amber `accent: #ffbf18` and is the default.
- [ ] Warm text and explicit `danger: #e35b45`.
- [ ] Monospace-only typography.
- [ ] `1 px` normal border and `2 px` radius.
- [ ] `2 px` keyboard-focus indicator.
- [ ] No shadow, blur, gradient, glass, pill, or spring animation.
- [ ] Normal and secondary functional text target at least `4.5:1` contrast.
- [ ] Functional boundaries and focus indicators target at least `3:1`.
- [ ] Selection, occupancy, mute, unavailable, focus, and error all include non-color cues.
- [ ] Focus is distinct from hover and selection; a selected-plus-focused control visibly retains both states.
- [ ] Disabled controls do not react.
- [ ] Symbolic controls expose accessible names, roles, state, and values.
- [ ] Long labels elide visually while retaining complete accessible text.
- [ ] Panels pass keyboard and clipping checks at 1× and 2× scaling in an 800×600 logical viewport.
- [ ] Optional transition durations are zero.

---

## 9. Test strategy

### Automated tests

Use Qt Quick Test with fake adapters. Keep tests at state and coordination boundaries rather than testing incidental QML layout structure.

#### `tst_ConfigStore.qml`

- path precedence;
- absolute-path requirement;
- valid version-1 normalization and built-in theme selection;
- unknown theme and duplicate/unknown module ID rejection;
- startup defaults;
- valid reload;
- invalid reload retention;
- recovery after a later valid save.

#### `tst_WorkspaceState.qml`

- output-local focused workspace;
- occupied and empty derivation;
- unavailable state;
- fixed IDs `1…6` and Hyprland-global activation semantics;
- no optimistic focus update.

#### `tst_CalendarModel.qml`

- leap years;
- month boundaries;
- Monday-first offset;
- today detection;
- previous/next year crossing;
- reset-to-current-month on open.

#### `tst_AudioState.qml`

- initial loading;
- ready;
- no output;
- disconnect after readiness;
- stream filtering;
- output/input filtering;
- clamp and five-point adjustment;
- mute;
- current-node validation;
- device removal and default replacement.

#### `tst_IpcBridge.qml`

- exactly five fixed IPC methods;
- parameter validation;
- disabled modules;
- unavailable audio service;
- no generic payload or workspace/device-selection IPC;
- no unrelated state mutation;
- OSD only after an observed direct output-volume/mute change.

#### `tst_PanelCoordinator.qml`

- open;
- same-trigger toggle;
- cross-output hide/re-anchor/show;
- old panel hidden before replacement, never two visible;
- same-trigger opener transaction;
- Escape/close/compositor-outside reasons;
- anchor and output loss;
- keyboard/IPC output fallback;
- focus-restoration decisions.

### Manual integration tests

Run against real Quickshell, Hyprland, and PipeWire:

1. Start with one output, then connect and disconnect a second output.
2. Verify separate active workspace highlights on both outputs.
3. Compare the clock midpoint under deliberately unequal side-zone widths.
4. Open calendar and audio from each output.
5. Replace one panel with the other and inspect focus behavior.
6. Remove the output owning an open panel.
7. Restart PipeWire while audio is closed and while it is open.
8. Disconnect the selected output and input devices.
9. Exercise mouse, Tab, Shift+Tab, arrows, Enter, Space, and Escape.
10. Invoke every fixed IPC method with valid and invalid arguments.
11. Corrupt, truncate, delete, and restore configuration while running.
12. Test at common compositor scale factors and on a short-height output.
13. Inspect accessibility names and keyboard-focus visibility.
14. Verify no per-stream, plugin, launcher, notification, settings, Vim, or per-monitor-config behavior appears.

A release candidate passes all automated tests and the complete manual checklist on at least one two-output Hyprland session.

---

## 10. Definition of done

The **first coherent version** is done only when:

- every ordered slice is complete;
- all exact acceptance checks pass;
- the default configuration presents workspace, clock/calendar, and audio on every output;
- one shared model exists for each external domain;
- `PanelCoordinator` exclusively owns calendar/audio panel lifecycle;
- all panel states remain dismissible;
- audio loading, no-device, disconnect, stale-device, and failure states are honest;
- pointer and basic keyboard controls share module operations, while fixed IPC routes only the documented panel/output-audio methods;
- observed direct output-volume/mute changes produce OSD, while unavailable requests produce failure feedback;
- invalid hot reload demonstrably preserves the last-known-good snapshot;
- visual and accessibility checks pass;
- automated tests pass;
- the two-output manual acceptance run passes;
- no runtime path references the prototype plugin registry or user plugin directory;
- no deferred functionality, placeholder, compatibility promise, or generalized framework is shipped;
- documentation describes only behavior that is actually present.

---

## 11. Risks

| Risk | Boundary and mitigation |
|---|---|
| `PopupWindow.grabFocus` dismissal and opener-click ordering vary by compositor timing | Prove the one-turn coordinator-clear transaction with calendar before audio; test same-trigger, replacement, application click, and Escape on Hyprland. |
| Popup geometry under mixed scaling may drift or straddle outputs | Resolve geometry in output-local coordinates; clamp to target bounds; manually test mixed scaling. |
| Hyprland screen objects may not map directly to Quickshell screens | Keep mapping inside `HyprlandAdapter`; test output add/remove and invalid focused output. |
| PipeWire node IDs and objects may disappear during interaction | Validate against the current node set at execution time; never retain selectable stale rows. |
| PipeWire readiness may transiently change during startup | Track whether readiness has ever occurred so loading and reconnection remain distinct. |
| QML property writes may not provide rich operation errors | Present only reported state, detect known unavailable/stale cases synchronously, and avoid claiming success before observation. |
| Dynamic module loading can still trigger broader in-process QML failures | Contain loader errors where possible, but make no crash-isolation or sandbox promise. |
| Config watching may observe partially written files | Validate complete text before replacement and retain the current snapshot on every invalid reload. |
| Focus repair after device removal can become inconsistent | Define nearest surviving control fallback and test it with fake node removal. |
| Accessibility may regress through private component styling | Require shared primitives and semantic tokens; reject raw component colors in review. |
| IPC could grow into an unsafe generic command framework | Keep one fixed handler with six methods, typed arguments, no arbitrary payload, and no destructive actions. |
| Legacy prototype files may imply plugin or stream support | Remove runtime references and user-facing terminology before declaring completion. |

---

## Concise closing comment

> Issue #10 is ready for implementation as Rashell’s **first coherent version**: one identical three-zone bar per output, output-local workspaces, centered clock/calendar, shared output/input audio, one global `PanelCoordinator`, conventional pointer/keyboard operation, fixed IPC actions, volume OSD and Rashell feedback, atomic last-known-good config reload, and the canonical accessible amber-on-black visual system. The handoff fixes architecture, slices, observable acceptance checks, tests, done criteria, and risks while excluding streams, plugins/extensions, launcher, notification ownership, settings UI, Vim keys, and per-monitor configuration. No files or GitHub state were changed.