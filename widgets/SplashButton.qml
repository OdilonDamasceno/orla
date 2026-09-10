import QtQuick
import QtQuick.Controls
import "../singletons"

Button {
    id: root

    font.pixelSize: Theme.labelSize
    font.weight: Font.Medium
    font.family: Theme.fontFamily
    icon.color: "transparent"
    palette.buttonText: Theme.textPrimary
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5

    leftPadding: 14
    rightPadding: 14
    topPadding: 6
    bottomPadding: 6

    background: Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: height / 2
        color: root.down ? Theme.pressedSurface : root.hovered ? Theme.hoverSurface : "transparent"
        border.width: root.visualFocus ? 1 : 0
        border.color: Theme.primary
    }
}
