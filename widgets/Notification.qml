pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../singletons"

Scope {
    id: root

    readonly property int defaultExpireTimeout: 5000
    property var interactingNotifications: []

    function setInteraction(notification, active): void {
        const remaining = interactingNotifications.filter(item => item !== notification);
        interactingNotifications = active ? remaining.concat([notification]) : remaining;
    }

    NotificationServer {
        id: notificationServer

        actionsSupported: true
        bodyImagesSupported: false
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true

        onNotification: notification => notification.tracked = true
    }

    Instantiator {
        model: notificationServer.trackedNotifications

        delegate: Timer {
            id: expiryTimer

            required property var modelData
            readonly property bool paused: root.interactingNotifications.includes(modelData)
            readonly property bool expires: modelData.expireTimeout !== 0 && modelData.urgency !== NotificationUrgency.Critical
            readonly property real duration: modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000 : root.defaultExpireTimeout
            property real remaining: duration
            property real deadline: 0

            // Quickshell exposes seconds; QML timers use milliseconds.
            interval: Math.max(1, remaining)
            repeat: false

            function resume() {
                if (expires && !paused) {
                    deadline = Date.now() + remaining;
                    start();
                }
            }

            onPausedChanged: {
                if (paused) {
                    if (running) {
                        stop();
                        remaining = Math.max(0, deadline - Date.now());
                    }
                } else {
                    resume();
                }
            }

            onDurationChanged: {
                stop();
                remaining = duration;
                resume();
            }
            onExpiresChanged: {
                if (!expires)
                    stop();
                else
                    resume();
            }
            Component.onCompleted: resume()
            onTriggered: {
                if (!paused)
                    modelData.expire();
            }
        }
    }

    LazyLoader {
        active: notificationServer.trackedNotifications.values.length > 0

        PanelWindow { // qmllint disable uncreatable-type
            id: notificationWindow

            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: true
                right: true
            }

            implicitWidth: 320
            implicitHeight: screen ? screen.height : 600
            color: "transparent"
            exclusiveZone: 0
            focusable: true

            mask: Region {
                item: notificationList
            }

            ListView {
                id: notificationList

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spacingLarge
                // Reserve space inside the clipped viewport for the floating close button.
                readonly property int closeButtonOverflow: 6
                anchors.leftMargin: Theme.spacingLarge - closeButtonOverflow
                anchors.topMargin: Theme.spacingLarge - closeButtonOverflow
                height: Math.min(contentHeight, Math.max(0, notificationWindow.height - y - Theme.spacingLarge))
                clip: true
                spacing: Theme.spacingMedium

                model: notificationServer.trackedNotifications
                delegate: Item {
                    id: notificationDelegate

                    required property var modelData

                    width: notificationList.width
                    height: notificationCard.height + notificationList.closeButtonOverflow

                    NotificationCard {
                        id: notificationCard

                        x: notificationList.closeButtonOverflow
                        y: notificationList.closeButtonOverflow
                        width: notificationDelegate.width - x
                        modelData: notificationDelegate.modelData
                        onInteractionChanged: (notification, active) => root.setInteraction(notification, active)
                    }
                }
            }
        }
    }
}
