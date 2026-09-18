pragma ComponentBehavior: Bound

import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Io
import "../singletons"

Scope {
    id: root

    enum Mode {
        Applications,
        Wallpapers
    }

    property int mode: LauncherBackend.Applications
    property string searchText: ""
    property var fileResults: []
    property var browserHistoryIndex: []
    property string fileSearchQuery: ""
    readonly property bool wallpaperMode: mode === LauncherBackend.Wallpapers
    readonly property string normalizedQuery: normalize(searchText.trim())
    readonly property bool searching: fileSearchProcess.running || historyProcess.running
    readonly property var applicationIndex: DesktopEntries.applications.values.map(entry => ({
                "entry": entry,
                "normalizedName": normalize(entry.name),
                "searchableText": normalize([entry.name, entry.genericName, entry.comment, (entry.keywords ?? []).join(" ")].join(" "))
            }))
    readonly property var frequentlyUsedApplications: {
        const usage = usageState.appUsage ?? {};
        return Object.keys(usage).map(entryId => {
            const record = usage[entryId];
            return {
                "entry": DesktopEntries.byId(entryId),
                "count": typeof record === "number" ? record : (record?.count ?? 0),
                "lastUsed": typeof record === "number" ? 0 : (record?.lastUsed ?? 0)
            };
        }).filter(item => item.entry !== null && item.count > 0).sort((a, b) => b.count - a.count || b.lastUsed - a.lastUsed).slice(0, 6).map(item => item.entry);
    }
    readonly property var wallpaperIndex: {
        const entries = [];
        for (let index = 0; index < wallpaperFiles.count; ++index) {
            const fileName = wallpaperFiles.get(index, "fileName");
            entries.push({
                "kind": "wallpaper",
                "name": fileName.replace(/\.[^.]+$/, ""),
                "fileName": fileName,
                "path": wallpaperFiles.get(index, "filePath"),
                "url": wallpaperFiles.get(index, "fileUrl"),
                "searchableText": normalize(fileName)
            });
        }
        return entries;
    }
    readonly property var results: {
        const terms = normalizedQuery.length ? normalizedQuery.split(/\s+/) : [];
        if (wallpaperMode)
            return wallpaperIndex.filter(item => terms.every(term => item.searchableText.includes(term)));
        if (!normalizedQuery.length)
            return [];

        const applications = applicationIndex.filter(item => terms.every(term => item.searchableText.includes(term))).sort((a, b) => {
            const aPrefix = a.normalizedName.startsWith(normalizedQuery);
            const bPrefix = b.normalizedName.startsWith(normalizedQuery);
            return Number(bPrefix) - Number(aPrefix) || a.entry.name.localeCompare(b.entry.name);
        }).slice(0, 8).map(item => ({
                    "kind": "application",
                    "name": item.entry.name,
                    "description": item.entry.genericName || item.entry.comment || I18n.tr("applicationResult"),
                    "icon": item.entry.icon,
                    "entry": item.entry
                }));
        const history = browserHistoryIndex.filter(item => terms.every(term => item.searchableText.includes(term))).slice(0, 6);
        const files = fileResults.filter(item => terms.every(term => item.searchableText.includes(term))).slice(0, 8);
        return applications.concat(history, files);
    }
    property bool applyingWallpaper: false
    property string errorMessage: ""

    signal activationSucceeded

    onNormalizedQueryChanged: scheduleFileSearch()
    onWallpaperModeChanged: {
        fileSearchTimer.stop();
        if (fileSearchProcess.running)
            fileSearchProcess.running = false;
        fileResults = [];
        if (!wallpaperMode)
            scheduleFileSearch();
    }

    function normalize(value: string): string {
        return value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
    }

    function prepare(): void {
        if (!wallpaperMode)
            refreshBrowserHistory();
    }

    function refreshBrowserHistory(): void {
        if (historyProcess.running)
            historyProcess.running = false;
        historyProcess.command = ["sqlite3", "-batch", "-noheader", "-separator", "\t", "file:" + Config.braveOriginHistoryPath + "?immutable=1", "SELECT replace(replace(coalesce(title, ''), char(9), ' '), char(10), ' '), replace(replace(url, char(9), ''), char(10), ''), last_visit_time FROM urls WHERE hidden = 0 AND url NOT LIKE 'brave://%' ORDER BY last_visit_time DESC LIMIT 500;"];
        historyProcess.running = true;
    }

    function scheduleFileSearch(): void {
        fileSearchTimer.stop();
        fileResults = [];
        if (fileSearchProcess.running)
            fileSearchProcess.running = false;
        if (!wallpaperMode && normalizedQuery.length >= 2)
            fileSearchTimer.start();
    }

    function startFileSearch(): void {
        fileSearchQuery = searchText.trim();
        fileSearchProcess.command = ["fd", "--type", "file", "--ignore-case", "--glob", "*" + fileSearchQuery + "*", "--max-results", "12", ".", Config.fileSearchRoot];
        fileSearchProcess.running = true;
    }

    function parseFileResults(output: string): var {
        return output.split("\n").filter(path => path.length > 0).map(path => {
            const separator = path.lastIndexOf("/");
            const name = separator >= 0 ? path.slice(separator + 1) : path;
            const parentPath = separator > 0 ? path.slice(0, separator) : Config.fileSearchRoot;
            return {
                "kind": "file",
                "name": name,
                "description": I18n.tr("fileResult") + " · " + parentPath,
                "icon": iconForFile(name),
                "path": path,
                "searchableText": normalize(name + " " + path)
            };
        });
    }

    function iconForFile(fileName: string): string {
        const extension = fileName.includes(".") ? fileName.split(".").pop().toLowerCase() : "";
        if (["png", "jpg", "jpeg", "webp", "gif", "svg", "jxl"].includes(extension))
            return "image-x-generic";
        if (["mp3", "flac", "ogg", "wav", "m4a"].includes(extension))
            return "audio-x-generic";
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(extension))
            return "video-x-generic";
        if (extension === "pdf")
            return "application-pdf";
        if (["zip", "7z", "rar", "tar", "gz", "xz"].includes(extension))
            return "package-x-generic";
        return "text-x-generic";
    }

    function historyTitle(title: string, url: string): string {
        if (title.trim().length)
            return title.trim();
        return url.replace(/^https?:\/\//, "").split(/[\/?#]/)[0] || url;
    }

    function rememberApplication(entry): void {
        const usage = Object.assign({}, usageState.appUsage ?? {});
        const previous = usage[entry.id];
        const previousCount = typeof previous === "number" ? previous : (previous?.count ?? 0);
        usage[entry.id] = {
            "count": previousCount + 1,
            "lastUsed": Date.now()
        };
        usageState.appUsage = usage;
        usageFile.writeAdapter();
    }

    function activate(entry): void {
        if (!entry)
            return;
        if (wallpaperMode || entry.kind === "wallpaper") {
            applyWallpaper(entry);
        } else if (entry.kind === "application") {
            activateApplication(entry.entry);
        } else if (entry.kind === "file") {
            openExternal(entry.path);
        } else if (entry.kind === "history") {
            openExternal(entry.url);
        } else {
            activateApplication(entry);
        }
    }

    function activateApplication(entry): void {
        if (!entry)
            return;
        rememberApplication(entry);
        entry.execute();
        activationSucceeded();
    }

    function openExternal(target: string): void {
        if (!target.length)
            return;
        externalOpenProcess.command = ["xdg-open", target];
        externalOpenProcess.running = true;
        activationSucceeded();
    }

    function applyWallpaper(entry): void {
        if (!entry || applyingWallpaper)
            return;
        errorMessage = "";
        applyingWallpaper = true;
        const monitors = Quickshell.screens.map(screen => screen.name);
        wallpaperProcess.command = ["sh", "-c", "wallpaper_path=$1; shift; for monitor do hyprctl hyprpaper wallpaper \"$monitor,$wallpaper_path,cover\" || exit 1; done", "orla-wallpaper", entry.path].concat(monitors);
        wallpaperProcess.running = true;
    }

    FileView {
        id: usageFile

        path: Config.launcherStatePath
        blockLoading: true
        atomicWrites: true
        printErrors: false

        JsonAdapter {
            id: usageState

            property var appUsage: ({})
        }
    }

    Timer {
        id: fileSearchTimer

        interval: 240
        repeat: false
        onTriggered: root.startFileSearch()
    }

    FolderListModel {
        id: wallpaperFiles

        folder: Config.wallpaperDirectoryUrl
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.jxl"]
        caseSensitive: false
        showDirs: false
        showFiles: true
        showHidden: false
        showOnlyReadable: true
        sortField: FolderListModel.Name
        sortCaseSensitive: false
    }

    Process {
        id: historyProcess

        stdout: StdioCollector {
            id: historyOutput
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                return;
            const entries = [];
            const seenUrls = {};
            const lines = historyOutput.text.split("\n");
            for (let index = 0; index < lines.length; ++index) {
                const fields = lines[index].split("\t");
                if (fields.length < 2 || !fields[1].length || seenUrls[fields[1]])
                    continue;
                seenUrls[fields[1]] = true;
                const title = root.historyTitle(fields[0], fields[1]);
                entries.push({
                    "kind": "history",
                    "name": title,
                    "description": I18n.tr("braveHistoryResult") + " · " + fields[1],
                    "icon": "brave-origin",
                    "url": fields[1],
                    "searchableText": root.normalize(title + " " + fields[1])
                });
            }
            root.browserHistoryIndex = entries;
        }
    }

    Process {
        id: fileSearchProcess

        stdout: StdioCollector {
            id: fileSearchOutput
        }
        onExited: exitCode => {
            if (exitCode === 0 && root.fileSearchQuery === root.searchText.trim())
                root.fileResults = root.parseFileResults(fileSearchOutput.text);
        }
    }

    Process {
        id: externalOpenProcess
    }

    Process {
        id: wallpaperProcess

        stdout: StdioCollector {
            id: wallpaperProcessOutput
        }
        stderr: StdioCollector {
            id: wallpaperProcessError
        }
        onExited: exitCode => {
            root.applyingWallpaper = false;
            if (exitCode === 0) {
                root.activationSucceeded();
                return;
            }
            const details = (wallpaperProcessError.text || wallpaperProcessOutput.text).trim();
            root.errorMessage = details.length ? details : I18n.tr("wallpaperApplyFailed");
        }
    }
}
