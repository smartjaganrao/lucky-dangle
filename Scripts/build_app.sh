#!/bin/bash
# Builds LuckyDangle in release mode and wraps it in a proper .app bundle
# (LuckyDangle.app) so it behaves like a normal Mac app: double-clickable,
# a stable identity for Accessibility/Input Monitoring permissions, etc.
set -e

cd "$(dirname "$0")/.."

echo "Building (release)..."
swift build -c release

APP_NAME="Lucky Dangle"
APP_DIR="./${APP_NAME}.app"
BIN_PATH=$(swift build -c release --show-bin-path)

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH/LuckyDangle" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "Sources/LuckyDangle/Info.plist" "$APP_DIR/Contents/Info.plist"
cp Resources/* "$APP_DIR/Contents/Resources/" 2>/dev/null || true

# Ad-hoc code sign so macOS treats it as a consistent app identity across
# launches (required for Input Monitoring / Accessibility permission to
# stick reliably).
codesign --force --deep --sign - "$APP_DIR"

echo "Built: $APP_DIR"
echo "Move it to /Applications and launch it from there."
