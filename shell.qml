pragma ComponentBehavior: Bound
//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import QtQuick
import "services"
import "singletons"
import "surfaces"

Scope {
    id: root

    readonly property var activeTopBar: {
        const currentScreenName = Config.currentScreen?.name;
        return topBars.instances.find(topBar => topBar.screen?.name === currentScreenName) ?? topBars.instances[0] ?? null;
    }

    function closeLaunchers(): void {
        topBars.instances.forEach(topBar => topBar.closeLauncher());
    }

    function closeInactiveOverlays(activeTopBar): void {
        topBars.instances.forEach(topBar => {
            if (topBar === activeTopBar)
                return;

            topBar.closeLauncher();
            topBar.closeControls();
        });
    }

    NotificationOverlay {}

    LiveMatchService {
        id: liveMatchService
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.closeInactiveOverlays(root.activeTopBar);
            root.activeTopBar?.toggleApplicationLauncher();
        }

        function close(): void {
            root.closeLaunchers();
        }

        function isOpen(): bool {
            return root.activeTopBar?.launcherOpen ?? false;
        }
    }

    IpcHandler {
        target: "wallpapers"

        function toggle(): void {
            root.closeInactiveOverlays(root.activeTopBar);
            root.activeTopBar?.toggleWallpaperLauncher();
        }

        function close(): void {
            root.closeLaunchers();
        }

        function isOpen(): bool {
            return (root.activeTopBar?.launcherOpen ?? false) && (root.activeTopBar?.wallpaperMode ?? false);
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            root.closeInactiveOverlays(root.activeTopBar);
            root.activeTopBar?.toggleSettings();
        }

        function close(): void {
            root.activeTopBar?.closeControls();
        }

        function isOpen(): bool {
            return root.activeTopBar?.settingsOpen() ?? false;
        }
    }

    Variants {
        id: topBars

        model: Quickshell.screens
        delegate: Component {
            TopBar {
                required property var modelData
                screen: modelData
                liveMatch: liveMatchService.match
                liveMatchHomeBadgeUrl: liveMatchService.homeBadgeUrl
                liveMatchAwayBadgeUrl: liveMatchService.awayBadgeUrl
            }
        }
    }
}
