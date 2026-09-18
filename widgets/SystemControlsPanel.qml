pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../singletons"

Item {
    id: root

    property bool active: false
    property string page: "home"
    property real maximumHeight: Theme.controlsPopupMaxHeight
    readonly property bool showNotificationHistory: root.page === "home"
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audioSource: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property string networkName: {
        for (const device of Networking.devices.values) {
            for (const network of device.networks.values) {
                if (network.connected)
                    return network.name;
            }
        }
        return I18n.tr("notConnected");
    }
    readonly property string bluetoothName: {
        const devices = root.adapter?.devices.values.filter(device => device.connected) ?? [];
        return devices.length ? devices.map(device => device.name).join(", ") : I18n.tr(root.adapter?.enabled ? "serviceOn" : "serviceOff");
    }
    readonly property real controlPaneWidth: (root.page === "home" ? Theme.controlsPopupWidth : Theme.controlsDetailsWidth) - Theme.spacingLarge * 2
    readonly property real preferredWidth: root.showNotificationHistory ? Theme.spacingLarge * 2 + root.controlPaneWidth + Theme.spacingLarge * 2 + 1 + Theme.notificationHistoryWidth : Theme.controlsDetailsWidth
    readonly property Item loadedPage: pageLoader.item as Item
    readonly property real bodyHeight: root.page === "home" ? homeContent.implicitHeight : root.loadedPage?.implicitHeight ?? homeContent.implicitHeight
    readonly property real chromeHeight: Theme.spacingLarge * 2 + (header.visible ? Theme.spacingMedium + header.implicitHeight : 0)

    signal closeRequested

    visible: active
    implicitWidth: root.preferredWidth
    implicitHeight: Math.max(1, Math.min(Math.ceil(Math.max(root.bodyHeight, root.showNotificationHistory ? notificationHistory.contentImplicitHeight : 0) + root.chromeHeight), root.maximumHeight))

    function navigate(destination: string): void {
        root.page = destination;
        pageAnimation.restart();
        Qt.callLater(() => destination === "home" ? internetTile.forceActiveFocus(Qt.TabFocusReason) : backButton.forceActiveFocus(Qt.TabFocusReason));
    }

    onActiveChanged: {
        root.page = "home";
        if (active) {
            pageAnimation.restart();
            Qt.callLater(() => internetTile.forceActiveFocus(Qt.TabFocusReason));
        }
    }

    PwObjectTracker {
        objects: [root.audioSink, root.audioSource].filter(node => node !== null)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: Theme.spacingMedium

        RowLayout {
            id: header

            visible: root.page !== "home"
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            SplashButton {
                id: backButton

                visible: root.page !== "home"
                Layout.preferredWidth: Theme.controlTargetSize
                Layout.preferredHeight: Theme.controlTargetSize
                leftPadding: Theme.spacingMedium
                rightPadding: Theme.spacingMedium
                icon.source: "../icons/arrow-left.svg"
                Accessible.name: I18n.tr("back")
                onClicked: root.navigate("home")
            }

            Text {
                Layout.fillWidth: true
                text: I18n.tr(root.page === "network" ? "internet" : root.page === "input" ? "microphone" : root.page)
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
                    visible: root.page === "home"
                    contentWidth: availableWidth
                    contentHeight: homeContent.implicitHeight
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: homeContent

                        width: homeScroll.availableWidth
                        spacing: Theme.spacingMedium

                        AudioLevelSlider {
                            Layout.fillWidth: true
                            audio: root.audioSink?.audio ?? null
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
                                status: root.networkName
                                iconSource: "../icons/wifi.svg"
                                active: Networking.devices.values.some(device => device.connected)
                                onClicked: root.navigate("network")
                            }

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                title: I18n.tr("bluetooth")
                                status: root.adapter ? root.bluetoothName : I18n.tr("serviceUnavailable")
                                iconSource: "../icons/bluetooth.svg"
                                active: root.adapter?.enabled ?? false
                                onClicked: root.navigate("bluetooth")
                            }

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                title: I18n.tr("audio")
                                status: !root.audioSink ? I18n.tr("audioUnavailable") : root.audioSink.audio?.muted ? I18n.tr("audioMuted") : root.audioSink.description
                                iconSource: "../icons/speaker-high.svg"
                                active: root.audioSink?.audio !== null && !(root.audioSink?.audio?.muted ?? true)
                                onClicked: root.navigate("audio")
                            }

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                title: I18n.tr("microphone")
                                status: !root.audioSource ? I18n.tr("serviceUnavailable") : root.audioSource.audio?.muted ? I18n.tr("audioMuted") : root.audioSource.description
                                iconSource: "../icons/microphone.svg"
                                active: root.audioSource?.audio !== null && !(root.audioSource?.audio?.muted ?? true)
                                onClicked: root.navigate("input")
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

                        MediaPlayerCard {
                            Layout.fillWidth: true
                            player: Mpris.players.values.find(player => player.isPlaying) ?? Mpris.players.values[0] ?? null
                            active: root.active && root.page === "home"
                            outputName: root.audioSink?.description ?? I18n.tr("audioUnavailable")
                            onOutputRequested: root.navigate("audio")
                        }
                    }
                }

                Loader {
                    id: pageLoader

                    anchors.fill: parent
                    active: root.active && root.page !== "home"
                    sourceComponent: root.page === "network" ? networkPage : root.page === "bluetooth" ? bluetoothPage : audioPage
                }
            }

            Rectangle {
                visible: root.showNotificationHistory
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Theme.outlineVariant
            }

            NotificationHistory {
                id: notificationHistory

                visible: root.showNotificationHistory
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
            inputMode: root.page === "input"
        }
    }
}
