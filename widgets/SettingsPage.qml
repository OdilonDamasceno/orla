pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons"

ScrollView {
    id: root

    contentWidth: availableWidth
    contentHeight: content.implicitHeight
    implicitHeight: Math.min(contentHeight, Theme.controlsPopupMaxHeight)
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    component SectionTitle: Text {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacingMedium
        leftPadding: Theme.spacingSmall
        text: ""
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.labelSize
        font.weight: Font.DemiBold
    }

    component SwitchSetting: Rectangle {
        id: switchCard

        property string title: ""
        property string description: ""
        property bool checked: false
        signal changed(bool checked)

        Layout.fillWidth: true
        implicitHeight: Math.max(Theme.serviceRowHeight, switchLayout.implicitHeight + Theme.spacingCompact * 2)
        radius: Theme.radiusMedium
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant

        RowLayout {
            id: switchLayout

            anchors.fill: parent
            anchors.margins: Theme.spacingCompact
            spacing: Theme.spacingMedium

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Text {
                    Layout.fillWidth: true
                    text: switchCard.title
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodySize
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: switchCard.description
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSize
                    wrapMode: Text.WordWrap
                }
            }

            Switch {
                id: settingSwitch

                implicitWidth: 52
                implicitHeight: Theme.controlTargetSize
                checked: switchCard.checked
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                Accessible.name: switchCard.title
                onToggled: switchCard.changed(checked)

                indicator: Rectangle {
                    anchors.centerIn: parent
                    width: 52
                    height: 32
                    radius: height / 2
                    color: settingSwitch.checked ? Theme.primary : Theme.surfaceContainerHigh
                    border.width: settingSwitch.checked ? 0 : 2
                    border.color: settingSwitch.visualFocus ? Theme.primary : Theme.outline

                    Rectangle {
                        x: settingSwitch.checked ? 24 : 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: settingSwitch.checked ? 24 : 16
                        height: width
                        radius: width / 2
                        color: settingSwitch.checked ? Theme.primaryContent : Theme.textSecondary

                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.feedbackDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.feedbackDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                contentItem: Item {}
                background: Rectangle {
                    radius: height / 2
                    color: settingSwitch.down ? Theme.pressedSurface : settingSwitch.hovered ? Theme.hoverSurface : "transparent"
                }
            }
        }
    }

    component TextSetting: Rectangle {
        id: textCard

        property string title: ""
        property string description: ""
        property string value: ""
        signal accepted(string value)

        Layout.fillWidth: true
        implicitHeight: textLayout.implicitHeight + Theme.spacingCompact * 2
        radius: Theme.radiusMedium
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant

        ColumnLayout {
            id: textLayout

            anchors.fill: parent
            anchors.margins: Theme.spacingCompact
            spacing: Theme.spacingMedium

            Text {
                Layout.fillWidth: true
                text: textCard.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: textCard.description
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                wrapMode: Text.WordWrap
            }

            TextField {
                id: settingField

                Layout.fillWidth: true
                text: textCard.value
                color: Theme.textPrimary
                placeholderTextColor: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                selectByMouse: true
                Accessible.name: textCard.title
                onEditingFinished: {
                    const candidate = text.trim();
                    if (candidate.length && candidate !== textCard.value)
                        textCard.accepted(candidate);
                }

                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.surfaceContainerHigh
                    border.width: settingField.activeFocus ? 2 : 1
                    border.color: settingField.activeFocus ? Theme.primary : Theme.outline
                }
            }
        }
    }

    component ColorSetting: Rectangle {
        id: colorCard

        property string title: ""
        property string value: "#000000"
        signal accepted(string value)

        Layout.fillWidth: true
        implicitHeight: Theme.serviceRowHeight
        radius: Theme.radiusMedium
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingCompact
            spacing: Theme.spacingMedium

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: Theme.radiusSmall
                color: colorField.acceptableInput ? colorField.text : colorCard.value
                border.width: 1
                border.color: Theme.outline
            }

            Text {
                Layout.fillWidth: true
                text: colorCard.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                elide: Text.ElideRight
            }

            TextField {
                id: colorField

                Layout.preferredWidth: 116
                text: colorCard.value
                color: acceptableInput ? Theme.textPrimary : Theme.error
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                selectByMouse: true
                Accessible.name: colorCard.title
                validator: RegularExpressionValidator {
                    regularExpression: /^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/
                }
                onEditingFinished: {
                    if (acceptableInput && text !== colorCard.value)
                        colorCard.accepted(text.toUpperCase());
                }

                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.surfaceContainerHigh
                    border.width: colorField.activeFocus ? 2 : 1
                    border.color: colorField.activeFocus ? Theme.primary : colorField.acceptableInput ? Theme.outline : Theme.error
                }
            }
        }
    }

    component NumberSetting: Rectangle {
        id: numberCard

        property string title: ""
        property int value: 0
        property int from: 0
        property int to: 100
        property int stepSize: 1
        property string suffix: ""
        signal changed(int value)

        Layout.fillWidth: true
        implicitHeight: Theme.serviceRowHeight
        radius: Theme.radiusMedium
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingCompact
            spacing: Theme.spacingMedium

            Text {
                Layout.fillWidth: true
                text: numberCard.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                elide: Text.ElideRight
            }

            SpinBox {
                id: numberInput

                Layout.preferredWidth: 132
                from: numberCard.from
                to: numberCard.to
                stepSize: numberCard.stepSize
                value: numberCard.value
                editable: true
                Accessible.name: numberCard.title
                textFromValue: function (value, locale): string {
                    return value + numberCard.suffix;
                }
                valueFromText: function (text, locale): int {
                    const parsed = parseInt(text, 10);
                    return Number.isFinite(parsed) ? parsed : numberCard.value;
                }
                onValueModified: numberCard.changed(value)

                contentItem: TextInput {
                    z: 2
                    text: numberInput.textFromValue(numberInput.value, numberInput.locale)
                    color: Theme.textPrimary
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.primaryContent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    readOnly: !numberInput.editable
                    validator: numberInput.validator
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }

                up.indicator: Rectangle {
                    x: numberInput.width - width
                    width: 32
                    height: numberInput.height
                    radius: Theme.radiusSmall
                    color: numberInput.up.pressed ? Theme.pressedSurface : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodySize
                    }
                }

                down.indicator: Rectangle {
                    width: 32
                    height: numberInput.height
                    radius: Theme.radiusSmall
                    color: numberInput.down.pressed ? Theme.pressedSurface : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "−"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodySize
                    }
                }

                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.surfaceContainerHigh
                    border.width: numberInput.activeFocus ? 2 : 1
                    border.color: numberInput.activeFocus ? Theme.primary : Theme.outline
                }
            }
        }
    }

    component ChoiceSetting: Rectangle {
        id: choiceCard

        property string title: ""
        property var values: []
        property var labels: []
        property string currentValue: ""
        signal selected(string value)

        Layout.fillWidth: true
        implicitHeight: Theme.serviceRowHeight
        radius: Theme.radiusMedium
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingCompact
            spacing: Theme.spacingMedium

            Text {
                Layout.fillWidth: true
                text: choiceCard.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                elide: Text.ElideRight
            }

            ComboBox {
                id: choiceInput

                Layout.preferredWidth: 152
                model: choiceCard.labels
                currentIndex: Math.max(0, choiceCard.values.indexOf(choiceCard.currentValue))
                Accessible.name: choiceCard.title
                onActivated: index => choiceCard.selected(choiceCard.values[index])

                contentItem: Text {
                    leftPadding: Theme.spacingCompact
                    rightPadding: 28
                    text: choiceInput.displayText
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSize
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                indicator: Item {
                    x: choiceInput.width - width - Theme.spacingMedium
                    y: (choiceInput.height - height) / 2
                    width: 12
                    height: 8

                    Rectangle {
                        x: 1
                        y: 2
                        width: 7
                        height: 2
                        radius: 1
                        rotation: 40
                        color: Theme.textSecondary
                    }

                    Rectangle {
                        x: 5
                        y: 2
                        width: 7
                        height: 2
                        radius: 1
                        rotation: -40
                        color: Theme.textSecondary
                    }
                }

                background: Rectangle {
                    radius: Theme.radiusSmall
                    color: Theme.surfaceContainerHigh
                    border.width: choiceInput.visualFocus ? 2 : 1
                    border.color: choiceInput.visualFocus ? Theme.primary : Theme.outline
                }

                delegate: ItemDelegate {
                    id: choiceDelegate

                    required property var modelData
                    required property int index

                    width: choiceInput.width
                    highlighted: choiceInput.highlightedIndex === index
                    contentItem: Text {
                        text: choiceDelegate.modelData
                        color: choiceDelegate.highlighted ? Theme.primary : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelSize
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: choiceDelegate.highlighted ? Theme.secondaryContainer : "transparent"
                    }
                }

                popup: Popup {
                    y: choiceInput.height + Theme.spacingSmall
                    width: choiceInput.width
                    implicitHeight: contentItem.implicitHeight + padding * 2
                    padding: Theme.spacingSmall

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: choiceInput.popup.visible ? choiceInput.delegateModel : null
                        currentIndex: choiceInput.highlightedIndex
                    }

                    background: Rectangle {
                        radius: Theme.radiusMedium
                        color: Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: Theme.outlineVariant
                    }
                }
            }
        }
    }

    component AnimationSetting: Rectangle {
        id: animationCard

        property real value: 1
        signal changed(real value)

        Layout.fillWidth: true
        implicitHeight: animationLayout.implicitHeight + Theme.spacingCompact * 2
        radius: Theme.radiusMedium
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant

        ColumnLayout {
            id: animationLayout

            anchors.fill: parent
            anchors.margins: Theme.spacingCompact
            spacing: Theme.spacingMedium

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: I18n.tr("animationScale")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodySize
                }

                Text {
                    text: Number(animationSlider.value).toFixed(2) + "×"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSize
                }
            }

            Slider {
                id: animationSlider

                Layout.fillWidth: true
                from: 0
                to: 3
                stepSize: 0.25
                value: animationCard.value
                Accessible.name: I18n.tr("animationScale")
                onMoved: animationCard.changed(value)

                background: Rectangle {
                    x: animationSlider.leftPadding
                    y: (animationSlider.height - height) / 2
                    width: animationSlider.availableWidth
                    height: 8
                    radius: height / 2
                    color: Theme.track

                    Rectangle {
                        width: animationSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Theme.primary
                    }
                }

                handle: Rectangle {
                    x: animationSlider.leftPadding + animationSlider.visualPosition * (animationSlider.availableWidth - width)
                    y: (animationSlider.height - height) / 2
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: width / 2
                    color: Theme.primary
                    border.width: animationSlider.visualFocus ? 2 : 0
                    border.color: Theme.textPrimary
                }
            }
        }
    }

    ColumnLayout {
        id: content

        width: root.availableWidth
        spacing: Theme.spacingMedium

        Text {
            Layout.fillWidth: true
            text: I18n.tr("settingsSubtitle")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSize
            wrapMode: Text.WordWrap
        }

        SectionTitle {
            text: I18n.tr("generalSettings")
        }

        ChoiceSetting {
            title: I18n.tr("language")
            values: ["pt_BR", "en_US"]
            labels: ["Português (Brasil)", "English (US)"]
            currentValue: Config.locale
            onSelected: value => Config.setPreference("", "locale", value)
        }

        SectionTitle {
            text: I18n.tr("appearanceSettings")
        }

        TextSetting {
            title: I18n.tr("fontFamily")
            value: Config.fontFamily
            onAccepted: value => Config.setPreference("appearance", "fontFamily", value)
        }

        AnimationSetting {
            enabled: !Config.reducedMotion
            opacity: enabled ? 1 : 0.5
            value: Config.preferredAnimationScale
            onChanged: value => Config.setPreference("appearance", "animationScale", value)
        }

        SwitchSetting {
            title: I18n.tr("reducedMotion")
            description: I18n.tr("reducedMotionDescription")
            checked: Config.reducedMotion
            onChanged: checked => Config.setPreference("accessibility", "reducedMotion", checked)
        }

        ColorSetting {
            title: I18n.tr("primaryColor")
            value: Config.primaryColor
            onAccepted: value => Config.setPreference("appearance", "primaryColor", value)
        }

        ColorSetting {
            title: I18n.tr("primaryContentColor")
            value: Config.primaryContentColor
            onAccepted: value => Config.setPreference("appearance", "primaryContentColor", value)
        }

        ColorSetting {
            title: I18n.tr("surfaceColor")
            value: Config.surfaceColor
            onAccepted: value => Config.setPreference("appearance", "surfaceColor", value)
        }

        ColorSetting {
            title: I18n.tr("islandColor")
            value: Config.islandColor
            onAccepted: value => Config.setPreference("appearance", "islandColor", value)
        }

        ColorSetting {
            title: I18n.tr("surfaceContainerColor")
            value: Config.surfaceContainerColor
            onAccepted: value => Config.setPreference("appearance", "surfaceContainerColor", value)
        }

        ColorSetting {
            title: I18n.tr("surfaceContainerHighColor")
            value: Config.surfaceContainerHighColor
            onAccepted: value => Config.setPreference("appearance", "surfaceContainerHighColor", value)
        }

        ColorSetting {
            title: I18n.tr("textPrimaryColor")
            value: Config.textPrimaryColor
            onAccepted: value => Config.setPreference("appearance", "textPrimaryColor", value)
        }

        ColorSetting {
            title: I18n.tr("textSecondaryColor")
            value: Config.textSecondaryColor
            onAccepted: value => Config.setPreference("appearance", "textSecondaryColor", value)
        }

        ColorSetting {
            title: I18n.tr("errorColor")
            value: Config.errorColor
            onAccepted: value => Config.setPreference("appearance", "errorColor", value)
        }

        ColorSetting {
            title: I18n.tr("liveIndicatorColor")
            value: Config.liveIndicatorColor
            onAccepted: value => Config.setPreference("appearance", "liveIndicatorColor", value)
        }

        ColorSetting {
            title: I18n.tr("outlineColor")
            value: Config.outlineColor
            onAccepted: value => Config.setPreference("appearance", "outlineColor", value)
        }

        ColorSetting {
            title: I18n.tr("outlineVariantColor")
            value: Config.outlineVariantColor
            onAccepted: value => Config.setPreference("appearance", "outlineVariantColor", value)
        }

        SectionTitle {
            text: I18n.tr("barAndLiveActivity")
        }

        TextSetting {
            title: I18n.tr("clockFormat")
            description: I18n.tr("clockFormatDescription")
            value: Config.clockFormat
            onAccepted: value => Config.setPreference("bar", "clockFormat", value)
        }

        SwitchSetting {
            title: I18n.tr("showTray")
            checked: Config.showTray
            onChanged: checked => Config.setPreference("bar", "showTray", checked)
        }

        SwitchSetting {
            title: I18n.tr("showLiveActivity")
            checked: Config.showLiveActivity
            onChanged: checked => Config.setPreference("bar", "showLiveActivity", checked)
        }

        SwitchSetting {
            title: I18n.tr("liveActivityEnabled")
            checked: Config.liveActivityEnabled
            onChanged: checked => Config.setPreference("liveActivity", "enabled", checked)
        }

        TextSetting {
            title: I18n.tr("favoriteTeam")
            value: Config.liveActivityTeam
            onAccepted: value => Config.setPreference("liveActivity", "team", value)
        }

        NumberSetting {
            title: I18n.tr("refreshInterval")
            value: Math.round(Config.liveActivityRefreshInterval / 1000)
            from: 15
            to: 600
            stepSize: 15
            suffix: " " + I18n.tr("secondsShort")
            onChanged: value => Config.setPreference("liveActivity", "refreshIntervalSeconds", value)
        }

        SwitchSetting {
            title: I18n.tr("showTeamBadges")
            checked: Config.liveActivityShowBadges
            onChanged: checked => Config.setPreference("liveActivity", "showBadges", checked)
        }

        SectionTitle {
            text: I18n.tr("launcherSettings")
        }

        SwitchSetting {
            title: I18n.tr("fileSearch")
            checked: Config.fileSearchEnabled
            onChanged: checked => Config.setPreference("launcher", "fileSearchEnabled", checked)
        }

        TextSetting {
            title: I18n.tr("fileSearchRoot")
            value: Config.fileSearchRoot
            onAccepted: value => Config.setPreference("launcher", "fileSearchRoot", value)
        }

        SwitchSetting {
            title: I18n.tr("browserHistory")
            checked: Config.browserHistoryEnabled
            onChanged: checked => Config.setPreference("launcher", "browserHistoryEnabled", checked)
        }

        TextSetting {
            title: I18n.tr("browserHistoryPath")
            value: Config.browserHistoryPath
            onAccepted: value => Config.setPreference("launcher", "browserHistoryPath", value)
        }

        NumberSetting {
            title: I18n.tr("maximumResults")
            value: Config.launcherMaximumResults
            from: 1
            to: 20
            onChanged: value => Config.setPreference("launcher", "maximumResults", value)
        }

        NumberSetting {
            title: I18n.tr("frequentApplicationsLimit")
            value: Config.frequentApplicationsLimit
            from: 0
            to: 6
            onChanged: value => Config.setPreference("launcher", "frequentApplicationsLimit", value)
        }

        TextSetting {
            title: I18n.tr("wallpaperDirectory")
            value: String(Config.wallpaperDirectoryUrl).replace(/^file:\/\//, "")
            onAccepted: value => Config.setPreference("launcher", "wallpaperDirectory", value)
        }

        SectionTitle {
            text: I18n.tr("notificationSettings")
        }

        NumberSetting {
            title: I18n.tr("defaultTimeout")
            value: Math.round(Config.notificationDefaultTimeout / 1000)
            from: 1
            to: 60
            suffix: " " + I18n.tr("secondsShort")
            onChanged: value => Config.setPreference("notifications", "defaultTimeoutSeconds", value)
        }

        NumberSetting {
            title: I18n.tr("historyLimit")
            value: Config.notificationHistoryLimit
            from: 0
            to: 500
            stepSize: 10
            onChanged: value => Config.setPreference("notifications", "historyLimit", value)
        }

        ChoiceSetting {
            title: I18n.tr("notificationPosition")
            values: ["top-left", "top-right", "bottom-left", "bottom-right"]
            labels: [I18n.tr("topLeft"), I18n.tr("topRight"), I18n.tr("bottomLeft"), I18n.tr("bottomRight")]
            currentValue: Config.notificationPosition
            onSelected: value => Config.setPreference("notifications", "position", value)
        }

        SectionTitle {
            text: I18n.tr("osdSettings")
        }

        NumberSetting {
            title: I18n.tr("volumeOsdDuration")
            value: Config.volumeOsdDuration
            from: 250
            to: 10000
            stepSize: 250
            suffix: " ms"
            onChanged: value => Config.setPreference("osd", "volumeDurationMilliseconds", value)
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingMedium
            Layout.bottomMargin: Theme.spacingLarge
            text: I18n.tr(Config.configWriteFailed ? "settingsSaveFailed" : "settingsSavedAutomatically")
            color: Config.configWriteFailed ? Theme.error : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSize
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
