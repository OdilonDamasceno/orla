#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

if ! command -v qmllint >/dev/null 2>&1; then
    echo 'qmllint indisponível. Execute dentro de nix develop.' >&2
    exit 1
fi

import_args=()
IFS=: read -r -a import_paths <<< "${QML_IMPORT_PATH:-}"
for import_path in "${import_paths[@]}"; do
    if [[ -n "$import_path" ]]; then
        import_args+=(-I "$import_path")
    fi
done

qmllint "${import_args[@]}" shell.qml AppBar.qml singletons/*.qml widgets/*.qml
git diff --check
