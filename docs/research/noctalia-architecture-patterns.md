# Research draft: Noctalia v5 patterns applicable to Rashell

## Scope and method

This review compares Rashell with Noctalia v5 at pinned commit [`0f61b0ae07607739189d07a0a7617ef0d8f3796c`](https://github.com/noctalia-dev/noctalia/tree/0f61b0ae07607739189d07a0a7617ef0d8f3796c).

Sources were limited to first-party Noctalia code, repository documentation, configuration examples, and the official documentation site. The website is not commit-pinned, so implementation conclusions defer to the pinned source when ambiguity exists.

Rashell remains a much smaller system: a personal Quickshell/QML shell targeting Hyprland and PipeWire. Noctalia’s architecture is therefore useful as a source of boundaries, not as a framework to reproduce.

---

## Executive conclusion

Noctalia’s most transferable idea is **host ownership**:

- the shell owns Wayland surfaces;
- services own external state and actions;
- configuration selects and arranges features;
- themes expose semantic tokens;
- extensions provide content through host-defined entry points rather than owning arbitrary shell infrastructure.

Rashell should borrow those boundaries in a much smaller form:

1. Keep one bar instance per monitor.
2. Move popup ownership into one shell-level panel host.
3. Keep PipeWire and Hyprland state outside panel chrome, using Quickshell’s existing singleton services.
4. Retain one versioned JSON configuration with defaults and hot reload.
5. Keep the existing fixed semantic theme.
6. Treat current “plugins” as internal built-in feature modules, not a public extension API.

A first-party user plugin platform should **not** be part of the first milestone. Rashell’s current manifest declares only `bar-widget`, while the clock and audio features also contain undeclared `Panel.qml` surfaces. That is evidence that the extension contract has been introduced before Rashell’s actual widget/panel/service boundaries are stable.

---

## 1. Shell surfaces

### How Noctalia organizes them

Noctalia separates shell-specific surfaces by purpose under `src/shell/`: bars, dock, panels, wallpaper, notifications, OSDs, lock screen, settings, desktop widgets, and other surface families. Generic controls and scene-graph infrastructure live separately under `src/ui/` and `src/render/`. This division is documented explicitly in [`CONTRIBUTING.md`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/CONTRIBUTING.md).

Surface ownership converges in the application composition root:

- [`src/app/application.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/app/application.h) owns the bar, dock, wallpaper, panels, OSDs, notifications, lock screen, and supporting services.
- [`src/app/application_ui.cpp`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/app/application_ui.cpp) defines a canonical output-surface creation order and recreates those surfaces when outputs change.
- [`src/shell/bar/bar.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/shell/bar/bar.h) owns per-output bar instances.
- [`src/shell/panel/panel.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/shell/panel/panel.h) defines panel content and placement policy.
- [`src/shell/panel/panel_manager.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/shell/panel/panel_manager.h) owns opening, closing, anchoring, focus, outside-click handling, and the active-panel slot.

The official [bar documentation](https://docs.noctalia.dev/noctalia/bar/) describes named bars that are instantiated on every monitor, with `start`, `center`, and `end` widget lanes and optional per-monitor overrides.

The important distinction is that a bar widget may request a panel, but it does not independently implement panel-window policy.

### Rashell assessment

Rashell already has a good minimal per-output surface pattern:

- [`shell.qml`](shell.qml) is the composition root.
- [`bar/Bar.qml`](bar/Bar.qml) uses `Variants` over `Quickshell.screens`.
- Configuration supplies left, center, and right feature IDs.

The weak point is panel ownership:

- [`plugins/audio/BarWidget.qml`](plugins/audio/BarWidget.qml) loads its own `Panel.qml`.
- [`plugins/clock/BarWidget.qml`](plugins/clock/BarWidget.qml) does the same.
- Each feature independently controls popup creation, anchoring, chrome, and open state.

This permits inconsistent behavior and multiple unrelated panels to remain open. It also makes future outside-click, Escape, focus, and monitor-placement rules feature responsibilities.

### Applicable pattern

Borrow Noctalia’s **central panel ownership**, but not its full `PanelManager`.

Rashell needs only:

- one active panel;
- a panel ID or component;
- the clicked anchor item;
- open, close, and toggle operations;
- Escape and outside-click dismissal;
- shared panel chrome.

A single shell-level host is sufficient. Attached/floating policy, persistent panels, custom Hyprland focus-grab orchestration, animation orchestration, and compositor-specific geometry are unnecessary until a real requirement appears; the first implementation uses Quickshell `PopupWindow.grabFocus`.

---

## 2. Services and external state

### How Noctalia organizes them

Noctalia places external integrations outside visual components:

- PipeWire under `src/pipewire/`;
- D-Bus integrations under `src/dbus/`;
- compositor adapters under `src/compositors/`;
- hardware and desktop state under `src/system/`;
- time under `src/time/`.

[`src/pipewire/pipewire_service.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/pipewire/pipewire_service.h) exposes audio snapshots and actions independently of the bar and control center. It owns sinks, sources, streams, defaults, volume, mute, and change notification.

The application creates services once and passes them into surfaces. For example:

- [`src/shell/bar/bar_services.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/shell/bar/bar_services.h) describes the capabilities available to bar widgets.
- [`src/shell/control_center/control_center_services.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/shell/control_center/control_center_services.h) does the same for the control center.
- [`src/app/application_services.cpp`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/app/application_services.cpp) wires service changes to affected surfaces.

This prevents every monitor’s widget from creating its own PipeWire, D-Bus, or polling connection.

### Rashell assessment

Rashell already receives shared process-wide state from Quickshell’s `Pipewire` and `Hyprland` singletons. Reimplementing Noctalia-style C++ services would add indirection without new capability.

The useful boundary is conceptual:

- service/model code owns external state and commands;
- bar widgets render compact state;
- panels render detailed controls;
- neither presentation owns popup policy.

A dedicated `AudioService.qml` is not required merely to wrap `Quickshell.Services.Pipewire`. It becomes justified only when filtering, labels, policy, or mutations are duplicated across multiple consumers.

### Applicable pattern

Borrow **one shared state source with several presentations**.

Do not borrow Noctalia’s broad dependency bags, custom poll loop, D-Bus wrappers, or direct PipeWire implementation. Quickshell already supplies that infrastructure.

---

## 3. Configuration

### How Noctalia organizes it

Noctalia has a typed effective configuration assembled from:

1. built-in defaults;
2. alphabetically merged user TOML files;
3. application-managed `settings.toml` overrides.

The official [configuration documentation](https://docs.noctalia.dev/noctalia/configuration/) also covers includes, validation, migrations, source locations, state separation, and hot reload. [`example.toml`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/example.toml) exposes the complete user-facing hierarchy.

In source:

- [`src/config/config_types.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/config/config_types.h) defines typed configuration snapshots.
- [`src/config/config_service.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/config/config_service.h) owns loading, watching, mutations, overrides, and reload subscribers.
- [`src/config/schema/config_schema.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/config/schema/config_schema.h) is the shared schema surface for reading, writing, and validation.
- Change sets let subscribers avoid rebuilding for unrelated configuration changes.

This complexity supports a settings GUI, declarative distributions, migrations, multiple bars, many services, and a public plugin platform.

### Rashell assessment

Rashell’s current configuration is appropriately smaller:

- [`shell.qml`](shell.qml) contains a complete default.
- [`config.json`](config.json) provides one versioned override.
- Parse or version failure falls back to defaults.
- `FileView` hot-reloads changes.
- Bar placement uses stable IDs rather than file paths.

That is sufficient for the first milestone.

### Applicable pattern

Borrow:

- explicit schema version;
- complete in-process defaults;
- validation before replacing the active snapshot;
- config-driven feature placement;
- atomic “old valid snapshot or new valid snapshot” behavior.

Do not add:

- multi-file merging;
- GUI-managed override layers;
- migrations;
- includes;
- configuration export;
- generated settings forms;
- per-monitor overrides.

Add new fields only when a milestone feature requires them—for example configurable workspace IDs. Do not attempt to expose every QML property.

---

## 4. Theming

### How Noctalia organizes it

Noctalia separates three concerns:

1. **Semantic color roles** in [`src/ui/palette.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/ui/palette.h), such as `surface`, `on_surface`, `primary`, `error`, and `outline`.
2. **Layout and control metrics** in [`src/ui/style.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/ui/style.h).
3. **Palette resolution** in [`src/theme/theme_service.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/theme/theme_service.h) and [`src/theme/theme_service.cpp`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/theme/theme_service.cpp).

The resolver supports built-in, custom, community, and wallpaper-generated palettes, light/dark scheduling, accessibility transforms, transitions, and application templates. The official [theme](https://docs.noctalia.dev/noctalia/theming/) and [palette](https://docs.noctalia.dev/noctalia/theming/palette/) documentation consistently tells consumers to reference roles rather than fixed colors.

### Rashell assessment

[`core/Theme.qml`](core/Theme.qml) already follows the useful part of this model:

- semantic colors;
- typography;
- shared dimensions;
- one fixed visual identity.

Combining color and metrics in one singleton is reasonable at Rashell’s size. Splitting them would currently create files rather than reduce complexity.

### Applicable pattern

Keep the amber-on-black palette fixed and continue using semantic properties. Add roles only when a component otherwise repeats a raw color.

Reject wallpaper palette extraction, Material color generation, community palettes, application templates, light/dark scheduling, and animated palette transitions for the first milestone.

---

## 5. Extensions

### How Noctalia organizes them

Noctalia’s extension model is a complete hosted runtime:

- [`src/scripting/plugin_manifest.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/scripting/plugin_manifest.h) defines identity, compatibility, entry kinds, and typed settings.
- Supported entries include bar widgets, panels, desktop widgets, control-center shortcuts, launcher providers, and headless services.
- [`src/scripting/plugin_manager.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/scripting/plugin_manager.h) handles sources, enablement, compatibility, materialization, updates, and removal.
- [`src/scripting/plugin_service_host.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/scripting/plugin_service_host.h) gives service entries singleton lifecycles outside UI instances.
- [`src/app/application_plugins.cpp`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/app/application_plugins.cpp) adapts plugin entries into host-owned launcher and panel surfaces.
- [`src/scripting/plugin_api.h`](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/scripting/plugin_api.h) tracks compatibility across API levels 3–28.

The official [plugin overview](https://docs.noctalia.dev/noctalia/plugins/) and [development documentation](https://docs.noctalia.dev/noctalia/plugins/development/) describe trusted Luau code running in per-entry VMs, off the UI thread, with host APIs and execution budgets. The manifest and APIs are explicitly marked beta.

Noctalia’s isolation primarily protects shell responsiveness and lifecycle integrity; it does not turn plugins into untrusted code.

### Rashell assessment

Rashell’s current registry is much narrower:

- [`core/PluginRegistry.qml`](core/PluginRegistry.qml) scans built-in and user manifests through a Bash process.
- [`bar/PluginSlot.qml`](bar/PluginSlot.qml) dynamically loads trusted QML.
- Manifests support only `bar-widget`.
- Audio and clock panels exist outside the declared manifest contract.
- Plugin QML can access the user session directly.

The implementation is not wrong for trusted personal experiments, but it is premature as a promised extension API. Supporting real user extensions would immediately require decisions about panels, shared services, settings, lifecycle, reload semantics, API compatibility, error containment, and source precedence.

---

## Recommendation matrix

| Noctalia pattern | Rashell decision | Reason |
|---|---|---|
| Per-output surface reconciliation | **Borrow now** | Directly supports the multi-monitor bar; Rashell already mostly has it. |
| Host-owned panel manager | **Borrow now, simplify heavily** | Clock and audio need consistent popup ownership. |
| Services independent from visuals | **Borrow now as a boundary** | Shared PipeWire/Hyprland state should feed several views. |
| Semantic palette roles | **Borrow now** | Already fits `Theme.qml` and the fixed visual identity. |
| Versioned config with defaults and hot reload | **Borrow now** | Already small and sufficient. |
| Named feature IDs in bar lanes | **Borrow now** | Keeps layout independent from concrete files. |
| Typed settings schemas | **Consider selectively later** | Useful only after more configurable feature fields exist. |
| Per-monitor bar overrides | **Defer** | No demonstrated need beyond one bar on every output. |
| Multiple named bars | **Defer** | The first milestone specifies one top bar. |
| Dedicated service wrappers | **Add selectively** | Only when shared policy appears beyond Quickshell’s singleton APIs. |
| Public plugin manifests with several entry kinds | **Defer** | Current built-in contracts are not stable. |
| Direct Wayland/GLES scene graph | **Reject** | Quickshell already owns this layer. |
| Custom poll loop and native D-Bus/PipeWire stack | **Reject** | Framework duplication. |
| Luau runtime, worker pools, API levels | **Reject** | No requirement justifies a second runtime. |
| Git plugin sources, catalog, materialization, auto-update | **Reject** | Distribution machinery for a personal shell. |
| GUI overrides, includes, migrations, export | **Reject for milestone one** | Solves a configuration-product problem Rashell does not have. |
| Material palettes, templates, community themes | **Reject for milestone one** | Conflicts with the fixed amber-on-black goal. |
| Multi-compositor adapter layer | **Reject** | Rashell targets Hyprland. |

---

## Concrete decision for Rashell’s first milestone

The first milestone should be:

1. **One multi-monitor top bar**
   - one instance per connected screen;
   - left, center, and right lanes configured by stable built-in feature IDs.

2. **Three built-in feature modules**
   - Hyprland workspaces;
   - clock with calendar panel;
   - PipeWire volume with direct output/input selection.

3. **One shell-owned panel host**
   - one active panel globally;
   - anchored to the invoking widget’s monitor;
   - shared chrome, Escape handling, outside-click dismissal, and toggle behavior;
   - widgets request panels but do not create `PopupWindow` instances themselves.

4. **One versioned JSON configuration**
   - complete defaults in code;
   - hot reload;
   - invalid updates preserve or restore the default valid snapshot;
   - only fields required by the three built-ins.

5. **One fixed semantic theme**
   - retain `Theme.qml`;
   - no palette engine, theme store, or application templating.

6. **No public user plugin API**
   - current feature IDs remain internal placement keys;
   - current modules may remain under `plugins/` temporarily, but they are built-ins and carry no compatibility promise;
   - filesystem discovery and `~/.config/rashell/plugins/` are deferred until widget, panel, service, settings, and lifecycle contracts have been proven by built-in features.

This milestone borrows Noctalia’s strongest architectural seam—host-owned surfaces consuming shared services—without importing the machinery required by a general desktop shell and extension ecosystem.

---

## Issue-closing comment

Researched Noctalia v5 at `0f61b0ae07607739189d07a0a7617ef0d8f3796c`. The patterns worth adopting are host-owned per-output surfaces, one coordinated panel host, shared service state, versioned config with defaults/hot reload, and semantic theme tokens. Rashell’s first milestone will remain one multi-monitor bar with workspace, clock/calendar, and audio built-ins, one central panel host, one JSON config, and the fixed amber theme. Public user plugins are deferred because the current `bar-widget` manifest does not model the panels and service boundaries the prototypes already need. We will not copy Noctalia’s renderer, multi-layer config system, palette/template machinery, multi-compositor adapters, or Luau/git plugin platform.