//@ pragma UseQApplication

import Quickshell
import QtQuick
import "surfaces"

Scope {
    NotificationOverlay {}

    TopIsland {}

    Variants {
        model: Quickshell.screens
        delegate: Component {
            ScreenBar {
                required property var modelData
                screen: modelData
            }
        }
    }
}
