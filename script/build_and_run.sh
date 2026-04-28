#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Lockey"
BUNDLE_ID="com.rumipro.Lockey"
MIN_SYSTEM_VERSION="14.0"
APP_VERSION="${LOCKEY_VERSION:-1.0.0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
INFO_PLIST="$APP_CONTENTS/Info.plist"
LOGO_SOURCE="$ROOT_DIR/assets/logo.png"
ICONSET_DIR="$DIST_DIR/AppIcon.iconset"
ICON_FILE="$APP_RESOURCES/AppIcon.icns"
DMG_STAGING_DIR="$DIST_DIR/dmg"
DMG_FILE="$DIST_DIR/$APP_NAME-$APP_VERSION.dmg"
DMG_LATEST_FILE="$DIST_DIR/$APP_NAME.dmg"
CODESIGN_IDENTITY="${LOCKEY_CODESIGN_IDENTITY:-}"
NOTARY_PROFILE="${LOCKEY_NOTARY_PROFILE:-}"
KEYCHAIN_PROFILE_ARG=()
MODULE_CACHE_DIR="$ROOT_DIR/.build/ModuleCache"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
mkdir -p "$MODULE_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"
export SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR"

if [[ -n "$NOTARY_PROFILE" ]]; then
  KEYCHAIN_PROFILE_ARG=(--keychain-profile "$NOTARY_PROFILE")
fi

build_binary() {
  swift build >&2
  printf '%s\n' "$(swift build --show-bin-path)/$APP_NAME"
}

sign_app_if_requested() {
  if [[ -z "$CODESIGN_IDENTITY" ]]; then
    return
  fi

  codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
}

sign_file_if_requested() {
  local target="$1"

  if [[ -z "$CODESIGN_IDENTITY" ]]; then
    return
  fi

  codesign --force --timestamp --sign "$CODESIGN_IDENTITY" "$target"
}

notarize_if_requested() {
  local target="$1"

  if [[ -z "$NOTARY_PROFILE" ]]; then
    return
  fi

  xcrun notarytool submit "$target" "${KEYCHAIN_PROFILE_ARG[@]}" --wait
  xcrun stapler staple "$target"
}

BUILD_BINARY="$(build_binary)"

rm -rf "$APP_BUNDLE" "$DMG_STAGING_DIR"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_MACOS/$APP_NAME"
chmod +x "$APP_MACOS/$APP_NAME"

if [[ -f "$LOGO_SOURCE" ]]; then
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"

  sips -z 16 16 "$LOGO_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$LOGO_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$LOGO_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$LOGO_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$LOGO_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$LOGO_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$LOGO_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$LOGO_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$LOGO_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  cp "$LOGO_SOURCE" "$ICONSET_DIR/icon_512x512@2x.png"

  iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

sign_app_if_requested

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

build_dmg() {
  rm -rf "$DMG_STAGING_DIR" "$DMG_FILE" "$DMG_LATEST_FILE"
  mkdir -p "$DMG_STAGING_DIR"
  cp -R "$APP_BUNDLE" "$DMG_STAGING_DIR/"
  ln -s /Applications "$DMG_STAGING_DIR/Applications"

  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING_DIR" \
    -format UDZO \
    -ov \
    "$DMG_FILE"

  sign_file_if_requested "$DMG_FILE"
  notarize_if_requested "$DMG_FILE"
  cp "$DMG_FILE" "$DMG_LATEST_FILE"

  printf 'DMG created at %s\n' "$DMG_FILE"
  printf 'Latest DMG alias created at %s\n' "$DMG_LATEST_FILE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --bundle|bundle)
    printf 'App bundle created at %s\n' "$APP_BUNDLE"
    ;;
  --dmg|dmg)
    build_dmg
    ;;
  --debug|debug)
    lldb -- "$APP_MACOS/$APP_NAME"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--bundle|--dmg|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
