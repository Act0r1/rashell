# Issue #9 — Low-Fidelity Composition Prototype

**Status:** Planning-only specification  
**Scope:** Rashell’s **first coherent version**  
**Source basis:** All documents under `docs/research/` and `docs/architecture/` were reviewed. Where they conflict, `docs/architecture/consistency-review.md` is authoritative.

## Prototype conclusion

**Yes—with the contracts below.** The composition is understandable and cohesive across normal, loading, empty, disconnected, error, and multi-monitor states when:

- every monitor receives the same three-zone bar composition;
- workspaces, clock/calendar, and audio are first-party modules;
- the clock is geometrically centered rather than centered between unequal side zones;
- one global `PanelCoordinator` owns all anchored-panel lifecycle;
- panels open on the invoking or focused output and never migrate after output loss;
- workspace focus is output-local while audio and time state are shared;
- unavailable state is explicit rather than represented as valid zero or empty data;
- the calendar remains a pure month-reference surface;
- audio includes output and available input controls only, with no per-application streams;
- the volume OSD and Rashell feedback overlay remain independent, non-interactive overlays.

This prototype validates the surface model. It does not imply that the behavior has been implemented.

---

## 1. Surface composition and ownership

| Surface | Instances | Owner | Focus | Role |
|---|---:|---|---|---|
| Three-zone bar | One per connected output | Core | Does not take focus | Persistent orientation and task entry |
| Workspace view | One per bar | Workspaces first-party module | No bar focus | Show and request workspace focus |
| Clock view | One per bar | Clock/calendar first-party module | No bar focus | Time reference and calendar trigger |
| Audio view | One per bar | Audio first-party module | No bar focus | Output volume/mute summary and audio trigger |
| Anchored panel | At most one globally active | `PanelCoordinator` | Takes focus while open | Calendar or audio task |
| Volume OSD | One global presentation on the event’s output | Core | Click-through | Direct volume-adjustment feedback |
| Rashell feedback overlay | One global presentation on the event’s output | Core | Click-through | Rashell-originated failure or confirmation |

The global panel slot is a behavioral guarantee. It does not prescribe the number of internal QML window objects.

Domain state is not duplicated per bar:

- one shared Hyprland-backed workspace model;
- one shared clock/calendar model;
- one shared PipeWire-backed audio model;
- per-monitor widgets are views over those models.

---

## 2. Canonical visual frame

Reference dimensions:

| Element | Prototype rule |
|---|---|
| Bar | 44 px high |
| Bar placement | 12 px from the top; 36 px from each horizontal edge |
| Bar zones | Left-aligned, independently centered, right-aligned |
| Panel gap | 10 px below its trigger |
| Panel edge clamp | At least 12 px inside the target output |
| Calendar panel | Prefers 360 × 390 px |
| Audio panel | Prefers 460 px wide; height follows content |
| Borders/radius | 1 px border, 2 px radius |
| Typography | Monospace; uppercase section headings |
| Surfaces | Near-black layers, no blur, shadow, gradient, or glass |
| Accent | Amber for active, selected, progress, and keyboard focus |
| Error | Danger color plus readable error text |
| Motion | Immediate state changes; optional 120 ms opacity transition |

Panels clamp or adapt to the target output and never intentionally straddle outputs. Content scrolls when scaling or available height would otherwise clip controls.

### State notation used below

```text
[*1*]  workspace focused on this output
[ 2+]  occupied but not focused here
[ 3 ]  empty
> row  selected device, also labelled IN USE
>>     keyboard focus; distinct from hover and selection
```

---

## 3. One three-zone bar per monitor

The center lane is anchored to the physical midpoint of the output. It does not shift when left or right content changes width.

```text
Monitor A
+--------------------------------------------------------------------------------------+
| +----------------------------------------------------------------------------------+ |
| | [*1*] [ 2+] [ 3 ] [ 4 ]       |       TUE 12 MAR 14:38       |       VOL 62% | |
| +----------------------------------------------------------------------------------+ |
|                                      ^ exact output center                             |
|                                                                                       |
|                              application workspace                                    |
|                                                                                       |
+--------------------------------------------------------------------------------------+

Monitor B
+--------------------------------------------------------------------------------------+
| +----------------------------------------------------------------------------------+ |
| | [ 1+] [ 2 ] [*3*] [ 4 ]       |       TUE 12 MAR 14:38       |       VOL 62% | |
| +----------------------------------------------------------------------------------+ |
|                                      ^ exact output center                             |
|                                                                                       |
|                              application workspace                                    |
|                                                                                       |
+--------------------------------------------------------------------------------------+
```

Both bars show the same effective workspace ID set and the same configured first-party module order. Each workspace view highlights the workspace active on its own output.

Audio and clock state are shared. A change made from either monitor updates both bars.

If side content approaches the center lane, side labels compact or elide before the clock moves. The clock’s center anchor remains authoritative.

---

## 4. Workspace module

The workspace module has no panel. It completes its task directly from the bar.

```text
Normal:       [*1*] [ 2+] [ 3 ] [ 4 ]
All empty:    [*1*] [ 2 ] [ 3 ] [ 4 ]
Loading:      [ 1.] [ 2.] [ 3.] [ 4.]    disabled
Disconnected: [ WORKSPACES UNAVAILABLE ] disabled
Module error: [ WORKSPACES ! ]           diagnostic available
```

### Workspace interaction

| Input | Result |
|---|---|
| Primary click on a workspace | Request that Hyprland focus that workspace |
| External keyboard/IPC workspace action | Validate the workspace ID, then make the same request |
| Hover | Show hover only; never imply focus |
| Failed request | Leave reported state unchanged; show Rashell feedback on the originating output |
| Hyprland update | Re-render from compositor state; do not predict success locally |

The normal bar does not become keyboard-focusable. Rashell installs no Hyprland bindings; external bindings may invoke the minimal action.

---

## 5. Centered clock and pure month-reference calendar

### Closed clock

```text
                     |       TUE 12 MAR 14:38       |
                                      ^
                               output center
```

The clock is a status value and calendar trigger. It does not contain agenda, alarm, event, weather, or reminder state.

### Open calendar

The panel centers on the invoking clock and clamps to that output.

```text
                              clock trigger
                                   |
                                   v
                     +------------------------------------+
                     | CALENDAR                       [X] |
                     |                                    |
                     | [<]         MARCH 2025         [>] |
                     |                                    |
                     | MON  TUE  WED  THU  FRI  SAT  SUN  |
                     |                          1    2     |
                     |  3    4    5    6    7    8    9  |
                     | 10   11  [12]  13   14   15   16  |
                     | 17   18   19   20   21   22   23  |
                     | 24   25   26   27   28   29   30  |
                     | 31                                 |
                     +------------------------------------+
```

`[12]` represents today using amber fill and a non-color cue.

Calendar rules:

- every fresh opening starts on the current month;
- previous/next changes only the displayed month;
- today is highlighted only when present in the displayed month;
- days are reference text, not selectable controls;
- there are no events, agenda rows, reminders, scheduling actions, or date details;
- navigating months does not close the panel.

### Calendar keyboard flow

1. Opening focuses the previous-month button.
2. `Tab` and `Shift+Tab` traverse previous month, next month, and close.
3. `Enter` or `Space` activates the focused button.
4. Left/right arrows on month navigation move to the previous/next month.
5. `Escape` closes the panel.

---

## 6. Audio bar and panel

### Audio bar states

```text
Normal:       VOL 62%
Muted:        MUTE 62%
Zero:         VOL 0%
Loading:      AUDIO ...
Disconnected: AUDIO UNAVAILABLE
Module error: AUDIO !
```

Absence is never rendered as a fictional `0%` or muted state.

Primary click opens the audio panel. Pointer wheel adjustment is an accelerator, not the only way to change volume.

### Normal audio panel

```text
audio trigger ------------------------------------------------------+
                                                                    |
                         +------------------------------------------+
                         | AUDIO                                [X] |
                         |                                          |
                         | OUTPUT                                   |
                         | [===========------] 62%       [ MUTE ]   |
                         |                                          |
                         | > Built-in Audio                 IN USE  |
                         |   USB Headset                            |
                         |   HDMI Display                           |
                         |------------------------------------------|
                         | INPUT                                    |
                         | [=======----------] 41%       [ MUTE ]   |
                         |                                          |
                         | > USB Microphone                 IN USE  |
                         |   Webcam Microphone                      |
                         +------------------------------------------+
```

There is deliberately no application-stream heading, empty stream state, placeholder, or reserved space.

### Audio keyboard flow

Initial focus:

- output slider when a usable output exists;
- otherwise the close control.

Tab order:

1. output slider;
2. output mute;
3. output-device list;
4. input slider, when available;
5. input mute, when available;
6. input-device list, when available;
7. close.

Control behavior:

| Focused control | Keys |
|---|---|
| Slider | Left/right adjusts by the prototype step; pointer drag sets directly |
| Mute | `Enter` or `Space` toggles |
| Device list | Up/down moves the cursor; `Enter` or `Space` selects |
| Any control | `Tab`/`Shift+Tab` traverses; `Escape` closes |

Pointer and keyboard routes call the same audio operations. Selecting a device or adjusting volume leaves the panel open.

Changes made inside the open audio panel do not show the volume OSD because the panel already gives sufficient feedback.

---

## 7. Global `PanelCoordinator`

### State transitions

| Current state | Invocation | Required result |
|---|---|---|
| Closed | Bar trigger | Open on that exact bar output and anchor |
| Closed | Keyboard/IPC toggle | Open on focused Hyprland output; otherwise first available output |
| Calendar open | Same clock trigger | Close |
| Audio open | Same audio trigger | Close |
| Calendar open | Audio trigger | Atomically replace with audio; no focus flash |
| Audio open | Clock trigger | Atomically replace with calendar |
| Panel open on A | Same module trigger on B | Re-anchor atomically to B; do not toggle closed |
| Panel open | `Escape` or close control | Close and restore the captured application when valid |
| Panel open | Outside click/focus | Close without reclaiming focus |
| Panel open | Anchor or target output removed | Close; never migrate to another output |
| Panel open | Owning module fails/unloads | Close and expose a targeted diagnostic |

### Opening and focus

- The bar itself never enters a broad keyboard focus grab.
- An opened panel becomes the active keyboard focus scope.
- Focus begins on the first meaningful enabled task control.
- If the panel opens while loading, close receives focus.
- When data arrives, focus does not jump automatically.
- Keyboard focus remains visibly distinct from pointer hover and selected state.
- Opening another panel transfers focus directly without briefly returning to the application.

### Dismissal transaction

The trigger click and panel opening are treated as one interaction transaction. Focus loss caused by opening must not immediately dismiss the panel.

Panel operations and inline errors do not implicitly close it.

---

## 8. Multi-monitor behavior

| Event | Exact behavior |
|---|---|
| Output connects | Create one bar with the same configured composition and shared state |
| Output disconnects | Destroy that bar; close a panel anchored to it |
| Non-panel output disconnects | Keep the active panel unchanged |
| Workspace state changes | Every bar updates; each highlights its own output’s active workspace |
| Bar trigger on output A | Anchor the panel to that exact trigger on A |
| Keyboard/IPC panel action | Use focused Hyprland output; otherwise first output in the current output list |
| Invalid/lost focused output | Fall back only at invocation time; do not migrate an already-open panel |
| Panel would cross an edge | Slide or clamp within the invoking output |
| Audio changes on one output | Update all bars from shared PipeWire state |
| Direct volume action | Show OSD on the action’s resolved origin output |
| Output containing OSD disappears | Hide the OSD; do not move it |
| Output containing feedback disappears | Hide the feedback; do not move it |

There is no per-monitor configuration, most-recent-output tracker, or explicit output-name IPC argument in the first coherent version.

---

## 9. Volume OSD

The volume OSD is bottom-centered on the output where a direct adjustment originated, approximately 48 px above the usable bottom edge.

```text
                         +-----------------------------+
                         | VOL 62%  [===========-----] |
                         +-----------------------------+
```

```text
                         +-----------------------------+
                         | MUTE 62% [===========-----] |
                         +-----------------------------+
```

Rules:

- click-through and non-focus-stealing;
- independent of the `PanelCoordinator` slot;
- shown for bar scroll or external direct volume/mute actions;
- not shown for changes made inside the open audio panel;
- updates in place and resets its approximately 1.2-second timeout;
- the newest event determines its output;
- unavailable or failed operations use Rashell feedback instead of a misleading meter.

---

## 10. Rashell feedback overlay

The Rashell feedback overlay is for Rashell-originated confirmation or failure, not desktop application notifications.

```text
                                                        +---------------------------+
                                                        | AUDIO: device unavailable |
                                                        +---------------------------+
```

It appears near the lower-right edge of the event’s output. If it would collide with the bottom-centered OSD, it stacks above the OSD with a 12 px gap.

Rules:

- non-interactive, click-through, and non-focus-stealing;
- concise text with an explicit error or confirmation cue;
- newest global message replaces the previous message and resets expiry;
- panel-originated errors remain inline instead;
- configuration, module loading, IPC, or direct-action failures may use it;
- no history, actions, grouping, DND, or notification-daemon behavior.

---

## 11. State matrix

| State | Workspace module | Clock/calendar module | Audio module |
|---|---|---|---|
| **Normal** | IDs show focused, occupied, and empty states | Clock shows time; panel shows current/navigated month | Volume/mute and current output; available input section |
| **Loading** | Stable disabled workspace placeholders | Stable clock/panel frame with concise loading text | Stable panel chrome; controls disabled; close remains available |
| **Empty** | Empty workspace buttons remain visible and selectable | Not applicable: a month is never an empty product state | No outputs shows explicit empty state; no input omits input section |
| **Disconnected** | `WORKSPACES UNAVAILABLE`; focus requests disabled | Not applicable to an external service; invalid local time is an error | `AUDIO UNAVAILABLE`; panel remains open, dismissible, and retries on reconnect |
| **Error** | Compact module indicator or action feedback; reported state retained | Stable panel with readable error and close control | Inline panel error; outside-panel failure uses Rashell feedback |

### Audio edge states

| Condition | Presentation and behavior |
|---|---|
| No output devices | “No output devices”; no percentage, slider, mute, or selectable stale row |
| No input devices | Omit the entire input section |
| One output/input | Show it explicitly as `IN USE`; do not imply alternatives |
| PipeWire reconnecting | Keep panel frame; show unavailable/reconnecting state |
| Device disappears | Remove it immediately and derive the new default from PipeWire |
| Focused row disappears | Move focus to the nearest surviving control in that section, otherwise close |
| Selection fails | Keep prior reported selection and show an inline error |
| Volume operation fails outside panel | No OSD; show Rashell feedback |
| Application streams absent | No state or UI exists because streams are outside scope |

### Shell-level failure states

| Condition | Result |
|---|---|
| Module loading | Preserve its slot with a compact loading indicator |
| Module load failure | Compact labelled error indicator; unrelated modules and bars remain usable |
| Invalid configuration at startup | Use complete in-code defaults and report the problem |
| Invalid hot reload | Retain the current valid in-memory snapshot and report the problem |
| Panel anchor loss | Close through `PanelCoordinator` and release focus safely |
| Feedback/OSD unavailable | Do not block or alter the underlying domain action |

No process-crash isolation is promised for in-process QML.

---

## 12. Prototype findings and required implementation reactions

| Prototype finding | Required change |
|---|---|
| Independent widget-owned panels make cross-monitor behavior ambiguous | Replace module-owned popup lifecycle with one global `PanelCoordinator` |
| Per-monitor audio instances risk divergent tracking and selection state | Construct one root-level audio state and render it through every bar |
| A normal row layout cannot guarantee a truly centered clock | Give the center zone an independent physical center anchor |
| Workspace focus cannot be globally highlighted on every monitor | Highlight the active workspace separately for each output |
| “Plugin” terminology implies an unsupported public contract | Treat audio, workspaces, and clock/calendar as first-party modules |
| The current calendar can become a broader status surface accidentally | Limit it to current month, today, previous, and next |
| Stream placeholders make deferred functionality look broken | Remove all per-application stream discovery, states, controls, and reserved UI |
| A single unavailable audio value can be mistaken for zero volume | Add distinct loading, empty-output, disconnected, and action-error states |
| Keyboard behavior cannot remain module-specific | Share conventional focus, Tab, arrows, activation, and Escape behavior |
| Panel feedback and direct-action feedback have different needs | Keep panel errors inline; use OSD or Rashell feedback outside panels |
| Overlays could compete with panels or each other | Keep them outside the panel slot and assign deterministic output/placement rules |
| Output loss cannot safely trigger fallback migration | Close the anchored panel and overlays on that output |
| General action/extension infrastructure is unnecessary | Implement only current panel toggle/close, workspace, volume, mute, and device operations |
| Vim aliases add scope without improving the basic prototype | Defer `j`/`k` and `h`/`l` aliases |

---

## 13. Planning acceptance criteria

The composition is ready to guide implementation when all of the following are treated as requirements:

- [ ] One identical three-zone bar appears on every connected output.
- [ ] The clock remains geometrically centered under unequal side-zone widths.
- [ ] Workspaces use output-local focus and shared Hyprland truth.
- [ ] Only one panel is active globally through `PanelCoordinator`.
- [ ] Calendar and audio panels anchor to the correct output and never straddle it.
- [ ] Pointer and basic keyboard workflows produce equivalent domain actions.
- [ ] Every panel remains dismissible while loading, empty, disconnected, or errored.
- [ ] Audio includes output and available input controls only.
- [ ] No per-application stream UI or state exists.
- [ ] Calendar remains a pure month-reference surface.
- [ ] Direct volume adjustments show the volume OSD on their origin output.
- [ ] Panel errors are inline; other Rashell failures use the Rashell feedback overlay.
- [ ] Output removal closes affected transient surfaces without migration.
- [ ] First-party module failures remain visible without silently removing unrelated UI.
- [ ] The document remains planning-only and makes no implementation-completion claim.

## Concise issue-closing comment

> Planning resolution: the low-fidelity prototype validates Rashell’s first coherent version as one three-zone bar per monitor with output-local workspace focus, a truly centered clock and pure month-reference calendar, output/input-only audio, one global `PanelCoordinator`, a volume OSD, and a non-interactive Rashell feedback overlay. It defines pointer/basic keyboard flows, focus and dismissal, exact multi-monitor routing, and honest loading, empty, disconnected, and error states. Required implementation reactions include shared root-level domain state, host-owned panel lifecycle, removal of all per-application stream UI, true center anchoring, and deterministic output-loss behavior. No implementation completion is implied.