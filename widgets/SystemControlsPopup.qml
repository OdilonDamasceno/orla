pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import "../singletons"

PopupWindow {
    id: root

    readonly property real availableHeight: Math.max(1, (screen?.height ?? 600) - Theme.barHeight - Theme.spacingLarge)

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight + Theme.spacingMedium * 2
    color: "transparent"
    anchor.adjustment: PopupAdjustment.Slide
    grabFocus: true

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.visible
        onActivated: panel.page === "home" ? root.visible = false : panel.navigate("home")
    }

    RectangularShadow {
        anchors.fill: popupSurface
        radius: popupSurface.radius
        blur: Theme.floatingShadowBlur
        offset: Qt.vector2d(0, Theme.floatingShadowOffset)
        color: Theme.floatingShadow
    }

    Rectangle {
        id: popupSurface

        anchors.fill: parent
        anchors.topMargin: Theme.spacingMedium
        anchors.bottomMargin: Theme.spacingMedium
        radius: Theme.radiusExtraLarge
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        clip: true

        SystemControlsPanel {
            id: panel

            anchors.fill: parent
            active: root.visible
            maximumHeight: root.availableHeight - Theme.spacingMedium * 2
            onCloseRequested: root.visible = false
        }
    }
}
