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
        color: Theme.surfaceRaised
        border.color: Theme.borderInteractive
        border.width: Theme.borderWidth

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: Theme.accent
        }

    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: 12
        height: 20
        color: control.pressed || control.activeFocus ? Theme.accent : Theme.text
        border.color: control.activeFocus ? Theme.focus : Theme.background
        border.width: control.activeFocus ? Theme.focusWidth : Theme.borderWidth
        radius: 1
    }

}
