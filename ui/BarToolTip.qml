import QtQuick
import QtQuick.Controls
import qs.core

ToolTip {
    id: tip

    popupType: Popup.Window
    delay: 500
    timeout: 5000
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? parent.height + Theme.spaceMd : Theme.spaceMd
    margins: Theme.spaceMd
    padding: Theme.spaceMd
    implicitWidth: Math.min(320, label.implicitWidth + leftPadding + rightPadding)
    implicitHeight: label.implicitHeight + topPadding + bottomPadding

    contentItem: Text {
        id: label
        text: tip.text
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
    }

    background: Rectangle {
        color: Theme.surface
        border.color: Theme.borderInteractive
        border.width: Theme.borderWidth
        radius: Theme.radius
    }
}
