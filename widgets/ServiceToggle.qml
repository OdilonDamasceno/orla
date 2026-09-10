pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons"

Switch {
    id: root

    required property string title
    required property string status
    required property url iconSource

    implicitHeight: Theme.serviceRowHeight
    leftPadding: Theme.spacingCompact
    rightPadding: Theme.spacingCompact
    topPadding: Theme.spacingMedium
    bottomPadding: Theme.spacingMedium
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: root.title
    Accessible.description: root.status
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()

    indicator: Item {}
    background: Rectangle {
        radius: Theme.radiusMedium
        color: root.down ? Theme.pressedSurface : root.hovered && root.enabled ? Theme.hoverSurface : "transparent"
        border.width: root.visualFocus ? 2 : 0
        border.color: Theme.primary

        Behavior on color {
            ColorAnimation { duration: Theme.feedbackDuration }
        }
    }

    contentItem: RowLayout {
        spacing: Theme.spacingCompact
        opacity: root.enabled ? 1 : 0.5

        Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: root.iconSource
            color: root.checked ? Theme.primary : Theme.textSecondary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                Layout.fillWidth: true
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                font.weight: Font.Medium
                color: Theme.textPrimary
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.status
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 32
            radius: height / 2
            color: root.checked ? Theme.primary : Theme.surfaceContainerHigh
            border.width: root.checked ? 0 : 2
            border.color: Theme.outline

            Rectangle {
                x: root.checked ? 24 : 8
                anchors.verticalCenter: parent.verticalCenter
                width: root.checked ? 24 : 16
                height: width
                radius: width / 2
                color: root.checked ? Theme.primaryContent : Theme.textSecondary

                Behavior on x {
                    NumberAnimation { duration: Theme.feedbackDuration; easing.type: Easing.OutCubic }
                }
                Behavior on width {
                    NumberAnimation { duration: Theme.feedbackDuration; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    ToolTip.visible: hovered && status.length > 0
    ToolTip.delay: 700
    ToolTip.text: status
}
