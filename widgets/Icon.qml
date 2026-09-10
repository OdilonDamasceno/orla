pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

Item {
    id: root

    property alias source: image.source
    property color color: "transparent"

    implicitWidth: 14
    implicitHeight: 14

    Image {
        id: image
        anchors.fill: parent
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
        layer.enabled: root.color.a > 0
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: root.color
        }
    }
}
