pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../services"
import "../singletons"
import "../widgets"

PanelWindow { // qmllint disable uncreatable-type
    id: root

    // A compact island that expands around the search results.
    property bool launcherOpen: false
    property bool controlsOpen: false
    readonly property bool wallpaperMode: launcherBackend.wallpaperMode
    readonly property bool expanded: launcherOpen && (launcherBackend.normalizedQuery.length > 0 || wallpaperMode)
    readonly property int resultRowHeight: wallpaperMode ? 80 : 72
    readonly property real collapsedWidth: Math.ceil(clockButtonLabel.implicitWidth + Theme.spacingLarge * 2)
    readonly property var searchResults: launcherBackend.results

    function closeLauncher() {
        launcherOpen = false;
        launcherBackend.mode = LauncherBackend.Applications;
        launcherBackend.errorMessage = "";
        search.clear();
    }

    function toggleLauncher(mode: int): void {
        if (launcherOpen && launcherBackend.mode === mode) {
            closeLauncher();
        } else {
            screen = Config.currentScreen;
            controlsOpen = false;
            launcherBackend.mode = mode;
            launcherBackend.errorMessage = "";
            search.clear();
            launcherOpen = true;
            Qt.callLater(() => search.forceActiveFocus());
        }
    }

    function closeControls(): void {
        controlsOpen = false;
    }

    function toggleControls(): void {
        if (controlsOpen) {
            closeControls();
        } else {
            closeLauncher();
            controlsOpen = true;
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.toggleLauncher(LauncherBackend.Applications);
        }
        function close(): void {
            root.closeLauncher();
        }
        function isOpen(): bool {
            return root.launcherOpen;
        }
    }

    IpcHandler {
        target: "wallpapers"
        function toggle(): void {
            root.toggleLauncher(LauncherBackend.Wallpapers);
        }
        function close(): void {
            root.closeLauncher();
        }
        function isOpen(): bool {
            return root.launcherOpen && root.wallpaperMode;
        }
    }

    LauncherBackend {
        id: launcherBackend

        searchText: search.text
        onActivationSucceeded: root.closeLauncher()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.launcherOpen || root.controlsOpen
        onActivated: {
            if (root.launcherOpen)
                root.closeLauncher();
            else if (systemControls.currentPage !== SystemControlsPanel.Home)
                systemControls.navigate(SystemControlsPanel.Home);
            else
                root.closeControls();
        }
    }

    function moveSelection(offset: int) {
        if (!results.count)
            return;
        results.currentIndex = (results.currentIndex + offset + results.count) % results.count;
        results.positionViewAtIndex(results.currentIndex, ListView.Contain);
    }

    anchors {
        top: true
        left: true
        right: true
    }
    margins { // qmllint disable unqualified unresolved-type
        top: 2
    }
    // Keep the Wayland surface stable: only the scene inside it animates.
    // Resizing the native window every frame competes with compositor animations.
    implicitHeight: Math.min(Math.max(501, Theme.controlsPopupMaxHeight) + Theme.floatingShadowMargin, screen ? screen.height - 16 : Math.max(501, Theme.controlsPopupMaxHeight) + Theme.floatingShadowMargin)
    exclusionMode: ExclusionMode.Ignore
    // Request compositor keyboard focus while either expanded mode is active.
    WlrLayershell.keyboardFocus: launcherOpen || controlsOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    mask: Region {
        Region {
            item: island
        }
        Region {
            item: trayIsland
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    RectangularShadow {
        anchors.fill: island
        radius: island.radius
        blur: Theme.floatingShadowBlur
        offset: Qt.vector2d(0, Theme.floatingShadowOffset)
        color: Theme.floatingShadow
    }

    Item {
        id: trayIsland

        visible: tray.implicitWidth > 0
        anchors {
            top: island.top
            left: island.right
            leftMargin: Theme.spacingMedium
        }
        width: tray.implicitWidth
        height: 28

        RectangularShadow {
            anchors.fill: traySurface
            radius: traySurface.radius
            blur: Theme.floatingShadowBlur
            offset: Qt.vector2d(0, Theme.floatingShadowOffset)
            color: Theme.floatingShadow
        }

        Rectangle {
            id: traySurface

            anchors.fill: parent
            radius: height / 2
            color: Theme.islandSurface
            border.width: 1
            border.color: Theme.outlineVariant

            Tray {
                id: tray

                anchors.fill: parent
            }
        }
    }

    Rectangle {
        id: island
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(root.width - Theme.floatingShadowMargin * 2, root.launcherOpen ? (root.expanded ? (root.wallpaperMode ? 560 : 480) : 300) : root.controlsOpen ? systemControls.preferredWidth : root.collapsedWidth)
        height: root.launcherOpen ? Math.min(root.height - Theme.floatingShadowMargin, 52 + (root.expanded ? 17 + Math.max(root.resultRowHeight, Math.min(root.searchResults.length, 6) * root.resultRowHeight) : 0)) : root.controlsOpen ? systemControls.implicitHeight : 28
        radius: root.launcherOpen || root.controlsOpen ? Theme.radiusExtraLarge : 14
        color: Theme.islandSurface
        border.width: 1
        border.color: Theme.outlineVariant
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: Theme.motionDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Theme.motionDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionDuration
                easing.type: Easing.OutCubic
            }
        }

        Button {
            id: clockButton

            visible: !root.launcherOpen && !root.controlsOpen
            anchors.fill: parent
            padding: 0
            hoverEnabled: true
            Accessible.name: I18n.tr("systemControls")
            Accessible.description: clockButtonLabel.text
            onClicked: root.toggleControls()

            background: Rectangle {
                radius: island.radius
                color: clockButton.down ? Theme.pressedSurface : clockButton.hovered ? Theme.hoverSurface : "transparent"
                border.width: clockButton.visualFocus ? 1 : 0
                border.color: Theme.primary
            }

            contentItem: Text {
                id: clockButtonLabel

                text: {
                    const value = Qt.locale(I18n.locale).toString(clock.date, I18n.tr("time"));
                    return value.charAt(0).toUpperCase() + value.slice(1);
                }
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        SystemControlsPanel {
            id: systemControls

            anchors.fill: parent
            active: root.controlsOpen
            maximumHeight: root.height - Theme.floatingShadowMargin
            onCloseRequested: root.closeControls()
        }

        RowLayout {
            id: searchBar
            visible: root.launcherOpen
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 16
                rightMargin: 8
            }
            height: 52
            spacing: 12

            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Rectangle {
                    x: 3
                    y: 3
                    width: 14
                    height: 14
                    radius: 7
                    color: "transparent"
                    border {
                        width: 2
                        color: Theme.textSecondary
                    }
                }
                Rectangle {
                    x: 16
                    y: 15
                    width: 8
                    height: 2
                    radius: 1
                    rotation: 45
                    color: Theme.textSecondary
                }
            }

            TextField {
                id: search
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                color: Theme.textPrimary
                placeholderText: root.wallpaperMode ? I18n.tr("searchWallpapers") : I18n.tr("searchApplications")
                placeholderTextColor: Theme.textSecondary
                selectionColor: Theme.secondaryContainer
                selectedTextColor: Theme.textPrimary
                background: null
                selectByMouse: true
                focus: root.launcherOpen
                Accessible.name: placeholderText
                onAccepted: launcherBackend.activate(root.searchResults[results.currentIndex])
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onUpPressed: root.moveSelection(-1)
            }

            ToolButton {
                id: clearButton
                visible: search.text.length > 0
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                text: "×"
                font.pixelSize: 26
                Accessible.name: I18n.tr("clearSearch")
                contentItem: Text {
                    text: clearButton.text
                    font: clearButton.font
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: Theme.radiusLarge
                    color: Theme.textPrimary
                    opacity: clearButton.down ? 0.12 : clearButton.hovered || clearButton.visualFocus ? 0.08 : 0
                }
                onClicked: {
                    search.clear();
                    search.forceActiveFocus();
                }
            }
        }

        Rectangle {
            visible: root.expanded
            anchors {
                top: searchBar.bottom
                left: parent.left
                right: parent.right
                leftMargin: 16
                rightMargin: 16
            }
            height: 1
            color: Theme.outlineVariant
        }

        ListView {
            id: results
            visible: root.expanded
            anchors {
                top: searchBar.bottom
                topMargin: 9
                bottom: parent.bottom
                bottomMargin: 8
                left: parent.left
                right: parent.right
                leftMargin: 8
                rightMargin: 8
            }
            clip: true
            model: root.searchResults
            onModelChanged: currentIndex = count ? 0 : -1
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            delegate: ItemDelegate {
                id: result
                required property var modelData
                required property int index
                width: results.width
                height: root.resultRowHeight
                highlighted: ListView.isCurrentItem
                Accessible.name: modelData.name
                enabled: !launcherBackend.applyingWallpaper
                onClicked: launcherBackend.activate(modelData)
                background: Rectangle {
                    id: resultBackground

                    radius: Theme.radiusLarge
                    color: result.highlighted ? Theme.secondaryContainer : Theme.surface
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.textPrimary
                        opacity: result.down ? 0.12 : result.hovered || result.visualFocus ? 0.08 : 0
                    }
                }
                contentItem: RowLayout {
                    spacing: 16
                    ClippingRectangle {
                        id: wallpaperPreview

                        readonly property real edgeMargin: Math.max(0, (result.height - height) / 2)

                        Layout.preferredWidth: root.wallpaperMode ? 96 : 40
                        Layout.preferredHeight: root.wallpaperMode ? 56 : 40
                        radius: root.wallpaperMode ? Math.max(0, resultBackground.radius - edgeMargin) : 0
                        color: "transparent"
                        Image {
                            id: appIcon
                            anchors.fill: parent
                            source: root.wallpaperMode ? result.modelData.url : result.modelData.icon ? Quickshell.iconPath(result.modelData.icon, true) : ""
                            sourceSize.width: root.wallpaperMode ? 192 : 40
                            sourceSize.height: root.wallpaperMode ? 112 : 40
                            fillMode: root.wallpaperMode ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !root.wallpaperMode && appIcon.status !== Image.Ready
                            text: result.modelData.name.charAt(0).toUpperCase()
                            color: Theme.primary
                            font.pixelSize: 24
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            Layout.fillWidth: true
                            text: result.modelData.name
                            font {
                                family: Theme.fontFamily
                                pixelSize: 16
                            }
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.wallpaperMode ? (result.modelData.fileName ?? "") : (result.modelData.genericName || result.modelData.comment || "")
                            visible: text.length > 0
                            font {
                                family: Theme.fontFamily
                                pixelSize: 12
                            }
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: (launcherBackend.normalizedQuery.length > 0 || root.wallpaperMode) && results.count === 0
                text: root.wallpaperMode ? I18n.tr("noWallpapers") : I18n.tr("noApplications")
                color: Theme.textSecondary
                font {
                    family: Theme.fontFamily
                    pixelSize: 14
                }
            }

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: Theme.spacingLarge
                }
                visible: launcherBackend.errorMessage.length > 0
                text: launcherBackend.errorMessage
                color: Theme.error
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.labelSize
                }
            }
        }
    }
}
