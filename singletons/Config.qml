pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property bool configDirectoryReady: false
    property bool configWriteFailed: false
    property bool writePending: false
    readonly property string homeDirectory: Quickshell.env("HOME")
    readonly property string configDirectory: (Quickshell.env("XDG_CONFIG_HOME") || homeDirectory + "/.config") + "/orla"
    readonly property string stateDirectory: Quickshell.env("XDG_STATE_HOME") || homeDirectory + "/.local/state"
    readonly property string configPath: configDirectory + "/config.json"
    readonly property string launcherStatePath: stateDirectory + "/orla-launcher.json"
    readonly property ShellScreen currentScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0] ?? null
    readonly property var settings: settingsAdapter // qmllint disable unqualified

    readonly property string locale: supportedLocale(root.settings.locale)

    readonly property string fontFamily: nonEmpty(root.settings.appearance.fontFamily, "Sunghyun Sans")
    readonly property real preferredAnimationScale: bounded(root.settings.appearance.animationScale, 0, 3, 1)
    readonly property real animationScale: root.settings.accessibility.reducedMotion ? 0 : preferredAnimationScale
    readonly property bool reducedMotion: root.settings.accessibility.reducedMotion
    readonly property string surfaceColor: validColor(root.settings.appearance.surfaceColor, "#080809")
    readonly property string islandColor: validColor(root.settings.appearance.islandColor, "#000000")
    readonly property string surfaceContainerColor: validColor(root.settings.appearance.surfaceContainerColor, "#101010")
    readonly property string surfaceContainerHighColor: validColor(root.settings.appearance.surfaceContainerHighColor, "#242424")
    readonly property string textPrimaryColor: validColor(root.settings.appearance.textPrimaryColor, "#F5F5F7")
    readonly property string textSecondaryColor: validColor(root.settings.appearance.textSecondaryColor, "#A1A1AA")
    readonly property string primaryColor: validColor(root.settings.appearance.primaryColor, "#D0BCFF")
    readonly property string primaryContentColor: validColor(root.settings.appearance.primaryContentColor, "#381E72")
    readonly property string errorColor: validColor(root.settings.appearance.errorColor, "#FFB4AB")
    readonly property string liveIndicatorColor: validColor(root.settings.appearance.liveIndicatorColor, "#FF453A")
    readonly property string outlineColor: validColor(root.settings.appearance.outlineColor, "#666666")
    readonly property string outlineVariantColor: validColor(root.settings.appearance.outlineVariantColor, "#29292E")

    readonly property string clockFormat: nonEmpty(root.settings.bar.clockFormat, "ddd d 'de' MMM hh:mm")
    readonly property bool showTray: root.settings.bar.showTray
    readonly property bool showLiveActivity: root.settings.bar.showLiveActivity

    readonly property bool liveActivityEnabled: root.settings.liveActivity.enabled
    readonly property string liveActivityTeam: nonEmpty(root.settings.liveActivity.team, "Flamengo")
    readonly property int liveActivityRefreshInterval: Math.round(bounded(root.settings.liveActivity.refreshIntervalSeconds, 15, 600, 60) * 1000)
    readonly property bool liveActivityShowBadges: root.settings.liveActivity.showBadges

    readonly property bool fileSearchEnabled: root.settings.launcher.fileSearchEnabled
    readonly property string fileSearchRoot: expandHome(nonEmpty(root.settings.launcher.fileSearchRoot, homeDirectory))
    readonly property bool browserHistoryEnabled: root.settings.launcher.browserHistoryEnabled
    readonly property string browserHistoryPath: expandHome(nonEmpty(root.settings.launcher.browserHistoryPath, homeDirectory + "/.config/BraveSoftware/Brave-Origin/Default/History"))
    readonly property int launcherMaximumResults: Math.round(bounded(root.settings.launcher.maximumResults, 1, 20, 8))
    readonly property int frequentApplicationsLimit: Math.round(bounded(root.settings.launcher.frequentApplicationsLimit, 0, 6, 6))
    readonly property url wallpaperDirectoryUrl: "file://" + expandHome(nonEmpty(root.settings.launcher.wallpaperDirectory, homeDirectory + "/.config/hypr/wallpapers"))

    readonly property int notificationDefaultTimeout: Math.round(bounded(root.settings.notifications.defaultTimeoutSeconds, 1, 60, 5) * 1000)
    readonly property int notificationHistoryLimit: Math.round(bounded(root.settings.notifications.historyLimit, 0, 500, 100))
    readonly property string notificationPosition: validNotificationPosition(root.settings.notifications.position)
    readonly property int volumeOsdDuration: Math.round(bounded(root.settings.osd.volumeDurationMilliseconds, 250, 10000, 1000))

    function bounded(value, minimum: real, maximum: real, fallback: real): real {
        const number = Number(value);
        if (!Number.isFinite(number))
            return fallback;
        return Math.max(minimum, Math.min(maximum, number));
    }

    function nonEmpty(value, fallback: string): string {
        const candidate = String(value ?? "").trim();
        return candidate.length ? candidate : fallback;
    }

    function expandHome(path: string): string {
        if (path === "~")
            return homeDirectory;
        if (path.startsWith("~/"))
            return homeDirectory + path.slice(1);
        return path;
    }

    function validColor(value, fallback: string): string {
        const candidate = String(value ?? "").trim();
        return /^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(candidate) ? candidate : fallback;
    }

    function supportedLocale(value): string {
        return ["pt_BR", "en_US"].includes(value) ? value : "pt_BR";
    }

    function validNotificationPosition(value): string {
        const candidate = String(value ?? "");
        return ["top-left", "top-right", "bottom-left", "bottom-right"].includes(candidate) ? candidate : "top-right";
    }

    function setPreference(group: string, key: string, value): void {
        const target = group.length ? root.settings[group] : root.settings;
        if (!target || target[key] === undefined)
            return;

        target[key] = value;
        root.configWriteFailed = false;
        root.writePending = true;
        saveTimer.restart();
    }

    function persistPreferences(): void {
        if (!root.writePending)
            return;

        if (root.configDirectoryReady) {
            root.writePending = false;
            configFile.writeAdapter();
        } else if (!configDirectoryProcess.running) {
            configDirectoryProcess.command = ["mkdir", "-p", root.configDirectory];
            configDirectoryProcess.running = true;
        }
    }

    Timer {
        id: saveTimer

        interval: 250
        repeat: false
        onTriggered: root.persistPreferences()
    }

    Process {
        id: configDirectoryProcess

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.configWriteFailed = true;
                root.writePending = false;
                return;
            }

            root.configDirectoryReady = true;
            root.persistPreferences();
        }
    }

    FileView {
        id: configFile

        path: root.configPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onSaved: root.configWriteFailed = false
        onSaveFailed: root.configWriteFailed = true

        JsonAdapter {
            id: settingsAdapter

            property int version: 1
            property string locale: "pt_BR"

            property JsonObject appearance: JsonObject {
                property string fontFamily: "Sunghyun Sans"
                property real animationScale: 1
                property string surfaceColor: "#080809"
                property string islandColor: "#000000"
                property string surfaceContainerColor: "#101010"
                property string surfaceContainerHighColor: "#242424"
                property string textPrimaryColor: "#F5F5F7"
                property string textSecondaryColor: "#A1A1AA"
                property string primaryColor: "#D0BCFF"
                property string primaryContentColor: "#381E72"
                property string errorColor: "#FFB4AB"
                property string liveIndicatorColor: "#FF453A"
                property string outlineColor: "#666666"
                property string outlineVariantColor: "#29292E"
            }

            property JsonObject bar: JsonObject {
                property string clockFormat: "ddd d 'de' MMM hh:mm"
                property bool showTray: true
                property bool showLiveActivity: true
            }

            property JsonObject liveActivity: JsonObject {
                property bool enabled: true
                property string team: "Flamengo"
                property int refreshIntervalSeconds: 60
                property bool showBadges: true
            }

            property JsonObject launcher: JsonObject {
                property bool fileSearchEnabled: true
                property string fileSearchRoot: "~"
                property bool browserHistoryEnabled: true
                property string browserHistoryPath: "~/.config/BraveSoftware/Brave-Origin/Default/History"
                property int maximumResults: 8
                property int frequentApplicationsLimit: 6
                property string wallpaperDirectory: "~/.config/hypr/wallpapers"
            }

            property JsonObject notifications: JsonObject {
                property int defaultTimeoutSeconds: 5
                property int historyLimit: 100
                property string position: "top-right"
            }

            property JsonObject osd: JsonObject {
                property int volumeDurationMilliseconds: 1000
            }

            property JsonObject accessibility: JsonObject {
                property bool reducedMotion: false
            }
        }
    }
}
