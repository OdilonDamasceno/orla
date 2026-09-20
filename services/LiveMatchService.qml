pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../singletons"

Scope {
    id: root

    readonly property int refreshInterval: Config.liveActivityRefreshInterval
    readonly property string favoriteTeam: Config.liveActivityTeam
    readonly property string liveEventsUrl: "https://api.sofascore.com/api/v1/sport/football/events/live"
    property var match: null
    property bool available: true
    property var activeRequest: null
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
                // Keep the text fallback visible and retry on the next match refresh.
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

    function liveTimeForEvent(event): string {
        const statusCode = Number(event?.status?.code ?? 0);
        if (statusCode === 31)
            return I18n.tr("halfTime");

        const timing = event?.time ?? event?.statusTime;
        const periodStartedAt = Number(timing?.currentPeriodStartTimestamp ?? timing?.timestamp ?? 0);
        if (periodStartedAt <= 0)
            return event?.status?.description || I18n.tr("liveMatch");

        const initialSeconds = Number(timing?.initial ?? 0);
        const maximumSeconds = Number(timing?.max ?? 0);
        const elapsedSeconds = Math.max(0, Math.floor(Date.now() / 1000) - periodStartedAt + initialSeconds);
        if (maximumSeconds > 0 && elapsedSeconds > maximumSeconds) {
            const regulationMinute = Math.floor(maximumSeconds / 60);
            const additionalMinute = Math.max(1, Math.ceil((elapsedSeconds - maximumSeconds) / 60));
            return `${regulationMinute}+${additionalMinute}'`;
        }

        return `${Math.max(1, Math.floor(elapsedSeconds / 60) + 1)}'`;
    }

    function normalizedTeam(team): var {
        return {
            id: Number(team?.id ?? 0),
            name: String(team?.name ?? ""),
            short_name: String(team?.nameCode || team?.shortName || team?.name || "")
        };
    }

    function normalizedEvent(event): var {
        return {
            id: Number(event?.id ?? 0),
            status: "live",
            home_team: normalizedTeam(event?.homeTeam),
            away_team: normalizedTeam(event?.awayTeam),
            home_score: Number(event?.homeScore?.current ?? event?.homeScore?.display ?? 0),
            away_score: Number(event?.awayScore?.current ?? event?.awayScore?.display ?? 0),
            live_time: liveTimeForEvent(event)
        };
    }

    function updateFromResponse(response): void {
        if (!Array.isArray(response?.events))
            throw new Error("Invalid SofaScore live events response");

        const event = response.events.find(candidate => candidate?.status?.type === "inprogress"
            && (isFavoriteTeam(candidate?.homeTeam) || isFavoriteTeam(candidate?.awayTeam))) ?? null;
        match = event ? normalizedEvent(event) : null;
        requestMatchBadges(match);
        available = true;
    }

    function refresh(): void {
        if (!Config.liveActivityEnabled || activeRequest !== null)
            return;

        const request = new XMLHttpRequest();
        activeRequest = request;
        request.onreadystatechange = function (): void {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;

            root.activeRequest = null;
            if (request.status !== 200) {
                root.available = false;
                return;
            }

            try {
                root.updateFromResponse(JSON.parse(request.responseText));
            } catch (error) {
                root.available = false;
            }
        };
        request.open("GET", liveEventsUrl);
        request.setRequestHeader("Accept", "application/json");
        request.send();
    }

    onFavoriteTeamChanged: {
        match = null;
        refresh();
    }
    onRefreshIntervalChanged: refreshTimer.restart()

    Connections {
        target: Config

        function onLiveActivityEnabledChanged(): void {
            if (Config.liveActivityEnabled) {
                root.refresh();
            } else {
                if (root.activeRequest !== null)
                    root.activeRequest.abort();
                root.activeRequest = null;
                root.match = null;
            }
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
}
