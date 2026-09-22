#!/bin/sh
# Export locally. No upload, Developer ID credentials, or notarization.
set -eu
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$PROJECT_ROOT"
TARGET=${1:-all}
case "$TARGET" in all|macos|web) ;; *) printf '%s\n' 'Usage: ./tools/package.sh [all|macos|web]' >&2; exit 2;; esac
mkdir -p exports/macos exports/web
touch exports/.gdignore
./tools/godot --headless --path "$PROJECT_ROOT" --import
if [ "$TARGET" = all ] || [ "$TARGET" = macos ]; then
    ./tools/godot --headless --path "$PROJECT_ROOT" --export-release macOS "$PROJECT_ROOT/exports/macos/Last Call in Lost Wages.app"
    ditto -c -k --norsrc --noextattr --keepParent "$PROJECT_ROOT/exports/macos/Last Call in Lost Wages.app" "$PROJECT_ROOT/exports/Last Call in Lost Wages-macOS.zip"
fi
if [ "$TARGET" = all ] || [ "$TARGET" = web ]; then
    ./tools/godot --headless --path "$PROJECT_ROOT" --export-release Web "$PROJECT_ROOT/exports/web/index.html"
    ditto -c -k --norsrc --noextattr "$PROJECT_ROOT/exports/web" "$PROJECT_ROOT/exports/Last Call in Lost Wages-Web.zip"
fi
node tools/verify-exports.mjs "$TARGET"
if [ "$TARGET" = all ] || [ "$TARGET" = macos ]; then
    node tools/smoke-native.mjs
fi
node tools/build-manifest.mjs "$TARGET"
