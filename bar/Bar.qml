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
    required property var audioState
    required property var mediaState
    required property var systemState
    required property var keyboardState
    required property var controlState
    required property var tokenState
    required property var notificationState
    required property var coordinator
    required property var osd
    required property var feedback

    component ModuleRow: Row {
        id: moduleRow

        required property var moduleIds
        required property string outputName
        required property var workspaceState
        required property var clockState
        required property var audioState
        required property var mediaState
        required property var systemState
        required property var keyboardState
        required property var controlState
        required property var tokenState
        required property var notificationState
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
                audioState: moduleRow.audioState
                mediaState: moduleRow.mediaState
                systemState: moduleRow.systemState
                keyboardState: moduleRow.keyboardState
                controlState: moduleRow.controlState
                tokenState: moduleRow.tokenState
                notificationState: moduleRow.notificationState
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
                implicitHeight: Theme.barHeight + Theme.edgeMargin * 2
                color: "transparent"
                exclusionMode: ExclusionMode.Auto

                anchors { top: true; left: true; right: true }
                WlrLayershell.namespace: "rashell-bar"
                WlrLayershell.layer: WlrLayer.Top

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Theme.edgeMargin
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: Theme.borderWidth
                    radius: Theme.radius

                    ModuleRow {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        moduleIds: root.configStore.leftModules
                        configStore: root.configStore
                        outputName: barWindow.modelData.name
                        workspaceState: root.workspaceState
                        clockState: root.clockState
                        audioState: root.audioState
                        mediaState: root.mediaState
                        systemState: root.systemState
                        keyboardState: root.keyboardState
                        controlState: root.controlState
                        tokenState: root.tokenState
                        notificationState: root.notificationState
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }

                    ModuleRow {
                        anchors.centerIn: parent
                        moduleIds: root.configStore.centerModules
                        configStore: root.configStore
                        outputName: barWindow.modelData.name
                        workspaceState: root.workspaceState
                        clockState: root.clockState
                        audioState: root.audioState
                        mediaState: root.mediaState
                        systemState: root.systemState
                        keyboardState: root.keyboardState
                        controlState: root.controlState
                        tokenState: root.tokenState
                        notificationState: root.notificationState
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
                        outputName: barWindow.modelData.name
                        workspaceState: root.workspaceState
                        clockState: root.clockState
                        audioState: root.audioState
                        mediaState: root.mediaState
                        systemState: root.systemState
                        keyboardState: root.keyboardState
                        controlState: root.controlState
                        tokenState: root.tokenState
                        notificationState: root.notificationState
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }
                }
            }
        }
    }
}
