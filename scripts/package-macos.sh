#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/KindleShare.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"

swift build -c release

rm -rf "$APP_DIR" "$DIST_DIR/KindleShare.zip"
mkdir -p "$MACOS_DIR"

cp "$ROOT_DIR/.build/release/KindleShare" "$MACOS_DIR/KindleShare"
chmod +x "$MACOS_DIR/KindleShare"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Kindle Share</string>
  <key>CFBundleDisplayName</key>
  <string>Kindle Share</string>
  <key>CFBundleIdentifier</key>
  <string>local.kindleshare.app</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleExecutable</key>
  <string>KindleShare</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSLocalNetworkUsageDescription</key>
  <string>Kindle Share uses your local network so Kindle devices on the same Wi-Fi can download selected books.</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_DIR"
ditto -c -k --keepParent "$APP_DIR" "$DIST_DIR/KindleShare.zip"

echo "Created $DIST_DIR/KindleShare.zip"
