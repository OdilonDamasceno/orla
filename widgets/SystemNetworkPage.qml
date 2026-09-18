pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Networking
import "../components"
import "../singletons"

ScrollView {
    id: root
    readonly property var wifiDevices: Networking.devices.values.filter(device => device.type === DeviceType.Wifi)
    readonly property var wiredDevices: Networking.devices.values.filter(device => device.type === DeviceType.Wired)
    readonly property var networks: {
        let result = [];
        for (const device of root.wifiDevices)
            result = result.concat(device.networks.values);
        return result.filter(network => network.name.length > 0).sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength);
    }
    property WifiNetwork passwordNetwork: null
    property WifiNetwork requestedNetwork: null
    property string errorMessage: ""
    contentWidth: availableWidth
    contentHeight: content.implicitHeight
    implicitHeight: contentHeight + topPadding + bottomPadding
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    function supportsPassword(network): bool {
        return network.security === WifiSecurityType.WpaPsk || network.security === WifiSecurityType.Wpa2Psk || network.security === WifiSecurityType.Sae;
    }
    function showPassword(network): void {
        root.passwordNetwork = network;
        Qt.callLater(() => {
            root.contentItem.contentY = 0;
            password.forceActiveFocus();
        });
    }
    function requestConnection(network): void {
        root.errorMessage = "";
        password.clear();
        root.passwordNetwork = null;
        if (network.connected) {
            network.disconnect();
        } else if (network.known || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) {
            root.requestedNetwork = network;
            network.connect();
            connectionTimeout.restart();
        } else if (root.supportsPassword(network)) {
            root.showPassword(network);
        } else {
            root.errorMessage = I18n.tr("advancedNetworkRequired");
        }
    }
    function submitPassword(): void {
        if (!root.passwordNetwork || !password.text.length)
            return;
        root.requestedNetwork = root.passwordNetwork;
        root.passwordNetwork.connectWithPsk(password.text);
        password.clear();
        root.passwordNetwork = null;
        connectionTimeout.restart();
    }

    // Scanning is scoped to this page, restoring the previous state on departure.
    Instantiator {
        model: root.wifiDevices
        delegate: Binding {
            required property var modelData
            target: modelData
            property: "scannerEnabled"
            value: Networking.wifiEnabled
            restoreMode: Binding.RestoreBindingOrValue
        }
    }
    Connections {
        target: Networking
        function onWifiEnabledChanged(): void {
            root.passwordNetwork = null;
            password.clear();
            root.errorMessage = "";
            connectionTimeout.stop();
        }
    }
    Connections {
        target: root.requestedNetwork
        function onConnectedChanged(): void {
            if (root.requestedNetwork?.connected) {
                connectionTimeout.stop();
                root.errorMessage = "";
            }
        }
        function onConnectionFailed(reason): void {
            connectionTimeout.stop();
            root.errorMessage = I18n.tr(reason === ConnectionFailReason.NoSecrets ? "wifiPasswordFailed" : "connectionFailed");
            if (root.requestedNetwork && root.supportsPassword(root.requestedNetwork)) {
                root.showPassword(root.requestedNetwork);
            }
        }
    }
    Timer {
        id: connectionTimeout
        interval: 30000
        onTriggered: root.errorMessage = I18n.tr("connectionFailed")
    }
    Timer { id: initialScan; interval: 6000; running: true }

    ColumnLayout {
        id: content
        width: root.availableWidth
        spacing: Theme.spacingMedium
        Repeater {
            model: root.wiredDevices
            delegate: ServiceListItem {
                required property var modelData
                Layout.fillWidth: true
                title: I18n.tr("ethernet")
                subtitle: modelData.connected ? modelData.network?.name ?? modelData.name : I18n.tr("notConnected")
                selected: modelData.connected
                actionText: I18n.tr(modelData.connected ? "disconnect" : "connect")
                enabled: modelData.hasLink && modelData.network !== null && modelData.state !== ConnectionState.Connecting
                onClicked: modelData.connected ? modelData.disconnect() : modelData.network.connect()
            }
        }
        ServiceToggle {
            Layout.fillWidth: true
            title: I18n.tr("wifi")
            status: !root.wifiDevices.length ? I18n.tr("serviceUnavailable") : !Networking.wifiHardwareEnabled ? I18n.tr("serviceBlocked") : I18n.tr(Networking.wifiEnabled ? "serviceOn" : "serviceOff")
            iconSource: "../icons/wifi.svg"
            enabled: root.wifiDevices.length > 0 && Networking.wifiHardwareEnabled
            checked: Networking.wifiEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
        Text {
            Layout.fillWidth: true
            visible: root.errorMessage.length > 0
            text: root.errorMessage
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySize
            color: Theme.error
            wrapMode: Text.WordWrap
            Accessible.role: Accessible.AlertMessage
        }
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.passwordNetwork !== null
            spacing: Theme.spacingMedium
            Text {
                Layout.fillWidth: true
                text: I18n.tr("passwordFor") + " " + (root.passwordNetwork?.name ?? "")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                wrapMode: Text.WordWrap
            }
            TextField {
                id: password
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                echoMode: TextInput.Password
                placeholderText: I18n.tr("networkPassword")
                Accessible.name: placeholderText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                color: Theme.textPrimary
                placeholderTextColor: Theme.textSecondary
                selectionColor: Theme.secondaryContainer
                selectedTextColor: Theme.textPrimary
                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.surfaceContainerHigh
                    border.color: password.activeFocus ? Theme.primary : Theme.outline
                }
                onAccepted: root.submitPassword()
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                StateLayerButton {
                    text: I18n.tr("cancel")
                    implicitHeight: Theme.controlTargetSize
                    onClicked: { password.clear(); root.passwordNetwork = null; }
                }
                StateLayerButton {
                    text: I18n.tr("connect")
                    implicitHeight: Theme.controlTargetSize
                    enabled: password.text.length > 0
                    onClicked: root.submitPassword()
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: Networking.wifiEnabled && root.wifiDevices.length > 0
            text: I18n.tr("availableNetworks")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSize
            color: Theme.textSecondary
        }
        Repeater {
            model: Networking.wifiEnabled ? root.networks : []
            delegate: ServiceListItem {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.name
                subtitle: I18n.tr(modelData.connected ? "connected" : modelData.stateChanging ? "serviceChanging" : modelData.known ? "savedNetwork" : modelData.security === WifiSecurityType.Open ? "openNetwork" : "securedNetwork") + " · " + Math.round(modelData.signalStrength * 100) + "%"
                iconSource: "../icons/wifi.svg"
                selected: modelData.connected
                actionText: I18n.tr(modelData.connected ? "disconnect" : "connect")
                enabled: !modelData.stateChanging && !connectionTimeout.running
                onClicked: root.requestConnection(modelData)
            }
        }
        Text {
            Layout.fillWidth: true
            visible: Networking.wifiEnabled && root.networks.length === 0
            text: I18n.tr(!root.wifiDevices.length ? "serviceUnavailable" : initialScan.running ? "searchingNetworks" : "noNetworks")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySize
            wrapMode: Text.WordWrap
        }
    }
}
