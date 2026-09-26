import QtQuick

Text {
    property int iconSize: 22
    property color iconColor: "#cdd6f4"
    property string symFont: ""

    font.family: symFont
    font.pixelSize: iconSize
    color: iconColor
}
