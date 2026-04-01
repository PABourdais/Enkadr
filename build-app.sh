#!/bin/bash
set -e

APP_NAME="Enkadr"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"

# Build release
swift build -c release

# Create .app bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Build icon with iconutil
ICONSET="/tmp/$APP_NAME.iconset"
SRC="$APP_NAME/Assets.xcassets/AppIcon.appiconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
cp "$SRC/icon_16x16.png"      "$ICONSET/icon_16x16.png"
cp "$SRC/icon_32x32.png"      "$ICONSET/icon_16x16@2x.png"
cp "$SRC/icon_32x32.png"      "$ICONSET/icon_32x32.png"
cp "$SRC/icon_64x64.png"      "$ICONSET/icon_32x32@2x.png"
cp "$SRC/icon_128x128.png"    "$ICONSET/icon_128x128.png"
cp "$SRC/icon_256x256.png"    "$ICONSET/icon_128x128@2x.png"
cp "$SRC/icon_256x256.png"    "$ICONSET/icon_256x256.png"
cp "$SRC/icon_512x512.png"    "$ICONSET/icon_256x256@2x.png"
cp "$SRC/icon_512x512.png"    "$ICONSET/icon_512x512.png"
cp "$SRC/icon_1024x1024.png"  "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Enkadr</string>
    <key>CFBundleDisplayName</key>
    <string>Enkadr</string>
    <key>CFBundleIdentifier</key>
    <string>com.enkadr.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Enkadr</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "Built $APP_BUNDLE successfully."
echo ""
echo "To install: cp -r $APP_BUNDLE /Applications/"
echo "Or double-click $APP_BUNDLE to launch."
