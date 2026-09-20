pragma ComponentBehavior: Bound

import QtQuick
import "../singletons"

Item {
    id: root

    required property string teamName
    property url badgeUrl: ""

    implicitWidth: 16
    implicitHeight: 16

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.surfaceContainerHigh
        visible: badge.status !== Image.Ready

        Text {
            anchors.centerIn: parent
            text: root.teamName.charAt(0).toUpperCase()
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }
    }

    Image {
        id: badge

        anchors.fill: parent
        source: root.badgeUrl
        sourceSize.width: 36
        sourceSize.height: 36
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
    }
}
