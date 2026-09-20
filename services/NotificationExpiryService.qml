pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Services.Notifications
import "../singletons"

Scope {
    id: root

    required property var notifications
    readonly property int defaultExpireTimeout: Config.notificationDefaultTimeout
    property var pausedNotifications: []

    function setPaused(notification, paused: bool): void {
        const remaining = pausedNotifications.filter(item => item !== notification);
        pausedNotifications = paused ? remaining.concat([notification]) : remaining;
    }

    Instantiator {
        model: root.notifications

        delegate: Timer {
            id: expiryTimer

            required property var modelData
            readonly property bool paused: root.pausedNotifications.includes(modelData)
            readonly property bool expires: modelData.expireTimeout !== 0 && modelData.urgency !== NotificationUrgency.Critical
            readonly property real duration: modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000 : root.defaultExpireTimeout
            property real remaining: duration
            property real deadline: 0

            // Quickshell exposes seconds; QML timers use milliseconds.
            interval: Math.max(1, remaining)
            repeat: false

            function resume(): void {
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
}
