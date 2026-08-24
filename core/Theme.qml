pragma Singleton

import QtQuick

QtObject {
    id: theme

    property string activeName: "muninn"

    readonly property var palettes: ({
        oilslick: {
            background: "#050507",
            surface: "#09090d",
            surfaceRaised: "#171721",
            accent: "#9a82ff",
            accentMuted: "#b09ff2",
            text: "#f4f6fc",
            textMuted: "#a7acbd",
            textDisabled: "#777c90",
            textOnAccent: "#07070a",
            border: "#30313b",
            borderInteractive: "#676b7e",
            danger: "#ff5f7e"
        },
        muninn: {
            background: "#0f1012",
            surface: "#111214",
            surfaceRaised: "#1d1e21",
            accent: "#c9a227",
            accentMuted: "#bca550",
            text: "#eae5d8",
            textMuted: "#aaa69b",
            textDisabled: "#7f7b72",
            textOnAccent: "#0f1012",
            border: "#353537",
            borderInteractive: "#6b6962",
            danger: "#d85b43"
        },
        nevermore: {
            background: "#08070a",
            surface: "#0f0d12",
            surfaceRaised: "#1c171e",
            accent: "#c43b52",
            accentMuted: "#b56371",
            text: "#e6ded0",
            textMuted: "#b3aa9b",
            textDisabled: "#7f776b",
            textOnAccent: "#fff5e9",
            border: "#393238",
            borderInteractive: "#766d70",
            danger: "#ed536b"
        },
        talon: {
            background: "#0b0c0e",
            surface: "#101113",
            surfaceRaised: "#202124",
            accent: "#f2f0ea",
            accentMuted: "#b9b8b3",
            text: "#f2f0ea",
            textMuted: "#aaa9a5",
            textDisabled: "#747571",
            textOnAccent: "#0b0c0e",
            border: "#38393b",
            borderInteractive: "#757671",
            danger: "#ff4d4d"
        },
        ember: {
            background: "#0e0e13",
            surface: "#17171f",
            surfaceRaised: "#22222d",
            accent: "#ffbd5a",
            accentMuted: "#ad8046",
            text: "#f2ecdf",
            textMuted: "#bcb4a6",
            textDisabled: "#777168",
            textOnAccent: "#0e0e13",
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
            textOnAccent: "#0d0e16",
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
            textOnAccent: "#0c110e",
            border: "#2b3d31",
            borderInteractive: "#4f745d",
            danger: "#f07167"
        }
    })

    readonly property var palette: palettes[activeName] || palettes.muninn
    readonly property color background: palette.background
    readonly property color surface: palette.surface
    readonly property color surfaceRaised: palette.surfaceRaised
    readonly property color accent: palette.accent
    readonly property color accentMuted: palette.accentMuted
    readonly property color text: palette.text
    readonly property color textMuted: palette.textMuted
    readonly property color textDisabled: palette.textDisabled
    readonly property color textOnAccent: palette.textOnAccent
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

    readonly property int barHeight: activeName === "talon" ? controlHeight
        : activeName === "oilslick" || activeName === "nevermore" ? 44 : 40
    readonly property int edgeMargin: activeName === "nevermore" ? 8 : activeName === "ember" || activeName === "raven" || activeName === "jade" ? 4 : 0
    readonly property int barHorizontalMargin: edgeMargin
    readonly property int panelGap: 8
    readonly property int panelPadding: 16
    readonly property int controlHeight: 32
    readonly property int compactControlSize: 30
    readonly property int rowHeight: 40
    readonly property int radius: activeName === "talon" ? 0 : activeName === "muninn" ? 2 : activeName === "nevermore" ? 8 : 12
    readonly property int borderWidth: 1
    readonly property int focusWidth: 2
    readonly property int sliderTrackHeight: activeName === "talon" || activeName === "muninn" ? 6 : 8
}
