import QtQuick
import QtQuick.Layouts
import Quickshell
import "../singletons"

PopupWindow {
    id: root

    implicitWidth: Math.min(400, screen ? screen.width : 400)
    implicitHeight: Math.max(1, (screen ? screen.height : 600) - Theme.barHeight)
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingLarge

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: I18n.tr("sidePanel")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.titleSize
                    color: Theme.textPrimary
                }

                SplashButton {
                    icon.source: "../icons/x.svg"
                    Accessible.name: I18n.tr("closePanel")
                    onClicked: root.visible = false
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: I18n.tr("sidePanelEmpty")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
            }
        }
    }
}
