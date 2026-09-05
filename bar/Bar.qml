pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Item {
    id: root

    required property var configStore
    required property var workspaceState
    required property var clockState
    required property var weatherState
    required property var audioState
    required property var mediaState
    required property var screenshotState
    required property var systemState
    required property var keyboardState
    required property var controlState
    required property var tokenState
    required property var notificationState
    required property var sessionModeState
    required property var textCaptureState
    required property var barEditor
    required property var lockScreen
    required property var wallpaperPicker
    required property var coordinator
    required property var osd
    required property var feedback

    component ModuleRow: Row {
        id: moduleRow

        required property var moduleIds
        required property string outputName
        required property var workspaceState
        required property var clockState
        required property var weatherState
        required property var audioState
        required property var mediaState
        required property var screenshotState
        required property var systemState
        required property var keyboardState
        required property var controlState
        required property var tokenState
        required property var notificationState
        required property var sessionModeState
        required property var textCaptureState
        required property var barEditor
        required property var lockScreen
        required property var wallpaperPicker
        required property var coordinator
        required property var osd
        required property var feedback
        required property var configStore

        spacing: 3

        Repeater {
            model: moduleRow.moduleIds

            ModuleSlot {
                required property string modelData
                moduleId: modelData
                outputName: moduleRow.outputName
                workspaceState: moduleRow.workspaceState
                clockState: moduleRow.clockState
                weatherState: moduleRow.weatherState
                audioState: moduleRow.audioState
                mediaState: moduleRow.mediaState
                screenshotState: moduleRow.screenshotState
                systemState: moduleRow.systemState
                keyboardState: moduleRow.keyboardState
                controlState: moduleRow.controlState
                tokenState: moduleRow.tokenState
                notificationState: moduleRow.notificationState
                sessionModeState: moduleRow.sessionModeState
                textCaptureState: moduleRow.textCaptureState
                barEditor: moduleRow.barEditor
                lockScreen: moduleRow.lockScreen
                wallpaperPicker: moduleRow.wallpaperPicker
                coordinator: moduleRow.coordinator
                osd: moduleRow.osd
                feedback: moduleRow.feedback
                configStore: moduleRow.configStore
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow

                required property var modelData
                screen: modelData
                implicitHeight: Theme.barHeight
                color: "transparent"
                exclusionMode: ExclusionMode.Auto

                anchors { top: true; left: true; right: true }
                WlrLayershell.namespace: "rashell-bar"
                WlrLayershell.layer: WlrLayer.Top


                IdleInhibitor {
                    window: barWindow
                    enabled: root.sessionModeState.inhibitIdle
                }

                Item {
                    id: shellAnchor
                    width: 1
                    height: barWindow.height
                    x: barWindow.width / 2
                    Component.onCompleted: root.coordinator.registerAnchor("shell", barWindow.modelData.name, shellAnchor, "center")
                    Component.onDestruction: root.coordinator.unregisterAnchor("shell", barWindow.modelData.name, shellAnchor)
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surface

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Theme.borderWidth
                        color: Theme.border
                    }

                    ModuleRow {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        moduleIds: root.configStore.leftModules
                        configStore: root.configStore
                        lockScreen: root.lockScreen
                        outputName: barWindow.modelData.name
                        workspaceState: root.workspaceState
                        clockState: root.clockState
                        weatherState: root.weatherState
                        audioState: root.audioState
                        mediaState: root.mediaState
                        screenshotState: root.screenshotState
                        systemState: root.systemState
                        keyboardState: root.keyboardState
                        controlState: root.controlState
                        tokenState: root.tokenState
                        notificationState: root.notificationState
                        sessionModeState: root.sessionModeState
                        textCaptureState: root.textCaptureState
                        barEditor: root.barEditor
                        wallpaperPicker: root.wallpaperPicker
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }

                    ModuleRow {
                        anchors.centerIn: parent
                        moduleIds: root.configStore.centerModules
                        configStore: root.configStore
                        lockScreen: root.lockScreen
                        outputName: barWindow.modelData.name
                        workspaceState: root.workspaceState
                        clockState: root.clockState
                        weatherState: root.weatherState
                        audioState: root.audioState
                        mediaState: root.mediaState
                        screenshotState: root.screenshotState
                        systemState: root.systemState
                        keyboardState: root.keyboardState
                        controlState: root.controlState
                        tokenState: root.tokenState
                        notificationState: root.notificationState
                        sessionModeState: root.sessionModeState
                        textCaptureState: root.textCaptureState
                        barEditor: root.barEditor
                        wallpaperPicker: root.wallpaperPicker
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }

                    ModuleRow {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        moduleIds: root.configStore.rightModules
                        configStore: root.configStore
                        lockScreen: root.lockScreen
                        outputName: barWindow.modelData.name
                        workspaceState: root.workspaceState
                        clockState: root.clockState
                        weatherState: root.weatherState
                        audioState: root.audioState
                        mediaState: root.mediaState
                        screenshotState: root.screenshotState
                        systemState: root.systemState
                        keyboardState: root.keyboardState
                        controlState: root.controlState
                        tokenState: root.tokenState
                        notificationState: root.notificationState
                        sessionModeState: root.sessionModeState
                        textCaptureState: root.textCaptureState
                        barEditor: root.barEditor
                        wallpaperPicker: root.wallpaperPicker
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }
                }
            }
        }
    }
}
