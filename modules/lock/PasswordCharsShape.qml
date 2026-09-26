import QtQuick
import "shapes/material-shapes.js" as MaterialShapes
import "shapes/shapes/morph.js" as Morph

Canvas {
    id: root

    property int shapeIndex: 0
    property color shapeColor: "#cba6f7"
    property real implicitSize: 18

    width: implicitSize
    height: implicitSize

    onShapeColorChanged: requestPaint()
    onShapeIndexChanged: requestPaint()
    onImplicitSizeChanged: requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
        const context = getContext("2d")
        context.clearRect(0, 0, width, height)
        if (width <= 0 || height <= 0) return

        let polygon = null
        switch (root.shapeIndex % 7) {
        case 0:
            polygon = MaterialShapes.getClover4Leaf()
            break
        case 1:
            polygon = MaterialShapes.getArrow()
            break
        case 2:
            polygon = MaterialShapes.getPill()
            break
        case 3:
            polygon = MaterialShapes.getSoftBurst()
            break
        case 4:
            polygon = MaterialShapes.getDiamond()
            break
        case 5:
            polygon = MaterialShapes.getClamShell()
            break
        default:
            polygon = MaterialShapes.getPentagon()
            break
        }
        if (!polygon) return

        const morph = new Morph.Morph(polygon, polygon)
        const cubics = morph.asCubics(1)
        if (!cubics || cubics.length === 0) return

        const size = Math.min(root.width, root.height)
        const offsetX = root.width / 2 - size / 2
        const offsetY = root.height / 2 - size / 2

        context.save()
        context.fillStyle = root.shapeColor.toString()
        context.translate(offsetX, offsetY)
        context.scale(size, size)
        context.beginPath()
        context.moveTo(cubics[0].anchor0X, cubics[0].anchor0Y)
        for (let index = 0; index < cubics.length; index++) {
            const cubic = cubics[index]
            context.bezierCurveTo(
                cubic.control0X,
                cubic.control0Y,
                cubic.control1X,
                cubic.control1Y,
                cubic.anchor1X,
                cubic.anchor1Y
            )
        }
        context.closePath()
        context.fill()
        context.restore()
    }
}
