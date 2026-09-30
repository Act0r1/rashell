import QtQuick
import QtQuick.Controls
import qs.core

Button {
    id: control

    property string accessibleName: "Close"
    property bool compact: false

    implicitWidth: compact ? 24 : Theme.controlHeight
    implicitHeight: compact ? 24 : Theme.controlHeight
    leftPadding: Theme.spaceMd
    rightPadding: Theme.spaceMd
    topPadding: Theme.spaceSm
    bottomPadding: Theme.spaceSm
    hoverEnabled: true
    Accessible.name: accessibleName
    Accessible.role: Accessible.Button

    contentItem: Item {
        Repeater {
            model: [45, -45]
            Rectangle {
                required property int modelData
                anchors.centerIn: parent
                width: control.compact ? 11 : 13
                height: 1.5
                radius: height / 2
                rotation: modelData
                antialiasing: true
                color: control.down || control.hovered || control.visualFocus ? Theme.text : Theme.textMuted
            }
        }
    }

    background: Rectangle {
        color: control.down ? Theme.pressedSurface
            : control.hovered || control.visualFocus ? Theme.hoverSurface : "transparent"
        border.color: control.visualFocus ? Theme.focus : "transparent"
        border.width: control.visualFocus ? Theme.focusWidth : 0
        radius: control.compact ? Math.min(Theme.radius, 6) : Theme.radius
    }
}
