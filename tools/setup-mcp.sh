#!/bin/sh
set -eu
TOOLS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$TOOLS_DIR/godot-mcp"
npm ci --ignore-scripts
npm run build
npm audit --omit=dev
