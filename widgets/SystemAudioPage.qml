pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../singletons"

ScrollView {
    id: root
    property bool inputMode: false
    readonly property var selectedNode: inputMode ? Pipewire.defaultAudioSource : Pipewire.defaultAudioSink
    readonly property var nodes: Pipewire.nodes.values.filter(node => !node.isStream && node.audio !== null && node.isSink !== root.inputMode)
    readonly property var audio: root.selectedNode?.audio ?? null
    readonly property url contextIcon: inputMode ? "../icons/microphone.svg" : "../icons/speaker-high.svg"
    contentWidth: availableWidth
    contentHeight: content.implicitHeight
    implicitHeight: contentHeight + topPadding + bottomPadding
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    PwObjectTracker { objects: root.nodes }

    ColumnLayout {
        id: content
        width: root.availableWidth
        spacing: Theme.spacingMedium
        ServiceToggle {
            Layout.fillWidth: true
            title: I18n.tr(root.inputMode ? "microphone" : "audio")
            status: !root.audio ? I18n.tr("serviceUnavailable") : I18n.tr(root.audio.muted ? "audioMuted" : "serviceOn")
            iconSource: root.contextIcon
            checked: root.audio !== null && !root.audio.muted
            enabled: root.audio !== null
            onClicked: { if (root.audio) root.audio.muted = !root.audio.muted; }
        }
        AudioLevelSlider {
            Layout.fillWidth: true
            audio: root.audio
            iconSource: root.contextIcon
            Accessible.name: I18n.tr(root.inputMode ? "inputVolume" : "volume")
        }
        Text {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingMedium
            text: I18n.tr(root.inputMode ? "inputDevices" : "outputDevices")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSize
            color: Theme.textSecondary
        }
        Repeater {
            model: root.nodes
            delegate: ServiceListItem {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.description || modelData.name
                subtitle: I18n.tr(selected ? "defaultDevice" : "selectDevice")
                iconSource: root.contextIcon
                selected: modelData === root.selectedNode
                enabled: modelData.ready
                onClicked: {
                    if (root.inputMode)
                        Pipewire.preferredDefaultAudioSource = modelData;
                    else
                        Pipewire.preferredDefaultAudioSink = modelData;
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: root.nodes.length === 0
            text: I18n.tr(Pipewire.ready ? "noDevices" : "audioUnavailable")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySize
            color: Theme.textSecondary
            wrapMode: Text.WordWrap
        }
    }
}
