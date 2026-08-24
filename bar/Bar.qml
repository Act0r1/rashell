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
        required property var coordinator
        required property var osd
        required property var feedback

        spacing: Theme.spaceSm

        Repeater {
            model: moduleRow.moduleIds

            ModuleSlot {
                required property string modelData
                moduleId: modelData
                outputName: moduleRow.outputName
                workspaceState: moduleRow.workspaceState
                clockState: moduleRow.clockState
                audioState: moduleRow.audioState
                coordinator: moduleRow.coordinator
                osd: moduleRow.osd
                feedback: moduleRow.feedback
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

                anchors {
                    top: true
                    left: true
                    right: true
                }

                WlrLayershell.namespace: "rashell-bar"
                WlrLayershell.layer: WlrLayer.Top

                Rectangle {
                    anchors {
                        fill: parent
                        topMargin: Theme.edgeMargin
                        leftMargin: Theme.barHorizontalMargin
                        rightMargin: Theme.barHorizontalMargin
                        bottomMargin: Theme.edgeMargin
                    }
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: Theme.borderWidth
                    radius: Theme.radius

                    ModuleRow {
                        anchors {
                            left: parent.left
                            leftMargin: Theme.spaceLg
                            verticalCenter: parent.verticalCenter
                        }
                        moduleIds: root.configStore.leftModules
                        outputName: barWindow.modelData.name
                        workspaceState: root.workspaceState
                        clockState: root.clockState
                        audioState: root.audioState
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }

                    ModuleRow {
                        anchors.centerIn: parent
                        moduleIds: root.configStore.centerModules
                        outputName: barWindow.modelData.name
                        workspaceState: root.workspaceState
                        clockState: root.clockState
                        audioState: root.audioState
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }

                    ModuleRow {
                        anchors {
                            right: parent.right
                            rightMargin: Theme.spaceLg
                            verticalCenter: parent.verticalCenter
                        }
                        moduleIds: root.configStore.rightModules
                        outputName: barWindow.modelData.name
                        workspaceState: root.workspaceState
                        clockState: root.clockState
                        audioState: root.audioState
                        coordinator: root.coordinator
                        osd: root.osd
                        feedback: root.feedback
                    }
                }
            }
        }
    }
}
