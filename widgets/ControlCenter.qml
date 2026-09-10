import QtQuick
import Quickshell
import "../singletons"

SplashButton {
    id: root

    required property QtObject parentWindow

    topPadding: 0
    bottomPadding: 0
    icon.source: "../icons/sliders-horizontal-fill.svg"
    icon.height: 20
    icon.width: 20
    Accessible.name: I18n.tr("systemControls")

    background: Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: height / 2
        color: root.down ? Theme.pressedSurface : menu.visible ? Theme.secondaryContainer : root.hovered ? Theme.hoverSurface : "transparent"
        border.width: root.visualFocus ? 1 : 0
        border.color: Theme.primary
    }

    SystemControlsPopup {
        id: menu
        anchor.window: root.parentWindow
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
    }

    onClicked: menu.visible = !menu.visible
}
