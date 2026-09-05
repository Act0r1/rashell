pragma ComponentBehavior: Bound

import QtQuick
import qs.core

Item {
    id: root

    required property string weatherKind
    property string scenePhase: "unknown"
    property bool running: visible
    property real daylight: scenePhase === "day" ? 1 : scenePhase === "sunset" ? 0.4 : scenePhase === "unknown" ? 0.18 : 0
    property real twilight: scenePhase === "sunset" ? 1 : 0
    readonly property bool clearSky: weatherKind === "sun" || weatherKind === "partly"
    property real overcast: weatherKind === "fog" ? 0.76
        : weatherKind === "storm" ? 0.65 : weatherKind === "rain" ? 0.5 : weatherKind === "cloud" ? 0.35 : 0
    readonly property color skyTop: mixColor(mixColor(mixColor("#151329", "#3f638b", daylight), "#4b3e69", twilight), "#49465a", overcast)
    readonly property color skyMiddle: mixColor(mixColor(mixColor("#302742", "#a5b4c8", daylight), "#ca8e9a", twilight * 0.85), "#6a7080", overcast)
    readonly property color skyBottom: mixColor(mixColor("#171723", "#c9d0d9", daylight), "#dfb2a0", twilight * 0.8)

    function mixColor(first, second, amount) {
        const left = Qt.color(first)
        const right = Qt.color(second)
        return Qt.rgba(left.r + (right.r - left.r) * amount, left.g + (right.g - left.g) * amount,
            left.b + (right.b - left.b) * amount, 1)
    }

    Behavior on daylight { enabled: root.running; NumberAnimation { duration: 1200; easing.type: Easing.InOutCubic } }
    Behavior on twilight { enabled: root.running; NumberAnimation { duration: 1200; easing.type: Easing.InOutCubic } }
    Behavior on overcast { enabled: root.running; NumberAnimation { duration: 1200; easing.type: Easing.InOutCubic } }
    onDaylightChanged: skyline.requestPaint()
    onTwilightChanged: skyline.requestPaint()

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: root.skyTop }
            GradientStop { position: 0.62; color: root.skyMiddle }
            GradientStop { position: 1; color: root.skyBottom }
        }
    }

    Repeater {
        model: 26

        Rectangle {
            required property int index
            x: (index * 83 + 17) % Math.max(1, root.width)
            y: (index * 47 + 11) % Math.max(1, root.height * 0.55)
            width: 1 + index % 3 * 0.45
            height: width
            radius: width / 2
            color: "#eee7ff"
            opacity: root.clearSky && root.scenePhase !== "unknown"
                ? (0.18 + index % 5 * 0.1) * Math.max(0, 1 - root.daylight * 3) : 0
            Behavior on opacity { enabled: root.running; NumberAnimation { duration: 1000 } }
        }
    }

    Item {
        id: orb
        x: root.width * (0.75 + root.twilight * 0.05)
        y: root.height * (0.08 + root.twilight * 0.38)
        width: 76
        height: 76
        opacity: root.scenePhase === "unknown" ? 0 : root.clearSky ? 1 : 0.26
        Behavior on opacity { enabled: root.running; NumberAnimation { duration: 1000 } }

        Repeater {
            model: 4
            Rectangle {
                required property int index
                anchors.centerIn: parent
                width: 38 + index * 14
                height: width
                radius: width / 2
                color: root.daylight > 0.2 ? "#ffe5c8" : "#d9d6ff"
                opacity: 0.035
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 28 + root.daylight * 6
            height: width
            radius: width / 2
            color: root.mixColor("#dedcf7", "#fff0d3", root.daylight)
            opacity: 0.92

            Rectangle {
                x: 8
                y: -4
                width: parent.width - 2
                height: width
                radius: width / 2
                color: root.skyTop
                opacity: Math.max(0, 1 - root.daylight * 4)
            }
        }
    }

    Repeater {
        model: 4

        Item {
            id: cloud
            required property int index
            x: root.width * (0.07 + index * 0.28) + drift
            y: root.height * (0.14 + index % 2 * 0.16)
            width: root.width * (0.29 + index % 2 * 0.07)
            height: root.height * 0.14
            opacity: root.weatherKind === "sun" ? 0.06 : root.weatherKind === "partly" ? 0.2 : 0.31
            property real drift: 0
            Behavior on opacity { enabled: root.running; NumberAnimation { duration: 1000 } }

            SequentialAnimation on drift {
                running: root.running
                loops: Animation.Infinite
                NumberAnimation { from: -10; to: 10; duration: 19000 + cloud.index * 2000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 10; to: -10; duration: 19000 + cloud.index * 2000; easing.type: Easing.InOutSine }
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(0.83, 0.85, 0.92, 0.38) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            Rectangle {
                x: parent.width * 0.2
                y: -parent.height * 0.35
                width: parent.width * 0.55
                height: parent.height * 1.2
                radius: height / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(0.83, 0.85, 0.92, 0.25) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
        }
    }

    Canvas {
        id: skyline
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const context = getContext("2d")
            context.clearRect(0, 0, width, height)
            let seed = 9187
            const random = function() {
                seed = (seed * 1103515245 + 12345) & 0x7fffffff
                return seed / 0x7fffffff
            }
            const drawRange = function(base, minimumHeight, maximumHeight, minimumWidth, maximumWidth, color, windows) {
                let x = -12
                while (x < width + 12) {
                    const buildingWidth = minimumWidth + random() * (maximumWidth - minimumWidth)
                    const buildingHeight = (minimumHeight + random() * (maximumHeight - minimumHeight)) * height / 250
                    context.globalAlpha = 1
                    context.fillStyle = color
                    context.fillRect(x, base - buildingHeight, buildingWidth, buildingHeight + height * 0.25)
                    if (windows) {
                        for (let windowY = base - buildingHeight + 8; windowY < base - 5; windowY += 10) {
                            for (let windowX = x + 5; windowX < x + buildingWidth - 5; windowX += 8) {
                                if (random() > 0.76) {
                                    context.globalAlpha = (0.22 + random() * 0.48) * (1 - root.daylight * 0.78)
                                    context.fillStyle = random() > 0.4 ? "#e9caa0" : Theme.accent
                                    context.fillRect(windowX, windowY, 2, 3)
                                }
                            }
                        }
                    }
                    x += buildingWidth + 3 + random() * 7
                }
            }

            drawRange(height * 0.82, 28, 85, 22, 50, root.mixColor("#393248", "#717e94", root.daylight), false)
            drawRange(height * 1.03, 58, 135, 26, 58, root.mixColor("#161624", "#394359", root.daylight), true)
            context.globalAlpha = 1
        }

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1; color: Qt.rgba(0.06, 0.05, 0.1, 0.38) }
        }
    }

    Connections {
        target: Theme
        function onActiveNameChanged() { skyline.requestPaint() }
    }
}
