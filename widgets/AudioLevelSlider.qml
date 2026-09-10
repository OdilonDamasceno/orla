pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../singletons"

Slider {
    id: root

    required property var audio
    property url iconSource: "../icons/speaker-high.svg"

    enabled: audio !== null
    hoverEnabled: true
    implicitHeight: Theme.controlTargetSize
    leftPadding: Theme.sliderIconSize + Theme.spacingCompact
    rightPadding: Theme.controlTargetSize + Theme.spacingMedium
    from: 0
    to: 1
    stepSize: 0.01
    value: Math.max(0, Math.min(1, audio?.volume ?? 0))
    Accessible.name: I18n.tr("volume")
    opacity: enabled ? 1 : 0.5

    onMoved: {
        if (audio) {
            audio.volume = value;
            if (value > 0)
                audio.muted = false;
        }
    }

    Icon {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.sliderIconSize
        height: Theme.sliderIconSize
        source: root.iconSource
        color: Theme.textSecondary
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.controlTargetSize
        text: root.audio ? Math.round(root.value * 100) + "%" : "—"
        horizontalAlignment: Text.AlignRight
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.labelSize
    }

    background: Item {
        id: track

        // Keep the handle center and both track segments aligned at every value.
        x: root.leftPadding + Theme.sliderHandleWidth / 2
        y: (root.height - height) / 2
        width: Math.max(0, root.availableWidth - Theme.sliderHandleWidth)
        height: Theme.sliderTrackHeight
        readonly property real handleCenter: root.visualPosition * width
        readonly property real halfGap: Theme.sliderHandleWidth / 2 + Theme.sliderHandleGap

        Rectangle {
            id: leadingTrack
            width: Math.max(0, track.handleCenter - track.halfGap)
            height: track.height
            color: root.mirrored ? Theme.secondaryContainer : Theme.primary
            topLeftRadius: height / 2
            bottomLeftRadius: height / 2
            topRightRadius: Theme.sliderInsideRadius
            bottomRightRadius: Theme.sliderInsideRadius

            Rectangle {
                visible: root.mirrored && leadingTrack.width > Theme.sliderTrackHeight
                x: Theme.sliderTrackHeight / 2 - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.spacingSmall
                height: width
                radius: width / 2
                color: Theme.primary
            }
        }

        Rectangle {
            id: trailingTrack
            x: Math.min(track.width, track.handleCenter + track.halfGap)
            width: Math.max(0, track.width - x)
            height: track.height
            color: root.mirrored ? Theme.primary : Theme.secondaryContainer
            topLeftRadius: Theme.sliderInsideRadius
            bottomLeftRadius: Theme.sliderInsideRadius
            topRightRadius: height / 2
            bottomRightRadius: height / 2

            Rectangle {
                visible: !root.mirrored && trailingTrack.width > Theme.sliderTrackHeight
                x: parent.width - Theme.sliderTrackHeight / 2 - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.spacingSmall
                height: width
                radius: width / 2
                color: Theme.primary
            }
        }
    }

    handle: Item {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: (root.height - height) / 2
        implicitWidth: Theme.sliderHandleWidth
        implicitHeight: Theme.sliderHandleHeight

        Rectangle {
            anchors.centerIn: parent
            width: Theme.spacingLarge
            height: Theme.controlTargetSize
            radius: width / 2
            color: Qt.alpha(Theme.primary, root.pressed ? 0.16 : 0.08)
            visible: root.hovered || root.pressed || root.visualFocus
            border.width: root.visualFocus ? 1 : 0
            border.color: Theme.primary
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.pressed ? Theme.sliderHandleWidth / 2 : Theme.sliderHandleWidth
            height: Theme.sliderHandleHeight
            radius: width / 2
            color: Theme.primary
        }
    }
}
