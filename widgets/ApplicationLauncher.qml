pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../singletons"

PanelWindow {
    id: root

    // A compact island that expands around the search results.
    property bool launcherOpen: false
    property bool controlsOpen: false
    readonly property bool expanded: launcherOpen && query.length > 0
    readonly property real collapsedWidth: Math.ceil(clockButtonLabel.implicitWidth + Theme.spacingLarge * 2)
    readonly property string query: normalize(search.text.trim())
    readonly property var matches: {
        if (!query.length)
            return [];
        const terms = query.split(/\s+/);
        return DesktopEntries.applications.values.filter(entry => {
            const haystack = normalize([entry.name, entry.genericName, entry.comment, (entry.keywords ?? []).join(" ")].join(" "));
            return terms.every(term => haystack.includes(term));
        }).sort((a, b) => {
            const aPrefix = normalize(a.name).startsWith(query);
            const bPrefix = normalize(b.name).startsWith(query);
            return Number(bPrefix) - Number(aPrefix) || a.name.localeCompare(b.name);
        });
    }

    function normalize(value: string): string {
        return value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
    }

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        closeLauncher();
    }

    function closeLauncher() {
        launcherOpen = false;
        search.clear();
    }

    function toggleLauncher() {
        if (launcherOpen) {
            closeLauncher();
        } else {
            screen = Config.currentScreen;
            controlsOpen = false;
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
            root.toggleLauncher();
        }
        function close(): void {
            root.closeLauncher();
        }
        function isOpen(): bool {
            return root.launcherOpen;
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.launcherOpen || root.controlsOpen
        onActivated: {
            if (root.launcherOpen)
                root.closeLauncher();
            else if (systemControls.page !== "home")
                systemControls.navigate("home");
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
    margins.top: 2
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
        width: Math.min(root.width - Theme.floatingShadowMargin * 2, root.launcherOpen ? (root.expanded ? 480 : 300) : root.controlsOpen ? systemControls.preferredWidth : root.collapsedWidth)
        height: root.launcherOpen ? Math.min(root.height - Theme.floatingShadowMargin, 52 + (root.expanded ? 17 + Math.max(72, Math.min(root.matches.length, 6) * 72) : 0)) : root.controlsOpen ? systemControls.implicitHeight : 28
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
                placeholderText: I18n.tr("searchApplications")
                placeholderTextColor: Theme.textSecondary
                selectionColor: Theme.secondaryContainer
                selectedTextColor: Theme.textPrimary
                background: null
                selectByMouse: true
                focus: root.launcherOpen
                Accessible.name: placeholderText
                onAccepted: root.launch(root.matches[results.currentIndex])
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
                    radius: 24
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
            model: root.matches
            onModelChanged: currentIndex = count ? 0 : -1
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            delegate: ItemDelegate {
                id: result
                required property var modelData
                required property int index
                width: results.width
                height: 72
                highlighted: ListView.isCurrentItem
                Accessible.name: modelData.name
                onClicked: root.launch(modelData)
                background: Rectangle {
                    radius: 24
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
                    Item {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Image {
                            id: appIcon
                            anchors.fill: parent
                            source: result.modelData.icon ? Quickshell.iconPath(result.modelData.icon, true) : ""
                            sourceSize.width: 40
                            sourceSize.height: 40
                            fillMode: Image.PreserveAspectFit
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: appIcon.status !== Image.Ready
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
                            text: result.modelData.genericName || result.modelData.comment
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
                visible: root.query.length > 0 && results.count === 0
                text: I18n.tr("noApplications")
                color: Theme.textSecondary
                font {
                    family: Theme.fontFamily
                    pixelSize: 14
                }
            }
        }
    }
}
