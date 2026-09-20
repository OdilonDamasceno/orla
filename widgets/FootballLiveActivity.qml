pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../singletons"

Item {
    id: root

    required property var matchData
    property url homeBadgeUrl: ""
    property url awayBadgeUrl: ""

    readonly property var homeTeam: matchData?.home_team
    readonly property var awayTeam: matchData?.away_team
    readonly property string homeName: homeTeam?.short_name || homeTeam?.name || ""
    readonly property string awayName: awayTeam?.short_name || awayTeam?.name || ""
    readonly property string homeLabel: teamLabel(homeTeam)
    readonly property string awayLabel: teamLabel(awayTeam)
    readonly property string score: `${matchData?.home_score ?? 0} × ${matchData?.away_score ?? 0}`
    readonly property string liveTime: matchData?.live_time || I18n.tr("liveMatch")
    readonly property string accessibleScore: `${I18n.tr("teamLiveScore")}: ${homeTeam?.name || homeName} ${score} ${awayTeam?.name || awayName}, ${liveTime}`

    function teamLabel(team): string {
        const name = String(team?.short_name || team?.name || "").trim();
        return name.slice(0, 3).toUpperCase();
    }

    implicitWidth: Math.min(240, scoreContent.implicitWidth + Theme.spacingLarge * 2)
    implicitHeight: 28
    Accessible.role: Accessible.StaticText
    Accessible.name: accessibleScore

    RectangularShadow {
        anchors.fill: scoreSurface
        radius: scoreSurface.radius
        blur: Theme.floatingShadowBlur
        offset: Qt.vector2d(0, Theme.floatingShadowOffset)
        color: Theme.floatingShadow
    }

    Rectangle {
        id: scoreSurface

        anchors.fill: parent
        radius: height / 2
        color: Theme.islandSurface
        border.width: 1
        border.color: Theme.outlineVariant

        RowLayout {
            id: scoreContent

            anchors {
                fill: parent
                leftMargin: Theme.spacingCompact
                rightMargin: Theme.spacingCompact
            }
            spacing: Theme.spacingMedium

            Rectangle {
                Layout.preferredWidth: 6
                Layout.preferredHeight: 6
                radius: 3
                color: Theme.liveIndicator
            }

            TeamBadge {
                visible: Config.liveActivityShowBadges
                teamName: root.homeName
                badgeUrl: root.homeBadgeUrl
            }

            Text {
                text: root.homeLabel
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                font.weight: Font.DemiBold
            }

            Text {
                text: root.score
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                font.weight: Font.Bold
            }

            Text {
                text: root.awayLabel
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                font.weight: Font.Medium
            }

            TeamBadge {
                visible: Config.liveActivityShowBadges
                teamName: root.awayName
                badgeUrl: root.awayBadgeUrl
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 12
                color: Theme.outlineVariant
            }

            Text {
                text: root.liveTime
                color: Theme.liveIndicator
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                font.weight: Font.DemiBold
            }
        }

        ToolTip.visible: scoreHover.hovered
        ToolTip.text: root.accessibleScore

        HoverHandler {
            id: scoreHover
        }
    }
}
