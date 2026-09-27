#!/usr/bin/env bash
#
# Copy the shared build configuration into another Getbrick repository and report drift.
#
#   ./scripts/install-build-config.sh /path/to/getbrick-core            # install
#   ./scripts/install-build-config.sh /path/to/getbrick-core --check    # CI: fail on drift
#
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config"
TARGET_DIR="${1:-}"
MODE="${2:-install}"

usage() {
    echo "usage: $(basename "$0") <target-repo> [--check]" >&2
    exit 2
}

[ -n "$TARGET_DIR" ] || usage
[ -d "$SOURCE_DIR" ] || { echo "source config not found: $SOURCE_DIR" >&2; exit 1; }

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || { echo "target not found: $1" >&2; exit 1; }
DEST="${TARGET_DIR}/config"

if [ "$MODE" = "--check" ]; then
    if ! diff -ru "$SOURCE_DIR" "$DEST"; then
        echo
        echo "config/ is out of sync with getbrick-build."
        echo "Run: ./scripts/install-build-config.sh $TARGET_DIR"
        exit 1
    fi
    echo "config/ is in sync."
    exit 0
fi

mkdir -p "$DEST"
changed=0
while IFS= read -r -d '' file; do
    rel="${file#"$SOURCE_DIR/"}"
    if [ -f "$DEST/$rel" ] && diff -q "$file" "$DEST/$rel" >/dev/null 2>&1; then
        continue
    fi
    mkdir -p "$(dirname "$DEST/$rel")"
    if [ -f "$DEST/$rel" ]; then
        echo "  updated: config/$rel"
    else
        echo "  added:   config/$rel"
    fi
    cp "$file" "$DEST/$rel"
    changed=$((changed + 1))
done < <(find "$SOURCE_DIR" -type f -print0)

# Drop files that no longer exist upstream.
while IFS= read -r -d '' file; do
    rel="${file#"$DEST/"}"
    if [ ! -f "$SOURCE_DIR/$rel" ]; then
        echo "  removed: config/$rel"
        rm -f "$file"
        changed=$((changed + 1))
    fi
done < <(find "$DEST" -type f -print0)

if [ "$changed" -eq 0 ]; then
    echo "config/ already up to date in ${TARGET_DIR}."
else
    echo "${changed} file(s) synced into ${DEST}."
fi
