#!/bin/bash
# Assembles dist/Kofein.app from the SwiftPM release build.
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release --arch arm64

BUILD_DIR="$(swift build -c release --arch arm64 --show-bin-path)"
APP="dist/Kofein.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BUILD_DIR/Kofein" "$APP/Contents/MacOS/Kofein"
cp -R "$BUILD_DIR/Kofein_KofeinCore.bundle" "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>Kofein</string>
	<key>CFBundleIdentifier</key>
	<string>com.markosamastur.Kofein</string>
	<key>CFBundleName</key>
	<string>Kofein</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>26.0</string>
	<key>LSUIElement</key>
	<true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"

echo "Built $APP"
