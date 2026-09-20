pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../singletons"

Scope {
    id: root

    readonly property int refreshInterval: Config.liveActivityRefreshInterval
    readonly property string favoriteTeam: Config.liveActivityTeam
    property var match: null
    property bool available: true
    property var badgeUrls: ({})
    property var pendingBadgeRequests: ({})
    readonly property string homeBadgeUrl: badgeForTeam(match?.home_team)
    readonly property string awayBadgeUrl: badgeForTeam(match?.away_team)

    function normalizedTeamName(team): string {
        const name = typeof team === "string" ? team : team?.name;
        return String(name ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().trim();
    }

    function isFavoriteTeam(team): bool {
        const candidate = normalizedTeamName(team);
        const favorite = normalizedTeamName(favoriteTeam);
        return candidate.length > 0 && favorite.length > 0 && (candidate.includes(favorite) || favorite.includes(candidate));
    }

    function badgeForTeam(team): string {
        if (!Config.liveActivityShowBadges)
            return "";
        return badgeUrls[normalizedTeamName(team)] ?? "";
    }

    function requestBadge(team): void {
        if (!Config.liveActivityShowBadges)
            return;

        const name = String(team?.name ?? "").trim();
        const key = normalizedTeamName(team);
        if (!key.length || Object.prototype.hasOwnProperty.call(badgeUrls, key) || pendingBadgeRequests[key])
            return;

        const requests = Object.assign({}, pendingBadgeRequests);
        requests[key] = true;
        pendingBadgeRequests = requests;

        const request = new XMLHttpRequest();
        request.onreadystatechange = function (): void {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;

            const remainingRequests = Object.assign({}, root.pendingBadgeRequests);
            delete remainingRequests[key];
            root.pendingBadgeRequests = remainingRequests;

            if (request.status !== 200)
                return;

            try {
                const response = JSON.parse(request.responseText);
                const teams = Array.isArray(response.teams) ? response.teams.filter(candidate => candidate.strSport === "Soccer") : [];
                const exactTeam = teams.find(candidate => root.normalizedTeamName(candidate.strTeam) === key);
                const result = exactTeam ?? teams[0] ?? null;
                const urls = Object.assign({}, root.badgeUrls);
                urls[key] = result?.strBadge ? result.strBadge + "/tiny" : "";
                root.badgeUrls = urls;
            } catch (error) {
                // Keep the fallback visible and retry on the next match refresh.
            }
        };
        request.open("GET", "https://www.thesportsdb.com/api/v1/json/123/searchteams.php?t=" + encodeURIComponent(name));
        request.send();
    }

    function requestMatchBadges(currentMatch): void {
        if (!currentMatch || !Config.liveActivityShowBadges)
            return;

        requestBadge(currentMatch.home_team);
        requestBadge(currentMatch.away_team);
    }

    function updateFromOutput(output: string): void {
        try {
            const envelope = JSON.parse(output);
            if (envelope.status !== "ok" || !Array.isArray(envelope.data)) {
                available = false;
                match = null;
                return;
            }

            match = envelope.data.find(candidate => candidate.status === "live" && (isFavoriteTeam(candidate.home_team) || isFavoriteTeam(candidate.away_team))) ?? null;
            requestMatchBadges(match);
            available = true;
        } catch (error) {
            available = false;
            match = null;
        }
    }

    function refresh(): void {
        if (!Config.liveActivityEnabled || golazoProcess.running)
            return;

        golazoProcess.command = ["golazo", "live", "--timeout", "10s"];
        golazoProcess.running = true;
    }

    onFavoriteTeamChanged: {
        match = null;
        refresh();
    }
    onRefreshIntervalChanged: refreshTimer.restart()

    Connections {
        target: Config

        function onLiveActivityEnabledChanged(): void {
            if (Config.liveActivityEnabled)
                root.refresh();
            else
                root.match = null;
        }

        function onLiveActivityShowBadgesChanged(): void {
            if (Config.liveActivityShowBadges)
                root.requestMatchBadges(root.match);
        }
    }

    Component.onCompleted: refresh()

    Timer {
        id: refreshTimer

        interval: root.refreshInterval
        repeat: true
        running: Config.liveActivityEnabled
        onTriggered: root.refresh()
    }

    Process {
        id: golazoProcess

        stdout: StdioCollector {
            id: golazoOutput
        }
        onExited: exitCode => {
            if (exitCode === 0)
                root.updateFromOutput(golazoOutput.text);
            else
                root.available = false;
        }
    }
}
