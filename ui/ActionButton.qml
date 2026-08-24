import QtQuick
import QtQuick.Controls
import qs.core

Button {
    id: control

    property bool selected: false
    property bool danger: false
    property string accessibleName: text

    implicitHeight: Theme.compactControlSize
    implicitWidth: Math.max(Theme.compactControlSize, contentItem.implicitWidth + Theme.spaceLg * 2)
    hoverEnabled: true
    Accessible.name: accessibleName
    Accessible.role: Accessible.Button

    contentItem: Text {
        text: control.text
        color: control.selected ? Theme.textOnAccent
            : control.danger ? Theme.danger : control.enabled ? Theme.text : Theme.textDisabled
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        font.bold: control.selected
        elide: Text.ElideRight
        maximumLineCount: 1
        clip: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: control.selected ? Theme.accent
            : control.down || control.hovered ? Theme.surfaceRaised : "transparent"
        border.color: control.activeFocus ? Theme.focus
            : control.selected ? Theme.accent
            : control.danger ? Theme.danger : Theme.borderInteractive
        border.width: control.activeFocus ? Theme.focusWidth : Theme.borderWidth
        radius: Theme.radius
    }
}
