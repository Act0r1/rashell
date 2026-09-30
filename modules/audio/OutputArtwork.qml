import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: artwork

    property string kind: "speaker"
    property color tint: Theme.accent

    implicitWidth: 64
    implicitHeight: 64

    Image {
        anchors.fill: parent
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectFit
        source: "data:image/svg+xml;utf8," + encodeURIComponent(svg.text().replace(/currentColor/g, artwork.tint.toString()))
    }

    FileView {
        id: svg
        path: Quickshell.shellDir + "/assets/icons/phosphor/"
            + (artwork.kind === "headphones" ? "headphones" : "speaker-hifi") + "-duotone.svg"
        blockLoading: true
    }
}
