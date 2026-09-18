pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import "../components"
import "../singletons"

Rectangle {
    id: card

    required property var notification
    property bool expanded: false
    property bool replying: false
    readonly property bool hovered: cardHover.hovered || closeButton.hovered
    readonly property bool interacting: hovered || (expanded && replying) || inlineReply.activeFocus || closeButton.activeFocus
    signal interactionChanged(var notification, bool active)

    onInteractingChanged: interactionChanged(notification, interacting)
    Component.onDestruction: interactionChanged(notification, false)

    implicitWidth: 288
    height: Math.max(content.implicitHeight, 32) + 24
    radius: 20
    color: Theme.surfaceContainer

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        color: Theme.shadow
    }

    GradientBorder {}

    HoverHandler {
        id: cardHover
    }

    Button {
        id: expandButton
        anchors.fill: parent
        Accessible.name: card.notification?.summary ?? ""
        background: Rectangle {
            color: "transparent"
            radius: card.radius
            border.width: expandButton.visualFocus ? 1 : 0
            border.color: Theme.primary
        }

        onClicked: {
            card.expanded = !card.expanded;
            if (!card.expanded)
                inlineReply.focus = false;
        }
    }

    Button {
        id: closeButton

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: -6
        anchors.topMargin: -6
        width: 24
        height: 24
        z: 2
        visible: true
        hoverEnabled: true
        padding: 5

        icon.source: "../icons/x.svg"
        icon.color: "transparent"
        icon.width: 14
        icon.height: 14
        Accessible.name: I18n.tr("closeNotification")

        background: Rectangle {
            radius: width / 2
            color: closeButton.down ? Theme.pressedSurface : closeButton.hovered ? Theme.hoverSurface : Theme.surfaceContainerHigh
            border.color: closeButton.visualFocus ? Theme.primary : Theme.outline
            border.width: 1
        }

        onClicked: card.notification?.dismiss()
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }

        ClippingWrapperRectangle {
            Layout.alignment: Qt.AlignTop
            radius: 12

            Image {
                source: card.notification?.image ?? ""
                sourceSize.width: 32
                sourceSize.height: 32
            }
        }

        ColumnLayout {
            id: content

            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                Layout.fillWidth: true

                textFormat: Text.PlainText
                text: card.notification?.appName ?? ""
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true

                text: card.notification?.summary ?? ""
                textFormat: Text.PlainText
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true

                text: card.notification?.body ?? ""
                textFormat: Text.StyledText
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: card.expanded ? -1 : 1
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 6
                visible: card.expanded && !card.replying && ((card.notification?.actions.length ?? 0) > 0 || (card.notification?.hasInlineReply ?? false))

                Repeater {
                    // Inline reply is exposed separately from the regular actions.
                    model: (card.notification?.actions.length ?? 0) + (card.notification?.hasInlineReply ? 1 : 0)

                    delegate: Button {
                        id: actionButton

                        required property int index
                        readonly property bool isReply: index === (card.notification?.actions.length ?? 0)

                        Layout.fillWidth: true
                        text: isReply ? (card.notification?.inlineReplyPlaceholder || I18n.tr("reply")) : card.notification?.actions[index]?.text ?? ""
                        padding: 8
                        hoverEnabled: true

                        contentItem: Text {
                            text: actionButton.text
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.labelSize
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WordWrap
                        }

                        background: Rectangle {
                            radius: 8
                            color: actionButton.down ? Theme.pressedSurface : actionButton.hovered ? Theme.hoverSurface : Theme.surfaceContainerHigh
                            border.width: actionButton.visualFocus ? 1 : 0
                            border.color: Theme.primary
                        }

                        onClicked: {
                            if (isReply) {
                                card.replying = true;
                                inlineReply.forceActiveFocus();
                            } else {
                                card.notification?.actions[index]?.invoke();
                            }
                        }
                    }
                }
            }

            TextField {
                id: inlineReply

                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: card.expanded && card.replying && (card.notification?.hasInlineReply ?? false)
                placeholderText: card.notification?.inlineReplyPlaceholder || I18n.tr("replyPlaceholder")
                color: Theme.textPrimary
                placeholderTextColor: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                padding: 8
                selectByMouse: true

                Keys.onEscapePressed: {
                    card.replying = false;
                    inlineReply.focus = false;
                }

                background: Rectangle {
                    radius: 8
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: inlineReply.activeFocus ? Theme.primary : Theme.outline
                }

                onAccepted: {
                    if (!inlineReply.text.trim())
                        return;
                    const reply = inlineReply.text;
                    inlineReply.clear();
                    card.replying = false;
                    inlineReply.focus = false;
                    card.notification?.sendInlineReply(reply);
                }
            }
        }
    }
}
