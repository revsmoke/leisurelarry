#!/bin/sh
set -eu
TOOLS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export GODOT_PATH="${GODOT_PATH:-/Applications/Godot.app/Contents/MacOS/Godot}"
exec node "$TOOLS_DIR/godot-mcp/build/index.js"
