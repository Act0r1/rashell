import QtQuick
import qs.core
import qs.ui

FocusScope {
    id: root
    required property var coordinator
    required property var tokenState
    implicitWidth: 430
    implicitHeight: panel.implicitHeight

    Shortcut { sequence: "Esc"; onActivated: root.coordinator.close("escape") }

    PanelFrame {
        id: panel
        width: parent.width
        title: "TOKEN METER · TODAY"
        onCloseRequested: root.coordinator.close("close-control")

        Column {
            width: parent.width
            spacing: Theme.spaceLg

            Grid {
                width: parent.width
                columns: 2
                spacing: Theme.spaceMd

                Repeater {
                    model: [
                        ["TOKENS", root.tokenState.compact(root.tokenState.totalTokens)],
                        ["COST", "$" + root.tokenState.cost.toFixed(2)],
                        ["CACHE", Math.round(root.tokenState.cacheRate * 100) + "%"],
                        ["SESSIONS", String(root.tokenState.sessions)]
                    ]
                    Rectangle {
                        required property var modelData
                        width: (parent.width - parent.spacing) / 2
                        height: 70
                        color: Theme.surfaceRaised
                        border.color: Theme.border
                        border.width: 1
                        radius: Theme.radius
                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData[0]
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData[1]
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontTitle
                                font.bold: true
                            }
                        }
                    }
                }
            }

            ActionButton {
                width: parent.width
                text: "Refresh usage"
                accessibleName: "Refresh token usage"
                onClicked: root.tokenState.refresh()
            }
        }
    }
}
