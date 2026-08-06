#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_PATH="${KINDLE_SHARE_BUILD_PATH:-/tmp/kindle-share-package-build}"
PACKAGE_DIR="${KINDLE_SHARE_PACKAGE_DIR:-/tmp/kindle-share-package-dist}"
APP_DIR="$PACKAGE_DIR/KindleShare.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BOKO_DIR="$RESOURCES_DIR/Boko"
ICON_SOURCE="$ROOT_DIR/Assets/KindleShareLogo-BookWifi.png"
ICONSET_DIR="$DIST_DIR/KindleShare.iconset"
ICON_FILE="$RESOURCES_DIR/KindleShare.icns"
BOKO_REPO="${KINDLE_SHARE_BOKO_REPO:-https://github.com/zacharydenton/boko.git}"
BOKO_SOURCE_DIR="${KINDLE_SHARE_BOKO_SOURCE_DIR:-/tmp/kindle-share-boko}"
BOKO_BINARY_SOURCE="${KINDLE_SHARE_BOKO:-}"

cd "$ROOT_DIR"

swift build -c release --build-path "$BUILD_PATH"

rm -rf "$PACKAGE_DIR" "$DIST_DIR/KindleShare.app" "$DIST_DIR/KindleShare.zip" "$ICONSET_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$DIST_DIR"

cp "$BUILD_PATH/release/KindleShare" "$MACOS_DIR/KindleShare"
chmod +x "$MACOS_DIR/KindleShare"

if [ -n "$BOKO_BINARY_SOURCE" ] && [ -x "$BOKO_BINARY_SOURCE" ]; then
  mkdir -p "$BOKO_DIR"
  cp "$BOKO_BINARY_SOURCE" "$BOKO_DIR/boko"
  echo "Bundled boko converter from $BOKO_BINARY_SOURCE"
else
  if [ ! -d "$BOKO_SOURCE_DIR/.git" ]; then
    rm -rf "$BOKO_SOURCE_DIR"
    git clone --depth 1 "$BOKO_REPO" "$BOKO_SOURCE_DIR"
  fi

  cargo build --manifest-path "$BOKO_SOURCE_DIR/Cargo.toml" --release --bin boko
  mkdir -p "$BOKO_DIR"
  cp "$BOKO_SOURCE_DIR/target/release/boko" "$BOKO_DIR/boko"
  cp "$BOKO_SOURCE_DIR/LICENSE" "$BOKO_DIR/LICENSE-GPL-3.0-or-later.txt"
  echo "Bundled boko converter from $BOKO_SOURCE_DIR"
fi
chmod +x "$BOKO_DIR/boko"

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
xattr -d com.apple.FinderInfo "$APP_DIR" 2>/dev/null || true
xattr -d "com.apple.fileprovider.fpfs#P" "$APP_DIR" 2>/dev/null || true
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"
ditto -c -k --keepParent "$APP_DIR" "$PACKAGE_DIR/KindleShare.zip"
cp "$PACKAGE_DIR/KindleShare.zip" "$DIST_DIR/KindleShare.zip"

echo "Created $DIST_DIR/KindleShare.zip"
