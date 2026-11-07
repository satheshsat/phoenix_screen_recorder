#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_ID="phoenix.screen.recorder"
APP_NAME="Phoenix Screen Recorder"
USER_ICONS_DIR="${HOME}/.local/share/icons/hicolor"
USER_APPS_DIR="${HOME}/.local/share/applications"

# Locate the executable
if [ -x "${SCRIPT_DIR}/phoenix_screen_recorder" ]; then
  # Running from inside extracted zip / bundle
  EXEC_PATH="${SCRIPT_DIR}/phoenix_screen_recorder"
elif [ -x "${SCRIPT_DIR}/../build/linux/x64/release/bundle/phoenix_screen_recorder" ]; then
  # Running from repo after release build
  EXEC_PATH="$(cd "${SCRIPT_DIR}/../build/linux/x64/release/bundle" && pwd)/phoenix_screen_recorder"
elif [ -x "${SCRIPT_DIR}/../build/linux/x64/debug/bundle/phoenix_screen_recorder" ]; then
  # Running from repo after debug build
  EXEC_PATH="$(cd "${SCRIPT_DIR}/../build/linux/x64/debug/bundle" && pwd)/phoenix_screen_recorder"
elif [ -n "$1" ] && [ -x "$1" ]; then
  EXEC_PATH="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
else
  EXEC_PATH="${SCRIPT_DIR}/phoenix_screen_recorder"
fi

# Locate the icons directory
if [ -d "${SCRIPT_DIR}/data/icons" ]; then
  ICONS_DIR="${SCRIPT_DIR}/data/icons"
elif [ -d "${SCRIPT_DIR}/icons" ]; then
  ICONS_DIR="${SCRIPT_DIR}/icons"
elif [ -d "${SCRIPT_DIR}/../linux/icons" ]; then
  ICONS_DIR="${SCRIPT_DIR}/../linux/icons"
else
  ICONS_DIR=""
fi

echo "=========================================================="
echo " Installing ${APP_NAME}"
echo "=========================================================="
echo "  App ID:      ${APP_ID}"
echo "  Executable:  ${EXEC_PATH}"
echo "  Icons Dir:   ${ICONS_DIR}"
echo ""

# Install icons into ~/.local/share/icons/hicolor/
if [ -n "$ICONS_DIR" ] && [ -d "$ICONS_DIR" ]; then
  SIZES=(16 24 32 48 64 128 256 512)
  for size in "${SIZES[@]}"; do
    src_icon="${ICONS_DIR}/icon_${size}x${size}.png"
    dest_dir="${USER_ICONS_DIR}/${size}x${size}/apps"
    if [ -f "$src_icon" ]; then
      mkdir -p "$dest_dir"
      cp -f "$src_icon" "${dest_dir}/${APP_ID}.png"
      echo "  [OK] Installed ${size}x${size} icon"
    fi
  done

  # Fallback main icon
  if [ -f "${ICONS_DIR}/icon.png" ]; then
    mkdir -p "${USER_ICONS_DIR}/512x512/apps"
    cp -f "${ICONS_DIR}/icon.png" "${USER_ICONS_DIR}/512x512/apps/${APP_ID}.png"
  fi
fi

# Fallback from flutter_assets if icons dir wasn't found
if [ ! -f "${USER_ICONS_DIR}/512x512/apps/${APP_ID}.png" ]; then
  ASSET_ICON="${SCRIPT_DIR}/data/flutter_assets/assets/icon/icon.png"
  if [ -f "$ASSET_ICON" ]; then
    mkdir -p "${USER_ICONS_DIR}/512x512/apps"
    cp -f "$ASSET_ICON" "${USER_ICONS_DIR}/512x512/apps/${APP_ID}.png"
    echo "  [OK] Installed icon from bundle flutter_assets"
  fi
fi

# Install desktop entry
mkdir -p "$USER_APPS_DIR"
cat > "${USER_APPS_DIR}/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${APP_NAME}
GenericName=Screen Recorder
Comment=Record your screen and audio effortlessly
Exec="${EXEC_PATH}" %U
Icon=${APP_ID}
Terminal=false
StartupNotify=true
StartupWMClass=${APP_ID}
Categories=AudioVideo;Recorder;Utility;
Keywords=screen;recorder;capture;video;audio;phoenix;
EOF

chmod +x "${USER_APPS_DIR}/${APP_ID}.desktop"
echo "  [OK] Created launcher at ${USER_APPS_DIR}/${APP_ID}.desktop"

# Update desktop and icon caches
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "${USER_ICONS_DIR}" >/dev/null 2>&1 || true
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${USER_APPS_DIR}" >/dev/null 2>&1 || true
fi

echo ""
echo " Installation complete! The app is now available in your"
echo " application menu and the taskbar/dock icon is registered."
echo "=========================================================="

