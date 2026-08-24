import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Scope {
    id: root
    required property var notificationState

    Variants {
        model: Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []

        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.notificationState.popupVisible && root.notificationState.latest !== null
                implicitWidth: 420
                implicitHeight: 100
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; right: true }
                margins { top: 58; right: 12 }
                WlrLayershell.namespace: "rashell-notification"
                WlrLayershell.layer: WlrLayer.Overlay

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surface
                    border.color: Theme.accent
                    border.width: 1
                    radius: Theme.radius

                    Column {
                        anchors.left: parent.left
                        anchors.right: closeButton.left
                        anchors.leftMargin: 14
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text {
                            width: parent.width
                            text: root.notificationState.latest ? root.notificationState.latest.appName : ""
                            textFormat: Text.PlainText
                            color: Theme.accent
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: root.notificationState.latest ? root.notificationState.latest.summary : ""
                            textFormat: Text.PlainText
                            color: Theme.text
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: root.notificationState.latest ? root.notificationState.latest.body : ""
                            textFormat: Text.PlainText
                            color: Theme.textMuted
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    ActionButton {
                        id: closeButton
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        width: 30
                        text: "×"
                        accessibleName: "Dismiss notification"
                        onClicked: {
                            if (root.notificationState.latest) root.notificationState.latest.dismiss()
                            root.notificationState.popupVisible = false
                        }
                    }
                }
            }
        }
    }
}
