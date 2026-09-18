import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell
import "../components"
import "../singletons"

RowLayout {
    spacing: -10

    Repeater {
        model: SystemTray.items

        delegate: StateLayerButton {
            id: tray

            required property SystemTrayItem modelData

            Layout.fillHeight: true
            leftPadding: Theme.spacingCompact
            rightPadding: Theme.spacingCompact
            Accessible.name: modelData.title || modelData.id

            icon.source: modelData.icon
            icon.color: "transparent"
            onClicked: {
                if (modelData.onlyMenu && modelData.hasMenu)
                    menuAnchor.open();
                else
                    modelData.activate();
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: tray.modelData.menu // qmllint disable unresolved-type
                anchor.item: tray
                anchor.margins.top: tray.height
                anchor.margins.right: 10
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: function (mouse) {
                    if (tray.modelData.hasMenu)
                        menuAnchor.open();
                }
            }
        }
    }
}
