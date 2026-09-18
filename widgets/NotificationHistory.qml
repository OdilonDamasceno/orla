pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../singletons"

Item {
    id: root

    readonly property var groups: {
        const grouped = [];
        const indexes = {};
        for (const notification of NotificationStore.history) {
            const key = notification.appKey;
            let index = indexes[key];
            if (index === undefined) {
                index = grouped.length;
                indexes[key] = index;
                grouped.push({
                    "appKey": key,
                    "appName": notification.appName || I18n.tr("unknownApplication"),
                    "appIcon": notification.appIcon,
                    "notifications": []
                });
            }
            grouped[index].notifications.push(notification);
        }
        return grouped;
    }
    readonly property real contentImplicitHeight: historyHeader.implicitHeight + Theme.spacingMedium + Math.max(emptyState.implicitHeight, groupsColumn.implicitHeight)

    implicitWidth: Theme.notificationHistoryWidth
    implicitHeight: contentImplicitHeight

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingMedium

        RowLayout {
            id: historyHeader

            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlTargetSize
            spacing: Theme.spacingMedium

            Text {
                Layout.fillWidth: true
                text: I18n.tr("notificationHistory")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Button {
                id: clearButton

                visible: NotificationStore.history.length > 0
                text: I18n.tr("clearHistory")
                padding: Theme.spacingMedium
                hoverEnabled: true
                Accessible.name: text
                onClicked: NotificationStore.clear()

                contentItem: Text {
                    text: clearButton.text
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: clearButton.down ? Theme.pressedSurface : clearButton.hovered || clearButton.visualFocus ? Theme.hoverSurface : "transparent"
                    border.width: clearButton.visualFocus ? 1 : 0
                    border.color: Theme.primary
                }
            }
        }

        ScrollView {
            id: historyScroll

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            contentHeight: Math.max(emptyState.implicitHeight, groupsColumn.implicitHeight)
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Text {
                id: emptyState

                visible: NotificationStore.history.length === 0
                width: historyScroll.availableWidth
                topPadding: Theme.spacingLarge
                text: I18n.tr("emptyNotificationHistory")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                id: groupsColumn

                visible: NotificationStore.history.length > 0
                width: historyScroll.availableWidth
                spacing: Theme.spacingLarge

                Repeater {
                    model: root.groups

                    delegate: ColumnLayout {
                        id: groupDelegate

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Theme.spacingMedium

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingMedium

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24

                                ClippingWrapperRectangle {
                                    anchors.fill: parent
                                    radius: Theme.radiusSmall
                                    color: Theme.surfaceContainerHigh

                                    Image {
                                        id: appIcon

                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingSmall
                                        source: {
                                            const icon = groupDelegate.modelData.appIcon;
                                            return icon ? Quickshell.iconPath(icon, true) : "";
                                        }
                                        sourceSize.width: 16
                                        sourceSize.height: 16
                                        fillMode: Image.PreserveAspectFit
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: appIcon.status !== Image.Ready
                                    text: groupDelegate.modelData.appName.charAt(0).toUpperCase()
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.labelSize
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: groupDelegate.modelData.appName
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.labelSize
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.preferredWidth: countLabel.implicitWidth + Theme.spacingMedium * 2
                                Layout.preferredHeight: 24
                                radius: height / 2
                                color: Theme.surfaceContainerHigh

                                Text {
                                    id: countLabel

                                    anchors.centerIn: parent
                                    text: groupDelegate.modelData.notifications.length
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.labelSize
                                }
                            }
                        }

                        Repeater {
                            model: groupDelegate.modelData.notifications

                            delegate: Rectangle {
                                id: historyCard

                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: notificationContent.implicitHeight + Theme.spacingLarge
                                radius: Theme.radiusMedium
                                color: Theme.surfaceContainer
                                border.width: 1
                                border.color: Theme.outlineVariant

                                RowLayout {
                                    id: notificationContent

                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: Theme.spacingMedium
                                    }
                                    spacing: Theme.spacingMedium

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSmall

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Theme.spacingMedium

                                            Text {
                                                Layout.fillWidth: true
                                                text: historyCard.modelData.summary
                                                textFormat: Text.PlainText
                                                color: Theme.textPrimary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.labelSize
                                                font.weight: Font.DemiBold
                                                wrapMode: Text.WordWrap
                                            }

                                            Text {
                                                text: Qt.locale(I18n.locale).toString(new Date(historyCard.modelData.timestamp), I18n.tr("notificationTime"))
                                                color: Theme.textSecondary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.labelSize
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: text.length > 0
                                            text: historyCard.modelData.body
                                            textFormat: Text.StyledText
                                            color: Theme.textSecondary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.labelSize
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                        }
                                    }

                                    ToolButton {
                                        Layout.alignment: Qt.AlignTop
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        padding: Theme.spacingMedium
                                        icon.source: "../icons/x.svg"
                                        icon.color: "transparent"
                                        Accessible.name: I18n.tr("removeFromHistory")
                                        onClicked: NotificationStore.remove(historyCard.modelData.historyId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
