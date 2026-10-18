#!/bin/bash
# Builds release and assembles build/Ports.app (ad-hoc signed).
# Usage: ./scripts/bundle.sh [--install]
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
bin="$(swift build -c release --show-bin-path)/Ports"

app=build/Ports.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin" "$app/Contents/MacOS/Ports"
cp Resources/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"
echo "built $app"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x Ports || true
    rm -rf /Applications/Ports.app
    cp -R "$app" /Applications/
    echo "installed /Applications/Ports.app"
fi
