pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

Item {
    id: root

    required property var pluginRegistry
    property var leftPlugins: []
    property var centerPlugins: []
    property var rightPlugins: []

    component PluginRow: Row {
        id: pluginRow

        required property var pluginIds
        required property var registry

        spacing: 4

        Repeater {
            model: pluginRow.pluginIds

            PluginSlot {
                required property string modelData
                pluginId: modelData
                pluginRegistry: pluginRow.registry
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
                        leftMargin: Theme.edgeMargin * 3
                        rightMargin: Theme.edgeMargin * 3
                        bottomMargin: Theme.edgeMargin
                    }
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1
                    radius: Theme.radius

                    PluginRow {
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        pluginIds: root.leftPlugins
                        registry: root.pluginRegistry
                    }

                    PluginRow {
                        anchors.centerIn: parent
                        pluginIds: root.centerPlugins
                        registry: root.pluginRegistry
                    }

                    PluginRow {
                        anchors {
                            right: parent.right
                            rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        pluginIds: root.rightPlugins
                        registry: root.pluginRegistry
                    }
                }
            }
        }
    }
}
