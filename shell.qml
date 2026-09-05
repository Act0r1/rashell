//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.bar
import qs.modules.workspaces
import qs.modules.clock
import qs.modules.weather
import qs.modules.audio
import qs.modules.media
import qs.modules.system
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.lock
import qs.modules.wallpaper
import qs.modules.appearance
import qs.modules.projects
import qs.modules.session
import qs.modules.capture
import qs.overlays
import "core/LauncherActions.js" as LauncherActions

ShellRoot {
    id: shell

    function moduleEnabled(moduleId) {
        return configStore.leftModules.indexOf(moduleId) !== -1
            || configStore.centerModules.indexOf(moduleId) !== -1
            || configStore.rightModules.indexOf(moduleId) !== -1
    }

    function reportIpcFailure(message) {
        const outputName = panelCoordinator.preferredOutputName()
        if (outputName !== "") feedback.show(outputName, message)
    }

    function reportSuccess(message) {
        const outputName = panelCoordinator.preferredOutputName()
        if (outputName !== "") feedback.show(outputName, message, false)
    }

    function openAppearance(screen, themeId) {
        const outputName = panelCoordinator.preferredOutputName()
        const target = screen || Quickshell.screens.find(function(item) { return item.name === outputName }) || null
        launcher.close()
        wallpaperPicker.close()
        barEditor.close()
        panelCoordinator.close("appearance")
        appearancePicker.open(target, themeId || "")
        return appearancePicker.opened
    }

    function toggleTaskPanel(panelId) {
        const sources = {
            control: "system/ControlPanel.qml", audio: "audio/AudioPanel.qml",
            network: "system/NetworkPanel.qml", bluetooth: "system/BluetoothPanel.qml",
            notifications: "notifications/NotificationPanel.qml", calendar: "clock/CalendarPanel.qml",
            weather: "weather/WeatherPanel.qml", media: "media/MediaPanel.qml",
            screenshot: "system/ScreenshotPanel.qml", system: "system/SystemPanel.qml",
            updates: "system/UpdatesPanel.qml", modes: "session/ModePanel.qml",
            text: "capture/TextCapturePanel.qml"
        }
        if (!sources[panelId]) return false
        const outputName = panelCoordinator.preferredOutputName()
        const anchor = panelCoordinator.registeredAnchor(panelId, outputName)
            || panelCoordinator.registeredAnchor("control", outputName)
            || panelCoordinator.registeredAnchor("shell", outputName)
        if (!anchor) {
            reportIpcFailure("Panel output is unavailable")
            return false
        }
        let properties = { coordinator: panelCoordinator }
        if (panelId === "audio") properties.audioState = audioState
        else if (panelId === "media") properties.mediaState = mediaState
        else if (panelId === "calendar") properties.clockState = clockState
        else if (panelId === "weather") {
            properties.weatherState = weatherState
            properties.configStore = configStore
        } else if (panelId === "notifications") properties.notificationState = notificationState
        else if (panelId === "system" || panelId === "updates") properties.systemState = systemState
        else if (panelId === "screenshot") {
            properties.captureState = screenshotState
            properties.configStore = configStore
            properties.outputName = outputName
        } else if (panelId === "modes") properties.modeState = sessionModeState
        else if (panelId === "text") properties.captureState = textCaptureState
        else if (panelId === "control") {
            properties = {
                coordinator: panelCoordinator, audioState: audioState,
                screenshotState: screenshotState, systemState: systemState,
                controlState: controlState, notificationState: notificationState,
                configStore: configStore, barEditor: barEditor, lockScreen: lockScreen,
                wallpaperPicker: wallpaperPicker, outputName: outputName,
                sessionModeState: sessionModeState, textCaptureState: textCaptureState
            }
        }
        panelCoordinator.toggle(panelId, anchor.item, anchor.alignment,
            Quickshell.shellDir + "/modules/" + sources[panelId], properties)
        return true
    }

    function activateAction(actionId) {
        if (actionId.indexOf("panel.") === 0) {
            const panelId = actionId.slice(6)
            return toggleTaskPanel(panelId === "capture" ? "screenshot" : panelId)
        }
        if (actionId.indexOf("mode.") === 0) return sessionModeState.setMode(actionId.slice(5))
        if (actionId.indexOf("theme.") === 0) return shell.openAppearance(null, actionId.slice(6))
        if (actionId === "appearance") return shell.openAppearance(null, "")
        if (actionId === "audio.output-mute") return audioState.toggleOutputMute()
        if (actionId === "audio.input-mute") return audioState.toggleInputMute()
        if (actionId === "notifications.dnd") {
            notificationState.doNotDisturb = !notificationState.doNotDisturb
            return true
        }
        if (actionId === "projects") {
            launcher.openMode("projects")
            return true
        }
        if (actionId === "text.ocr") {
            if (!textCaptureState.ocrAvailable || textCaptureState.busy) return false
            panelCoordinator.close("ocr")
            Qt.callLater(function() { textCaptureState.startOcr() })
            return true
        }
        if (actionId === "text.dictate") {
            if (textCaptureState.recording) textCaptureState.stopDictation()
            else if (textCaptureState.dictationAvailable && !textCaptureState.busy) textCaptureState.startDictation()
            else return false
            return true
        }
        const outputName = panelCoordinator.preferredOutputName()
        const screen = Quickshell.screens.find(function(item) { return item.name === outputName }) || null
        if (actionId === "wallpaper") {
            panelCoordinator.close("wallpaper")
            wallpaperPicker.open(screen)
            return true
        }
        if (actionId === "bar-editor") {
            panelCoordinator.close("bar-editor")
            barEditor.open(screen)
            return true
        }
        if (actionId === "lock") {
            panelCoordinator.close("lock")
            textCaptureState.cancel()
            lockScreen.lock()
            return true
        }
        return false
    }

    ConfigStore {
        id: configStore
        onConfigError: function(message) {
            console.warn(message)
            const outputName = panelCoordinator.preferredOutputName()
            if (outputName !== "") feedback.show(outputName, "CONFIG ERROR")
        }
    }

    TelegramTheme {
        configStore: configStore
    }

    Wallpaper {
        sourcePath: configStore.wallpaper
    }

    LockScreen {
        id: lockScreen
        configStore: configStore
    }

    Binding {
        target: Theme
        property: "activeName"
        value: configStore.theme
    }

    WorkspaceState {
        id: workspaceState
    }

    ClockState {
        id: clockState
    }

    WeatherState {
        id: weatherState
        configStore: configStore
    }

    AudioState {
        id: audioState
    }

    MediaState {
        id: mediaState
    }

    ScreenshotState {
        id: screenshotState
        onFailed: function(outputName, message) {
            feedback.show(outputName, message)
        }
    }

    SystemState {
        id: systemState
    }

    KeyboardState {
        id: keyboardState
    }

    ControlState {
        id: controlState
    }

    TokenState {
        id: tokenState
    }

    NotificationState {
        id: notificationState
        configStore: configStore
    }

    NotificationPopup {
        notificationState: notificationState
    }

    ProjectState {
        id: projectState
        onFailed: function(message) { shell.reportIpcFailure(message) }
        onLaunched: function(name) { shell.reportSuccess("Opened " + name) }
    }

    SessionModeState {
        id: sessionModeState
        notificationState: notificationState
    }

    TextCaptureState {
        id: textCaptureState
        onFailed: function(message) { shell.reportIpcFailure(message) }
        onCompleted: function(message) { shell.reportSuccess(message) }
    }

    Connections {
        target: lockScreen
        function onLockedChanged() {
            if (lockScreen.locked) {
                textCaptureState.cancel()
                appearancePicker.close()
            }
        }
    }

    Launcher {
        id: launcher
        coordinator: panelCoordinator
        actions: LauncherActions.entries({
            outputUsable: audioState.outputUsable,
            inputUsable: audioState.inputUsable,
            doNotDisturb: notificationState.doNotDisturb,
            modeActive: sessionModeState.active,
            captureBusy: textCaptureState.busy,
            recording: textCaptureState.recording,
            ocrAvailable: textCaptureState.ocrAvailable,
            dictationAvailable: textCaptureState.dictationAvailable,
            ocrReason: textCaptureState.ocrReason,
            dictationReason: textCaptureState.dictationReason
        }, Theme.catalog)
        projects: projectState.projects
        projectError: projectState.error
        projectConfigPath: projectState.configPath
        onActionRequested: function(actionId) {
            if (!shell.activateAction(actionId)) shell.reportIpcFailure("Action unavailable")
        }
        onProjectRequested: function(projectId) { projectState.launch(projectId) }
    }

    PanelCoordinator {
        id: panelCoordinator
        onAppearanceRequested: function(screen) { shell.openAppearance(screen, "") }
    }

    Connections {
        target: audioState
        function onOutputChangeObserved(outputName) {
            const targetOutput = outputName !== "" ? outputName : panelCoordinator.preferredOutputName()
            if (targetOutput !== "") volumeOsd.show(targetOutput)
        }
    }

    VolumeOsd {
        id: volumeOsd
        audioState: audioState
    }

    FeedbackOverlay {
        id: feedback
    }

    WorkflowStatus {
        coordinator: panelCoordinator
        modeState: sessionModeState
        captureState: textCaptureState
        locked: lockScreen.locked
    }

    BarEditorPanel {
        id: barEditor
        configStore: configStore
    }

    WallpaperPicker {
        id: wallpaperPicker
        configStore: configStore
    }

    AppearancePicker {
        id: appearancePicker
        configStore: configStore
        onWallpaperRequested: function(screen) { wallpaperPicker.open(screen) }
    }

    Bar {
        configStore: configStore
        workspaceState: workspaceState
        clockState: clockState
        weatherState: weatherState
        audioState: audioState
        mediaState: mediaState
        screenshotState: screenshotState
        systemState: systemState
        keyboardState: keyboardState
        controlState: controlState
        tokenState: tokenState
        notificationState: notificationState
        sessionModeState: sessionModeState
        textCaptureState: textCaptureState
        barEditor: barEditor
        lockScreen: lockScreen
        wallpaperPicker: wallpaperPicker
        coordinator: panelCoordinator
        osd: volumeOsd
        feedback: feedback
    }

    IpcHandler {
        target: "rashell"

        function actionsToggle(): string {
            if (launcher.opened && launcher.mode === "actions") launcher.close()
            else launcher.openMode("actions")
            return "ok"
        }

        function projectsToggle(): string {
            if (launcher.opened && launcher.mode === "projects") launcher.close()
            else launcher.openMode("projects")
            return "ok"
        }

        function sessionModeSet(mode: string): string {
            return sessionModeState.setMode(mode) ? "ok" : "unknown mode"
        }

        function textCaptureToggle(): string {
            return shell.toggleTaskPanel("text") ? "ok" : "output unavailable"
        }

        function dictationToggle(): string {
            return shell.activateAction("text.dictate") ? "ok" : "dictation unavailable"
        }

        function ocrCapture(): string {
            return shell.activateAction("text.ocr") ? "ok" : "OCR unavailable"
        }

        function launcherToggle(): string {
            launcher.toggle()
            return "ok"
        }

        function wallpaperPickerToggle(): string {
            panelCoordinator.close("wallpaper-picker")
            wallpaperPicker.toggle(null)
            return "ok"
        }

        function appearanceToggle(): string {
            if (appearancePicker.opened) {
                appearancePicker.close()
                return "ok"
            }
            return shell.openAppearance(null, "") ? "ok" : "output unavailable"
        }

        function lockScreenLock(): string {
            panelCoordinator.close("lock-screen")
            lockScreen.lock()
            return "ok"
        }

        function lockScreenSuspend(): string {
            panelCoordinator.close("suspend")
            lockScreen.lockAndSuspend()
            return "ok"
        }

        function controlCenterToggle(): string {
            const opened = panelCoordinator.toggleRegistered(
                "control",
                Quickshell.shellDir + "/modules/system/ControlPanel.qml",
                {
                    coordinator: panelCoordinator,
                    audioState: audioState,
                    screenshotState: screenshotState,
                    systemState: systemState,
                    controlState: controlState,
                    notificationState: notificationState,
                    sessionModeState: sessionModeState,
                    textCaptureState: textCaptureState,
                    configStore: configStore,
                    barEditor: barEditor,
                    lockScreen: lockScreen,
                    wallpaperPicker: wallpaperPicker,
                    outputName: panelCoordinator.preferredOutputName()
                }
            )
            return opened ? "ok" : "control anchor unavailable"
        }

        function bluetoothPanelToggle(): string {
            if (!shell.moduleEnabled("rashell.bluetooth")) {
                shell.reportIpcFailure("BLUETOOTH MODULE DISABLED")
                return "bluetooth disabled"
            }
            const opened = panelCoordinator.toggleRegistered(
                "bluetooth",
                Quickshell.shellDir + "/modules/system/BluetoothPanel.qml",
                { coordinator: panelCoordinator }
            )
            if (!opened) shell.reportIpcFailure("BLUETOOTH ANCHOR UNAVAILABLE")
            return opened ? "ok" : "bluetooth anchor unavailable"
        }

        function mediaPanelToggle(): string {
            const opened = panelCoordinator.toggleRegistered(
                "media",
                Quickshell.shellDir + "/modules/media/MediaPanel.qml",
                { coordinator: panelCoordinator, mediaState: mediaState }
            )
            return opened ? "ok" : "media anchor unavailable"
        }

        function audioPanelToggle(): string {
            if (!shell.moduleEnabled("rashell.audio")) {
                shell.reportIpcFailure("AUDIO MODULE DISABLED")
                return "audio disabled"
            }
            const opened = panelCoordinator.toggleRegistered(
                "audio",
                Quickshell.shellDir + "/modules/audio/AudioPanel.qml",
                { coordinator: panelCoordinator, audioState: audioState }
            )
            if (!opened) shell.reportIpcFailure("AUDIO ANCHOR UNAVAILABLE")
            return opened ? "ok" : "audio anchor unavailable"
        }

        function weatherPanelToggle(): string {
            if (!shell.moduleEnabled("rashell.weather")) {
                shell.reportIpcFailure("WEATHER MODULE DISABLED")
                return "weather disabled"
            }
            const opened = panelCoordinator.toggleRegistered(
                "weather",
                Quickshell.shellDir + "/modules/weather/WeatherPanel.qml",
                {
                    coordinator: panelCoordinator,
                    weatherState: weatherState,
                    configStore: configStore
                }
            )
            if (!opened) shell.reportIpcFailure("WEATHER ANCHOR UNAVAILABLE")
            return opened ? "ok" : "weather anchor unavailable"
        }

        function calendarPanelToggle(): string {
            if (!shell.moduleEnabled("rashell.clock")) {
                shell.reportIpcFailure("CALENDAR MODULE DISABLED")
                return "calendar disabled"
            }
            const opened = panelCoordinator.toggleRegistered(
                "calendar",
                Quickshell.shellDir + "/modules/clock/CalendarPanel.qml",
                { coordinator: panelCoordinator, clockState: clockState }
            )
            if (!opened) shell.reportIpcFailure("CALENDAR ANCHOR UNAVAILABLE")
            return opened ? "ok" : "calendar anchor unavailable"
        }

        function panelClose(): string {
            panelCoordinator.close("ipc")
            return "ok"
        }

        function outputVolumeAdjust(delta: real): string {
            if (!shell.moduleEnabled("rashell.audio")) return "audio disabled"
            if (!isFinite(delta) || Math.abs(delta) > 1.5) {
                shell.reportIpcFailure("INVALID VOLUME DELTA")
                return "invalid delta"
            }
            const outputName = panelCoordinator.preferredOutputName()
            if (!audioState.adjustOutputDirect(delta, outputName)) {
                shell.reportIpcFailure("AUDIO UNAVAILABLE")
                return "audio unavailable"
            }
            return "ok"
        }

        function outputMuteToggle(): string {
            if (!shell.moduleEnabled("rashell.audio")) return "audio disabled"
            const outputName = panelCoordinator.preferredOutputName()
            if (!audioState.toggleOutputMuteDirect(outputName)) {
                shell.reportIpcFailure("AUDIO UNAVAILABLE")
                return "audio unavailable"
            }
            return "ok"
        }
    }
}
