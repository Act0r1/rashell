# Animations & Dynamic Island — research handoff

Self-contained summary of a design session (2026-10-27). Everything needed to continue is here; no web research needs to be repeated.

- Interactive demo (open in a browser): `docs/research/animations-demo.html`
- Same demo as a private link: https://claude.ai/artifact/44D55H9e8VMZYK2jN9Q2gC
- Status: **design agreed, no QML written yet.** Next step is a written implementation plan, reviewed by the user before any code.

## 1. Decisions made by the user

| Surface | Decision |
|---|---|
| Center of bar | A Dynamic-Island-style morphing pill. Holds **long-running** state only: idle clock → media (compact) → expanded player on click; recording timer. When media and recording are both active, recording splits off into a small detached bubble. |
| Notifications | **Not** in the island. Cards stack in the **top-right** corner under the bar, slide in from the right edge, newest on top. Each card has a close button, themed action buttons (e.g. Telegram: Reply + Open), an inline reply field, an auto-dismiss line, hover-to-pause, and swipe-right-to-dismiss. |
| Volume | **Not** in the island. Its own pill at **bottom-center**: slides up, hides 1.4 s after the last change, rubber-band stretch when pushed past 0 % / 100 %. |
| Motion model | One spring model everywhere (Apple duration + bounce), with velocity kept when an animation is interrupted. |
| Theme | Everything uses existing `Theme` tokens and existing primitives (`PanelFrame`, `CloseButton`, `ActionButton`). |

## 2. What the codebase has today (verified)

- `core/Theme.qml:131-133`: only `motionFast: 120`, `motionSurface: 220`, `motionEasing: Easing.OutCubic`. No spring tokens.
- Animation inventory across all QML: 55 `NumberAnimation`, 0 `SpringAnimation`, easing mostly `OutCubic` / `InOutCubic` / `InOutSine`. `Easing.OutBack` is used only on the lock screen (`modules/lock/LockScreen.qml:312,407`). `modules/lock/PixelDots.qml:83` uses an overshoot bezier `[0.34, 1.56, 0.64, 1]`.
- **Surfaces with no enter/exit animation at all:**
  - every panel opened through `core/PanelCoordinator.qml`. It already has `opened` and `transitioning` flags (lines 14-15, set around lines 89-103) that a transition could use.
  - `modules/notifications/NotificationPopup.qml`
  - `overlays/VolumeOsd.qml` (layer namespace `rashell-volume-osd`)
  - `modules/launcher/Launcher.qml`
  - `modules/workspaces/WorkspaceBar.qml` (only an attention pulse; the active indicator doesn't slide)
- **Notifications already support actions and inline reply:**
  - `NotificationPopup.qml` is a single `PanelWindow` on the first screen, anchored top + right, `margins { top: 58; right: 12 }`, width 420, `WlrLayer.Overlay`. Keyboard focus is `Exclusive` only while replying.
  - `NotificationActions.qml` already reads `notification.actions` and `notification.hasInlineReply`, and has `beginReply()` / `submitReply()`.
  - `NotificationState.qml` has `popupQueue`, `holdPopup()` / `resumePopup()`, `popupProgress`, and replace-in-place (`replaces_id`).
  - So the notification work is mostly **stacking several cards + animation + restyling**, not new protocol work. Today it shows one popup at a time and queues the rest.
- Audio: `modules/audio/AudioState.qml` reads and writes `output.audio.volume` directly (`setOutputVolume`, clamped) and the OSD shows `Math.round(volume * 100)`. Whether that value is linear or already perceptual is **not verified** (see §4.1).

## 3. Apple motion research (the facts that matter)

### 3.1 Springs, not easing curves
- Apple UI motion is **damped springs** (a physical oscillator), not logarithmic or bezier curves. Settling is **exponential decay**. Critically damped ("smooth"): `x(t) = 1 − (1 + ω·t)·e^(−ω·t)`.
- WWDC23 "Animate with springs" reduces springs to two parameters: **duration** (perceived length) and **bounce** (−1…1). bounce 0 = critically damped / "smooth"; > 0 = overshoot / "bouncy"; < 0 = overdamped / "flattened".
- SwiftUI presets: `.smooth` (bounce 0), `.snappy` (small bounce), `.bouncy` (visible bounce). Spring defaults: duration 0.5 s, bounce 0. Exact preset values aren't documented. The demo uses smooth `0.5/0`, snappy `0.4/0.15`, bouncy `0.5/0.3`, and the working default `0.42/0.15`.
- Converting to physics (mass = 1) — the demo uses exactly this:
  ```
  stiffness = (2π / duration)²
  damping   = 4π · (1 − bounce) / duration          (bounce ≥ 0)
  damping   = 4π / (duration · (1 + bounce))        (bounce < 0)
  ```

### 3.2 Why Apple feels smooth (in order of importance)
1. **Velocity is preserved when interrupted.** A spring retargeted mid-flight turns around from its current speed. `NumberAnimation` restarts from zero speed, which causes a visible kink. The demo's "Why springs, not curves" section graphs this.
2. **No fixed end time.** Motion settles naturally, so short and long moves both feel right.
3. **Properties move together:** scale ≈ 0.94–0.96 → 1, opacity and a small offset, all with the transform origin at the source (e.g. a panel grows out of its bar button).
4. **Gestures hand their velocity to the spring** (flick to dismiss).

### 3.3 Other Apple formulas worth reusing
- **Rubber band (scroll-view overscroll resistance):** `f(x) = (1 − 1 / (x·c/d + 1)) · d`, with `c = 0.55` and `d` = the dimension (e.g. view width). It grows roughly logarithmically, so resistance increases the further you pull. Use it for: dragging a notification card left, the volume pill past its limits, panel overscroll.
- **Flick projection** (WWDC18 "Designing Fluid Interfaces"): where a flick would come to rest under scroll-view deceleration.
  `projected = (velocity / 1000) · rate / (1 − rate)`, with `rate = 0.998` (normal) or `0.99` (fast), velocity in px/s.
  Use it to decide swipe-dismiss: dismiss if `dx + projected > threshold`. This is better than the demo's two separate thresholds (`dx > 110 || velocity > 700`).
- In Qt, only `SpringAnimation` and `SmoothedAnimation` keep velocity. `SpringAnimation`'s `spring`/`damping` units don't map to the formulas above. A custom spring driven by `FrameAnimation` (§5) gives an exact match.

### 3.4 Dynamic Island anatomy
- **Compact:** leading and trailing content around the pill (art + waveform). **Minimal:** with two live activities, one stays attached and the other detaches into a small circle. **Expanded:** long-press for rich controls; a tap opens the app. On desktop: click = expand, and clicking again collapses.
- Width, height and corner radius are **separate springs** on one black shape. Content cross-fades with blur (≈ 8 px → 0) and scale (0.88 → 1). It never just swaps.
- Split and merge look like a liquid metaball. The browser demo fakes it with an SVG filter (Gaussian blur 5 + alpha matrix `0 0 0 22 −9`). **QML needs a small `ShaderEffect`** (blur + alpha threshold, or an SDF smooth-min of two rounded rects) for this one detail. Everything else maps directly.

## 4. Where logarithmic / exponential math actually applies here

### 4.1 Volume (most important)
Loudness is perceived roughly logarithmically. If `audio.volume` is linear amplitude, then 50 % on the slider sounds far quieter than "half", and the top half of the slider feels dead.
- **Check first:** is Quickshell's `PwNodeAudio.volume` linear or already cubic-mapped? `wpctl` and pavucontrol show the cubic convention, `linear = ui³`. Compare `wpctl get-volume @DEFAULT_AUDIO_SINK@` with what the bar shows.
- If it's linear, put a single mapping in `AudioState`: `ui = linear^(1/3)`, `linear = ui³`, and use `ui` for the slider, the OSD and the ±step. One place, not per widget.

### 4.2 Rubber band
§3.3 formula, logarithmic-like resistance. For the volume pill at 0/100 %, card drag to the left, and overscroll.

### 4.3 Flick / momentum
Exponential decay with projection (§3.3) for swipe dismiss.

Not useful: a log curve as an easing function. It never settles, so it can't replace springs.

## 5. QML building block (proposed, not yet in the repo)

`core/Spring.qml` — an Apple-style spring that keeps velocity when retargeted:

```qml
import QtQuick

QtObject {
    id: spring
    property real target: 0
    property real value: target
    property real velocity: 0
    property real duration: Theme.springDuration
    property real bounce: Theme.springBounce

    readonly property real stiffness: Math.pow(2 * Math.PI / duration, 2)
    readonly property real damping: bounce >= 0
        ? 4 * Math.PI * (1 - bounce) / duration
        : 4 * Math.PI / (duration * (1 + bounce))

    property FrameAnimation driver: FrameAnimation {
        running: Math.abs(spring.target - spring.value) > 0.01 || Math.abs(spring.velocity) > 0.01
        onTriggered: {
            const steps = Math.max(1, Math.ceil(frameTime * 240))
            const h = frameTime / steps
            for (let i = 0; i < steps; i++) {
                spring.velocity += (spring.stiffness * (spring.target - spring.value) - spring.damping * spring.velocity) * h
                spring.value += spring.velocity * h
            }
        }
    }
}
```

Unverified details to check while implementing:
- `FrameAnimation` needs Qt ≥ 6.4. Check the Quickshell runtime's Qt version.
- The settle threshold should depend on the unit (px vs opacity). The demo uses `eps` per spring: 0.1 px, 0.002 opacity, 0.001 scale.
- Add `kick(v)` (add velocity) for the rubber-band and flick hand-off.

Theme tokens to add: `springDuration`, `springBounce`, plus preset pairs (`springSmooth`, `springSnappy`, `springBouncy`). Per-use speed multipliers: in the demo, opacity runs at 0.6× duration with bounce 0 (opacity must never overshoot), and scale at 0.9×.

**Layer-shell constraint (important):** don't resize a `PanelWindow` every frame to animate. Use a fixed-size transparent window big enough for the largest state, animate items inside it, and set `mask: Region { item: <visible shape> }` so clicks pass through the empty parts. This applies to the island (max ≈ 420×190), the notification stack and the volume pill.

## 6. Feature specs (values from the demo)

### 6.1 Island (bar center)
| State | w × h | radius |
|---|---|---|
| idle (clock) | 120 × 28 | 14 |
| media compact (art 20px, title, 4-bar EQ) | 280 × 28 | 14 |
| recording (pulsing red dot, `REC mm:ss`, click = stop) | 170 × 28 | 14 |
| expanded player (art 64, title/artist, progress, prev/play/next) | 400 × 178 | 34 |

- Priority: expanded (if media) > media > recording > idle.
- When recording is active alongside media, the bubble (28×28) detaches 22 px past the island's right edge (offset −16 → 22, scale 0.4 → 1).
- Island color is pure black; content text `#e8e6df`.
- Data: `MediaState` (media) and `ScreenshotState` / `overlays/RecordToolbar.qml` (recording). Later candidates: `MediaDownloadState` progress ring, Translate result, DND, timers.

### 6.2 Notification cards (top-right)
- Container: top 60, right 10, width 340, gap 8, max 4 visible (the oldest is dismissed when a 5th arrives).
- Enter: x 380 → 0, opacity 0 → 1, scale 0.96 → 1. Each card's `y` is a spring aimed at the sum of the heights above it, so the stack re-flows automatically on add, remove or reply-expand.
- Card: `Theme.surface`, `Theme.border`, `Theme.radius`. App icon 32 px. Title, then a "now" time, then a close button (reuse `CloseButton`). Body indented 42 px. Action buttons: first = accent/primary, others = raised (reuse `ActionButton`).
- Reply: the field reveals with a height spring, and the stack re-flows. Enter = send, Esc = cancel. Wire to the existing `NotificationActions.submitReply()`.
- Life: 6 s (or the existing `popupDurationSeconds`), shown as a 2 px accent line at the bottom; it pauses on hover and while replying (existing `holdPopup` / `resumePopup`).
- Swipe: dragging left gets resistance (demo uses ×0.25; better to use the rubber-band formula). Dismiss decision via flick projection. The release velocity is passed into the x spring.
- Structural change: `NotificationState` must expose a **list of visible popups** instead of the single `popup*` fields plus `popupQueue`.

### 6.3 Volume pill (bottom-center)
- 300 × 52, radius 26, bottom 28. Speaker icon (the sound waves hide at 0 %), accent fill bar (spring, bounce 0), percentage.
- Shows on change: y 90 → 0 and opacity. Hides 1.4 s after the last change.
- At a limit: add velocity to a `scaleX` spring (bounce 0.35, ≈ ±0.9) so it stretches and snaps back.
- Replaces the current `overlays/VolumeOsd.qml` placement.

### 6.4 Shared panel transition (all `PanelCoordinator` panels)
- opacity 0 → 1 (bounce 0, 0.7× duration), scale 0.94 → 1, y −8 → 0, `transformOrigin` at the anchor corner. Rows inside stagger in (opacity + y 6 → 0, 35 ms apart).
- Close: reverse to scale 0.96 / y −6. Hide when opacity < 0.01 and the target is 0.
- Implement once (in `PanelFrame` or the coordinator), not per panel.

### 6.5 Workspace pill
- Left and right edges are separate springs. The **leading edge is faster** (0.6× duration) than the trailing edge (1.15×), so the pill stretches in the direction of travel and then catches up.

### 6.6 Launcher
- Open: opacity + scale 0.94 → 1 plus a scrim. Rows stagger in (22 ms apart, start y +10).
- Filtering: each row's `y` is a spring to `index × rowHeight` (FLIP-style re-flow); rows that don't match fade out.
- Selection highlight: a spring on `y`.

## 7. Suggested order
1. `Spring.qml` + Theme spring tokens (everything else depends on these).
2. Shared panel transition (biggest visible win: every panel).
3. Volume pill at the bottom + perceptual volume check (§4.1).
4. Notification card stack (state refactor + animation).
5. Workspace pill.
6. Island (media + recording), with the metaball shader last.
7. Launcher motion.

## 8. Other feature ideas raised (not yet decided)
- Workspace overview (grid of live previews, drag windows between workspaces).
- Screen color picker with history.
- Night light / gamma toggle in the control center.
- Brightness OSD/slider (DDC already used by `MonitorInputBar`).
- Calculator / unit conversion in the launcher (check `LauncherSearch.js` first).

## Sources
- WWDC23 "Animate with springs": https://developer.apple.com/videos/play/wwdc2023/10158/
- WWDC Notes summary: https://wwdcnotes.com/notes/wwdc23/10158
- Apple docs, `interpolatingSpring(duration:bounce:initialVelocity:)`: https://developer.apple.com/documentation/swiftui/animation/interpolatingspring(duration:bounce:initialvelocity:)
- SwiftUI animation timing: https://nilcoalescing.com/blog/AnimationTimingInSwiftUI
- WWDC18 "Designing Fluid Interfaces" (projection + deceleration rates; rubber-band constant 0.55 is the widely cited UIScrollView value)
