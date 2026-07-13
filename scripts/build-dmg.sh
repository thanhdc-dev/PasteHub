#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PasteHub"
VOLUME_NAME="${APP_NAME} Installer"
CONFIGURATION="Release"
BUILD_DIR="../build"
SOURCE_FOLDER_PATH="${BUILD_DIR}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
BACKGROUND_IMAGE_PATH="dmg_background.png"

echo "🔨 Building $APP_NAME..."

xcodebuild clean build \
  -project "../$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=YES

if [ ! -d "$SOURCE_FOLDER_PATH" ]; then
    echo "❌ Build thất bại"
    exit 1
fi

echo "✍️  Ad-hoc signing..."
codesign --force --deep --sign - "$SOURCE_FOLDER_PATH"

echo "✅ Build + sign thành công: $SOURCE_FOLDER_PATH"

# Extract version from Info.plist using plutil
PLIST_PATH="${SOURCE_FOLDER_PATH}/Contents/Info.plist"
if [ -f "$PLIST_PATH" ]; then
    APP_VERSION=$(plutil -extract CFBundleShortVersionString raw "$PLIST_PATH" 2>/dev/null)
fi

if [ -z "${APP_VERSION:-}" ]; then
    echo "⚠️  Could not read app version, falling back to 'unknown'"
    APP_VERSION="unknown"
fi

# Construct DMG filename with version
DMG_FILE_NAME="${BUILD_DIR}/${APP_NAME}-Installer-${APP_VERSION}.dmg"

# Remove previous DMG if exists
if [[ -f "${DMG_FILE_NAME}" ]]; then
    rm "${DMG_FILE_NAME}"
fi

# Trên GitHub Actions (biến $CI được runner tự set = true), Finder không có phiên
# GUI tương tác ổn định để create-dmg set icon position/background qua AppleScript.
# --skip-jenkins bỏ qua bước customize UI này, chỉ tạo dmg đơn giản nhưng ổn định.
# Local dev (không có $CI) vẫn giữ nguyên dmg đẹp với background + icon layout.
CREATE_DMG_EXTRA_ARGS=()
if [ "${CI:-false}" = "true" ]; then
    echo "🤖 Phát hiện môi trường CI — dùng --skip-jenkins để tránh lỗi AppleScript/Finder"
    CREATE_DMG_EXTRA_ARGS+=(--skip-jenkins)
fi

# Create the DMG
create-dmg \
  --volname "${VOLUME_NAME}" \
  --background "${BACKGROUND_IMAGE_PATH}" \
  --window-pos 200 120 \
  --window-size 540 380 \
  --icon-size 100 \
  --icon "${APP_NAME}.app" 138 170 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 398 170 \
  "${CREATE_DMG_EXTRA_ARGS[@]}" \
  "${DMG_FILE_NAME}" \
  "${SOURCE_FOLDER_PATH}"

echo "📦 DMG output: ${DMG_FILE_NAME}"