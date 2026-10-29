#!/bin/sh
# Build Hotspot Meter, sign it with the company Developer ID, notarize it,
# and package it as a DMG that opens without Gatekeeper warnings.
#
# Needs, once per Mac:
#   - "Developer ID Application: ODD Inc. (STRPJDK4MR)" in the login keychain
#   - a notarytool keychain profile (xcrun notarytool store-credentials)
# Override with SIGN_IDENTITY and NOTARY_PROFILE.
set -eu

cd "$(dirname "$0")/.."

IDENTITY="${SIGN_IDENTITY:-Developer ID Application: ODD Inc. (STRPJDK4MR)}"
PROFILE="${NOTARY_PROFILE:-hotspotmeter-notary}"
APP="build/Hotspot Meter.app"

if ! security find-identity -v -p codesigning | grep -qF "\"$IDENTITY\""; then
    echo "Signing identity not found in the keychain: $IDENTITY" >&2
    exit 1
fi
if ! xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    echo "Notary profile not usable: $PROFILE (run xcrun notarytool store-credentials $PROFILE)" >&2
    exit 1
fi

scripts/bundle.sh
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG="build/HotspotMeter-$VERSION.dmg"

codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"

STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
rm -f "$DMG"
hdiutil create -volname "Hotspot Meter" -srcfolder "$STAGING" -format UDZO "$DMG"
codesign --force --timestamp --sign "$IDENTITY" "$DMG"

xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature --verbose "$DMG"

echo "Built $DMG"
