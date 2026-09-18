pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../components"
import "../singletons"

ScrollView {
    id: root
    signal externalOpened
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var devices: (root.bluetoothAdapter?.devices.values ?? []).slice().sort((a, b) => Number(b.connected) - Number(a.connected) || Number(b.paired) - Number(a.paired) || a.name.localeCompare(b.name))
    readonly property var pairingApplication: DesktopEntries.byId("blueman-manager")
    readonly property bool adapterBusy: root.bluetoothAdapter?.state === BluetoothAdapterState.Enabling || root.bluetoothAdapter?.state === BluetoothAdapterState.Disabling
    property BluetoothDevice requestedDevice: null
    property bool expectedConnection: false
    property string errorMessage: ""
    contentWidth: availableWidth
    contentHeight: content.implicitHeight
    implicitHeight: contentHeight + topPadding + bottomPadding
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    function openPairing(): void {
        if (root.pairingApplication) {
            const application = root.pairingApplication;
            root.externalOpened();
            application.execute();
        } else {
            root.errorMessage = I18n.tr("pairingUnavailable");
        }
    }
    function toggleDevice(device): void {
        root.errorMessage = "";
        if (!device.paired) {
            root.openPairing();
            return;
        }
        root.requestedDevice = device;
        root.expectedConnection = !device.connected;
        device.connected = root.expectedConnection;
        connectionTimeout.restart();
    }

    Binding {
        target: root.bluetoothAdapter
        property: "discovering"
        when: root.bluetoothAdapter !== null && scanTimer.running
        value: true
        restoreMode: Binding.RestoreBindingOrValue
    }
    Timer { id: scanTimer; interval: 20000 }
    Timer {
        id: connectionTimeout
        interval: 20000
        onTriggered: root.errorMessage = I18n.tr("connectionFailed")
    }
    Connections {
        target: root.requestedDevice
        function onConnectedChanged(): void {
            if (root.requestedDevice?.connected === root.expectedConnection)
                connectionTimeout.stop();
        }
        function onStateChanged(): void {
            if (root.expectedConnection && root.requestedDevice?.state === BluetoothDeviceState.Disconnected) {
                connectionTimeout.stop();
                root.errorMessage = I18n.tr("connectionFailed");
            }
        }
    }
    Connections {
        target: root.bluetoothAdapter
        function onEnabledChanged(): void {
            if (!root.bluetoothAdapter?.enabled) {
                scanTimer.stop();
                connectionTimeout.stop();
            }
        }
    }

    ColumnLayout {
        id: content
        width: root.availableWidth
        spacing: Theme.spacingMedium
        ServiceToggle {
            Layout.fillWidth: true
            title: I18n.tr("bluetooth")
            status: !root.bluetoothAdapter ? I18n.tr("serviceUnavailable") : root.adapterBusy ? I18n.tr("serviceChanging") : root.bluetoothAdapter.state === BluetoothAdapterState.Blocked ? I18n.tr("serviceBlocked") : I18n.tr(root.bluetoothAdapter.enabled ? "serviceOn" : "serviceOff")
            iconSource: "../icons/bluetooth.svg"
            checked: root.bluetoothAdapter?.enabled ?? false
            enabled: root.bluetoothAdapter !== null && root.bluetoothAdapter.state !== BluetoothAdapterState.Blocked && !root.adapterBusy
            onClicked: { if (root.bluetoothAdapter) root.bluetoothAdapter.enabled = !root.bluetoothAdapter.enabled; }
        }
        RowLayout {
            Layout.fillWidth: true
            StateLayerButton {
                Layout.fillWidth: true
                implicitHeight: Theme.controlTargetSize
                text: I18n.tr(scanTimer.running ? "stopSearching" : "searchDevices")
                enabled: root.bluetoothAdapter?.enabled ?? false
                onClicked: scanTimer.running ? scanTimer.stop() : scanTimer.restart()
            }
            StateLayerButton {
                implicitHeight: Theme.controlTargetSize
                text: I18n.tr("pairDevice")
                enabled: (root.bluetoothAdapter?.enabled ?? false) && root.pairingApplication !== null
                onClicked: root.openPairing()
            }
        }
        Text {
            Layout.fillWidth: true
            visible: root.errorMessage.length > 0
            text: root.errorMessage
            color: Theme.error
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySize
            wrapMode: Text.WordWrap
            Accessible.role: Accessible.AlertMessage
        }
        Repeater {
            model: root.bluetoothAdapter?.enabled ? root.devices : []
            delegate: ServiceListItem {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.name || modelData.address
                subtitle: I18n.tr(modelData.blocked ? "serviceBlocked" : modelData.connected ? "connected" : modelData.state === BluetoothDeviceState.Connecting ? "serviceChanging" : modelData.paired ? "pairedDevice" : "notPaired") + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                iconSource: "../icons/bluetooth.svg"
                selected: modelData.connected
                actionText: I18n.tr(modelData.connected ? "disconnect" : modelData.paired ? "connect" : "pairDevice")
                enabled: !modelData.blocked && !connectionTimeout.running && modelData.state !== BluetoothDeviceState.Connecting && modelData.state !== BluetoothDeviceState.Disconnecting
                onClicked: root.toggleDevice(modelData)
            }
        }
        Text {
            Layout.fillWidth: true
            visible: root.devices.length === 0 || !(root.bluetoothAdapter?.enabled ?? false)
            text: I18n.tr(!root.bluetoothAdapter ? "serviceUnavailable" : !root.bluetoothAdapter.enabled ? "bluetoothOffHint" : scanTimer.running ? "searchingDevices" : "noDevices")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySize
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            text: I18n.tr(root.pairingApplication ? "pairingHint" : "pairingUnavailable")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSize
            wrapMode: Text.WordWrap
        }
    }
}
