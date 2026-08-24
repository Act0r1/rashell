# Rashell planning consistency report

## Overall verdict

The documents agree on the product direction, but four decisions should be normalized before issues #7–#10 are finalized: audio streams, milestone terminology, modules/plugins, and configuration location/semantics.

Issue #1 must close planning only. Several “Resolved” or “delivers” statements currently read as though features have shipped.

## P0 — Resolve before finalizing issues

### 1. Per-application audio is both deferred and anticipated

**Conflict**

- `docs/architecture/product-boundary.md:96,104,129,152` explicitly defers per-application mixing and says not to reserve UI for streams.
- `docs/architecture/surface-navigation.md:61,179` says “eventually stream controls” and defines a no-stream panel state.
- `docs/research/omarchy-ui-patterns.md:17` describes Omarchy’s mixer, which can be mistaken for a Rashell requirement.

**Canonical decision**

Per-application stream discovery, state, controls, empty states, and placeholder UI are completely deferred beyond the first coherent version. The first audio scope is only:

- output volume and mute;
- output-device selection;
- input volume/mute and input-device selection when available;
- honest unavailable/device-disconnection states.

The Omarchy stream mixer remains research context, not accepted Rashell scope.

---

### 2. “First milestone/version” boundaries and planning status drift

**Conflict**

- Noctalia research defines a relatively narrow first milestone at `docs/research/noctalia-architecture-patterns.md:274–306`.
- Omarchy research adds keyboard behavior, IPC, and OSD at `docs/research/omarchy-ui-patterns.md:39–41`.
- Product and surface documents include action routing, IPC, OSD, feedback toasts, detailed focus restoration, typed actions, and structured results.
- `docs/architecture/product-boundary.md:152` says the version “delivers” these features even though this is planning.
- “First milestone,” “first coherent milestone,” “first complete version,” and “first version” are used interchangeably.

**Canonical decision**

Use one term: **first coherent version**.

It includes:

- one three-zone bar per monitor;
- workspace, clock/calendar, and audio first-party modules;
- one globally coordinated anchored panel;
- pointer and basic keyboard operation;
- one JSON configuration;
- fixed semantic visual grammar with three built-in dark themes;
- honest unavailable states;
- minimal panel-toggle IPC/actions;
- volume OSD.

It excludes stream mixing, public extensions, notification ownership, launcher/menu, settings UI, and generalized infrastructure for future surfaces.

Issue #1 and its planning conclusions remain **planning-only**: decisions may be accepted, but no document should imply implementation completion. Implementation belongs to later issues.

---

### 3. Plugins/modules/extensions vocabulary is inconsistent

**Conflict**

- `docs/architecture/core-modules-extensions.md:4,33–44,74–85` chooses first-party modules and defers plugins.
- The same document specifies a detailed future extension contract at lines 87–139, despite saying it is unjustified.
- `docs/architecture/product-boundary.md:18,107` still refers to trusted QML customization and failed “widget/plugin.”
- `docs/architecture/surface-navigation.md:10,58` calls current built-ins plugins.
- Outside the reviewed documents, `README.md` still advertises user plugins as part of the first milestone.

**Canonical vocabulary**

- **Core:** shell-owned composition, configuration, panel coordination, outputs, theme, and diagnostics.
- **Module:** first-party audio, workspaces, or clock/calendar feature.
- **Extension:** possible future trusted-local third-party contribution.
- **Plugin:** legacy name for the current prototype only; not product terminology.

For issues #7–#10, remove future extension manifests, discovery, lifecycle, compatibility, and user-directory behavior from requirements. The detailed future v1 contract should be treated as non-binding notes, not an implementation plan.

---

### 4. Configuration path and failure semantics are undecided

**Conflict/missing decision**

The documents consistently choose one versioned JSON file but never specify its runtime path. Current implementation reads repository-local `config.json`, while the architecture describes user-owned local configuration.

“Last known good” is also ambiguous: persistent cache versus the current in-memory snapshot.

**Canonical decision**

- Select once at startup: absolute `RASHELL_CONFIG`, then an existing `$XDG_CONFIG_HOME/rashell/config.json`, then checkout-local `config.json`.
- A relative `RASHELL_CONFIG` is diagnosed and ignored. An absolute selected path does not fall through merely because it is missing or invalid.
- Format: one JSON object with top-level `"version": 1`.
- Complete defaults remain in code.
- Missing or invalid selected configuration at startup uses defaults while continuing to watch the selected path.
- Invalid hot reload retains the current valid in-memory snapshot.
- Do not persist a separate last-known-good cache or switch to a newly created higher-priority path until restart.
- No merging, includes, migrations, GUI writes, executable expressions, or per-monitor overrides.

## P1 — Clarify the interaction contract

### 5. One global panel is agreed, but its abstraction drifts

`PanelCoordinator`, `SurfaceCoordinator`, “panel host,” and “surface router” describe overlapping responsibilities.

**Canonical decision**

Call it **PanelCoordinator** for the first coherent version:

- at most one anchored panel active across the process;
- same trigger toggles it closed;
- another panel replaces it atomically;
- Escape, visible close, outside interaction, anchor loss, or output loss closes it;
- bar-triggered panels open on the invoking bar’s output;
- OSD and Rashell feedback overlays do not occupy the panel slot.

Do not generalize it around future launchers or modal surfaces yet. “One globally active panel” is a behavior guarantee, not a requirement for a particular number of internal window objects.

---

### 6. Multi-monitor bar state and fallback routing are underspecified or overdesigned

The documents define identical bar structure and detailed panel fallback routing, but not how workspace state should appear per monitor. The “most recently interacted output” and explicit IPC output protocol add state without a demonstrated need.

**Canonical decision**

- One identical configured bar composition per connected output.
- No per-monitor configuration in the first version.
- Shared domain models; no PipeWire tracker per bar.
- Each workspace widget highlights the workspace active on its own output while showing the same configured workspace IDs.
- A bar invocation anchors to that exact output.
- A keyboard/IPC invocation targets the focused Hyprland output; otherwise use the first available output.
- Output removal closes its panel.
- Defer most-recent-output tracking and explicit output-name IPC arguments.

---

### 7. Keyboard requirements should be complete but smaller

`docs/architecture/surface-navigation.md:92–100` requires Tab, arrows, Vim keys, continuous adjustments, activation keys, and detailed focus behavior. This risks creating a generic navigation framework.

**Canonical decision**

- The normal bar does not take keyboard focus.
- External Hyprland bindings may invoke minimal Rashell IPC actions; Rashell does not install bindings.
- An opened panel takes focus.
- `Tab`/`Shift+Tab` traverse controls.
- Arrow keys operate lists and sliders.
- `Enter`/`Space` activate.
- `Escape` closes.
- Focus is visibly distinct from hover and selection.
- Pointer and keyboard call the same domain operation, but invocation context may determine the output.
- Defer `j`/`k` and `h`/`l` aliases until requested.

---

### 8. Toast ownership is mostly correct but terminology is risky

- Omarchy research says “actionable toasts.”
- Rashell’s surface taxonomy says feedback toasts are non-interactive.
- Product scope correctly rejects freedesktop notification ownership.

**Canonical decision**

Core may own a minimal **Rashell feedback overlay** for failures or confirmations caused by Rashell itself. It is:

- non-interactive;
- non-focus-stealing;
- ephemeral;
- without history, grouping, DND, or notification actions.

Panel-originated errors remain inline. Volume OSD appears for direct adjustments made outside the open audio panel; the panel itself provides sufficient feedback for changes made inside it. Desktop notifications remain owned by the existing notification daemon.

---

### 9. Calendar scope should lose “status details”

`docs/architecture/surface-navigation.md:60` says “calendar/status details,” while `product-boundary.md:82–85` defines a pure calendar reference surface.

**Canonical decision**

The first calendar panel shows:

- current month;
- today highlight;
- previous/next month navigation.

It has no selectable dates, agenda, events, reminders, scheduling, external calendar integration, or module-specific configuration. A fresh opening starts on the current month.

## P2 — Reduce overreach

### 10. Failure containment is overstated

`docs/architecture/product-boundary.md:146` promises a trusted QML contribution will not take down the shell, while `core-modules-extensions.md:139` correctly admits in-process QML cannot provide crash isolation.

**Canonical decision**

Contain manifest/loader/configuration errors where practical, but make no process-crash isolation guarantee. For the first version, apply this to first-party module loading and log targeted failures; do not build extension-grade isolation.

### 11. The action model is broader than needed

Typed argument schemas, enablement metadata, structured results, explicit output routing, and future launcher integration in `surface-navigation.md:156–170` resemble a public command framework.

**Canonical decision**

Define only the actions needed now, such as panel toggle/close and direct volume/mute operations. Keep them internal and refactorable. No generic registry, discoverability API, launcher contract, or compatibility promise.

## Recommended canonical summary

1. First coherent version, not multiple milestone names.
2. Issue #1 records planning decisions only.
3. First-party **modules** only; extensions deferred.
4. Per-application audio entirely deferred.
5. Calendar is month reference only.
6. One global `PanelCoordinator`; one active anchored panel.
7. Identical bar composition per output, shared state, output-local workspace highlight.
8. Basic conventional keyboard support; Vim aliases deferred.
9. One startup-selected versioned JSON config with in-memory valid-snapshot retention.
10. Core-owned Rashell feedback overlay and volume OSD; no notification daemon.
11. Minimal internal actions, not a general action or extension framework.
12. Best-effort loader failure containment, not crash isolation.

No files or GitHub state were changed.