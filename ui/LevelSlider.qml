import QtQuick
import QtQuick.Controls
import qs.core

Slider {
    id: control

    property string accessibleName: "Level"
    property string accessibleDescription: Math.round(value * 100) + " percent"

    implicitHeight: Theme.controlHeight

    from: 0
    to: 1
    stepSize: 0.05
    hoverEnabled: true
    Accessible.name: accessibleName
    Accessible.role: Accessible.Slider
    Accessible.description: accessibleDescription

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: Theme.sliderTrackHeight
        color: Theme.borderInteractive
        radius: Math.min(Theme.radius, height / 2)

        Rectangle {
            x: control.mirrored ? parent.width - width : 0
            width: control.position * parent.width
            height: parent.height
            radius: parent.radius
            color: control.enabled ? Theme.accent : Theme.textDisabled
        }

    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: Theme.spaceXl
        height: Theme.spaceXl
        color: !control.enabled ? Theme.textDisabled
            : control.pressed || control.hovered || control.visualFocus ? Theme.accent : Theme.text
        border.color: control.visualFocus ? Theme.focus : Theme.background
        border.width: control.visualFocus ? Theme.focusWidth : Theme.borderWidth
        radius: Math.min(Theme.radius, width / 2)
    }

}
