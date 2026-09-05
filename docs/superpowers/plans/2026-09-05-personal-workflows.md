# Rashell: personal workflows implementation plan

**Goal:** Add a searchable action palette, quick project opening, work/presentation modes, local text extraction and dictation, and improve notification controls.

**Architecture:** Keep the current Quickshell/QML shell and shared root state. Extend the existing launcher with Actions and Projects tabs; keep new domain state in small first-party modules. The root integration owns action routing and shared-file edits.

**Tech stack:** Quickshell, QtQuick/QML, existing system tools, Python only for bounded process/file helpers.

**Spec:** User request in this task on 2026-09-05, following the project assessment; notification reference `/tmp/codex-clipboard-f0b7a1c5-7adc-4367-a0b0-5fa7ac60cdf5.png`.

## Constraints

- Work in the current checkout; preserve all existing uncommitted work. No worktrees, commits, package installation, or desktop restarts.
- No new code comments or unrelated refactors. Keep the existing English interface copy.
- Monitor profiles, VPN, and Hysteria 2 integration are deferred.
- No microphone recording, screen capture, clipboard replacement, project launch, or session-mode activation during validation.
- No cloud transcription or automatic model downloads. Missing dependencies produce actionable disabled/error states.
- Validation uses parsing/linting and focused existing checks where safe. Do not run `tests/smoke.sh`, which starts a live shell.
- Agents own separate files; the coordinator integrates `shell.qml`, bar plumbing, and the control panel.

## Task 1: Launcher action palette

**Owner/files:** launcher agent; `modules/launcher/Launcher.qml`, `LauncherSearch.js`, launcher-only new components.

- [x] Preserve Applications and Clipboard; add Actions and Projects tabs with keyboard switching, search, Enter activation, Escape dismissal, and visible empty states.
- [x] Open on the coordinator's preferred output with a fallback to the first available screen.
- [x] Accept `actions` and `projects` array properties. Action records contain `id`, `name`, `comment`, `keywords`, `icon`, `enabled`; project records contain `id`, `name`, `path`, `comment`, `icon`.
- [x] Expose `actionRequested(string actionId)` and `projectRequested(string projectId)` signals, `projectError` and `projectConfigPath` strings, and `openMode(string modeName)`. Preserve existing `open()` and `toggle()` calls.
- [x] Close before requesting an action so a newly opened panel keeps focus. Disabled entries never execute; changing tabs/query resets the selected result.
- [x] Keep tabs usable on narrow displays and give each its own clear placeholder.

**Acceptance:** Apps and clipboard remain reachable; Actions/Projects can be navigated without a mouse; chosen output and disabled actions behave consistently.

## Task 2: Quick project opening

**Owner/files:** projects agent; new `modules/projects/ProjectState.qml`, `qmldir`, and small local helper if required.

- [x] Load optional `$XDG_CONFIG_HOME/rashell/projects.json` (fallback `~/.config/rashell/projects.json`), with absolute `RASHELL_PROJECTS_CONFIG` override.
- [x] Use a versioned document: `{"version":1,"projects":[{"id":"rashell","name":"Rashell","path":"/absolute/project","commands":[["editor","."],["terminal"]],"url":"http://localhost:5173"}]}`. `url` is optional. Never seed real project commands without user configuration.
- [x] Validate unique IDs, nonempty names, existing directories at launch, argv arrays, and optional http/https URLs. Keep last valid config on malformed updates; missing file is an empty setup state.
- [x] Expose `projects`, `error`, `configPath`, `launch(string projectId): bool`, and `failed(string message)` / `launched(string name)` signals.
- [x] Run configured argv with the project's working directory; paths and arguments must never become shell source. Report missing directories/executables and avoid claiming success before spawn acknowledgement.

**Acceptance:** Explicit configuration opens its commands in the intended directory; absent/broken configuration is explained in the launcher; user config is never overwritten.

## Task 3: Work and presentation modes

**Owner/files:** modes agent; new `modules/session/SessionModeState.qml`, `ModeControls.qml`, and `qmldir`.

- [x] Provide Normal, Work, and Presentation. Work enables DND for 25 minutes; Presentation enables DND and requests compositor idle inhibition until explicitly ended.
- [x] Capture prior DND only on transition from Normal; switching active modes preserves that original value. End restores only values still owned by the mode; respect manual DND overrides.
- [x] Expose `mode`, `title`, `active`, `remainingSeconds`, `inhibitIdle`, `setMode(string modeName): bool`, and `endMode()`; consume `notificationState`.
- [x] `ModeControls` accepts `state` and shows buttons, active status, and work countdown in the existing visual language.
- [x] Do not guess audio devices or change microphone settings. Integration attaches compositor idle inhibition to bar windows after confirming the local API.

**Acceptance:** Work ends automatically; active-mode switching and repeated calls preserve restoration semantics; Normal releases inhibition and mode-owned DND.

## Task 4: Notification interaction and design

**Owner/files:** notification agent; `modules/notifications/NotificationPopup.qml`, `NotificationPanel.qml`, optional shared close control in `ui/` and its `qmldir`.

- [x] Inspect the supplied image and current components. Use a clearly visible close glyph around 20px with at least a 36x36 logical-pixel hit area, explicit padding and hover/focus feedback.
- [x] Reserve the close control's column across the title/body lines so text cannot run beneath it. Keep concise content readable and allow meaningful body wrapping.
- [x] Apply the same close-control proportions to notification history where appropriate, without enlarging every unrelated button globally.
- [x] Preserve actions, inline reply, popup timer, dismissal, and focus behavior. Pause timeout while hovering the popup and resume on leave unless replying.

**Acceptance:** Close affordance is legible beside 13px text, content never overlaps it, and pointer/keyboard dismissal and reply remain intact.

## Task 5: Local OCR and dictation

**Owner/files:** extraction agent; new `modules/capture/TextCaptureState.qml`, `TextCapturePanel.qml`, `qmldir`, and bounded helper under `scripts/`.

- [x] Add user-triggered area OCR using existing capture tools plus a detected local OCR engine. Copy successful nonempty text only; cancelled selection leaves the clipboard intact.
- [x] Add explicit Start/Stop/Cancel dictation using installed local Whisper tooling and an existing model. Recording status must remain visible; no automatic recording or downloads.
- [x] Discover dependencies/model without starting the microphone. Prefer user-selected existing tooling; otherwise use `pw-record` plus `whisper-cli` with an explicit model path override and existing conventional model location.
- [x] Expose `busy`, `recording`, `status`, `error`, availability fields, `startOcr()`, `startDictation()`, `stopDictation()`, `cancel()`, plus completion/failure signals. The panel owns clear buttons and explanatory unavailable states.
- [x] Private temporary files are removed after completion/cancellation. Operate only on owned child processes; cancellation does not become successful output.

**Acceptance:** UI is ready for local tools and reports missing capabilities honestly; microphone capture occurs only on explicit action; stop transcribes, cancel discards, and errors do not overwrite the clipboard.

## Task 6: Integration and verification

**Owner/files:** coordinator; `shell.qml`, bar argument plumbing, `modules/system/ControlPanel.qml`, and narrow integration helpers.

- [x] Connect launcher actions to existing panel/session/theme actions and the new modules. Action palette opens existing panels using coherent routing, including when their bar icon is hidden where feasible.
- [x] Add project state, session mode controls, text capture access, and persistent recording/mode visibility without crowding the bar.
- [x] Keep the original user configuration intact. Document any new setup in this plan and expose it through relevant empty states.
- [x] Review each agent's delta against the pre-task snapshot at `/tmp/rashell-enhancements-20260905-y8lwt3rv/baseline`.
- [x] Parse/lint changed QML and helper scripts, perform safe focused checks, and review the integrated changes with a separate agent. Report runtime checks that require the user's live desktop separately.

## Execution status

- All five feature tasks and root integration are implemented; independent review findings have been addressed.
- Work/Presentation controls live in a compact dedicated panel reached from Control Center or Actions.
- The shared close control also covers panel headers and notification reply cancellation; queued popups retain hover pause.
- OCR/dictation copy uses an explicit UI/helper commit handshake so an accepted cancellation cannot copy text.
- Deliberate scope choice: audio presets for calls require chosen devices and remain outside the initial Work/Presentation modes.
- Deliberate scope choice: no framework, package installer, monitor/VPN integration, or unrelated module rewrites.


## Use and remaining runtime checks

- Existing launcher: Applications, Clipboard, Actions, Projects; Ctrl+1 through Ctrl+4 selects a tab, Ctrl+Tab cycles, Enter activates, Escape closes.
- IPC: `actionsToggle`, `projectsToggle`, `sessionModeSet work`, `sessionModeSet presentation`, `sessionModeSet normal`, `textCaptureToggle`, `dictationToggle`, `ocrCapture` under the existing `rashell` target.
- Project configuration is optional and is read from the path shown in the Projects tab. Use the Task 2 schema and installed editor/terminal argv; no personal file was created or overwritten.
- Control Center exposes Session mode and Text & dictation. A small status surface shows active mode/countdown and recording controls; it is hidden while locked or taking an OCR screenshot.
- Dictation uses the existing local model. Model override: `RASHELL_WHISPER_MODEL` then `WHISPER_MODEL`; language: `WHISPER_LANGUAGE` (default `ru`). OCR language: `RASHELL_OCR_LANGUAGE` (default `eng`).
- Read-only capability probe on this machine detects dictation prerequisites and the existing model. OCR is unavailable because `tesseract` is missing; no system packages were installed.
- Validation: changed QML parsed successfully; import-aware lint exited 0 with Quickshell/dynamic-property metadata warnings. Existing launcher and notification checks, isolated mode-state checks, mocked process/protocol checks, and the offscreen notification layout check passed. These do not establish actual microphone quality, live Wayland focus/idle inhibition, or project application startup.
- Live shell restart, real dictation/OCR, clipboard write, project launch, and mode activation were deliberately not used for validation.
