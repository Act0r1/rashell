pragma Singleton

import QtQuick

QtObject {
    id: theme

    property string activeName: "ember"

    readonly property var palettes: ({
        ember: {
            background: "#0e0e13",
            surface: "#17171f",
            surfaceRaised: "#22222d",
            accent: "#ffbd5a",
            accentMuted: "#ad8046",
            text: "#f2ecdf",
            textMuted: "#bcb4a6",
            textDisabled: "#777168",
            border: "#32303a",
            borderInteractive: "#7a6a55",
            danger: "#ef6f6c"
        },
        raven: {
            background: "#0d0e16",
            surface: "#171824",
            surfaceRaised: "#222438",
            accent: "#a79aff",
            accentMuted: "#756eb8",
            text: "#ebe9ff",
            textMuted: "#b6b3ce",
            textDisabled: "#74728a",
            border: "#303247",
            borderInteractive: "#686b94",
            danger: "#f07178"
        },
        jade: {
            background: "#0c110e",
            surface: "#151d18",
            surfaceRaised: "#202c25",
            accent: "#73dfa1",
            accentMuted: "#4f9d71",
            text: "#e2f2e8",
            textMuted: "#a9c1b2",
            textDisabled: "#6c7e72",
            border: "#2b3d31",
            borderInteractive: "#4f745d",
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

    readonly property string fontFamily: "ComicShannsMono Nerd Font"
    readonly property int fontSmall: 12
    readonly property int fontBody: 14
    readonly property int fontTitle: 16

    readonly property int spaceXs: 2
    readonly property int spaceSm: 4
    readonly property int spaceMd: 8
    readonly property int spaceLg: 12
    readonly property int spaceXl: 16

    readonly property int barHeight: 40
    readonly property int edgeMargin: 4
    readonly property int barHorizontalMargin: 4
    readonly property int panelGap: 8
    readonly property int panelPadding: 16
    readonly property int controlHeight: 32
    readonly property int compactControlSize: 30
    readonly property int rowHeight: 40
    readonly property int radius: 10
    readonly property int borderWidth: 1
    readonly property int focusWidth: 2
    readonly property int sliderTrackHeight: 6
}
