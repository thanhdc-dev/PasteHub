#!/usr/bin/env bash

APP_NAME="PasteHub"
VOLUME_NAME="${APP_NAME} Installer"
CONFIGURATION="Release"
BUILD_DIR="../build"
DMG_FILE_NAME="${BUILD_DIR}/${APP_NAME}-Installer.dmg"
SOURCE_FOLDER_PATH="${BUILD_DIR}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
BACKGROUND_IMAGE_PATH="dmg_background.png"

# Since create-dmg does not clobber, be sure to delete previous DMG
[[ -f "${DMG_FILE_NAME}" ]] && rm "${DMG_FILE_NAME}"

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
  "${DMG_FILE_NAME}" \
  "${SOURCE_FOLDER_PATH}"
