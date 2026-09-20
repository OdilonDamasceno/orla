pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property int refreshInterval: 60000
    property var flamengoMatch: null
    property bool available: true
    property var badgeUrls: ({})
    property var pendingBadgeRequests: ({})
    readonly property string homeBadgeUrl: badgeForTeam(flamengoMatch?.home_team)
    readonly property string awayBadgeUrl: badgeForTeam(flamengoMatch?.away_team)

    function normalizedTeamName(team): string {
        return String(team?.name ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().trim();
    }

    function isFlamengo(team): bool {
        return normalizedTeamName(team).includes("flamengo");
    }

    function badgeForTeam(team): string {
        return badgeUrls[normalizedTeamName(team)] ?? "";
    }

    function requestBadge(team): void {
        const name = String(team?.name ?? "").trim();
        const key = normalizedTeamName(team);
        if (!key.length || Object.prototype.hasOwnProperty.call(badgeUrls, key) || pendingBadgeRequests[key])
            return;

        const requests = Object.assign({}, pendingBadgeRequests);
        requests[key] = true;
        pendingBadgeRequests = requests;

        const request = new XMLHttpRequest();
        request.onreadystatechange = function(): void {
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
                const exactTeam = teams.find(candidate => root.normalizedTeamName({ "name": candidate.strTeam }) === key);
                const result = exactTeam ?? teams[0] ?? null;
                const urls = Object.assign({}, root.badgeUrls);
                urls[key] = result?.strBadge ? result.strBadge + "/tiny" : "";
                root.badgeUrls = urls;
            } catch (error) {
                // Keep the fallback visible and retry on the next Golazo refresh.
            }
        };
        request.open("GET", "https://www.thesportsdb.com/api/v1/json/123/searchteams.php?t=" + encodeURIComponent(name));
        request.send();
    }

    function requestMatchBadges(match): void {
        if (!match)
            return;

        requestBadge(match.home_team);
        requestBadge(match.away_team);
    }

    function updateFromOutput(output: string): void {
        try {
            const envelope = JSON.parse(output);
            if (envelope.status !== "ok" || !Array.isArray(envelope.data)) {
                available = false;
                return;
            }

            flamengoMatch = envelope.data.find(match => match.status === "live"
                    && (isFlamengo(match.home_team) || isFlamengo(match.away_team))) ?? null;
            requestMatchBadges(flamengoMatch);
            available = true;
        } catch (error) {
            available = false;
        }
    }

    function refresh(): void {
        if (golazoProcess.running)
            return;

        golazoProcess.command = ["golazo", "live", "--timeout", "10s"];
        golazoProcess.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: root.refreshInterval
        repeat: true
        running: true
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
