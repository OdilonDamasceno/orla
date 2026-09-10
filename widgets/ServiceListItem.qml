pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons"

Button {
    id: root
    required property string title
    required property string subtitle
    property url iconSource: "../icons/check.svg"
    property string actionText: ""
    property bool selected: false

    implicitHeight: Theme.serviceRowHeight
    padding: Theme.spacingCompact
    hoverEnabled: true
    Accessible.name: title
    Accessible.description: subtitle + ". " + actionText
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    background: Rectangle {
        radius: Theme.radiusMedium
        color: root.down ? Theme.pressedSurface : root.hovered ? Theme.hoverSurface : root.selected ? Theme.secondaryContainer : Theme.surfaceContainerHigh
        border.width: root.visualFocus ? 2 : 0
        border.color: Theme.primary
    }
    contentItem: RowLayout {
        spacing: Theme.spacingMedium
        opacity: root.enabled ? 1 : 0.5
        Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: root.selected ? "../icons/check.svg" : root.iconSource
            color: root.selected ? Theme.primary : Theme.textSecondary
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
                text: root.subtitle
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
        }
        Text {
            visible: text.length > 0
            text: root.actionText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSize
            color: Theme.primary
        }
    }
    ToolTip.visible: hovered
    ToolTip.delay: 700
    ToolTip.text: title + "\n" + subtitle
}
