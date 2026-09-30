import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var systemState

    readonly property int packageCount: systemState.availableUpdates.count
    readonly property bool hasError: systemState.updatesError.length > 0
    readonly property bool canUpdate: systemState.updatesChecked
        && !systemState.updatesRefreshing && !hasError
    readonly property string checkedAt: systemState.updatesLastChecked.getTime() > 0
        ? Qt.formatDateTime(systemState.updatesLastChecked, "d MMM, hh:mm") : ""

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    PanelFrame {
        id: panel
        width: parent.width
        title: "System updates"
        contentWidth: 460
        onCloseRequested: root.coordinator.close("close-control")

        Column {
            width: parent.width
            spacing: Theme.spaceXl

            Row {
                width: parent.width
                spacing: Theme.spaceLg

                Rectangle {
                    width: 48
                    height: 48
                    radius: Theme.radius
                    color: root.hasError && !root.systemState.updatesRefreshing
                        ? Theme.dangerSurface : Theme.selectedSurface

                    ShellIcon {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        name: root.systemState.updatesRefreshing || root.hasError || root.packageCount === 0
                            ? "rotate-cw" : "download"
                        tint: root.hasError && !root.systemState.updatesRefreshing ? Theme.danger : Theme.accent
                    }
                }

                Column {
                    width: parent.width - 48 - parent.spacing
                    spacing: Theme.spaceSm

                    Text {
                        width: parent.width
                        text: root.systemState.updatesRefreshing ? "Checking for updates…"
                            : root.hasError ? "Couldn't check for updates"
                            : !root.systemState.updatesChecked ? "Ready to check for updates"
                            : root.packageCount > 0 ? root.packageCount + (root.packageCount === 1 ? " package update" : " package updates")
                            : "Repositories are up to date"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: root.systemState.updatesRefreshing ? "Checking official repository packages."
                            : root.hasError ? root.systemState.updatesError
                            : root.checkedAt !== "" ? "Last checked " + root.checkedAt
                            : "Packages from official repositories."
                        textFormat: Text.PlainText
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spaceSm
                visible: root.packageCount > 0

                Text {
                    width: parent.width
                    text: root.systemState.updatesRefreshing || root.hasError
                        ? "Repository packages · previous check" : "Repository packages"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }

                ListView {
                    id: updatesList
                    width: parent.width
                    height: Math.min(300, contentHeight)
                    model: root.systemState.availableUpdates
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        id: updatesScroll
                        policy: ScrollBar.AsNeeded
                        visible: updatesList.contentHeight > updatesList.height + 1
                        width: 5
                        contentItem: Rectangle {
                            implicitWidth: 3
                            radius: 2
                            color: updatesScroll.pressed || updatesScroll.hovered
                                ? Theme.accent : Theme.accentMuted
                        }
                        background: Item {}
                    }

                    delegate: Item {
                        id: packageRow
                        required property int index
                        required property string name
                        required property string currentVersion
                        required property string newVersion

                        width: ListView.view.width
                        height: 60
                        Accessible.role: Accessible.ListItem
                        Accessible.name: name + ", " + currentVersion + "  →  " + newVersion

                        Column {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                rightMargin: Theme.spaceLg
                            }
                            spacing: Theme.spaceSm

                            Text {
                                width: parent.width
                                text: packageRow.name
                                textFormat: Text.PlainText
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                elide: Text.ElideRight
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spaceMd

                                Text {
                                    width: (parent.width - versionArrow.width - parent.spacing * 2) / 2
                                    text: packageRow.currentVersion
                                    textFormat: Text.PlainText
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    elide: Text.ElideMiddle
                                }

                                Text {
                                    id: versionArrow
                                    text: "→"
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                }

                                Text {
                                    width: (parent.width - versionArrow.width - parent.spacing * 2) / 2
                                    text: packageRow.newVersion
                                    textFormat: Text.PlainText
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    elide: Text.ElideMiddle
                                }
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                rightMargin: Theme.spaceLg
                            }
                            visible: packageRow.index < updatesList.count - 1
                            height: Theme.borderWidth
                            color: Qt.alpha(Theme.border, 0.5)
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spaceLg

                Text {
                    width: parent.width
                    text: root.hasError && !root.systemState.updatesRefreshing
                        ? "Refresh to retry. Updates open in a terminal."
                        : "Opens a terminal for repositories, AUR and Flatpak."
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    spacing: Theme.spaceMd

                    Item {
                        width: parent.width - refreshButton.width - updateButton.width - parent.spacing * 2
                        height: 1
                    }

                    ActionButton {
                        id: refreshButton
                        width: 100
                        height: 36
                        flat: true
                        text: "Refresh"
                        accessibleName: root.hasError ? "Retry checking for updates" : "Refresh available updates"
                        enabled: !root.systemState.updatesRefreshing
                        onClicked: root.systemState.refreshUpdates()
                    }

                    ActionButton {
                        id: updateButton
                        width: 110
                        height: 36
                        text: "Update"
                        accessibleName: "Open terminal to update repositories, AUR and Flatpak"
                        enabled: root.canUpdate
                        selected: enabled
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
    }

    Component.onCompleted: systemState.refreshUpdates()
}
