//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.bar
import qs.modules.workspaces
import qs.modules.clock
import qs.modules.audio
import qs.modules.media
import qs.modules.system
import qs.modules.launcher
import qs.modules.notifications
import qs.overlays

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

    ConfigStore {
        id: configStore
        onConfigError: function(message) {
            console.warn(message)
            const outputName = panelCoordinator.preferredOutputName()
            if (outputName !== "") feedback.show(outputName, "CONFIG ERROR")
        }
    }

    Wallpaper {
        sourcePath: configStore.wallpaper
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

    AudioState {
        id: audioState
    }

    MediaState {
        id: mediaState
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
    }

    NotificationPopup {
        notificationState: notificationState
    }

    Launcher {
        id: launcher
        coordinator: panelCoordinator
    }

    PanelCoordinator {
        id: panelCoordinator
    }

    Connections {
        target: audioState
        function onDirectOutputChangeObserved(outputName) {
            if (outputName !== "") volumeOsd.show(outputName)
        }
    }

    VolumeOsd {
        id: volumeOsd
        audioState: audioState
    }

    FeedbackOverlay {
        id: feedback
    }

    Bar {
        configStore: configStore
        workspaceState: workspaceState
        clockState: clockState
        audioState: audioState
        mediaState: mediaState
        systemState: systemState
        keyboardState: keyboardState
        controlState: controlState
        tokenState: tokenState
        notificationState: notificationState
        coordinator: panelCoordinator
        osd: volumeOsd
        feedback: feedback
    }

    IpcHandler {
        target: "rashell"

        function launcherToggle(): string {
            launcher.toggle()
            return "ok"
        }

        function controlCenterToggle(): string {
            const opened = panelCoordinator.toggleRegistered(
                "control",
                Quickshell.shellDir + "/modules/system/ControlPanel.qml",
                {
                    coordinator: panelCoordinator,
                    audioState: audioState,
                    systemState: systemState,
                    controlState: controlState,
                    notificationState: notificationState,
                    configStore: configStore
                }
            )
            return opened ? "ok" : "control anchor unavailable"
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
