pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../singletons"

Rectangle {
    id: root

    property bool active: true
    property string outputName: ""
    required property var player
    readonly property bool playing: root.player?.isPlaying ?? false
    readonly property real duration: root.player?.lengthSupported ? Math.max(0, root.player.length) : 0
    readonly property real position: root.player?.positionSupported ? Math.max(0, Math.min(root.duration, root.player.position)) : 0
    signal outputRequested

    implicitHeight: Theme.mediaCardHeight
    radius: Theme.radiusLarge
    color: Theme.secondaryContainer

    function seekTo(seconds: real): void {
        if (root.player?.canSeek && root.player.positionSupported && root.duration > 0)
            root.player.position = Math.max(0, Math.min(root.duration, seconds));
    }
    function formatTime(seconds: real): string {
        const value = Math.max(0, Math.floor(seconds));
        return Math.floor(value / 60) + ":" + String(value % 60).padStart(2, "0");
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active && root.playing && (root.player?.positionSupported ?? false)
        onTriggered: root.player.positionChanged()
    }
    onActiveChanged: {
        if (root.active && root.player?.positionSupported)
            root.player.positionChanged();
    }

    Rectangle {
        id: artworkMask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }
    Item {
        anchors.fill: parent
        visible: cover.status === Image.Ready
        layer.enabled: visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: artworkMask
        }
        Image {
            id: cover
            anchors.fill: parent
            source: root.active ? root.player?.trackArtUrl ?? "" : ""
            sourceSize.width: Math.ceil(root.width * 2)
            sourceSize.height: Math.ceil(root.height * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.mediaScrimStart }
                GradientStop { position: 1; color: Theme.mediaScrimEnd }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMedium
        spacing: Theme.spacingSmall

        RowLayout {
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlTargetSize
            spacing: Theme.spacingMedium
            Icon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                source: "../icons/music-note.svg"
                color: Theme.primary
            }
            Text {
                Layout.fillWidth: true
                text: root.player?.identity || I18n.tr("mediaPlayer")
                textFormat: Text.PlainText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
            Button {
                id: outputButton
                Layout.preferredWidth: Math.min(168, root.width * 0.52)
                Layout.preferredHeight: Theme.controlTargetSize
                padding: Theme.spacingMedium
                hoverEnabled: true
                Accessible.name: I18n.tr("outputDevices")
                Accessible.description: root.outputName
                onClicked: root.outputRequested()
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                background: Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 28
                    radius: height / 2
                    color: outputButton.down ? Theme.primary : Theme.textPrimary
                    opacity: outputButton.hovered ? 1 : 0.92
                    border.width: outputButton.visualFocus ? 2 : 0
                    border.color: Theme.primary
                }
                contentItem: RowLayout {
                    spacing: Theme.spacingSmall
                    Icon {
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        source: "../icons/speaker-high.svg"
                        color: Theme.primaryContent
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.outputName || I18n.tr("audio")
                        textFormat: Text.PlainText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelSize
                        font.weight: Font.Medium
                        color: Theme.primaryContent
                        elide: Text.ElideRight
                    }
                }
                ToolTip.visible: hovered
                ToolTip.delay: 700
                ToolTip.text: root.outputName
            }
        }

        RowLayout {
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.mediaPlayButtonSize
            spacing: Theme.spacingCompact
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall
                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackTitle || I18n.tr("unknownTrack") : I18n.tr("noMedia")
                    textFormat: Text.PlainText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodySize
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    HoverHandler { id: titleHover }
                    ToolTip.visible: titleHover.hovered
                    ToolTip.delay: 700
                    ToolTip.text: text
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackArtist || root.player.trackAlbum || root.player.identity : I18n.tr("openMediaHint")
                    textFormat: Text.PlainText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSize
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    HoverHandler { id: artistHover }
                    ToolTip.visible: artistHover.hovered
                    ToolTip.delay: 700
                    ToolTip.text: text
                }
            }
            Button {
                id: playButton
                objectName: "mediaPlayButton"
                Layout.preferredWidth: Theme.mediaPlayButtonSize
                Layout.preferredHeight: Theme.mediaPlayButtonSize
                enabled: root.player?.canTogglePlaying ?? false
                hoverEnabled: true
                Accessible.name: I18n.tr(root.playing ? "pauseMedia" : "playMedia")
                onClicked: { if (root.player?.canTogglePlaying) root.player.togglePlaying(); }
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                background: Rectangle {
                    radius: root.playing ? Theme.radiusMedium : width / 2
                    color: Theme.primary
                    opacity: !playButton.enabled ? 0.3 : playButton.down ? 0.8 : 1
                    border.width: playButton.visualFocus ? 2 : 0
                    border.color: Theme.primaryContent
                    Behavior on radius {
                        NumberAnimation { duration: Theme.feedbackDuration }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.primaryContent
                        opacity: playButton.hovered && playButton.enabled ? 0.08 : 0
                    }
                }
                contentItem: Item {
                    Icon {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: root.playing ? "../icons/pause.svg" : "../icons/play.svg"
                        color: Theme.primaryContent
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlTargetSize
            spacing: Theme.spacingSmall
            SplashButton {
                objectName: "mediaPreviousButton"
                Layout.preferredWidth: Theme.controlTargetSize
                Layout.preferredHeight: Theme.controlTargetSize
                leftPadding: Theme.spacingMedium
                rightPadding: Theme.spacingMedium
                icon.source: "../icons/skip-previous.svg"
                icon.width: 20
                icon.height: 20
                enabled: root.player?.canGoPrevious ?? false
                Accessible.name: I18n.tr("previousTrack")
                onClicked: { if (root.player?.canGoPrevious) root.player.previous(); }
            }
            Slider {
                id: seek
                objectName: "mediaSeekSlider"
                property var dragPlayer: null
                property int dragTrack: -1
                property real requestedPosition: 0
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.controlTargetSize
                enabled: (root.player?.canSeek ?? false) && (root.player?.positionSupported ?? false) && root.duration > 0
                from: 0
                to: Math.max(1, root.duration)
                stepSize: 1
                hoverEnabled: true
                Accessible.name: I18n.tr("mediaProgress")
                Accessible.description: root.formatTime(value) + " / " + root.formatTime(root.duration)
                Binding {
                    target: seek
                    property: "value"
                    value: root.position
                    when: !seek.pressed
                    restoreMode: Binding.RestoreNone
                }
                onMoved: {
                    if (pressed)
                        requestedPosition = value;
                    else
                        root.seekTo(value);
                }
                onPressedChanged: {
                    if (pressed) {
                        dragPlayer = root.player;
                        dragTrack = root.player?.uniqueId ?? -1;
                        requestedPosition = value;
                    } else if (dragPlayer === root.player && dragTrack === (root.player?.uniqueId ?? -1)) {
                        root.seekTo(requestedPosition);
                    }
                }
                background: Canvas {
                    id: wave
                    x: seek.leftPadding + 6
                    y: (seek.height - height) / 2
                    width: Math.max(0, seek.availableWidth - 12)
                    height: 16
                    property real progress: seek.visualPosition
                    property bool playing: root.playing
                    onProgressChanged: requestPaint()
                    onPlayingChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const end = width * progress;
                        const middle = height / 2;
                        ctx.lineWidth = 2;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Qt.alpha(Theme.textPrimary, 0.3);
                        ctx.beginPath();
                        ctx.moveTo(end, middle);
                        ctx.lineTo(width, middle);
                        ctx.stroke();
                        ctx.strokeStyle = Theme.textPrimary;
                        ctx.beginPath();
                        for (let x = 0; x <= end; x += 1) {
                            const taper = Math.min(1, x / 8, (end - x) / 8);
                            const y = middle + (playing ? Math.sin(x * Math.PI / 10) * 2.5 * taper : 0);
                            if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                        }
                        ctx.stroke();
                    }
                }
                handle: Rectangle {
                    x: seek.leftPadding + seek.visualPosition * (seek.availableWidth - width)
                    y: (seek.height - height) / 2
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: width / 2
                    visible: root.duration > 0
                    color: Theme.textPrimary
                    border.width: seek.visualFocus ? 2 : 0
                    border.color: Theme.primaryContent
                }
                ToolTip.visible: hovered || pressed
                ToolTip.text: root.duration > 0 ? root.formatTime(value) + " / " + root.formatTime(root.duration) : I18n.tr("progressUnavailable")
            }
            SplashButton {
                objectName: "mediaNextButton"
                Layout.preferredWidth: Theme.controlTargetSize
                Layout.preferredHeight: Theme.controlTargetSize
                leftPadding: Theme.spacingMedium
                rightPadding: Theme.spacingMedium
                icon.source: "../icons/skip-next.svg"
                icon.width: 20
                icon.height: 20
                enabled: root.player?.canGoNext ?? false
                Accessible.name: I18n.tr("nextTrack")
                onClicked: { if (root.player?.canGoNext) root.player.next(); }
            }
        }
    }
}
