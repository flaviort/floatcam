#!/bin/bash
# FloatCam installer: double-click to build and install into /Applications
set -e
cd "$(dirname "$0")"
clear
echo "Installing FloatCam..."
echo

if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "Apple's Command Line Tools are not installed."
  echo "A window will open asking to install them. Click 'Install',"
  echo "wait for it to finish, then run this installer again."
  xcode-select --install 2>/dev/null || true
  echo
  read -n 1 -s -r -p "Press any key to close..."
  exit 1
fi

bash ./build.sh

pkill -x FloatCam 2>/dev/null || true
DEST="/Applications"
[ -w "$DEST" ] || { DEST="$HOME/Applications"; mkdir -p "$DEST"; }
rm -rf "$DEST/FloatCam.app"
cp -R build/FloatCam.app "$DEST/"

echo
echo "FloatCam installed to $DEST/FloatCam.app"
echo "Look for the webcam icon in the menu bar (top right)."
echo "Next time, open it with Spotlight: Cmd + Space, then type FloatCam"
echo
open "$DEST/FloatCam.app"
sleep 2
osascript -e 'tell application "Terminal" to close front window' >/dev/null 2>&1 &
exit 0
