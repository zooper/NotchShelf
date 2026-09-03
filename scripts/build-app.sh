#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
CONFIGURATION=${1:-release}
SIGNING_IDENTITY=${NOTCHSHELF_CODESIGN_IDENTITY:-}

if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
    print -u2 "Usage: $0 [debug|release]"
    exit 2
fi

cd "$PROJECT_DIR"
swift build --configuration "$CONFIGURATION"

BIN_DIR=$(swift build --configuration "$CONFIGURATION" --show-bin-path)
APP_DIR="$PROJECT_DIR/build/NotchShelf.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$PROJECT_DIR/build/NotchShelf.iconset"
ICON_FILE="$PROJECT_DIR/build/AppIcon.icns"

if [[ -d "$APP_DIR" ]]; then
    rm -rf "$APP_DIR"
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN_DIR/NotchShelf" "$MACOS_DIR/NotchShelf"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

swift "$PROJECT_DIR/scripts/generate-app-icon.swift" "$ICONSET_DIR"
iconutil --convert icns --output "$ICON_FILE" "$ICONSET_DIR"
cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"

if [[ -z "$SIGNING_IDENTITY" ]]; then
    SIGNING_IDENTITY=$(
        security find-identity -v -p codesigning 2>/dev/null \
            | awk '/"Developer ID Application:|"Apple Development:|"Mac Developer:/{print $2; exit}'
    )
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none "$APP_DIR"

    DESIGNATED_REQUIREMENT=$(codesign -d -r- "$APP_DIR" 2>&1)
    if [[ "$DESIGNATED_REQUIREMENT" == *"designated => cdhash"* ]]; then
        print -u2 "Signing failed to produce a stable designated requirement."
        exit 1
    fi
    print "Signed with stable identity: $SIGNING_IDENTITY"
else
    codesign --force --sign - --timestamp=none "$APP_DIR"
    print -u2 "Warning: no stable code-signing identity was found; Accessibility approval may need to be renewed after rebuilding."
fi

print "$APP_DIR"
