pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../singletons"
import "../widgets"

Scope {
    id: root

    NotificationExpiryService {
        id: notificationExpiry

        notifications: NotificationStore.activeNotifications
    }

    LazyLoader {
        active: NotificationStore.activeNotifications.values.length > 0

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

                model: NotificationStore.activeNotifications
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
                        notification: notificationDelegate.modelData
                        onInteractionChanged: (notification, active) => notificationExpiry.setPaused(notification, active)
                    }
                }
            }
        }
    }
}
