#!/bin/bash
# Builds build/FloatCam.app from source.
#
#   ./build.sh               build for this Mac's architecture
#   ./build.sh --universal   build for both Apple Silicon and Intel (used for releases)
set -euo pipefail
cd "$(dirname "$0")"

APP="build/FloatCam.app"
MIN_MACOS="14.0"

if [ "${1:-}" = "--universal" ]; then
  ARCHS=(arm64 x86_64)
else
  ARCHS=("$(uname -m)")
fi

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/obj

BINARIES=()
for ARCH in "${ARCHS[@]}"; do
  echo "Compiling for $ARCH (takes 20 to 40 seconds)..."
  xcrun swiftc -O -swift-version 5 \
    -target "${ARCH}-apple-macos${MIN_MACOS}" \
    -framework AppKit -framework AVFoundation \
    Sources/*.swift \
    -o "build/obj/FloatCam-$ARCH"
  BINARIES+=("build/obj/FloatCam-$ARCH")
done

if [ "${#BINARIES[@]}" -gt 1 ]; then
  lipo -create "${BINARIES[@]}" -output "$APP/Contents/MacOS/FloatCam"
else
  cp "${BINARIES[0]}" "$APP/Contents/MacOS/FloatCam"
fi
rm -rf build/obj

cp Info.plist "$APP/Contents/Info.plist"

echo "Signing (ad-hoc)..."
codesign --force --sign - "$APP" >/dev/null 2>&1

echo "Built $APP (${ARCHS[*]})"
