pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../components"
import "../singletons"

Item {
    id: root

    enum Page {
        Home,
        Network,
        Bluetooth,
        Audio,
        Input,
        History,
        Settings
    }

    property bool active: false
    property int currentPage: SystemControlsPanel.Home
    property real maximumHeight: Theme.controlsPopupMaxHeight
    property real availableWidth: wideHomeWidth
    readonly property real wideHomeWidth: Theme.controlsPopupWidth + Theme.spacingLarge * 2 + 1 + Theme.notificationHistoryWidth
    readonly property bool compact: availableWidth < wideHomeWidth
    readonly property bool showNotificationHistory: root.currentPage === SystemControlsPanel.History || (root.currentPage === SystemControlsPanel.Home && !root.compact)
    readonly property var defaultAudioSink: Pipewire.defaultAudioSink
    readonly property var defaultAudioSource: Pipewire.defaultAudioSource
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var connectedNetwork: {
        for (const device of Networking.devices.values) {
            for (const network of device.networks.values) {
                if (network.connected)
                    return network;
            }
        }
        return null;
    }
    readonly property bool networkConnected: Networking.devices.values.some(device => device.connected)
    readonly property string networkStatus: root.connectedNetwork?.name ?? I18n.tr("notConnected")
    readonly property string bluetoothStatus: {
        const devices = root.bluetoothAdapter?.devices.values.filter(device => device.connected) ?? [];
        return devices.length ? devices.map(device => device.name).join(", ") : I18n.tr(root.bluetoothAdapter?.enabled ? "serviceOn" : "serviceOff");
    }
    readonly property var activeMediaPlayer: Mpris.players.values.find(player => player.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string pageTitleKey: root.currentPage === SystemControlsPanel.Settings ? "settings" : root.currentPage === SystemControlsPanel.History ? "notificationHistory" : root.currentPage === SystemControlsPanel.Network ? "internet" : root.currentPage === SystemControlsPanel.Bluetooth ? "bluetooth" : root.currentPage === SystemControlsPanel.Input ? "microphone" : "audio"
    readonly property real controlPaneWidth: (root.currentPage === SystemControlsPanel.Home ? Theme.controlsPopupWidth : Theme.controlsDetailsWidth) - Theme.spacingLarge * 2
    readonly property real preferredWidth: Math.min(root.availableWidth, root.currentPage === SystemControlsPanel.Home ? (root.compact ? Theme.controlsPopupWidth : root.wideHomeWidth) : Theme.controlsDetailsWidth)
    readonly property Item loadedPage: pageLoader.item as Item
    readonly property real bodyHeight: root.currentPage === SystemControlsPanel.History ? notificationHistory.contentImplicitHeight : root.currentPage === SystemControlsPanel.Home ? homeContent.implicitHeight : root.loadedPage?.implicitHeight ?? homeContent.implicitHeight
    readonly property real chromeHeight: Theme.spacingLarge * 2 + (header.visible ? Theme.spacingMedium + header.implicitHeight : 0)

    signal closeRequested

    visible: active
    implicitWidth: root.preferredWidth
    implicitHeight: Math.max(1, Math.min(Math.ceil(Math.max(root.bodyHeight, root.showNotificationHistory ? notificationHistory.contentImplicitHeight : 0) + root.chromeHeight), root.maximumHeight))

    function navigate(destination: int): void {
        root.currentPage = destination;
        pageAnimation.restart();
        Qt.callLater(() => destination === SystemControlsPanel.Home ? internetTile.forceActiveFocus(Qt.TabFocusReason) : backButton.forceActiveFocus(Qt.TabFocusReason));
    }

    onActiveChanged: {
        root.currentPage = SystemControlsPanel.Home;
        if (active) {
            pageAnimation.restart();
            Qt.callLater(() => internetTile.forceActiveFocus(Qt.TabFocusReason));
        }
    }

    PwObjectTracker {
        objects: [root.defaultAudioSink, root.defaultAudioSource].filter(node => node !== null)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: Theme.spacingMedium

        RowLayout {
            id: header

            visible: root.currentPage !== SystemControlsPanel.Home
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            StateLayerButton {
                id: backButton

                visible: root.currentPage !== SystemControlsPanel.Home
                Layout.preferredWidth: Theme.controlTargetSize
                Layout.preferredHeight: Theme.controlTargetSize
                leftPadding: Theme.spacingMedium
                rightPadding: Theme.spacingMedium
                icon.source: "../icons/arrow-left.svg"
                Accessible.name: I18n.tr("back")
                onClicked: root.navigate(SystemControlsPanel.Home)
            }

            Text {
                Layout.fillWidth: true
                text: I18n.tr(root.pageTitleKey)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.titleSize
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingLarge

            Item {
                id: pageContent

                visible: root.currentPage !== SystemControlsPanel.History
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: root.controlPaneWidth
                Layout.fillHeight: true

                NumberAnimation {
                    id: pageAnimation

                    target: pageContent
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.feedbackDuration
                    easing.type: Easing.OutCubic
                }

                ScrollView {
                    id: homeScroll

                    anchors.fill: parent
                    visible: root.currentPage === SystemControlsPanel.Home
                    contentWidth: availableWidth
                    contentHeight: homeContent.implicitHeight
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: homeContent

                        width: homeScroll.availableWidth
                        spacing: Theme.spacingMedium

                        AudioLevelSlider {
                            Layout.fillWidth: true
                            audio: root.defaultAudioSink?.audio ?? null
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: Theme.spacingMedium
                            columnSpacing: Theme.spacingMedium

                            ControlTile {
                                id: internetTile

                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                title: I18n.tr("internet")
                                status: root.networkStatus
                                iconSource: "../icons/wifi.svg"
                                active: root.networkConnected
                                onClicked: root.navigate(SystemControlsPanel.Network)
                            }

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                title: I18n.tr("bluetooth")
                                status: root.bluetoothAdapter ? root.bluetoothStatus : I18n.tr("serviceUnavailable")
                                iconSource: "../icons/bluetooth.svg"
                                active: root.bluetoothAdapter?.enabled ?? false
                                onClicked: root.navigate(SystemControlsPanel.Bluetooth)
                            }

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                title: I18n.tr("audio")
                                status: !root.defaultAudioSink ? I18n.tr("audioUnavailable") : root.defaultAudioSink.audio?.muted ? I18n.tr("audioMuted") : root.defaultAudioSink.description
                                iconSource: "../icons/speaker-high.svg"
                                active: root.defaultAudioSink?.audio !== null && !(root.defaultAudioSink?.audio?.muted ?? true)
                                onClicked: root.navigate(SystemControlsPanel.Audio)
                            }

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                title: I18n.tr("microphone")
                                status: !root.defaultAudioSource ? I18n.tr("serviceUnavailable") : root.defaultAudioSource.audio?.muted ? I18n.tr("audioMuted") : root.defaultAudioSource.description
                                iconSource: "../icons/microphone.svg"
                                active: root.defaultAudioSource?.audio !== null && !(root.defaultAudioSource?.audio?.muted ?? true)
                                onClicked: root.navigate(SystemControlsPanel.Input)
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: I18n.tr("controlsHint")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.labelSize
                            color: Theme.textSecondary
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        StateLayerButton {
                            Layout.fillWidth: true
                            implicitHeight: Theme.controlTargetSize
                            text: I18n.tr("settings")
                            icon.source: "../icons/sliders-horizontal.svg"
                            Accessible.name: I18n.tr("settings")
                            onClicked: root.navigate(SystemControlsPanel.Settings)
                        }

                        StateLayerButton {
                            visible: root.compact
                            Layout.fillWidth: true
                            implicitHeight: Theme.controlTargetSize
                            text: I18n.tr("notificationHistory")
                            onClicked: root.navigate(SystemControlsPanel.History)
                        }

                        MediaPlayerCard {
                            Layout.fillWidth: true
                            player: root.activeMediaPlayer
                            active: root.active && root.currentPage === SystemControlsPanel.Home
                            outputName: root.defaultAudioSink?.description ?? I18n.tr("audioUnavailable")
                            onOutputRequested: root.navigate(SystemControlsPanel.Audio)
                        }
                    }
                }

                Loader {
                    id: pageLoader

                    anchors.fill: parent
                    active: root.active && root.currentPage !== SystemControlsPanel.Home && root.currentPage !== SystemControlsPanel.History
                    sourceComponent: root.currentPage === SystemControlsPanel.Settings ? settingsPage : root.currentPage === SystemControlsPanel.Network ? networkPage : root.currentPage === SystemControlsPanel.Bluetooth ? bluetoothPage : audioPage
                }
            }

            Rectangle {
                visible: root.showNotificationHistory && root.currentPage === SystemControlsPanel.Home
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Theme.outlineVariant
            }

            NotificationHistory {
                id: notificationHistory

                visible: root.showNotificationHistory
                Layout.fillWidth: root.currentPage === SystemControlsPanel.History
                Layout.minimumWidth: 0
                Layout.fillHeight: true
                Layout.preferredWidth: Theme.notificationHistoryWidth
            }
        }
    }

    Component {
        id: networkPage

        SystemNetworkPage {}
    }

    Component {
        id: bluetoothPage

        SystemBluetoothPage {
            onExternalOpened: root.closeRequested()
        }
    }

    Component {
        id: audioPage

        SystemAudioPage {
            inputMode: root.currentPage === SystemControlsPanel.Input
        }
    }

    Component {
        id: settingsPage

        SettingsPage {}
    }
}
