pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../singletons"

Button {
    id: root
    required property string title
    required property string status
    required property url iconSource
    property bool active: false
    readonly property color contentColor: active ? Theme.primaryContent : Theme.textPrimary

    implicitHeight: Theme.quickTileHeight
    padding: Theme.spacingCompact
    hoverEnabled: true
    Accessible.name: title
    Accessible.description: status + ". " + I18n.tr("openDetails")
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()

    background: Rectangle {
        radius: root.active ? Theme.radiusMedium : height / 2
        color: root.active ? Theme.primary : Theme.surfaceContainerHigh
        border.width: root.visualFocus ? 2 : 0
        border.color: root.active ? Theme.primaryContent : Theme.primary
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.contentColor
            opacity: root.down ? 0.16 : root.hovered ? 0.08 : 0
        }
        Behavior on radius {
            NumberAnimation { duration: Theme.feedbackDuration }
        }
        Behavior on color {
            ColorAnimation { duration: Theme.feedbackDuration }
        }
    }

    contentItem: RowLayout {
        spacing: Theme.spacingMedium
        Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: root.iconSource
            color: root.contentColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall
            Text {
                Layout.fillWidth: true
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                font.weight: Font.DemiBold
                color: root.contentColor
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.status
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                color: root.active ? root.contentColor : Theme.textSecondary
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }
    }
    ToolTip.visible: hovered
    ToolTip.delay: 700
    ToolTip.text: status
}
