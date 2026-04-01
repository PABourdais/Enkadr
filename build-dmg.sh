#!/bin/bash
set -e

APP_NAME="Enkadr"
DMG_NAME="$APP_NAME.dmg"
DMG_TEMP="$APP_NAME-temp.dmg"
VOLUME_NAME="$APP_NAME"
APP_BUNDLE="$APP_NAME.app"
DMG_DIR=".dmg-staging"
WINDOW_W=600
WINDOW_H=400

# Build the app first
echo "Building $APP_NAME..."
bash build-app.sh

# Clean up previous artifacts
rm -rf "$DMG_DIR" "$DMG_NAME" "$DMG_TEMP"

# Create staging directory
mkdir -p "$DMG_DIR"
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Create writable DMG (larger to fit content)
echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    -size 10m \
    "$DMG_TEMP"

# Mount and customize
hdiutil attach -readwrite -noverify "$DMG_TEMP"
MOUNT_DIR="/Volumes/$VOLUME_NAME"
sleep 1

# Configure Finder window with AppleScript
echo "Configuring window layout..."
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, $((100 + WINDOW_W)), $((100 + WINDOW_H))}

        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 80
        -- Position app icon on left, Applications on right
        set position of item "$APP_BUNDLE" of container window to {150, 190}
        set position of item "Applications" of container window to {450, 190}

        -- Set label color to white
        set label index of item "$APP_BUNDLE" of container window to 0
        set label index of item "Applications" of container window to 0

        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

SetFile -a V "$MOUNT_DIR/.fseventsd" 2>/dev/null || true

# Unmount
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed read-only DMG
echo "Compressing..."
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_NAME"

# Clean up
rm -rf "$DMG_DIR" "$DMG_TEMP"

echo ""
echo "Created $DMG_NAME successfully."
