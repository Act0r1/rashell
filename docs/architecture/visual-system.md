# Decision: Rashell’s canonical visual language and theme boundary

**Status:** Resolved by GitHub issue #7  
**Scope:** First coherent milestone

## Context

Rashell already has a clear visual direction:

- near-black layered surfaces;
- amber/gold as the primary accent;
- warm off-white text;
- one-pixel borders;
- square geometry with radii no larger than two pixels;
- monospace typography;
- compact controls and dense task panels.

This direction appears consistently in `README.md`, repository history, the current `core/Theme.qml`, and the audio, workspace, calendar, and bar prototypes. The visual grammar remains fixed while three built-in dark palettes provide deliberate variation.

The problem is not choosing another style. It is defining which parts of the existing style are canonical, making interaction states consistent and accessible, and preventing future components from introducing arbitrary colors or geometry.

## Decision

Rashell will have **one canonical visual system** for its first coherent version.

`Theme.qml` remains the single internal source for semantic colors, typography, shared spacing, common dimensions, and motion values. Components choose semantic roles and follow the component/state grammar defined here.

The first coherent version exposes three built-in themes selected by validated configuration and hot-reloaded with the effective config. It does not support external theme files, discovery, per-module styling, or arbitrary palette loading.

Token ownership does not imply that every token is user-overridable:

- **Canonical and fixed:** geometry, density, state grammar, component composition, focus behavior, and surface hierarchy.
- **Theme-owned values:** semantic colors, typography, common spacing, shared dimensions, and motion durations.
- **Supported variation:** complete built-in semantic dark-palette substitution.
- **Not supported:** arbitrary component layouts, radii, density, state mappings, light themes, or per-widget overrides.

## Canonical visual principles

### 1. Dark surfaces establish hierarchy

Rashell uses three near-black layers:

1. desktop/background;
2. normal shell surface;
3. raised or interactive surface.

Hierarchy comes from small luminance differences and borders—not shadows, blur, gradients, transparency effects, or glass styling.

### 2. Amber is scarce and meaningful

Bright amber identifies:

- the current or selected value;
- an active/open destination;
- progress or level;
- the highest-priority heading;
- keyboard focus when it is not on an amber-filled item.

Most content remains warm off-white or muted beige. Large panels must not become amber blocks.

### 3. Geometry is square and thin

- Borders are pixel-aligned and normally one pixel.
- Standard radius is two pixels.
- Small slider handles may use a one-pixel radius.
- Pills, highly rounded cards, floating bubbles, and circular icon buttons are not part of Rashell’s grammar.
- Keyboard focus may use a two-pixel indicator as an accessibility exception.

### 4. Typography carries structure

All Rashell-owned UI uses monospace typography.

- Titles and important values are bold.
- Section labels are uppercase with restrained letter spacing.
- Descriptions and errors use normal sentence casing.
- Numeric values remain aligned and stable.
- Icons must not replace text where their meaning is ambiguous.

Typography should create hierarchy without requiring large type or excessive vertical space.

### 5. Dense does not mean cryptic

Panels should show one bounded task with compact spacing and short labels. Density must not remove:

- visible focus;
- meaningful hit targets;
- explicit unavailable states;
- accessible names;
- keyboard navigation;
- enough room for localized or unexpectedly long device names.

### 6. State is never communicated by color alone

Persistent states use at least two channels:

- selected device: amber fill plus `>` or an explicit `IN USE` label;
- muted audio: danger color plus `MUTE` or `OFF`;
- unavailable integration: muted presentation plus explicit unavailable text;
- error: danger styling plus a readable message;
- keyboard focus: a visible outline or cursor independent of hover.

### 7. Persistent surfaces orient; transient surfaces act

The bar stays visually quiet and summarizes state. Panels contain detailed controls. OSDs provide short, non-interactive feedback.

A panel should look related to its opening bar control without making the bar itself resemble a collection of cards.

### 8. Motion is restrained

Motion clarifies a state transition but is not decoration.

- No bounce, spring, scale, or overshoot.
- No animated palette transitions.
- Focus, selection, errors, and domain-state changes appear immediately.
- Panels and OSDs may use a short opacity transition.
- Reduced-motion mode removes nonessential animation.

## Semantic token schema

The names below follow the existing `Theme.qml` style. They are internal API for the milestone, not a public extension ABI.

### Colors

| Token | Reference value | Meaning |
|---|---:|---|
| `background` | `#080806` | Shell canvas and inverse text on bright fills |
| `surface` | `#0d0c08` | Bar, panel, and OSD background |
| `surfaceRaised` | `#141108` | Hovered, pressed, or active control background |
| `accent` | `#ffbf18` | Selection, active destination, progress, primary heading |
| `accentMuted` | `#a48734` | Secondary amber labels and restrained emphasis |
| `text` | `#d6c58f` | Primary text |
| `textMuted` | `#9a8c62` | Secondary readable text |
| `textDisabled` | `#756a49` | Disabled content only |
| `textOnAccent` | `#080806` | Text and symbols on `accent` |
| `border` | `#3d3212` | Decorative separators and container borders |
| `borderInteractive` | `#735f22` | Functional control boundaries |
| `focus` | `#ffbf18` | Focus indicator on dark surfaces |
| `danger` | `#e35b45` | Error, failed action, and explicit negative status |
| `textOnDanger` | `#080806` | Text on a danger-filled compact indicator |

The current muted text and muted accent values are too low-contrast for small functional text. The revised roles preserve the existing appearance while keeping normal secondary text above a 4.5:1 contrast target. The old `textMuted` value becomes `textDisabled`.

`border` may remain subtle when decorative. Any border that is the only visible boundary of an interactive control must use `borderInteractive` or another role with at least 3:1 contrast.

No success, warning, informational, scrim, or shadow tokens are added until a milestone component actually needs them.

### Typography

| Token | Value | Use |
|---|---:|---|
| `fontFamily` | `monospace` | Every Rashell-owned label and value |
| `fontSmall` | `11` | Metadata, section labels, secondary state |
| `fontBody` | `13` | Controls, rows, percentages, calendar days |
| `fontTitle` | `15` | Clock, panel title, primary value |
| `fontWeightRegular` | regular | Normal content |
| `fontWeightStrong` | bold | Titles, current values, explicit status |
| `trackingLabel` | `1` | Compact uppercase labels |
| `trackingSection` | `2` | Panel headings and section labels |

Components must not introduce display fonts, proportional body fonts, or additional type scales during the first coherent version.

### Spacing

| Token | Value | Typical use |
|---|---:|---|
| `spaceXs` | `2` | Adjacent list rows and calendar cells |
| `spaceSm` | `4` | Bar widgets and tightly related controls |
| `spaceMd` | `8` | Content within a compact control |
| `spaceLg` | `12` | Sections and horizontal control padding |
| `spaceXl` | `16` | Panel padding |

`panelGap` remains a semantic ten-pixel distance between a bar trigger and its panel. Components should use this small scale rather than adding arbitrary six-, fourteen-, or twenty-four-pixel gaps.

### Shared dimensions

| Token | Value | Use |
|---|---:|---|
| `barHeight` | `44` | Visible bar surface |
| `edgeMargin` | `12` | Vertical screen-to-bar gutter |
| `barHorizontalMargin` | `36` | Horizontal screen-to-bar gutter |
| `controlHeight` | `34` | Normal bar control |
| `compactControlSize` | `28` | Close and compact navigation controls |
| `rowHeight` | `40` | Selectable panel row |
| `panelPadding` | `16` | Panel content inset |
| `panelGap` | `10` | Anchor-to-panel distance |
| `borderWidth` | `1` | Normal border and separator |
| `focusWidth` | `2` | Keyboard-focus indicator |
| `radius` | `2` | Standard corner radius |
| `sliderTrackHeight` | `6` | Continuous-value track |

Panel widths and content-specific sizes remain component defaults, not global theme tokens. The calendar may prefer 360 pixels and audio 460 pixels, but both must clamp or adapt to the target output.

### Motion

| Token | Value | Use |
|---|---:|---|
| `motionFast` | `80 ms` | Hover and pressed-state color transitions |
| `motionSurface` | `120 ms` | Panel and OSD opacity transitions |
| `motionEasing` | out-cubic | Nonessential surface transitions |
| `motionReduced` | `0 ms` | Effective duration under reduced motion |

Selection, keyboard focus, errors, mute state, and live values must not wait for animation. OSD visibility time is behavioral policy rather than a theme token; the initial target is approximately 1.2 seconds after the last update.

## Component and state grammar

Components use a small shared state model instead of defining audio-specific, calendar-specific, or workspace-specific colors.

| State | Background | Border | Content |
|---|---|---|---|
| Rest | Transparent within a surface | `borderInteractive` when a boundary is needed | `text` |
| Hover | `surfaceRaised` | `borderInteractive` | No layout or font-weight change |
| Pressed | `surfaceRaised` | `accentMuted` | Immediate; no movement or scaling |
| Active/open | `surfaceRaised` | `accent` | Explicit open or active marker |
| Selected/current | `accent` | `accent` | `textOnAccent` plus a textual/shape cue |
| Disabled | Transparent or unchanged surface | `border` | `textDisabled`; no hover or press response |
| Loading | Stable surface | `border` | Concise `textMuted` status |
| Error | Normal dark surface | `danger` | `danger` message or label |
| Keyboard focus | Existing state remains visible | Two-pixel focus indicator | Never replaced by hover |

State composition follows these rules:

1. Disabled suppresses hover and pressed styling.
2. Selection persists while hovered or focused.
3. Error styling is not erased by hover.
4. Focus is an overlay, not an alternative to selection or hover.
5. On an amber-filled selected item, focus uses a dark inset indicator or cursor so it remains distinguishable from the fill.
6. Pointer hover never masquerades as keyboard focus.
7. Non-interactive content must not gain hover styling.

## Reference components

### Bar

The bar uses:

- a transparent outer window;
- twelve-pixel top and bottom gutters;
- thirty-six-pixel horizontal gutters;
- a 44-pixel `surface` frame;
- one-pixel `border`;
- two-pixel radius;
- 34-pixel controls separated by four pixels.

Workspace buttons use a 32-pixel visual width. The focused workspace uses an amber fill, dark text, and bold weight. Occupied and empty workspaces remain distinguishable without pretending that either is focused.

The clock remains visually centered. Its open calendar state uses `surfaceRaised` with an amber border rather than turning the entire clock amber.

Audio shows an honest unavailable label instead of `0%` when PipeWire or the default output is absent. Muted state includes `MUTE` or `OFF`; red alone is insufficient.

### Anchored panels

All panels share:

- `surface` background;
- one-pixel outer border;
- two-pixel radius;
- sixteen-pixel padding;
- uppercase amber heading;
- visible 28-pixel close control;
- one-pixel section separators;
- predictable keyboard focus;
- stable loading, empty, and error frames.

The frame remains available when its domain service fails, so Escape and the close control always work.

#### Audio panel

The initial audio panel prefers a 460-pixel width.

- Volume controls show a six-pixel bordered track and a compact rectangular handle.
- The percentage remains visible beside the slider.
- Device rows are 40 pixels high.
- The selected device uses amber fill, dark text, and `IN USE` or an equivalent marker.
- Missing input devices remove the input section.
- Action failures appear inline without closing the panel.
- The deferred application-stream section is not rendered as a placeholder.

#### Calendar panel

The calendar prefers a 360-by-390-pixel frame.

- Month navigation uses compact square controls.
- Today uses amber fill and dark text.
- Weekday labels use muted small text.
- Calendar days are reference content in the first coherent version; non-actionable days must not show hover or pressed states.
- Month changes retain a stable grid and focus order.

### Volume OSD

The volume OSD is a compact, click-through, non-focus-stealing surface on the output where the action originated.

It contains:

- a short label such as `VOL` or `MUTE`;
- the numeric percentage when available;
- the same six-pixel level track used by the audio panel;
- a near-black surface, one-pixel border, two-pixel radius, and twelve-pixel padding.

It updates in place while adjustments continue, begins its timeout after the last update, and uses only a short opacity transition. Muted and unavailable states include text rather than relying on color or an empty meter.

## Accessibility requirements

The canonical theme itself must be accessible; accessibility is not deferred to a separate theme.

- Normal and secondary functional text target at least 4.5:1 contrast.
- Functional boundaries and focus indicators target at least 3:1 contrast.
- Decorative borders are not used as the sole cue for an interactive control.
- Every keyboard-focusable control has a visible focus state.
- Tab order follows visual order; lists additionally support arrows or `j`/`k`.
- Continuous controls support left/right or `h`/`l`.
- Enter and Space activate the focused control.
- Interactive hit areas are at least 28 by 28 pixels; selectable rows remain 40 pixels high.
- Every symbolic control has an accessible name, role, current state, and value where relevant.
- Disabled controls do not respond to pointer or keyboard input.
- Hover-only actions are prohibited.
- Long device names elide visually but retain their complete accessible name.
- Panels must remain usable under compositor scaling and must scroll or adapt instead of clipping controls.
- Reduced motion sets nonessential transition durations to zero.
- Errors, selection, mute, and unavailable states always have a non-color cue.

## Supported theme variation

### First coherent version

Rashell ships three built-in dark themes:

- `ember` — near-black with amber/gold accent; default and canonical screenshot direction;
- `raven` — near-black blue with periwinkle accent;
- `jade` — near-black green with jade accent.

The `theme` key selects one name. A valid config hot reload changes the complete semantic palette atomically. All themes must satisfy the same contrast and non-color state requirements.

Themes do not control:

- component structure;
- spacing or density;
- border widths or radius;
- panel placement and dimensions;
- state precedence;
- focus visibility;
- accessibility behavior;
- animations beyond the shared duration roles.

## Token policy

New visual tokens are added only when:

1. at least two components share the role; or
2. a distinct role is required for state clarity or accessibility.

Components must not add raw colors, private palette objects, or component-specific hover colors. Transparent fill and content-driven sizes are permitted where they express structure rather than theme.

## Explicit non-goals

The first coherent version does not include:

- light themes or automatic light/dark switching;
- external theme files, discovery, or user-defined palette schemas;
- wallpaper-derived, Material-generated, or community palettes;
- a theme marketplace, installer, or compatibility ecosystem;
- whole-system theming of Hyprland, terminals, editors, or applications;
- per-widget colors, CSS-like overrides, or user-supplied QML delegates;
- configurable radii, borderlessness, density modes, or alternative panel chrome;
- gradients, shadows, blur, glass surfaces, or decorative translucency;
- icon-pack selection or a new icon-font dependency;
- animated palette changes, spring motion, or a general animation framework;
- success, warning, chart, notification, or modal token families before included components require them;
- visual placeholders for deferred features such as application-stream mixing;
- treating the current internal token names as a public plugin API.

---

## Concise closing comment

> **Decision:** Rashell’s first coherent version has one canonical visual grammar and three built-in dark themes—`ember`, `raven`, and `jade`. `Theme.qml` owns semantic colors plus fixed typography, spacing, dimensions, and state behavior. Configuration may select a built-in palette, while geometry, density, focus, accessibility, and component composition remain fixed. Every palette must meet contrast requirements and every important state has a non-color cue. External themes, light mode, per-widget styling, palette generation, marketplace, and whole-system theming remain unsupported.