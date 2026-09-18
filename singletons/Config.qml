pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    readonly property ShellScreen currentScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0] ?? null
    readonly property url wallpaperDirectoryUrl: "file://" + Quickshell.env("HOME") + "/.config/hypr/wallpapers"
}
