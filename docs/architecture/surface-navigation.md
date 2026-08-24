# Decision: Rashell surface and navigation model

**Status:** Resolved by GitHub issue #5  
**Scope:** Surface composition and interaction contracts, not implementation details

## Context

Rashell is a small personal Quickshell shell, not a desktop environment or general shell framework. Its primary UI is a three-zone bar on every monitor, with compact task panels opened from bar controls.

The current prototype lets each feature module create a `PopupWindow` and maintain its own `open` state. This already produces inconsistent behavior:

- Audio and calendar panels can be open independently.
- Escape handling differs between panels.
- Focus-grab behavior has been added and removed to fix interactions.
- Dismissal, focus restoration, and cross-monitor behavior are implicit.

These are ownership problems rather than isolated popup bugs. Surface hosting, focus, dismissal, anchoring, and routing must therefore be shell contracts.

## Decision

Rashell will use:

1. **One persistent three-zone bar per monitor.**
2. **Shell-hosted anchored task panels for status details and controls.**
3. **One globally active interactive transient surface at a time.**
4. **Non-interactive OSD and shell-feedback overlays that may coexist with a panel.**
5. **Direct action IDs as the common route for pointer controls, keyboard bindings, and IPC.**

Rashell will not initially provide a dashboard or top-level navigation hierarchy. Users move directly from a status or action to its destination.

## Surface taxonomy

| Surface | Purpose | Focus | Lifetime | Initial examples |
|---|---|---|---|---|
| **Bar** | Persistent glanceable status and task entry points | Does not take keyboard focus during normal use | One per connected monitor | Workspaces, clock, audio |
| **Anchored task panel** | Inspect or manipulate one domain in place | Interactive focus scope | Explicitly dismissed | Calendar, audio controls |
| **OSD** | Feedback for continuous adjustments | Never takes focus; click-through | Coalesces and expires automatically | Volume level and mute state |
| **Rashell feedback overlay** | Report a detectable Rashell-originated failure | Non-interactive and non-focus-stealing | Expires automatically | Action failed, config reload failed |
| **Global palette** | Search and invoke actions without a visible bar entry | Interactive focus scope | Explicitly dismissed | Deferred |
| **Modal confirmation** | Confirm an exceptional destructive operation | Exclusive keyboard focus | Decision required | Deferred with session actions |

Desktop application notifications are not Rashell feedback overlays. Rashell does not initially claim the freedesktop notification service.

## Persistent bar

Each connected output receives the same structural bar:

- **Left:** navigation and workspace state.
- **Center:** geometrically centered time and contextual status.
- **Right:** system status and controls.

The center remains physically centered regardless of the widths of the left and right zones. Widgets may hide when their capability is absent, but conditional widgets must not move the center anchor.

The bar is primarily a status surface. A primary click or keyboard action opens the associated task panel. Scroll and secondary clicks may accelerate obvious continuous operations such as volume changes, but every primary operation must also be discoverable and keyboard-accessible.

## Anchored task panels

Calendar and audio are anchored panels, not independent module-owned windows:

- The clock opens a month-reference calendar.
- The audio indicator opens output, input, mute, volume, and device controls.
- Panels perform their task directly rather than forwarding users into another shell surface.
- Rashell will not combine unrelated controls into a large “quick settings” dashboard.

The shell core owns the panel host and lifecycle. A module supplies panel identity, content, preferred dimensions, and actions; it does not own a separate persistent `open` boolean or implement global dismissal itself. This interaction boundary applies to every first-party module.

## One-open-surface coordination

A core `PanelCoordinator` is the sole authority for anchored panel state. Conceptually it owns:

- active surface ID;
- target output;
- anchor instance;
- invocation source;
- previous external focus target;
- open, replace, and close reason.

Only one anchored panel is open across the entire shell, not one per monitor.

- Invoking a closed panel opens it.
- Invoking the active panel from the same trigger toggles it closed.
- Invoking a different panel hides the old one before showing the replacement; two panels are never visible simultaneously.
- OSDs and the non-interactive feedback overlay do not occupy the slot.

## Focus and dismissal contract

### Opening

Every interactive panel becomes a keyboard focus scope regardless of whether it was opened by pointer, keybinding, or IPC.

- Keyboard navigation starts on the first meaningful enabled control.
- `Tab` and `Shift+Tab` traverse controls.
- Arrow keys or `j`/`k` move through lists.
- Left/right or `h`/`l` adjust continuous values where appropriate.
- `Enter` or `Space` activates the focused control.
- Every pointer-only accelerator has a keyboard equivalent.
- Keyboard focus has a visible state distinct from hover and selection.

The shell records the previously focused non-Rashell window before opening a panel. Core uses one host-owned `PopupWindow` with `grabFocus: true`; it does not add a broad custom focus grab around the bar.

### Dismissal

A panel closes when:

- `Escape` is pressed;
- its visible close control is activated;
- its active bar trigger is invoked again;
- another interactive surface is opened;
- the user clicks or focuses outside the panel and its opening interaction;
- its anchor or output disappears;
- its owning module unloads.

Audio and calendar operations do not implicitly close their panels. Errors also leave the panel open so the user can understand or retry the operation.

Focus restoration depends on why the panel closed:

- Escape, close control, or trigger toggle restores the captured application when it is still valid.
- Switching panels transfers the focus lease directly to the replacement.
- Clicking or focusing another application closes the panel without stealing focus back.
- Losing an output closes the panel rather than unpredictably moving it to another monitor.

Outside-click handling belongs to the coordinator. The opener and popup must be treated as one interaction transaction so focus loss cannot close a panel immediately before the same click reopens it.

## Anchoring and multi-monitor routing

A bar-originated request carries the exact widget instance and output that invoked it. The panel is placed below that instance:

- left-zone panels align toward the left;
- center-zone panels center on their trigger;
- right-zone panels align toward the right;
- placement slides or clamps inside the target output’s usable bounds;
- a panel never intentionally straddles outputs.

Keyboard and IPC requests without an explicit output use:

1. the output containing the focused Hyprland window;
2. otherwise the mapped Hyprland monitor with the lowest monitor ID.

The coordinator resolves the matching bar anchor on that output. If the widget is not present there, it uses the panel’s declared fallback zone under the bar. IPC may provide an explicit output name; an invalid explicit output returns an error instead of silently choosing another monitor.

OSD feedback appears on the output where the action originated, using the same fallback order. Domain state such as PipeWire state remains shared rather than duplicated per monitor.

## Navigation and action model

Rashell has direct destinations, not pages connected by tabs:

- Read status from the bar.
- Activate a bar control, hotkey, or IPC action to open its panel.
- Activate another destination to replace the current panel.
- Press Escape to return to the previously focused application.

Pointer and keyboard controls call narrow first-party module operations directly. Fixed IPC exposes only audio/calendar panel toggle, panel close, output volume adjustment, and output mute toggle. Device selection stays panel-internal, and workspace bindings invoke Hyprland directly. There is no generic action registry, structured-result protocol, output argument, discovery API, or future-launcher contract.

## Empty, loading, and error states

Panel chrome remains available even when domain data is not.

- **Loading:** Show a stable panel frame and a concise loading state without focus jumping as rows arrive.
- **No output device:** Show `No output devices` and close only; omit percentage, slider, mute, and device rows.
- **No input device:** Omit the entire input section.
- **Service disconnected:** Keep the panel open with a clear unavailable state and retry when the service reconnects.
- **Action failure:** Show the error inline when initiated from a panel. Detectable failures initiated outside a panel may produce a three-second Rashell feedback overlay.
- **Module load failure:** Preserve layout with a compact error indicator rather than an invisible dead hit target, and log the module ID and cause.
- **Anchor or output loss:** Close through the coordinator and release focus safely.

Empty and error states must remain dismissible by both Escape and the visible close control.

## Explicitly deferred surfaces

### General launcher or command palette

Deferred until the number of useful actions makes direct bar controls and keybindings insufficient. When added, it will be one searchable global surface using the existing action registry and exclusive transient-surface coordinator.

### Notification daemon and notification center

Deferred. Rashell will coexist with the current desktop notification daemon and will not initially own banners, history, grouping, actions, or Do Not Disturb. Rashell-owned OSDs and feedback overlays are not a partial notification daemon.

### Settings UI

Deferred to issue #8. Configuration remains declarative and reloadable. Rashell should use the last known good configuration after an invalid edit, but it will not expose a gear button leading to an unfinished settings surface.

### Session actions

A dedicated logout, reboot, shutdown, suspend, or lock surface is deferred until product and service ownership are settled. Existing Hyprland or system bindings remain authoritative. Rashell must not expose destructive session actions over IPC without an explicit ownership and confirmation contract.

### Other excluded surfaces

The initial model also excludes:

- a combined dashboard or quick-settings center;
- visual bar layout editing;
- notification history;
- lock and authentication UI;
- a plugin marketplace or plugin-management UI.

## Consequences

This adds one small piece of core infrastructure, but removes duplicated popup state and inconsistent focus logic from every panel. It also gives future surfaces a clear place to integrate without requiring a navigation framework.

The first coherent surface set is therefore:

- a three-zone bar on every monitor;
- clock/calendar and audio as coordinated anchored panels;
- full pointer and keyboard operation;
- shared action IDs and IPC dispatch;
- a volume OSD;
- a minimal Rashell feedback overlay for detectable failures.

Everything else remains external or deferred until a concrete workflow justifies it.

---

## Concise closing comment

Proposed resolution: Rashell will use one three-zone bar per monitor, shell-hosted anchored task panels, and one globally active interactive transient surface coordinated by core. Calendar and audio use one shell-owned `PopupWindow` and `PanelCoordinator`; focus, Escape/compositor-outside dismissal, restoration, anchoring, and monitor routing are explicit shell contracts. Fixed IPC covers only panel toggles/close and direct output audio adjustment. OSD and Rashell feedback remain non-focus-stealing overlays.

A general launcher, freedesktop notification ownership/history, settings UI, combined quick-settings dashboard, and session-action surface are deferred. This keeps the first shell coherent while directly addressing the independent-popup and focus/dismissal bugs in the current prototype.