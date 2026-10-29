#!/bin/sh
# Package an app bundle as a drag-to-install DMG with a background and fixed icon layout.
# Usage: scripts/make-dmg.sh <app bundle> <output dmg>
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
DMG="$2"
APP_NAME="$(basename "$APP")"
VOLUME="Hotspot Meter"

WORK=$(mktemp -d)
MOUNT=""
cleanup() {
    [ -n "$MOUNT" ] && hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
    rm -rf "$WORK"
}
trap cleanup EXIT

mkdir -p "$WORK/stage/.background"
cp -R "$APP" "$WORK/stage/"
ln -s /Applications "$WORK/stage/Applications"
cp "$ROOT/Resources/dmg-background.tiff" "$WORK/stage/.background/background.tiff"
cp "$ROOT/Resources/AppIcon.icns" "$WORK/stage/.VolumeIcon.icns"

hdiutil create -volname "$VOLUME" -srcfolder "$WORK/stage" -fs HFS+ -format UDRW "$WORK/rw.dmg" >/dev/null
MOUNT=$(hdiutil attach -readwrite -noverify -noautoopen "$WORK/rw.dmg" | awk -F'\t' '/\/Volumes\//{print $NF}')
DISK="$(basename "$MOUNT")"
SetFile -a C "$MOUNT" 2>/dev/null || true

# Window: 600x380 content (plus title bar); positions match make-dmg-background.swift.
osascript <<EOF
tell application "Finder"
    tell disk "$DISK"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 800, 528}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 112
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:background.tiff"
        set position of item "$APP_NAME" of container window to {150, 180}
        set position of item "Applications" of container window to {450, 180}
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

sync
hdiutil detach "$MOUNT" -quiet
MOUNT=""
rm -f "$DMG"
hdiutil convert "$WORK/rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
echo "Packaged $DMG"
