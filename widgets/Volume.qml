pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "../singletons"

Scope {
    id: root

    required property ShellScreen targetScreen

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audio: root.audioSink?.audio ?? null
    readonly property real volumeLevel: root.audio?.muted ? 0 : Math.max(0, Math.min(1, root.audio?.volume ?? 0))
    readonly property bool isCurrentScreen: root.targetScreen?.name === Config.currentScreen?.name

    property bool shouldShowOsd: false

    function showOsd(): void {
        root.shouldShowOsd = true;
        hideTimer.restart();
    }

    PwObjectTracker {
        objects: root.audioSink ? [root.audioSink] : []
    }

    Connections {
        target: root.audio

        function onMutedChanged(): void {
            root.showOsd();
        }

        function onVolumeChanged(): void {
            root.showOsd();
        }
    }

    Timer {
        id: hideTimer

        interval: 1000
        onTriggered: root.shouldShowOsd = false
    }

    // Keep the native surface mapped: hiding it also dismisses active Qt popups.
    // Only the content disappears; the surface never takes input or reserves space.
    PanelWindow { // qmllint disable uncreatable-type
        id: osdWindow

        contentItem.visible: root.shouldShowOsd && root.isCurrentScreen
        screen: root.targetScreen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.bottom: true
        margins { // qmllint disable unqualified unresolved-type
            bottom: Math.max(16, (osdWindow.screen?.height ?? 600) / 6 - osdWindow.height)
        }
        exclusiveZone: 0

        implicitWidth: 260
        implicitHeight: 92
        color: "transparent"

        mask: Region {}

        RectangularShadow {
            anchors.fill: osdCard
            radius: osdCard.radius
            color: Theme.shadow
        }

        Rectangle {
            id: osdCard

            anchors.fill: parent
            anchors.margins: 10
            radius: 18
            color: Theme.surfaceContainer

            GradientBorder {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12

                Text {
                    Layout.fillWidth: true

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSize
                    text: root.audioSink?.description ?? I18n.tr("audioUnavailable")
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Icon {
                        source: "../icons/sound-low-solid.svg"
                    }

                    Rectangle {
                        id: volumeTrack

                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 20
                        color: Theme.track

                        Rectangle {
                            anchors {
                                left: volumeTrack.left
                                top: volumeTrack.top
                                bottom: volumeTrack.bottom
                            }

                            width: volumeTrack.width * root.volumeLevel
                            radius: volumeTrack.radius
                            color: Theme.textPrimary
                        }
                    }

                    Icon {
                        source: "../icons/sound-high-solid.svg"
                    }
                }
            }
        }
    }
}
