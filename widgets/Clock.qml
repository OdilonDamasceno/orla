import QtQuick
import Quickshell
import "../singletons"

SplashButton {
    id: root

    required property QtObject parentWindow

    text: {
        const value = Qt.locale(I18n.locale).toString(clock.date, I18n.tr("time"));
        return value.charAt(0).toUpperCase() + value.slice(1);
    }

    SideBar {
        id: side
        anchor.window: root.parentWindow
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onClicked: {
        side.visible = !side.visible;
    }
}
