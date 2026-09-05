import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var systemState

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    PanelFrame {
        id: panel
        width: parent.width
        title: "SYSTEM UPDATES"
        contentWidth: 460
        onCloseRequested: root.coordinator.close("close-control")

        Column {
            width: parent.width
            spacing: Theme.spaceMd

            Item {
                width: parent.width
                height: 22

                Text {
                    anchors {
                        left: parent.left
                        right: sourceLabel.left
                        rightMargin: Theme.spaceMd
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.systemState.updatesRefreshing
                        ? "SCANNING PACKAGES…"
                        : root.systemState.availableUpdates.count + " PACKAGES READY"
                    color: root.systemState.availableUpdates.count > 0 ? Theme.accent : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                }

                Text {
                    id: sourceLabel

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: "CHECKUPDATES"
                    color: Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }
            }

            Text {
                visible: !root.systemState.updatesRefreshing && root.systemState.availableUpdates.count === 0
                width: parent.width
                height: 72
                text: "✓  System is up to date"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: parent.width
                height: Math.min(316, updatesList.contentHeight) + Theme.borderWidth * 2
                visible: updatesList.count > 0
                color: Theme.surfaceRaised
                border.color: Theme.border
                border.width: Theme.borderWidth
                radius: Theme.radius
                clip: true

                ListView {
                    id: updatesList

                    anchors {
                        fill: parent
                        margins: Theme.borderWidth
                    }
                    model: root.systemState.availableUpdates
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        id: updatesScroll

                        policy: ScrollBar.AsNeeded
                        width: 6

                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: updatesScroll.pressed || updatesScroll.hovered
                                ? Theme.accent : Theme.accentMuted
                        }

                        background: Item {}
                    }

                    delegate: Rectangle {
                        required property int index
                        required property string name
                        required property string currentVersion
                        required property string newVersion

                        width: ListView.view.width
                        height: 52
                        color: index % 2 === 0 ? Theme.surfaceRaised : Theme.surface

                        Rectangle {
                            anchors {
                                left: parent.left
                                leftMargin: Theme.spaceMd
                                verticalCenter: parent.verticalCenter
                            }
                            width: 3
                            height: 20
                            color: Theme.accentMuted
                            radius: 1
                        }

                        Column {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: Theme.spaceLg + Theme.spaceMd
                                rightMargin: Theme.spaceLg
                            }
                            spacing: Theme.spaceSm

                            Text {
                                width: parent.width
                                text: name
                                textFormat: Text.PlainText
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: currentVersion + "  →  " + newVersion
                                textFormat: Text.PlainText
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: Theme.spaceLg + Theme.spaceMd
                            }
                            visible: index < updatesList.count - 1
                            height: Theme.borderWidth
                            color: Theme.border
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "Refresh"
                    accessibleName: "Refresh available updates"
                    enabled: !root.systemState.updatesRefreshing
                    onClicked: root.systemState.refreshUpdates()
                }

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "Update"
                    accessibleName: "Install " + root.systemState.updates + " system updates"
                    enabled: !root.systemState.updatesRefreshing && root.systemState.updates > 0
                    selected: root.systemState.updates > 0
                    onClicked: {
                        root.coordinator.close("start-update")
                        Quickshell.execDetached([
                            "ghostty", "-e", "bash", "-lc",
                            "yay; flatpak update; read -n 1 -p 'Press any key to close'"
                        ])
                    }
                }
            }
        }
    }

    Component.onCompleted: systemState.refreshUpdates()
}
