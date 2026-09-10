//@ pragma UseQApplication

import Quickshell
import QtQuick
import "widgets"

Scope {
    Notification {}

    ApplicationLauncher {}

    Variants {
        model: Quickshell.screens
        delegate: Component {
            AppBar {
                required property var modelData
                screen: modelData
            }
        }
    }
}
