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
                readonly property bool urgent: (attentionPending || root.state.urgent(modelData)) && !current
                property bool attentionPending: false
                property real attentionOpacity: 0

                width: current ? 30 : 22
                height: 22
                padding: 0
                hoverEnabled: true
                Accessible.name: "Workspace " + modelData + (current ? ", active" : urgent ? ", needs attention" : occupied ? ", occupied" : ", empty")
                Accessible.role: Accessible.Button

                onCurrentChanged: {
                    if (current) {
                        attentionPending = false
                        attentionAnimation.stop()
                        attentionOpacity = 0
                    }
                }

                onOccupiedChanged: {
                    if (!occupied) {
                        attentionPending = false
                        attentionAnimation.stop()
                        attentionOpacity = 0
                    }
                }

                Connections {
                    target: root.state

                    function onAttentionRequested(workspaceId) {
                        if (workspaceId === button.modelData && !button.current) {
                            button.attentionPending = true
                            attentionAnimation.restart()
                        }
                    }
                }

                SequentialAnimation {
                    id: attentionAnimation
                    loops: 3

                    NumberAnimation {
                        target: button
                        property: "attentionOpacity"
                        from: 0
                        to: 1
                        duration: 280
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: button
                        property: "attentionOpacity"
                        from: 1
                        to: 0
                        duration: 420
                        easing.type: Easing.InOutSine
                    }
                }

                contentItem: Text {
                    text: button.modelData
                    color: button.current || button.attentionOpacity > 0.5 ? Theme.textOnAccent
                        : button.urgent ? Theme.accent
                        : button.occupied ? Theme.text : Theme.textDisabled
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.features: { "tnum": 1 }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: button.current ? Theme.accent
                        : button.urgent ? Qt.alpha(Theme.accent, button.hovered || button.down ? 0.36 : 0.24)
                        : button.hovered || button.down ? Theme.surfaceRaised : "transparent"
                    border.color: button.current || button.urgent ? Theme.accent : button.occupied ? Theme.borderInteractive : Theme.border
                    border.width: button.urgent ? Theme.focusWidth : Theme.borderWidth
                    radius: height / 2

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.accent
                        opacity: button.attentionOpacity
                    }
                }

                onClicked: root.state.activate(modelData)
            }
        }
    }
}
