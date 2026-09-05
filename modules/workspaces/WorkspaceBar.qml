pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.core

Item {
    id: root

    required property var state
    required property string outputName

    implicitWidth: state.available ? row.implicitWidth : unavailableLabel.implicitWidth
    implicitHeight: Theme.controlHeight

    Text {
        id: unavailableLabel
        visible: !root.state.available
        anchors.verticalCenter: parent.verticalCenter
        text: "WORKSPACES UNAVAILABLE"
        color: Theme.textDisabled
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
    }

    Row {
        id: row
        visible: root.state.available
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.state.ids

            Button {
                id: button

                required property int modelData
                readonly property bool current: root.state.activeWorkspaceId(root.outputName) === modelData
                readonly property bool occupied: root.state.occupied(modelData)

                width: current ? 30 : 22
                height: 22
                hoverEnabled: true
                Accessible.name: "Workspace " + modelData + (current ? ", active" : occupied ? ", occupied" : ", empty")
                Accessible.role: Accessible.Button

                contentItem: Text {
                    text: button.modelData
                    color: button.current ? Theme.textOnAccent
                        : button.occupied ? Theme.text : Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: button.current ? Theme.accent
                        : button.hovered || button.down ? Theme.surfaceRaised : "transparent"
                    border.color: button.current ? Theme.accent : button.occupied ? Theme.borderInteractive : Theme.border
                    border.width: Theme.borderWidth
                    radius: height / 2
                }

                onClicked: root.state.activate(modelData)
            }
        }
    }
}
