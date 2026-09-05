pragma ComponentBehavior: Bound

import QtQuick
import qs.core

Rectangle {
    id: scene

    required property int weatherCode
    property bool refreshing: false
    property string scenePhase: "unknown"
    property bool active: visible
    property bool stale: false

    readonly property string weatherKind: classify(weatherCode)
    readonly property real fogAmount: weatherKind === "fog" ? 0.76
        : weatherKind === "storm" ? 0.48
        : weatherKind === "rain" ? 0.34
        : weatherKind === "cloud" ? 0.18
        : weatherKind === "snow" ? 0.26
        : weatherKind === "partly" ? 0.08 : 0.025
    readonly property real rainAmount: weatherKind === "storm" ? 0.8
        : weatherKind === "rain" ? 0.56 : 0
    readonly property real snowAmount: weatherKind === "snow" ? 0.64 : 0
    readonly property real cloudAmount: weatherKind === "sun" ? 0
        : weatherKind === "partly" ? 0.24
        : weatherKind === "fog" ? 0.9 : 0.62
    readonly property real stormAmount: weatherKind === "storm" ? 1 : 0
    readonly property real dropRate: weatherKind === "storm" ? 0.72
        : weatherKind === "rain" ? 0.46
        : weatherKind === "fog" ? 0.025 : 0

    function classify(code) {
        if (code === 113) return "sun"
        if (code === 116) return "partly"
        if ([143, 248, 260].indexOf(code) !== -1) return "fog"
        if ([200, 386, 389, 392, 395].indexOf(code) !== -1) return "storm"
        if ([179, 182, 185, 227, 230, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].indexOf(code) !== -1) return "snow"
        if ([176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 317, 320, 353, 356, 359].indexOf(code) !== -1) return "rain"
        return "cloud"
    }

    width: 328
    height: 176
    radius: Theme.radius
    color: Theme.surfaceRaised
    clip: true

    CityScene {
        id: city
        anchors.fill: parent
        weatherKind: scene.weatherKind
        scenePhase: scene.scenePhase
        running: scene.active && !scene.stale
    }

    GlassPane {
        visible: GraphicsInfo.api !== GraphicsInfo.Software
        anchors.fill: parent
        scene: city
        running: scene.active && !scene.stale
        fog: scene.fogAmount
        dropRate: scene.dropRate
        dropSize: 1
        bend: 0.055
        blurRadius: 18
        rainAmount: scene.rainAmount
        snowAmount: scene.snowAmount
        cloudAmount: scene.cloudAmount
        stormAmount: scene.stormAmount
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0.04, 0.03, 0.09, 0.26) }
            GradientStop { position: 0.3; color: Qt.rgba(0.04, 0.03, 0.09, 0.08) }
            GradientStop { position: 0.62; color: Qt.rgba(0.04, 0.03, 0.09, 0.35) }
            GradientStop { position: 1; color: Qt.rgba(0.04, 0.03, 0.09, 0.79) }
        }
        radius: scene.radius
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: Theme.borderWidth
    }

    Text {
        anchors {
            right: parent.right
            rightMargin: Theme.spaceMd
            bottom: parent.bottom
            bottomMargin: Theme.spaceSm
        }
        visible: scene.refreshing
        text: "REFRESHING"
        color: Qt.rgba(1, 1, 1, 0.72)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.bold: true
    }
}
