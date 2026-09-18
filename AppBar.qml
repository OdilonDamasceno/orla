pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "widgets"
import "singletons"

PanelWindow { // qmllint disable uncreatable-type
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    color: "transparent"
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    mask: Region {}

    Volume {
        id: volumeOsd
        targetScreen: root.screen
    }
}
