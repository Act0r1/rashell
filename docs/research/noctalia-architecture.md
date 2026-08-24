# Noctalia architecture patterns for Rashell

## Question and scope

Which Noctalia patterns for shell surfaces, services, configuration, theming, and extensions should Rashell adopt without becoming a general-purpose desktop-shell framework?

This compares current Noctalia v5 with its v4.7.7 Quickshell implementation. The latter is the closest implementation analogue; v5 is a native Wayland/OpenGL ES rewrite, is much broader than Rashell, and is still beta ([source](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/README.md#L3-L12)). Rashell's baseline is intentionally small: one multi-monitor bar, three trusted-QML plugin slots, one audio popup, a versioned JSON file, and one static theme singleton ([scope](https://github.com/Act0r1/rashell/blob/ada8a7970e5e3a6edd29afde218e1b8fdc313ef0/README.md#L3-L12), [composition](https://github.com/Act0r1/rashell/blob/ada8a7970e5e3a6edd29afde218e1b8fdc313ef0/shell.qml#L7-L51)).

## Source snapshot

Snapshot date: **2026-08-24 UTC**.

| Source | Pinned revision | Use |
|---|---|---|
| [`noctalia-dev/noctalia`](https://github.com/noctalia-dev/noctalia/tree/0f61b0ae07607739189d07a0a7617ef0d8f3796c) | `0f61b0ae07607739189d07a0a7617ef0d8f3796c` | Current v5 architecture |
| [`noctalia-dev/noctalia` v4.7.7](https://github.com/noctalia-dev/noctalia/tree/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7) | `3abfa1fc09b62dc4cdeeb7b787886f075696f0b7` | Quickshell architecture |
| [`noctalia-dev/noctalia-docs`](https://github.com/noctalia-dev/noctalia-docs/tree/5ff920a5206f0b4f4009dfdd784b5b82a0cb9e2a) | `5ff920a5206f0b4f4009dfdd784b5b82a0cb9e2a` | Current plugin contract and trust model |
| [`Act0r1/rashell`](https://github.com/Act0r1/rashell/tree/ada8a7970e5e3a6edd29afde218e1b8fdc313ef0) | `ada8a7970e5e3a6edd29afde218e1b8fdc313ef0` | Rashell baseline inspected |

## Evidence: observed facts

### Surfaces

- v4 keeps top-level surface families explicit (`Background`, `AllScreens`, `Dock`, notifications, OSD, lock screen) instead of letting widgets create the whole shell ad hoc ([source](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/shell.qml#L92-L137)). Its per-output host is a `Variants` over `Quickshell.screens`, with a screen-bound main surface and a separate bar window ([source](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Modules/MainScreen/AllScreens.qml#L9-L78)).
- v4 centralizes transient-panel registration and open state; opening one normal panel closes the previous one ([state/registration](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Services/UI/PanelService.qml#L14-L56), [single-open policy](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Services/UI/PanelService.qml#L238-L265)).
- v5 preserves the conceptual seam: `shell/` is split by surface family, `shell/panel/` owns panel mechanics, `shell/surface/` owns shared geometry, and `ui/controls/` owns reusable controls ([source](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/CONTRIBUTING.md#L141-L218)).

### Services

- v4's shell waits for settings/state prerequisites, initializes render-critical services before constructing surfaces, and defers non-critical services until later ([source](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/shell.qml#L45-L128)). Current v5 likewise orders services, plugin registry, UI, then plugin services ([source](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/app/application.cpp#L199-L227)).
- A v4 domain singleton such as `AudioService` owns the shared PipeWire view: default devices, filtered device collections, normalized volume/mute state, and fallback behavior ([source](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Services/Media/AudioService.qml#L1-L40), [derived state](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Services/Media/AudioService.qml#L101-L138), [device filtering](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Services/Media/AudioService.qml#L165-L206)).

### Configuration

- v4 exposes one `Settings` singleton backed by a typed `JsonAdapter`, watches the config and its directory, debounces reloads, and versions migrations ([source](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Commons/Settings.qml#L13-L63), [load/reload](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Commons/Settings.qml#L94-L172), [typed bar defaults](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Commons/Settings.qml#L198-L245)).
- v5's equivalent is intentionally much heavier: it merges includes and app-owned overrides, tracks origins and migrations, validates into a candidate, then installs the candidate or retains/falls back to usable configuration on error ([source](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/config/config_service.cpp#L1370-L1458), [validation/recovery](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/config/config_service.cpp#L1467-L1565)).

### Theming

- v4 separates semantic color roles (`primary`, `surface`, `on_surface`, `error`, outline, hover) from style metrics such as typography, spacing, radii, opacity, and animation durations ([colors](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Commons/Color.qml#L9-L82), [metrics](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Commons/Style.qml#L7-L101)).
- v5 keeps semantic palette roles and separate style metrics ([palette](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/ui/palette.h#L11-L47), [style](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/ui/style.h#L5-L43)) while `theme/` separately owns palette generation, templates, and template application ([layout](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/CONTRIBUTING.md#L210-L216)).

### Extensions

- v4 already used directory discovery plus a static manifest and rejected missing identity/entry-point fields or malformed versions before registration ([scan](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Services/Noctalia/PluginRegistry.qml#L253-L310), [validation](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Services/Noctalia/PluginRegistry.qml#L580-L618)). It loaded entry-point QML with `Qt.createComponent` and instantiated background components in the shell's graphics scene, providing fault reporting but no process isolation ([source](https://github.com/noctalia-dev/noctalia/blob/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7/Services/Noctalia/PluginService.qml#L775-L850)).
- v5 makes entry kinds, typed settings, compatibility (`pluginApiVersion`), and host-owned panel geometry explicit in the manifest model ([source](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/scripting/plugin_manifest.h#L16-L79), [entries/geometry](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/src/scripting/plugin_manifest.h#L88-L146)).
- Noctalia's per-entry Luau VMs and time budgets are fault-containment mechanisms, **not a security sandbox**: its docs call plugins trusted code and explicitly say filesystem helpers are not sandboxed ([source](https://github.com/noctalia-dev/noctalia-docs/blob/5ff920a5206f0b4f4009dfdd784b5b82a0cb9e2a/src/content/docs/noctalia/plugins/development/index.mdx#L9-L22), [filesystem warning](https://github.com/noctalia-dev/noctalia-docs/blob/5ff920a5206f0b4f4009dfdd784b5b82a0cb9e2a/src/content/docs/noctalia/plugins/development/runtime-api.mdx#L252-L267)).

## Decisions

| Pattern | Decision | Rashell action |
|---|---|---|
| Explicit top-level surface families; one per-output host | **Adopt** | Keep `Bar.qml`'s existing `Variants`; add new surface families only from `shell.qml`, not from arbitrary plugins. |
| One coordinator for transient panels | **Adapt** | When a second popup exists, add a tiny `PanelController` (`openId`, output, anchor, `open/toggle/close`) so only one transient panel is open. Do not copy Noctalia's popup/focus/animation framework. |
| Domain services shared by multiple views | **Adopt** | Extract `AudioService.qml` now so the audio bar widget and panel share filtering and commands. Add other services only when two consumers or non-trivial policy exist. |
| Versioned, hot-reloaded, last-known-good config | **Adapt** | Move parsing/defaults into `core/Config.qml`; validate only Rashell's current keys, replace the snapshot only after successful validation, and otherwise retain the prior valid snapshot. Keep one JSON file. |
| Semantic colors plus centralized metrics | **Adopt** | Keep the fixed amber palette and current `Theme` API; group/color-name it semantically and require built-ins to consume it rather than literal colors. A file split is unnecessary. |
| Static, validated extension manifest and host-owned placement | **Adapt** | Retain one supported kind (`bar-widget`), strict relative entry paths, and explicit schema compatibility. Warn on duplicate IDs and define built-in/user precedence. |
| Includes, GUI override sidecars, migrations framework, origin diagnostics | **Avoid** | Add a one-off migration only when schema v2 actually exists. |
| Plugin catalogs, git updater, Luau runtime, declarative UI DSL, many entry kinds | **Avoid** | Rashell is personal and local-first; trusted QML plus restart-on-change is enough. Never describe it as sandboxed. |
| Wallpaper palette generation, community themes, external-app templates | **Avoid** | Preserve Rashell's authored amber-on-black identity. |
| Cross-compositor backends, custom renderer, IPC/settings application | **Avoid** | Stay Hyprland + Quickshell until Rashell's requirements change. |

## Recommended near-term Rashell shape

```text
shell.qml                    # composition only: Config, registry, top-level surfaces
core/Config.qml              # defaults, v1 validation, watched last-good snapshot
core/Theme.qml               # semantic colors + compact metric scale (existing)
core/PanelController.qml     # defer until the second transient panel
services/AudioService.qml    # PipeWire model and audio commands
bar/Bar.qml                  # existing per-screen host and three lanes
plugins/<id>/                # trusted QML; manifest + bar widget (+ private panel file)
```

1. First extract audio state/actions from `plugins/audio/BarWidget.qml` and `Panel.qml`; views should only render and invoke service methods.
2. Then move `shell.qml`'s config parser into `Config.qml`, retaining the prior valid snapshot on invalid edits (defaults only when no valid snapshot exists).
3. Keep the current plugin loader narrow. Add a new entry kind or plugin API version only alongside a concrete second host surface; do not pre-build Noctalia's extension platform.
4. Add a shared panel controller only when another popup would otherwise duplicate open/close/outside-click policy.

## Risks and limits

- v5 is beta and no longer uses Quickshell ([source](https://github.com/noctalia-dev/noctalia/blob/0f61b0ae07607739189d07a0a7617ef0d8f3796c/README.md#L3-L12)), so its durable seams are more useful than its implementation scale.
- v4.7.7 is the closest QML precedent but is a historical tag ([source](https://github.com/noctalia-dev/noctalia/tree/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7)); current compatibility/security behavior comes from the pinned v5 docs ([source](https://github.com/noctalia-dev/noctalia-docs/blob/5ff920a5206f0b4f4009dfdd784b5b82a0cb9e2a/src/content/docs/noctalia/plugins/development/index.mdx#L9-L22)).
- This is source-architecture analysis, not a runtime or performance benchmark.
- Trusted QML can execute with the user's permissions. Manifest path checks improve correctness and accidental traversal resistance; they do not create isolation.

## Primary sources

- [Noctalia current source](https://github.com/noctalia-dev/noctalia/tree/0f61b0ae07607739189d07a0a7617ef0d8f3796c)
- [Noctalia v4.7.7 Quickshell source](https://github.com/noctalia-dev/noctalia/tree/3abfa1fc09b62dc4cdeeb7b787886f075696f0b7)
- [Noctalia documentation source](https://github.com/noctalia-dev/noctalia-docs/tree/5ff920a5206f0b4f4009dfdd784b5b82a0cb9e2a/src/content/docs/noctalia)
- [Rashell baseline](https://github.com/Act0r1/rashell/tree/ada8a7970e5e3a6edd29afde218e1b8fdc313ef0)
