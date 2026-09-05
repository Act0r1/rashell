import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property Item scene

    property bool running: visible
    property real fog: 0.7
    property real dropRate: 0.55
    property real dropSize: 1.0
    property real bend: 0.055
    property real blurRadius: 24
    property real rainAmount: 0.0
    property real snowAmount: 0.0
    property real cloudAmount: 0.0
    property real stormAmount: 0.0
    property real wipeRadius: 34
    property real refogSeconds: 6
    property real accumulatedFrameTime: 0
    property real maskActivity: 0

    clip: true

    ShaderEffectSource {
        id: sharpSource
        anchors.fill: parent
        sourceItem: root.scene
        hideSource: root.visible
        live: root.running && root.visible
        visible: false
    }

    MultiEffect {
        id: blurPass
        anchors.fill: parent
        source: sharpSource
        blurEnabled: true
        blur: 1
        blurMax: Math.round(root.blurRadius)
        brightness: -0.08
        saturation: -0.05
        layer.enabled: true
    }

    ShaderEffectSource {
        id: blurredSource
        anchors.fill: parent
        sourceItem: blurPass
        hideSource: root.visible
        live: root.running && root.visible
        visible: false
    }

    Canvas {
        id: wipeCanvas
        anchors.fill: parent
        canvasSize: Qt.size(Math.max(1, Math.ceil(width * 0.5)), Math.max(1, Math.ceil(height * 0.5)))
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative
        visible: false

        property var strokes: []
        property real decay: 0.01

        onPaint: {
            const context = getContext("2d")
            const scaleX = canvasSize.width / Math.max(1, width)
            const scaleY = canvasSize.height / Math.max(1, height)
            const radiusX = root.wipeRadius * scaleX
            const radiusY = root.wipeRadius * scaleY
            context.globalCompositeOperation = "destination-out"
            context.fillStyle = Qt.rgba(0, 0, 0, decay)
            context.fillRect(0, 0, canvasSize.width, canvasSize.height)
            context.globalCompositeOperation = "source-over"

            for (const stroke of strokes) {
                const strokeX = stroke.x * scaleX
                const strokeY = stroke.y * scaleY
                const gradient = context.createRadialGradient(
                    strokeX, strokeY, 0,
                    strokeX, strokeY, Math.max(radiusX, radiusY)
                )
                gradient.addColorStop(0, Qt.rgba(1, 1, 1, 0.95))
                gradient.addColorStop(0.72, Qt.rgba(1, 1, 1, 0.52))
                gradient.addColorStop(1, Qt.rgba(1, 1, 1, 0))
                context.fillStyle = gradient
                context.beginPath()
                context.ellipse(
                    strokeX - radiusX,
                    strokeY - radiusY,
                    radiusX * 2,
                    radiusY * 2
                )
                context.fill()
            }
            strokes = []
        }
    }

    ShaderEffectSource {
        id: wipeSource
        anchors.fill: parent
        sourceItem: wipeCanvas
        hideSource: root.visible
        live: root.running && root.visible
        visible: false
    }

    ShaderEffect {
        id: glass
        anchors.fill: parent

        property real time: 0
        property real fog: root.fog
        Behavior on fog { enabled: root.running; NumberAnimation { duration: 1100; easing.type: Easing.InOutCubic } }
        property real dropRate: root.dropRate
        Behavior on dropRate { enabled: root.running; NumberAnimation { duration: 1100; easing.type: Easing.InOutCubic } }
        property real dropSize: root.dropSize
        property real bend: root.bend
        property real aspect: width / Math.max(1, height)
        property real rainAmount: root.rainAmount
        Behavior on rainAmount { enabled: root.running; NumberAnimation { duration: 1100; easing.type: Easing.InOutCubic } }
        property real snowAmount: root.snowAmount
        Behavior on snowAmount { enabled: root.running; NumberAnimation { duration: 1100; easing.type: Easing.InOutCubic } }
        property real cloudAmount: root.cloudAmount
        Behavior on cloudAmount { enabled: root.running; NumberAnimation { duration: 1100; easing.type: Easing.InOutCubic } }
        property real stormAmount: root.stormAmount
        Behavior on stormAmount { enabled: root.running; NumberAnimation { duration: 1100; easing.type: Easing.InOutCubic } }
        property var sharp: sharpSource
        property var blurred: blurredSource
        property var wipe: wipeSource

        fragmentShader: Qt.resolvedUrl("shaders/rainglass.frag.qsb")
    }

    FrameAnimation {
        running: root.running && root.visible
        onTriggered: {
            root.accumulatedFrameTime += frameTime
            if (root.accumulatedFrameTime < 1 / 60) return

            const elapsed = root.accumulatedFrameTime
            root.accumulatedFrameTime = 0
            glass.time += elapsed
            if (root.maskActivity <= 0) return

            wipeCanvas.decay = 1 - Math.exp(-elapsed * 5 / Math.max(0.5, root.refogSeconds))
            wipeCanvas.requestPaint()
            root.maskActivity = Math.max(0, root.maskActivity - elapsed)
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: mouse => {
            wipeCanvas.strokes.push({ x: mouse.x, y: mouse.y })
            root.maskActivity = root.refogSeconds * 1.5
        }
    }
}
