pragma Singleton

import QtQuick

QtObject {
    readonly property color background: "#080806"
    readonly property color surface: "#0d0c08"
    readonly property color surfaceRaised: "#141108"
    readonly property color accent: "#ffbf18"
    readonly property color accentMuted: "#8f742a"
    readonly property color text: "#d6c58f"
    readonly property color textMuted: "#756a49"
    readonly property color border: "#3d3212"
    readonly property color danger: "#e35b45"

    readonly property string fontFamily: "monospace"
    readonly property int fontSmall: 11
    readonly property int fontBody: 13
    readonly property int fontTitle: 15

    readonly property int barHeight: 44
    readonly property int edgeMargin: 12
    readonly property int panelGap: 10
    readonly property int panelPadding: 16
    readonly property int controlHeight: 34
    readonly property int radius: 2
}
