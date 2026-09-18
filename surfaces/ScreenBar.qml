pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "../singletons"
import "../widgets"

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

    VolumeOsd {
        id: volumeOsd
        targetScreen: root.screen
    }
}
