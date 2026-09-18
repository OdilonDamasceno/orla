pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int historyLimit: 100
    property int nextHistoryId: 1
    property var history: []
    property alias notifications: notificationServer.trackedNotifications

    function capture(notification): void {
        const entry = {
            "historyId": root.nextHistoryId++,
            "notificationId": notification.id,
            "appKey": notification.desktopEntry || notification.appName || "unknown",
            "appName": notification.appName || notification.desktopEntry || "",
            "appIcon": notification.appIcon || "",
            "summary": notification.summary || "",
            "body": notification.body || "",
            "image": notification.image || "",
            "timestamp": Date.now()
        };
        const previous = root.history.filter(item => item.notificationId !== notification.id);
        root.history = [entry].concat(previous).slice(0, root.historyLimit);
    }

    function remove(historyId: int): void {
        root.history = root.history.filter(item => item.historyId !== historyId);
    }

    function clear(): void {
        root.history = [];
    }

    NotificationServer {
        id: notificationServer

        actionsSupported: true
        bodyImagesSupported: false
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true

        onNotification: notification => {
            root.capture(notification);
            notification.tracked = true;
        }
    }
}
