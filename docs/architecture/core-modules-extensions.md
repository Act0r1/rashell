## Decision: Core, first-party modules, and future local extensions

**Status:** Resolved by issue #6  
**Decision:** Rashell is a cohesive shell host, not a general plugin framework. Public extensions are **not** part of the first coherent version.

### Context

Rashell’s stated direction is a single Hyprland/Quickshell runtime with a multi-monitor bar and focused task panels. Prior decisions favor Noctalia-like seams—shared domain state, a single transient-panel owner, validated configuration—without its marketplace or framework scale.

The current manifest registry is useful evidence, but not an architecture commitment:

- It already separates placement (`config.json`) from widget implementation.
- It validates basic manifests and prevents obvious relative-path traversal.
- It loads a `bar-widget` per screen.
- It also exposes the entire registry to loaded QML, lets panels bypass the registry, and gives each monitor its own audio widget/panel state. It therefore does not yet establish a safe or stable extension contract.

### Decision

#### 1. Rashell core owns the shell host

Core is responsible for capabilities that must be coherent across every module and monitor:

- One Quickshell runtime, startup, diagnostics, and last-known-good configuration.
- Output discovery and multi-monitor surface composition.
- The bar window, its left/center/right placement model, and widget loading.
- Shared semantic presentation primitives: theme tokens, spacing, and common interaction states.
- A single transient-panel coordinator: anchoring, exclusivity, focus/dismissal policy, Escape handling, and error reporting.
- Module discovery/resolution when local extensions are eventually enabled.
- Failure containment at loading boundaries: one failing contribution must not remove the rest of the shell.

Core does **not** own audio policy, workspace policy, calendar behavior, notification-daemon behavior, application launching, distro management, or compositor abstraction beyond the Hyprland scope Rashell deliberately chose.

#### 2. Desktop features are first-party modules, not core features

Audio, workspaces, clock/calendar, and future focused desktop features belong in first-party modules. They may be replaced or removed later, but Rashell will not pre-build a generic replacement framework for that possibility.

Each module owns:

- Its domain behavior and presentation.
- Its private state and domain adapter.
- Its rendering contribution to the bar and, where needed, its panel content.
- Validation of its own configuration slice.

Each module must expose a small internal interface to the host rather than letting the host reach into its implementation. Internal interfaces remain refactorable until there are two real implementations or an external compatibility need.

Suggested internal shape:

```text
core/
  ShellHost            configuration, outputs, bar composition, diagnostics
  PanelCoordinator     one transient panel at a time
  Theme

modules/
  audio/               AudioState + PipeWire adapter + bar/panel views
  workspaces/          WorkspaceState + Hyprland adapter + bar view
  clock/               shared time state + bar/calendar views
```

Domain state is constructed once at the shell root. Per-monitor widgets are views over that shared state.

#### 3. Audio is the reference module

Audio should be the first module refactored to prove the split:

- One `AudioState` owns PipeWire observation, default-device selection, mute, and volume actions.
- One bar view is created for each configured output.
- Each view reads the same audio state; it must not create its own PipeWire tracker or independent device model.
- The module supplies panel content, while core’s `PanelCoordinator` owns the popup window and its lifecycle.
- Opening audio on one monitor closes any other transient Rashell panel.

This resolves the current prototype’s per-monitor `Panel.qml` ownership without inventing a general panel framework.

#### 4. Public plugins are deferred

The first coherent version contains **first-party modules only**. `plugins/` is a legacy prototype directory name, not a promise that arbitrary third-party QML is supported.

Do not ship or document:

- A marketplace, catalog, installer, updater, signing system, or dependency resolver.
- Plugin enable/install/update lifecycle hooks.
- A plugin SDK, compatibility guarantee, event bus, service locator, command registry, or inter-plugin messaging.
- Permission prompts or a sandbox; trusted QML cannot be meaningfully constrained in-process.

A local extension format may be introduced only after Rashell has a real trusted-local module that cannot reasonably remain first-party. Until then, editing Rashell’s source is the supported code-level customization path.

#### 5. Future extensions remain undecided

Future trusted-local extensions may be reconsidered only after a concrete external use case exists. The first coherent version defines no extension schema, discovery, lifecycle, compatibility, security, panel, service, or configuration contract.

### Current prototype disposition

| Current piece | Decision |
|---|---|
| `config.json` bar sections and ordered IDs | **Retain.** This is the right host-owned placement seam. |
| `PluginSlot.qml` loader boundary | **Retain and rename/refine** as an internal module slot; add visible diagnostics and a narrow creation context. |
| Manifest validation, `kinds`, and `entryPoints` | **Remove from the first coherent version.** No extension contract is defined. |
| Runtime shell-script scan and automatic `~/.config/rashell/plugins` creation | **Replace/remove for the first coherent version.** First-party modules need no user-directory scan or shell process. |
| Built-in/user collision and registry injection | **Remove.** A static catalog resolves only first-party modules. |
| Widget-owned `Panel.qml` popup windows | **Replace.** Core coordinates popup lifecycle; modules provide panel content. |
| Audio `PwObjectTracker` and panel/device state per widget instance | **Replace.** One root-level audio state module, many views. |
| Direct theme import from `qs.core` | **Retain internally.** Expose only stable semantic theme values if and when an external contract exists. |

### Consequences

This keeps Rashell small: a shell host plus a few deep first-party modules. It preserves future local customization without making today’s prototype a compatibility burden. The next implementation work should first establish root-owned shared state and panel coordination, using audio as the reference module.

---

### Concise closing comment

> **Decision:** Rashell core is the single-runtime shell host: output/bar composition, configuration, diagnostics, theme primitives, and one transient-panel coordinator. Audio, workspaces, and clock/calendar are first-party modules with shared root-level domain state and per-monitor views; audio is the reference refactor.  
>
> Public extensions are **not** part of the first coherent version. Replace user-directory scanning, manifests, registry injection, widget-owned popups, and per-monitor audio state with a static first-party module catalog, shell-owned panels, and shared root state. Any future extension design starts from a demonstrated use case rather than this prototype.