pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
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

    Volume {
        id: volumeOsd
        targetScreen: root.screen
    }

    RowLayout {
        anchors.fill: parent
        anchors.rightMargin: Theme.spacingMedium
        spacing: -20

        Item {
            Layout.fillWidth: true
        }

        Tray {
            Layout.fillHeight: true
        }

        ControlCenter {
            parentWindow: root
            leftPadding: Theme.barItemHorizontalPadding
            rightPadding: Theme.barItemHorizontalPadding
            Layout.fillHeight: true
        }

        Clock {
            parentWindow: root
            leftPadding: Theme.barItemHorizontalPadding
            rightPadding: Theme.barItemHorizontalPadding
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignRight
        }
    }
}
