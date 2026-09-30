import QtQuick
import QtQuick.Controls
import qs.core

Button {
    id: control

    property bool selected: false
    property bool subtleSelected: false
    property bool danger: false
    property int alignment: Text.AlignHCenter
    property string accessibleName: text
    property string toolTipText: accessibleName

    flat: false
    implicitHeight: Theme.compactControlSize
    implicitWidth: Math.max(Theme.compactControlSize, contentItem.implicitWidth + Theme.spaceLg * 2)
    hoverEnabled: true
    Accessible.name: accessibleName
    Accessible.role: Accessible.Button

    ToolTip {
        id: tip

        visible: control.hovered && control.toolTipText !== ""
        delay: 450
        timeout: 5000
        text: control.toolTipText
        y: -implicitHeight - Theme.spaceSm
        leftPadding: Theme.spaceLg
        rightPadding: Theme.spaceLg
        topPadding: Theme.spaceMd
        bottomPadding: Theme.spaceMd

        contentItem: Text {
            text: tip.text
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        background: Rectangle {
            color: Theme.surfaceRaised
            border.color: Theme.accentMuted
            border.width: Theme.borderWidth
            radius: Math.max(6, Theme.radius)
        }
    }

    contentItem: Text {
        text: control.text
        color: control.selected && !control.subtleSelected ? Theme.textOnAccent
            : control.selected ? Theme.accent
            : control.danger ? Theme.danger : control.enabled ? Theme.text : Theme.textDisabled
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        font.bold: control.selected
        elide: Text.ElideRight
        maximumLineCount: 1
        clip: true
        horizontalAlignment: control.alignment
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: control.selected && !control.subtleSelected
            ? (control.down ? Theme.accentPressed : control.hovered ? Theme.accentHover : Theme.accent)
            : control.selected ? (control.down ? Theme.selectedPressedSurface : control.hovered ? Theme.selectedHoverSurface : Theme.selectedSurface)
            : control.down ? Theme.pressedSurface
            : control.hovered ? Theme.hoverSurface
            : control.flat ? "transparent" : Theme.surface
        border.color: control.visualFocus ? (control.selected && !control.subtleSelected ? Theme.textOnAccent : Theme.focus)
            : control.danger ? Theme.danger
            : control.selected || control.down ? Theme.accent
            : control.hovered ? Theme.borderInteractive : Theme.border
        border.width: control.visualFocus ? Theme.focusWidth
            : !control.flat || control.hovered || control.down ? Theme.borderWidth : 0
        radius: Theme.radius
    }
}
