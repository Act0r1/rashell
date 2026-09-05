import QtQuick
import QtQuick.Controls
import qs.core

Button {
    id: control

    property string accessibleName: "Close"

    implicitWidth: 36
    implicitHeight: 36
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8
    hoverEnabled: true
    Accessible.name: accessibleName
    Accessible.role: Accessible.Button

    contentItem: Text {
        text: "×"
        color: control.down || control.hovered || control.activeFocus ? Theme.text : Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 20
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: control.down ? Theme.surfaceRaised
            : control.hovered || control.activeFocus ? Theme.surfaceRaised : "transparent"
        border.color: control.activeFocus ? Theme.focus : Theme.borderInteractive
        border.width: control.activeFocus ? Theme.focusWidth : Theme.borderWidth
        radius: Theme.radius
    }
}
