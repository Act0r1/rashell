# Decision draft: Configuration, settings, and customization boundary

**Status:** Resolved by GitHub issue #8

## Decision

Rashell has one user-owned, declarative JSON configuration. It controls shell composition, not live desktop state or arbitrary behavior.

The first coherent version has no settings UI and no public plugin lifecycle. Audio and calendar panels operate PipeWire and time state; they do not persist Rashell configuration. Code-level QML customization remains supported for the shell owner.

## Ownership, path, and format

Configuration is owned by the user and never rewritten by Rashell.

One active configuration file is selected:

1. `RASHELL_CONFIG`, when set to an absolute file path;
2. `$XDG_CONFIG_HOME/rashell/config.json` (defaulting to `~/.config/rashell/config.json`) when it exists;
3. `<Rashell checkout>/config.json` otherwise.

There is no merging, override layer, include syntax, or app-managed `settings.json`.

This reconciles XDG with a source-controlled personal shell:

- A checkout’s committed `config.json` remains the normal, reproducible dotfiles workflow.
- Users preferring XDG may keep the file there or symlink it to the tracked checkout file.
- `RASHELL_CONFIG` supports an explicit profile without inventing configuration precedence.

The format is strict JSON, UTF-8, with a required integer `version`. Comments, executable expressions, imports, and shell commands are not valid configuration.

## Version and validation

The initial schema version is `1`.

Rashell loads configuration into a normalized effective snapshot:

1. Parse JSON.
2. Check `version === 1`.
3. Validate the complete schema, types, IDs, and duplicate entries.
4. Apply the complete snapshot atomically only when all validation succeeds.

Built-in defaults are compiled into the shell and are used only before any valid configuration has loaded, or when no selected configuration file exists.

After a successful load, invalid, truncated, deleted, or unsupported updates preserve the in-memory **last-known-good** configuration. They must not replace a working bar with defaults. Rashell logs a targeted diagnostic and exposes a concise shell diagnostic where available. A subsequent valid save replaces the snapshot and clears the error.

The selected file is watched. Valid changes reload without restart; configuration code or module code changes still require restart. Reload never writes, reformats, or “repairs” the user file.

The current `shell.qml` fallback-to-default behavior on reload failure should change to last-known-good behavior.

## First coherent version schema

Version 1 exposes built-in theme selection and bar composition:

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

Rules:

- `theme` is required and must be `ember`, `raven`, or `jade`.
- `bar.left`, `bar.center`, and `bar.right` are required arrays of first-party module IDs.
- An ID may occur once across all three zones.
- Unknown IDs are a validation error rather than a silent missing widget.
- Order in an array is display order.
- Default composition is workspace left, clock center, and audio right.

No version-1 fields configure audio behavior, calendar behavior, workspace policy, monitor policy, typography, arbitrary colors, command bindings, or panel geometry. Hyprland, PipeWire, locale, and the selected built-in semantic theme remain authoritative where applicable.

## Module slices

A module receives only its own future configuration slice at:

```text
modules.<module-id>
```

Core owns parsing, version validation, file watching, and the active snapshot. Each first-party module owns validation and defaults for its slice. A module cannot inspect or mutate other modules’ slices or write configuration.

No `modules` object exists in version 1 because no included module yet needs a persistent preference. It is added only with the first justified module setting; an empty extensibility namespace is YAGNI.

## Theme selection and tokens

`Theme.qml` remains the single code-owned semantic token source.

Its current roles—background, surfaces, accent, text, border, danger, typography, and dimensions—are the supported internal styling contract. New roles should be semantic and added only when repeated raw styling proves necessary, including interaction roles when components need distinct hover, focus, selected, or disabled states.

The `theme` field selects one complete built-in dark palette: `ember`, `raven`, or `jade`. Valid config hot reload applies the palette atomically. There is no theme picker UI, external theme format, arbitrary color override, wallpaper-derived palette, light/dark scheduler, marketplace, or system-wide theme application.

## State is not configuration

Configuration describes desired Rashell composition. State describes live or transient facts.

| Category | Owner | Examples |
|---|---|---|
| Configuration | User JSON | Built-in theme and bar zone order |
| Shell transient state | Rashell | Active panel, anchor, focused output, reload diagnostic |
| Compositor state | Hyprland | Workspaces, focused window, outputs |
| Audio state | PipeWire | Devices, volume, mute, selected defaults |
| Calendar state | Clock/locale | Current date and displayed month |

Panels may request explicit changes to Hyprland or PipeWire. They do not turn these actions into persistent Rashell preferences.

## Actions and command safety

Pointer and keyboard controls call narrow first-party module methods. Fixed IPC exposes only audio/calendar panel toggle, panel close, output volume adjustment, and output mute toggle.

- No configuration field executes shell commands, QML, JavaScript, or arbitrary IPC payloads.
- Device selection remains panel-internal and accepts only a current observed PipeWire node.
- Workspace bindings invoke Hyprland directly; Rashell exposes no workspace IPC.
- Invalid or unavailable requests make no unrelated state change.
- There is no generic action endpoint, structured result protocol, output argument, or destructive session action.

This keeps Rashell a trusted local shell without creating an arbitrary command-execution interface.

## Settings UI boundary

The first coherent version has **no persistent in-shell settings experience**.

Audio and calendar panels are task panels, not settings editors:

- changing volume, mute, or default devices changes PipeWire state;
- navigating a month changes transient calendar state;
- neither writes Rashell configuration.

Users edit the selected JSON file and receive hot reload plus clear validation feedback. A settings UI is justified only when it can safely edit stable, schema-backed preferences without becoming a second configuration layer. It must write the same canonical file, preserve unknown future data deliberately, validate before commit, and never bypass source control assumptions.

## Code-level customization

Rashell remains personally customizable in code:

- Edit tracked QML, built-in modules, and `Theme.qml` in the checkout.
- Keep source and configuration together in a personal repository when reproducibility matters.
- Restart Rashell after QML/module changes.

This is trusted owner customization, not a public extension API. `plugins/` is an internal implementation location; built-in IDs and module interfaces have no third-party compatibility promise.

There is no user plugin directory scan, remote installation, marketplace, updater, lifecycle callback API, sandbox claim, arbitrary panel contribution, or full-bar replacement in the milestone.

## Migrations and deferred capabilities

Version 1 has no migration machinery. Unsupported versions fail validation and retain the last-known-good snapshot.

If a future version requires migration, it must be explicit, documented, and user-controlled. Rashell must not silently rewrite a source-controlled config. A future migration command may create a backup and produce a reviewed new file, but that capability is deferred.

Also deferred:

- multi-file configuration;
- GUI-managed overrides;
- per-monitor layouts;
- visual drag-and-drop bar editing;
- external theme files, custom palettes, and theme packs;
- module settings schemas before a real setting exists;
- public local extensions and all plugin lifecycle/distribution features.

## Consequences

This keeps the current `config.json` deliberately small while correcting reload semantics: successful configuration remains active through bad edits. It honors XDG without making a source-controlled shell configuration second-class, preserves a clean boundary between live desktop controls and shell preferences, and avoids committing Rashell to a settings product or extension platform before either has a demonstrated need.

### Concise closing comment

> Resolution: Rashell uses one user-owned, versioned JSON config selected once at startup by absolute path, existing XDG path, then tracked checkout fallback—never merged or auto-rewritten. Version 1 selects `ember`, `raven`, or `jade` and configures three bar zones; invalid reloads retain the in-memory last-known-good state. Settings UI, migrations, external themes, and public extension lifecycle remain deferred.