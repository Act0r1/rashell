# Rashell visual system

Current implementation reference. Sources: [`Theme.qml`](../../core/Theme.qml),
[`themes.json`](../../core/themes.json), [`ConfigStore.qml`](../../core/ConfigStore.qml),
and the shared [`ui`](../../ui/) primitives. Values below are QML pixels unless marked otherwise.

## Theme catalog and resolution

| ID | Name |
|---|---|
| `raven` | Raven |
| `dusk` | Dusk |
| `tokyonight` | Tokyo Night |
| `tokyostorm` | Tokyo Storm |
| `ayu-dark` | Ayu Dark |
| `ayu-mirage` | Ayu Mirage |

All six entries have `kind: "dark"`. `ConfigStore.defaults.theme` and
`Theme.activeName` default to `ayu-dark`; config validation accepts only `Theme.names`.
`shell.qml` binds `activeName` and `selectedFontFamily` to the effective configuration.

`catalogFile` loads `core/themes.json`; `catalog` parses it, `names` extracts IDs,
and `palettes` indexes palettes by ID. `themeInfo(name)` returns the matching entry,
then Ayu Dark, then the first entry if Ayu Dark is absent. `paletteFor(name)` falls
back to Ayu Dark for an unknown name and returns a copy with these effective overrides:

- `accentMuted = source.accentSecondary || source.accentMuted`;
- `danger = source.dangerText || source.danger`;
- `borderInteractive = source.borderControl || source.borderInteractive`.

`palette` is `paletteFor(activeName)`. Every catalog palette contains these 19 keys:
`background`, `surface`, `surfaceRaised`, `accent`, `accentMuted`, `accentSecondary`,
`text`, `textMuted`, `textDisabled`, `textOnAccent`, `border`, `borderInteractive`,
`danger`, `textOnDanger`, `dangerText`, `borderControl`, `success`, `warning`, `info`.
The catalog also carries `description`, `syntax`, and `terminal` data; these are
not additional shell color tokens. Read palette literals in the catalog rather
than assuming a fixed amber identity.

## Tokens

### Colors

Unless noted, each token reads the same-named key from the effective `palette`.

| Token | Role / resolution |
|---|---|
| `background` | Canvas and dark backing |
| `surface` | Normal panel/control surface |
| `surfaceRaised` | Raised content, including ActionButton tooltips |
| `accent` | Selection, active emphasis, level fill |
| `accentMuted`, `accentSecondary` | Both read effective `palette.accentMuted` |
| `text` | Primary content |
| `textMuted` | Secondary content |
| `textDisabled` | Disabled content |
| `textOnAccent` | Content on solid accent fill |
| `border` | Normal frame/control border |
| `borderInteractive` | Interactive boundary; uses the override above |
| `focus` | Alias of `palette.accent` |
| `danger` | Negative/error emphasis; uses the override above |
| `textOnDanger` | Content on danger fill |
| `success`, `warning`, `info` | Semantic status colors; each falls back to `palette.accent` if missing |

Derived surfaces use `Qt.tint(surface, Qt.alpha(color, alpha))`:

| Token | Tint color | Alpha |
|---|---|---:|
| `hoverSurface` | `accent` | 0.06 |
| `pressedSurface` | `accent` | 0.16 |
| `selectedSurface` | `accent` | 0.10 |
| `selectedHoverSurface` | `accent` | 0.13 |
| `selectedPressedSurface` | `accent` | 0.20 |
| `dangerSurface` | `danger` | 0.10 |

`accentHover = Qt.lighter(accent, 1.08)` and
`accentPressed = Qt.darker(accent, 1.08)`.

### Typography

`selectedFontFamily` defaults to `"Adwaita Sans"`, as does the configuration.
`fontFamilies` is `Qt.fontFamilies()`. `fontFamily` uses the selected family only
if present in that list; otherwise it returns `"Adwaita Sans"`. That fallback
string does not guarantee the font is installed.

| Token | Value |
|---|---|
| `fontSmall` | 12 |
| `fontBody` | 14 |
| `fontTitle` | 17 |
| `fontDisplay` | 24 |
| `fontHero` | 40 |
| `fontWeightRegular` | `Font.Normal` |
| `fontWeightStrong` | `Font.DemiBold` |

### Spacing and geometry

| Token | Value |
|---|---|
| `spaceXs`, `spaceSm`, `spaceMd`, `spaceLg`, `spaceXl` | 2, 4, 8, 12, 16 |
| `panelGap` | 8 |
| `panelPadding` | 16 |
| `controlHeight` | 32 |
| `compactControlSize` | 30 |
| `rowHeight` | 40 |
| `barHeight` | 40 |
| `edgeMargin` | 4 for `raven`, otherwise 0 |
| `barHorizontalMargin` | `edgeMargin` |
| `radius` | 12; outer panels (`PanelFrame`) |
| `radiusSmall` | 8; inner controls and tooltips |
| `borderWidth` | 1 |
| `focusWidth` | 2 |
| `sliderTrackHeight` | 8 |

`metricsFor(name)` converts the name to a string and returns
`{ radius: 12, barHeight: 40, edgeMargin: name === "raven" ? 4 : 0, sliderTrackHeight: 8 }`.
`metrics = metricsFor(activeName)` supplies those four tokens. This function does
not validate names: an unknown name gets zero margin even though its palette
falls back to Ayu Dark. Component-specific dimensions are not all global tokens.

### Motion

| Token | Value |
|---|---|
| `motionFast` | 120 ms |
| `motionSurface` | 220 ms |
| `motionEasing` | `Easing.OutCubic` |

These are shared transition values, not an automatic animation policy.
The primitives below do not declare animated state transitions. There is no
`motionReduced` token in `Theme.qml`; do not infer a global reduced-motion mode.

## Shared primitives

### ActionButton

`ActionButton` is a Qt Quick Controls `Button`, non-flat by default, with
`radiusSmall`, height `compactControlSize`, and width at least that size or
content width plus twice `spaceLg`. Content uses `fontFamily`/`fontBody`, one-line
elision, configurable alignment (center by default), and strong weight when selected.

For an ordinary enabled, non-selected, non-danger button:

| State | Fill | Border | Text |
|---|---|---|---|
| Rest | `surface`, or transparent if `flat` | `border` | `text` |
| Hover | `hoverSurface` | `borderInteractive` | `text` |
| Pressed (`down`) | `pressedSurface` | `accent` | `text` |
| Selected | `accent` / `accentHover` / `accentPressed` | `accent` | `textOnAccent` |
| Selected + `subtleSelected` | `selectedSurface` / `selectedHoverSurface` / `selectedPressedSurface` | `accent` | `accent` |

The selected triples are rest / hover / pressed; pressed takes precedence over
hover. `subtleSelected` has no effect without `selected`.

Composition follows the actual bindings:

- Fill precedence: solid selected, subtle selected, down, hovered, flat/rest.
- Border color precedence: `visualFocus`, danger, selected/down, hovered, rest.
  Danger sets the border to `danger` but does not add a danger fill.
- Text precedence: solid selected, subtle selected, danger, enabled, disabled.
  Thus `danger` text wins over disabled, and selected text wins over danger.
- Disabled ordinary text uses `textDisabled`. There is no explicit disabled fill,
  border, or opacity branch, and no `enabled` guard in the fill expression;
  input behavior comes from the underlying `Button`.
- Focus uses `focusWidth` and `focus`, except solid selection uses `textOnAccent`
  for its focus border. It leaves the existing fill intact.
- Otherwise border width is `borderWidth` when non-flat, hovered, or down, and
  zero for flat rest. Selection/danger alone do not make a flat rest border visible.

`accessibleName` defaults to `text`; the role is `Accessible.Button`.
`toolTipText` defaults to the accessible name. The tooltip appears on hover when
nonempty, with 450 ms delay and 5000 ms timeout, above the button by `spaceSm`.
It uses `surfaceRaised`, an `accentMuted` border, `radiusSmall`, `fontSmall`,
horizontal `spaceLg` padding and vertical `spaceMd` padding.

### PanelFrame and CloseButton

`PanelFrame` supplies a `surface` background, `borderWidth`/`border` outline,
`radius`, and `panelPadding` inset. Its required title uses `text`, `fontTitle`,
and `fontWeightStrong`, with elision. Default `contentWidth` is 360; the body is a
column with `spaceLg` spacing. Implicit height is header height + body implicit
height + twice `panelPadding` + `spaceLg`. The header is at least
`compactControlSize` tall and accommodates the close button. Closing emits
`closeRequested()`; the frame itself does not implement dismissal or keyboard routing.

`CloseButton` is `controlHeight` square, or a literal 24 square when `compact`.
Its X is drawn from two rotated rectangles, not an icon font or `ShellIcon`.
Rest uses transparent fill and `textMuted`; hover, down, or focus makes the X
`text`. Down uses `pressedSurface`; hover/focus uses `hoverSurface`. Only focus
adds a `focusWidth`/`focus` border. Radius is `radiusSmall`, capped at 6 when
compact. It exposes an accessible button name (`"Close"` by default).

### LevelSlider

`LevelSlider` defaults to range 0–1, step 0.05, and height `controlHeight`.
The track is `sliderTrackHeight` tall with `borderInteractive` backing; fill uses
`accent` (disabled: `textDisabled`) and follows `position`, reversing its origin
when mirrored. The `spaceXl` square handle follows `visualPosition` and uses
`text` at rest, `accent` while pressed/hovered/focused, or `textDisabled` when disabled.
Its border is `background`/`borderWidth`, or `focus`/`focusWidth` when focused.
Track and handle radii are capped at half their respective size, making them round.
Accessible role is slider, name defaults to `"Level"`, and description defaults to
rounded `value * 100` plus `" percent"`; override that description for other ranges.

### ShellIcon and BarToolTip

`ShellIcon` renders Lucide SVG markup from its embedded `glyphs` map, with
`name: "sliders-horizontal"`, `tint: Theme.text`, and implicit size 18 × 18.
It replaces `currentColor` with the tint, encodes a data URL, preserves aspect
ratio, and requests twice the display size. Unknown names fall back to
`sliders-horizontal`. The component does not load the asset directory at runtime.

To add an icon, add its SVG to `assets/icons/lucide/` (retain the license), then
add matching SVG text under its name in `ShellIcon.qml`'s `glyphs` map. Keep
`currentColor` for tinting. Adding only the asset does not register it. Use
`ShellIcon { name: "…"; tint: Theme.text }` in the component and give the
surrounding control an accessible name. The map also contains an inline `monitor`
icon with no matching asset file.

`BarToolTip` uses a separate popup window below its parent, 500 ms delay,
5000 ms timeout, `spaceMd` margins/padding, and a maximum implicit width of 320.
Text uses `fontSmall`, wrapping/elision up to three lines. Its surface uses
`surface`, `borderInteractive`, `borderWidth`, and `radiusSmall`.

## Known exceptions and migration work

- `modules/lock` has its own ii-pixel language: Roboto, bundled Material Symbols
  Rounded, shape effects, and local animations (including OutBack easing).
  It is not governed uniformly by the shell primitives above.
- Decorative/ambient motion is not fully tokenized: weather scenes use local
  durations (for example 1100 ms in `GlassPane.qml` and long cloud loops in
  `CityScene.qml`); the recording pulse in `ScreenshotBar.qml` uses 600 ms legs.
- Nerd Font/private-use glyphs remain pending migration to Lucide. The audit
  below counts **matching source lines**, not unique icons or glyph occurrences.
  It includes appearance, audio, media, and tray in addition to weather, control
  center, Bluetooth device types/status, network, and screenshot controls.

Reproduce the glyph inventory with:

```sh
git grep -nP '[\x{F0000}-\x{FFFFD}\x{E000}-\x{F8FF}]' -- '*.qml' ':!modules/lock'
```

| File | Matching lines |
|---|---:|
| `modules/appearance/AppearancePicker.qml` | 1 |
| `modules/appearance/DesktopPreview.qml` | 2 |
| `modules/audio/AudioPanel.qml` | 3 |
| `modules/media/MediaBar.qml` | 1 |
| `modules/system/BluetoothPanel.qml` | 3 |
| `modules/system/BluetoothState.qml` | 7 |
| `modules/system/ControlPanel.qml` | 15 |
| `modules/system/NetworkPanel.qml` | 6 |
| `modules/system/ScreenshotBar.qml` | 1 |
| `modules/system/ScreenshotPanel.qml` | 5 |
| `modules/system/TrayBar.qml` | 1 |
| `modules/weather/WeatherState.qml` | 16 |

## Rules for new components

- Use semantic `Theme` colors, spacing, dimensions, typography, and motion tokens;
  do not add raw hex colors or literal font sizes. Transparent structural fills
  and content-specific geometry are distinct from palette choices.
- Use `radius` for outer panel frames and `radiusSmall` for inner controls.
  Reuse shared primitives before inventing another state grammar.
- Use `ShellIcon` for new icons, with accessible names on symbolic controls.
- Keep state understandable without color alone: pair status colors with readable
  labels, symbols, or shape/weight changes. This is a component responsibility,
  not a verified guarantee across the shell; `ActionButton` does not add a status
  label automatically. Preserve visible focus and explicit unavailable/error text.
- Use layered surfaces and typography for hierarchy, with bounded tasks and short
  labels. Do not treat the lock screen or ambient scenes as the default grammar.
