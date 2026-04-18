#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

mkdir -p "$BIN_DIR"

echo "Building clipboard-info..."
cd "$SCRIPT_DIR/clipboard-info"
swift build -c release 2>&1
cp "$(swift build -c release --show-bin-path)/clipboard-info" "$BIN_DIR/"

echo "Building ax-inspector..."
cd "$SCRIPT_DIR/ax-inspector"
swift build -c release 2>&1
cp "$(swift build -c release --show-bin-path)/ax-inspector" "$BIN_DIR/"

echo "Bridge tools built successfully in $BIN_DIR"
ls -la "$BIN_DIR"
