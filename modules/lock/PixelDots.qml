pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property int dotCount: 0
    property color dotColor: "#cdd6f4"
    property color animColor: "#cba6f7"
    property real scrollX: Math.max(0, dotsRow.implicitWidth - width)

    implicitHeight: 22
    clip: true

    onDotCountChanged: {
        const difference = dotCount - dotsModel.count
        if (difference > 0) {
            for (let index = 0; index < difference; index++) {
                dotsModel.append({ "shapeIndex": dotsModel.count })
            }
        } else if (difference < 0) {
            dotsModel.remove(dotsModel.count + difference, -difference)
        }
    }

    Behavior on scrollX {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    ListModel {
        id: dotsModel
    }

    Row {
        id: dotsRow

        x: -root.scrollX
        spacing: 1
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: dotsModel

            delegate: Item {
                id: charItem

                required property int shapeIndex

                implicitWidth: shape.implicitSize
                implicitHeight: shape.implicitSize

                PasswordCharsShape {
                    id: shape

                    anchors.centerIn: parent
                    shapeIndex: charItem.shapeIndex
                    implicitSize: 0
                    opacity: 0
                    scale: 0.5
                    shapeColor: root.animColor

                    Component.onCompleted: appearAnimation.start()

                    ParallelAnimation {
                        id: appearAnimation

                        NumberAnimation {
                            target: shape
                            property: "opacity"
                            to: 1
                            duration: 50
                        }
                        NumberAnimation {
                            target: shape
                            property: "scale"
                            to: 1
                            duration: 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                        }
                        NumberAnimation {
                            target: shape
                            property: "implicitSize"
                            to: 18
                            duration: 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                        }
                        ColorAnimation {
                            target: shape
                            property: "shapeColor"
                            from: root.animColor
                            to: root.dotColor
                            duration: 1000
                        }
                    }
                }
            }
        }
    }
}
