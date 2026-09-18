pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    readonly property string homeDirectory: Quickshell.env("HOME")
    readonly property string stateDirectory: Quickshell.env("XDG_STATE_HOME") || homeDirectory + "/.local/state"
    readonly property ShellScreen currentScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0] ?? null
    readonly property string fileSearchRoot: homeDirectory
    readonly property string braveOriginHistoryPath: homeDirectory + "/.config/BraveSoftware/Brave-Origin/Default/History"
    readonly property string launcherStatePath: stateDirectory + "/orla-launcher.json"
    readonly property url wallpaperDirectoryUrl: "file://" + homeDirectory + "/.config/hypr/wallpapers"
}
