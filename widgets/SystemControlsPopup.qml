pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../singletons"

PopupWindow {
    id: root
    property string page: "home"
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

    function navigate(destination: string): void {
        root.page = destination;
        pageAnimation.restart();
        Qt.callLater(() => destination === "home" ? internetTile.forceActiveFocus(Qt.TabFocusReason) : backButton.forceActiveFocus(Qt.TabFocusReason));
    }

    readonly property real preferredWidth: root.page === "home" ? Theme.controlsPopupWidth : Theme.controlsDetailsWidth
    readonly property Item loadedPage: pageLoader.item as Item
    readonly property real bodyHeight: root.page === "home" ? homeContent.implicitHeight : root.loadedPage?.implicitHeight ?? homeContent.implicitHeight
    readonly property real chromeHeight: Theme.spacingMedium * 3 + Theme.spacingLarge * 2 + header.implicitHeight
    readonly property real availableHeight: Math.max(1, (screen?.height ?? 600) - Theme.barHeight - Theme.spacingLarge)

    implicitWidth: Math.max(1, Math.min(root.preferredWidth, (screen?.width ?? root.preferredWidth) - Theme.spacingLarge))
    // Resize to the measured context, without animating native Wayland geometry.
    // Only the content fades; lists scroll once the popup reaches its height limit.
    implicitHeight: Math.max(1, Math.min(Math.ceil(root.bodyHeight + root.chromeHeight), Theme.controlsPopupMaxHeight, root.availableHeight))
    color: "transparent"
    anchor.adjustment: PopupAdjustment.Slide
    // Use an interactive xdg_popup and its native outside-click dismissal.
    // A separate Hyprland grab can mistake popup input for an outside click.
    grabFocus: true
    onVisibleChanged: {
        root.page = "home";
        if (visible) {
            pageAnimation.restart();
            Qt.callLater(() => internetTile.forceActiveFocus(Qt.TabFocusReason));
        }
    }
    PwObjectTracker {
        objects: [root.audioSink, root.audioSource].filter(node => node !== null)
    }
    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.visible
        onActivated: root.page === "home" ? root.visible = false : root.navigate("home")
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingMedium
        anchors.bottomMargin: Theme.spacingMedium
        radius: Theme.radiusExtraLarge
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            RowLayout {
                id: header
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
                    text: I18n.tr(root.page === "home" ? "systemControls" : root.page === "network" ? "internet" : root.page === "input" ? "microphone" : root.page)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.titleSize
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                }
                SplashButton {
                    Layout.preferredWidth: Theme.controlTargetSize
                    Layout.preferredHeight: Theme.controlTargetSize
                    leftPadding: Theme.spacingMedium
                    rightPadding: Theme.spacingMedium
                    icon.source: "../icons/x.svg"
                    Accessible.name: I18n.tr("closePanel")
                    onClicked: root.visible = false
                }
            }

            Item {
                id: pageContent
                Layout.fillWidth: true
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
                            active: root.visible && root.page === "home"
                            outputName: root.audioSink?.description ?? I18n.tr("audioUnavailable")
                            onOutputRequested: root.navigate("audio")
                        }
                    }
                }
                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    active: root.visible && root.page !== "home"
                    sourceComponent: root.page === "network" ? networkPage : root.page === "bluetooth" ? bluetoothPage : audioPage
                }
            }
        }
    }
    Component {
        id: networkPage
        SystemNetworkPage {}
    }
    Component {
        id: bluetoothPage
        SystemBluetoothPage { onExternalOpened: root.visible = false }
    }
    Component {
        id: audioPage
        SystemAudioPage { inputMode: root.page === "input" }
    }
}
