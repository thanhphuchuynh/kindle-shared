#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_PATH="${KINDLE_SHARE_BUILD_PATH:-/tmp/kindle-share-package-build}"
APP_DIR="$DIST_DIR/KindleShare.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
CONVERTER_DIR="$RESOURCES_DIR/Converter"
CALIBRE_BUNDLE_DIR="$RESOURCES_DIR/Calibre"
ICON_SOURCE="$ROOT_DIR/Assets/KindleShareLogo-BookWifi.png"
ICONSET_DIR="$DIST_DIR/KindleShare.iconset"
ICON_FILE="$RESOURCES_DIR/KindleShare.icns"
CALIBRE_APP_SOURCE="${KINDLE_SHARE_CALIBRE_APP:-/Applications/calibre.app}"
CALIBRE_CONVERTER_SOURCE="${KINDLE_SHARE_EBOOK_CONVERT:-/Applications/calibre.app/Contents/MacOS/ebook-convert}"

cd "$ROOT_DIR"

swift build -c release --build-path "$BUILD_PATH"

rm -rf "$APP_DIR" "$DIST_DIR/KindleShare.zip" "$ICONSET_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_PATH/release/KindleShare" "$MACOS_DIR/KindleShare"
chmod +x "$MACOS_DIR/KindleShare"

if [ -d "$CALIBRE_APP_SOURCE" ] && [ -x "$CALIBRE_APP_SOURCE/Contents/MacOS/ebook-convert" ]; then
  mkdir -p "$CALIBRE_BUNDLE_DIR"
  ditto --noextattr --norsrc "$CALIBRE_APP_SOURCE" "$CALIBRE_BUNDLE_DIR/calibre.app"
  xattr -cr "$CALIBRE_BUNDLE_DIR/calibre.app"
  echo "Bundled Calibre runtime from $CALIBRE_APP_SOURCE"
elif [ -x "$CALIBRE_CONVERTER_SOURCE" ]; then
  mkdir -p "$CONVERTER_DIR"
  cp "$CALIBRE_CONVERTER_SOURCE" "$CONVERTER_DIR/ebook-convert"
  chmod +x "$CONVERTER_DIR/ebook-convert"
  echo "Bundled standalone EPUB converter from $CALIBRE_CONVERTER_SOURCE"
else
  echo "warning: EPUB converter not bundled. Install Calibre or set KINDLE_SHARE_CALIBRE_APP=/path/to/calibre.app before packaging." >&2
fi

if [ -f "$ICON_SOURCE" ]; then
  mkdir -p "$ICONSET_DIR"
  sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"
else
  echo "warning: app icon source not found at $ICON_SOURCE" >&2
fi

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
  <key>CFBundleIconFile</key>
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

rm -rf "$ICONSET_DIR"
find "$APP_DIR" -name ".DS_Store" -delete
dot_clean -m "$APP_DIR"
xattr -cr "$APP_DIR"
if ! codesign --force --deep --sign - "$APP_DIR"; then
  echo "warning: ad-hoc signing failed. Continuing with an unsigned test build." >&2
fi
ditto -c -k --keepParent "$APP_DIR" "$DIST_DIR/KindleShare.zip"

echo "Created $DIST_DIR/KindleShare.zip"
