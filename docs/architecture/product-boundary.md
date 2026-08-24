# Decision: Rashell’s product boundary and first coherent desktop workflows

## Decision

Rashell is a small, personal desktop shell for one Linux user running **Hyprland, PipeWire, and Quickshell/QML**. It makes the desktop’s immediate state visible and turns a narrow set of frequent system tasks into quick, coherent interactions.

It is not a distribution, desktop environment, provisioning tool, or general shell framework.

The first coherent version is a reliable multi-monitor top bar with workspace orientation, time and calendar reference, and a fully usable audio control workflow. It uses one visual and interaction grammar across persistent bar widgets, anchored task panels, action routing, and lightweight feedback.

## Target user

Rashell is for its owner: a technically capable Linux user who:

- already chooses and maintains Hyprland, PipeWire, applications, and dotfiles;
- prefers keyboard-first interaction but expects pointer interaction to be equally complete;
- wants a calm, legible desktop control layer rather than a configurable desktop environment;
- accepts local JSON configuration and trusted QML customization;
- values a small, dependable daily shell more than feature breadth or ecosystem compatibility.

It is **not** intended for users seeking a turnkey distro, GUI-first desktop administration, cross-compositor support, or installable third-party shell ecosystem.

## The user’s daily jobs

Rashell helps the user:

1. **Orient on the desktop** — see the active and occupied workspaces, current time, and relevant system state at a glance.
2. **Move deliberately between workspaces** — inspect workspace state and select a workspace without memorizing every compositor command.
3. **Check time and date** — read the time instantly and open a compact calendar when needed.
4. **Control audio without leaving the current task** — see volume and mute state, adjust volume, mute or unmute, and select the active output or input device.
5. **Understand what is unavailable** — distinguish no device, disconnected device, and unavailable integration without misleading controls or invented state.

## Product responsibilities

Rashell owns:

- Its own Quickshell/QML runtime, visual language, bar composition, task panels, OSD, and action routing.
- A persistent bar on every active monitor, with stable left, center, and right zones and a geometrically centered clock.
- Readable presentation of Hyprland workspace state and direct user-initiated workspace selection.
- Readable presentation and direct control of PipeWire audio state:
  - master output volume;
  - mute state;
  - output-device selection;
  - input volume and input-device selection when available.
- Compact, anchored panels that perform their task in place.
- One consistent interaction model: visible pointer controls, keyboard-accessible panel controls, Escape dismissal, and one active transient task panel at a time.
- Semantic theme tokens, consistent component states, and three built-in dark palettes (`ember`, `raven`, `jade`) for Rashell-owned surfaces.
- Local, validated configuration with a last-known-good fallback.
- Clear, proportional feedback: an OSD for continuous adjustments such as volume, and short confirmation or error feedback where it adds clarity.

## Non-responsibilities

Rashell explicitly does **not** own:

- Linux distribution lifecycle: installation, packages, updates, repositories, services, firmware, users, security policy, or release channels.
- Application provisioning, default application selection, launchers, clipboard history, capture pipelines, reminders, or a bundled utility suite.
- Hyprland policy: keybindings, workspace naming/numbering policy, window placement, tiling layouts, rules, groups, scratchpads, gestures, or monitor policy. Hyprland remains authoritative for those choices.
- PipeWire session-policy configuration or device-driver management.
- Freedesktop notification-daemon ownership, notification history, do-not-disturb policy, lock screen, session/logout UI, or polkit.
- System-wide theme generation or modification of other applications, Hyprland, terminals, boot UI, or dotfiles.
- A marketplace, remote plugin installation, plugin lifecycle manager, compatibility promise, or arbitrary bar replacement.
- Cross-compositor or cross-platform abstraction.

Rashell may expose shell action IDs for external bindings or commands, but it does not install or prescribe the corresponding Hyprland bindings.

## Primary workflows for the first coherent version

### 1. Orient and switch workspace

1. Rashell starts and presents the same three-zone bar on each active monitor.
2. The user sees workspace identity, focused state, and occupied versus empty state.
3. The user selects a visible workspace.
4. Rashell requests that Hyprland focus it.
5. The bar updates from Hyprland’s reported state.

The workflow is complete when Rashell reflects compositor state rather than maintaining a competing workspace model.

### 2. Check time and date

1. The user reads the centered clock without opening anything.
2. The user opens the clock task panel by pointer or its corresponding shell action.
3. Rashell shows the current month, identifies today, and permits month navigation.
4. The user dismisses the panel with Escape, its close affordance, a repeat invocation, or by opening another task panel.

The calendar is a compact reference surface, not an agenda, reminder, event, or scheduling product.

### 3. Adjust and route audio

1. The user sees current output volume and mute state in the bar.
2. The user opens the audio panel by pointer or its corresponding shell action.
3. The user adjusts output volume or toggles mute and receives immediate state change plus proportional feedback.
4. The user selects an output device; Rashell makes the selected device explicit and PipeWire becomes the source of truth.
5. When an input device exists, the user can adjust its volume and select it through the same interaction model.
6. The user returns to the desktop without needing a separate mixer for these core tasks.

Per-application stream mixing is deliberately outside this version.

## Failure and empty states

- **Hyprland unavailable or reconnecting:** retain the shell surface where possible; show workspace state as unavailable rather than stale, and disable workspace actions that cannot succeed.
- **PipeWire unavailable or no default output:** show an explicit audio-unavailable state; do not display a fictional `0%` value, enable mute, or offer device selection.
- **No input device:** omit the input controls and section rather than showing an empty, broken panel.
- **One device only:** show the active device clearly; device selection remains understandable without implying alternatives.
- **Device disconnects while a panel is open:** update the panel to the unavailable or remaining-device state immediately; never leave a selectable stale device.
- **Invalid configuration:** keep the last known good configuration; on first load without one, use built-in defaults and report the problem clearly.
- **Invalid or failed module load:** report the targeted failure while keeping unrelated first-party modules usable where possible; do not promise process-level crash isolation.

## First coherent version boundary

The first coherent version is specified to include:

- multi-monitor three-zone top bar;
- workspace display and direct focus request;
- centered clock and compact calendar;
- contextual audio status;
- an anchored audio task panel with output volume, mute, output selection, and available input controls;
- a single transient-panel owner and shared pointer/keyboard/dismissal behavior;
- shell action/IPC routing for the included tasks;
- a small volume OSD;
- semantic Rashell theme primitives and three config-selectable built-in palettes;
- local validated configuration with last-known-good fallback;
- capability-driven empty and failure states.

It deliberately defers:

- general menu or launcher;
- notification daemon and history;
- per-application audio controls;
- brightness, network, Bluetooth, battery, session, lock, or power panels;
- GUI settings, visual bar editing, migration machinery, and multiple configuration layers;
- third-party plugin lifecycle, remote catalogs, and full-bar replacement;
- whole-system theming and all distro/application provisioning.

## Acceptance principles

The version is coherent when:

1. **It is useful before it is broad.** Every included surface completes a frequent daily job; no placeholder surface implies ownership of a deferred product.
2. **State has one authority.** Hyprland and PipeWire provide operational truth; Rashell presents it and sends explicit user requests.
3. **Persistent UI orients; transient UI acts.** The bar summarizes state, while panels complete bounded tasks in place.
4. **Actions are equivalent across entry points.** Pointer, keyboard, and IPC routes invoke the same action and yield the same result.
5. **Only one transient task competes for attention.** Opening one panel closes or replaces another; dismissal is predictable.
6. **Unavailable is honest.** Missing services, devices, and configuration are explicit and safe, never fabricated as normal state.
7. **The shell stays in its lane.** Rashell does not absorb Hyprland policy, PipeWire policy, app management, or distribution management.
8. **A failure is reported precisely.** Configuration and module-loader failures preserve unrelated UI where possible, without claiming process-level isolation for in-process QML.
9. **The composition is stable across monitors.** Each monitor receives the same understandable bar grammar, while the clock remains visually centered.
10. **Complexity remains visible and justified.** New surfaces, configuration, and extension points require a demonstrated daily job beyond this boundary.

**Closing comment**

Decision: Rashell is a narrow personal Hyprland/PipeWire control layer, not a distro or framework. The first coherent version is specified to provide multi-monitor orientation, workspace switching, clock/calendar, and complete core audio control—with honest empty states, shared panel behavior, action routing, and volume OSD—while deferring provisioning, Hyprland policy, notifications, general menus, stream mixing, and plugin lifecycle.