pragma ComponentBehavior: Bound

import QtQuick

ListView {
    id: root

    required property var entries
    required property string selectionContext
    property string previousContext: ""

    // Update the model and selection together, retaining the selected identity
    // when asynchronous sources insert results before it.
    model: []

    function resultKey(entry): string {
        return entry ? entry.kind + ":" + (entry.entry?.id ?? entry.path ?? entry.url ?? "") : "";
    }

    function refreshResults(): void {
        const selectedKey = selectionContext === previousContext ? resultKey(model[currentIndex]) : "";
        const nextIndex = selectedKey.length ? entries.findIndex(entry => resultKey(entry) === selectedKey) : -1;
        previousContext = selectionContext;
        model = entries;
        currentIndex = nextIndex >= 0 ? nextIndex : entries.length ? 0 : -1;
        if (currentIndex >= 0)
            positionViewAtIndex(currentIndex, ListView.Contain);
    }

    onEntriesChanged: Qt.callLater(refreshResults)
    onSelectionContextChanged: Qt.callLater(refreshResults)
    Component.onCompleted: refreshResults()
}
