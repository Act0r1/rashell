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
    required property var sessionState
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
        required property var sessionState
        required property var textCaptureState
        required property var barEditor
        required property var lockScreen
        required property var wallpaperPicker
        required property var coordinator
        required property var osd
        required property var feedback
        required property var configStore

        property real mediaWidthReduction: 0
        readonly property real naturalWidth: {
            let total = 0
            let count = 0
            for (let index = 0; index < children.length; index++) {
                const child = children[index]
                if (child.implicitWidth > 0) {
                    total += child.implicitWidth
                    count++
                }
            }
            return total + Math.max(0, count - 1) * spacing
        }
        readonly property int mediaCount: mediaState.available && moduleIds.indexOf("rashell.media") >= 0 ? 1 : 0

        spacing: Theme.spaceXs

        Repeater {
            model: moduleRow.moduleIds

            ModuleSlot {
                required property string modelData
                moduleId: modelData
                width: moduleId === "rashell.media" && !emptyModule
                    ? Math.max(Theme.controlHeight, implicitWidth - moduleRow.mediaWidthReduction) : implicitWidth
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
                sessionState: moduleRow.sessionState
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
                implicitHeight: root.configStore.barMinimal ? 26 : Theme.barHeight
                color: "transparent"
                exclusionMode: ExclusionMode.Auto

                anchors { top: true; left: true; right: true }
                WlrLayershell.namespace: "rashell-bar"
                WlrLayershell.layer: WlrLayer.Top


                IdleInhibitor {
                    window: barWindow
                    enabled: root.sessionState.keepAwake
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
                    id: barSurface
                    readonly property real groupGap: Theme.spaceMd
                    readonly property real mediaReduction: Math.max(0,
                        leftGroup.naturalWidth + centerGroup.naturalWidth + rightGroup.naturalWidth
                        + 2 * groupGap + 2 * Theme.spaceMd - width)
                        / Math.max(1, leftGroup.mediaCount + centerGroup.mediaCount + rightGroup.mediaCount)
                    anchors.fill: parent
                    color: root.configStore.barMinimal ? "#80000000" : Theme.surface

                    Rectangle {
                        visible: !root.configStore.barMinimal
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Theme.borderWidth
                        color: Theme.border
                    }

                    ModuleRow {
                        id: leftGroup
                        mediaWidthReduction: barSurface.mediaReduction
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spaceMd
                        anchors.verticalCenter: parent.verticalCenter
                        moduleIds: root.configStore.barMinimal ? [] : root.configStore.leftModules
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
                        sessionState: root.sessionState
                        textCaptureState: root.textCaptureState
                        barEditor: root.barEditor
                        wallpaperPicker: root.wallpaperPicker
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }

                    ModuleRow {
                        id: centerGroup
                        mediaWidthReduction: barSurface.mediaReduction
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.configStore.barMinimal ? (parent.width - width) / 2
                            : Math.max(leftGroup.x + leftGroup.width + barSurface.groupGap,
                            Math.min((parent.width - width) / 2,
                                rightGroup.x - width - barSurface.groupGap))
                        moduleIds: root.configStore.barMinimal ? ["rashell.weather", "rashell.clock"] : root.configStore.centerModules
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
                        sessionState: root.sessionState
                        textCaptureState: root.textCaptureState
                        barEditor: root.barEditor
                        wallpaperPicker: root.wallpaperPicker
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }

                    ModuleRow {
                        id: rightGroup
                        mediaWidthReduction: barSurface.mediaReduction
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spaceMd
                        anchors.verticalCenter: parent.verticalCenter
                        moduleIds: root.configStore.barMinimal ? [] : root.configStore.rightModules
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
                        sessionState: root.sessionState
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
