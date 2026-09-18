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
    readonly property bool wallpaperMode: mode === LauncherBackend.Wallpapers
    readonly property string normalizedQuery: normalize(searchText.trim())
    readonly property var applicationIndex: DesktopEntries.applications.values.map(entry => ({
                "entry": entry,
                "normalizedName": normalize(entry.name),
                "searchableText": normalize([entry.name, entry.genericName, entry.comment, (entry.keywords ?? []).join(" ")].join(" "))
            }))
    readonly property var wallpaperIndex: {
        const entries = [];
        for (let index = 0; index < wallpaperFiles.count; ++index) {
            const fileName = wallpaperFiles.get(index, "fileName");
            entries.push({
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
        return applicationIndex.filter(item => terms.every(term => item.searchableText.includes(term))).sort((a, b) => {
            const aPrefix = a.normalizedName.startsWith(normalizedQuery);
            const bPrefix = b.normalizedName.startsWith(normalizedQuery);
            return Number(bPrefix) - Number(aPrefix) || a.entry.name.localeCompare(b.entry.name);
        }).map(item => item.entry);
    }
    property bool applyingWallpaper: false
    property string errorMessage: ""

    signal activationSucceeded

    function normalize(value: string): string {
        return value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
    }

    function activate(entry): void {
        if (!entry)
            return;
        if (wallpaperMode)
            applyWallpaper(entry);
        else {
            entry.execute();
            activationSucceeded();
        }
    }

    function applyWallpaper(entry): void {
        if (!entry || applyingWallpaper)
            return;
        errorMessage = "";
        applyingWallpaper = true;
        const monitors = Quickshell.screens.map(screen => screen.name);
        wallpaperProcess.command = [
            "sh",
            "-c",
            "wallpaper_path=$1; shift; for monitor do hyprctl hyprpaper wallpaper \"$monitor,$wallpaper_path,cover\" || exit 1; done",
            "orla-wallpaper",
            entry.path
        ].concat(monitors);
        wallpaperProcess.running = true;
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
