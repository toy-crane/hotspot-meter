#!/bin/sh
# Build a release binary and wrap it in a menu-bar-only .app bundle.
set -eu

cd "$(dirname "$0")/.."

APP="build/Hotspot Meter.app"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/HotspotMeter "$APP/Contents/MacOS/HotspotMeter"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>HotspotMeter</string>
    <key>CFBundleIdentifier</key>
    <string>com.odd.hotspotmeter</string>
    <key>CFBundleName</key>
    <string>Hotspot Meter</string>
    <key>CFBundleDisplayName</key>
    <string>Hotspot Meter</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
