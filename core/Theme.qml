pragma Singleton

import QtQuick

QtObject {
    id: theme

    property string activeName: "ember"

    readonly property var palettes: ({
        ember: {
            background: "#080806",
            surface: "#0d0c08",
            surfaceRaised: "#171309",
            accent: "#ffbf18",
            accentMuted: "#a48734",
            text: "#f2e6bf",
            textMuted: "#b6a878",
            textDisabled: "#756a49",
            border: "#3d3212",
            borderInteractive: "#735f22",
            danger: "#e86a52"
        },
        raven: {
            background: "#08090d",
            surface: "#0d1017",
            surfaceRaised: "#151a25",
            accent: "#9aabff",
            accentMuted: "#7182c7",
            text: "#e4e9f7",
            textMuted: "#aab4cf",
            textDisabled: "#69738c",
            border: "#293451",
            borderInteractive: "#586b9b",
            danger: "#f07178"
        },
        jade: {
            background: "#060a08",
            surface: "#0a100c",
            surfaceRaised: "#101a14",
            accent: "#63d995",
            accentMuted: "#459b6a",
            text: "#dceee3",
            textMuted: "#9fbbaa",
            textDisabled: "#617b6b",
            border: "#1f3d2c",
            borderInteractive: "#427a58",
            danger: "#f07167"
        }
    })

    readonly property var palette: palettes[activeName] || palettes.ember
    readonly property color background: palette.background
    readonly property color surface: palette.surface
    readonly property color surfaceRaised: palette.surfaceRaised
    readonly property color accent: palette.accent
    readonly property color accentMuted: palette.accentMuted
    readonly property color text: palette.text
    readonly property color textMuted: palette.textMuted
    readonly property color textDisabled: palette.textDisabled
    readonly property color textOnAccent: palette.background
    readonly property color border: palette.border
    readonly property color borderInteractive: palette.borderInteractive
    readonly property color focus: palette.accent
    readonly property color danger: palette.danger
    readonly property color textOnDanger: palette.background

    readonly property string fontFamily: "monospace"
    readonly property int fontSmall: 11
    readonly property int fontBody: 13
    readonly property int fontTitle: 15

    readonly property int spaceXs: 2
    readonly property int spaceSm: 4
    readonly property int spaceMd: 8
    readonly property int spaceLg: 12
    readonly property int spaceXl: 16

    readonly property int barHeight: 44
    readonly property int edgeMargin: 12
    readonly property int barHorizontalMargin: 36
    readonly property int panelGap: 10
    readonly property int panelPadding: 16
    readonly property int controlHeight: 34
    readonly property int compactControlSize: 28
    readonly property int rowHeight: 40
    readonly property int radius: 2
    readonly property int borderWidth: 1
    readonly property int focusWidth: 2
    readonly property int sliderTrackHeight: 6
}
