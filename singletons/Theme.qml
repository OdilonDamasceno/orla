pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string fontFamily: Config.fontFamily

    readonly property color surface: Config.surfaceColor
    readonly property color islandSurface: Config.islandColor
    readonly property color surfaceContainer: Config.surfaceContainerColor
    readonly property color surfaceContainerHigh: Config.surfaceContainerHighColor
    // MD3 on-surface roles use text names to avoid QML signal-handler syntax.
    readonly property color textPrimary: Config.textPrimaryColor
    readonly property color textSecondary: Config.textSecondaryColor
    readonly property color primary: Config.primaryColor
    readonly property color primaryContent: Config.primaryContentColor
    readonly property color error: Config.errorColor
    readonly property color liveIndicator: Config.liveIndicatorColor
    readonly property color secondaryContainer: "#27232F"
    readonly property color outline: Config.outlineColor
    readonly property color outlineVariant: Config.outlineVariantColor
    readonly property color hoverSurface: "#70333333"
    readonly property color pressedSurface: "#444444"
    readonly property color track: "#38383D"
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.24)
    readonly property color floatingShadow: Qt.rgba(0, 0, 0, 0.72)
    readonly property color glassHighlight: "#2fffffff"
    readonly property color mediaScrimStart: "#DB170F29"
    readonly property color mediaScrimEnd: "#B0170F29"

    readonly property int spacingSmall: 4
    readonly property int spacingMedium: 8
    readonly property int spacingCompact: 12
    readonly property int spacingLarge: 16
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 16
    readonly property int radiusLarge: 24
    readonly property int radiusExtraLarge: 32
    readonly property int labelSize: 12
    readonly property int bodySize: 14
    readonly property int titleSize: 16
    readonly property int barItemHorizontalPadding: 20
    readonly property int barHeight: 32
    readonly property int floatingShadowBlur: 20
    readonly property int floatingShadowOffset: 5
    readonly property int floatingShadowMargin: 20
    readonly property int motionDuration: Math.round(240 * Config.animationScale)
    readonly property int feedbackDuration: Math.round(150 * Config.animationScale)
    readonly property int controlTargetSize: 40
    readonly property int sliderIconSize: 20
    readonly property int sliderHandleWidth: 4
    readonly property int sliderHandleHeight: 32
    readonly property int sliderHandleGap: 6
    readonly property int sliderTrackHeight: 16
    readonly property int sliderInsideRadius: 2
    readonly property int serviceRowHeight: 56
    readonly property int controlsPopupWidth: 360
    readonly property int controlsDetailsWidth: 400
    readonly property int controlsPopupMaxHeight: 560
    readonly property int notificationHistoryWidth: 320
    readonly property int quickTileHeight: 64
    readonly property int mediaCardHeight: 144
    readonly property int mediaPlayButtonSize: 40
}
