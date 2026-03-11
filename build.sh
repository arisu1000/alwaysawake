#!/bin/bash

# Exit on error
set -e

APP_NAME="AlwaysAwake"
TARGET_DIR="${APP_NAME}.app"
CONTENTS_DIR="${TARGET_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ICON_SOURCE="$1"

echo "Creating App Bundle Directory Structure..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

export TMPDIR="$(pwd)/tmp"
mkdir -p "$TMPDIR"
export XCODE_CACHE_DIR="$TMPDIR"
export CPATH="$TMPDIR"

echo "Compiling Swift Source..."
swiftc -module-cache-path "$TMPDIR/module-cache" \
       -O AlwaysAwake.swift \
       -o "${MACOS_DIR}/${APP_NAME}"


echo "Generating Info.plist..."
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.alwaysawake.app</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/> <!-- Hides app from Dock -->
</dict>
</plist>
EOF

if [ -f "$ICON_SOURCE" ]; then
    echo "Converting App Icon..."
    echo "Setting App Icon using NSWorkspace..."
    cat <<'EOF_SWIFT' > "$TMPDIR/set_icon.swift"
import Cocoa
let args = CommandLine.arguments
if args.count < 3 { exit(1) }
if let image = NSImage(contentsOfFile: args[1]) {
    _ = NSWorkspace.shared.setIcon(image, forFile: args[2], options: [])
}
EOF_SWIFT

    swiftc -module-cache-path "$TMPDIR/module-cache" -O "$TMPDIR/set_icon.swift" -o "$TMPDIR/set_icon"
    "$TMPDIR/set_icon" "$ICON_SOURCE" "${TARGET_DIR}"
    touch "${TARGET_DIR}"
fi

echo "Build complete! App is located at: $(pwd)/${TARGET_DIR}"
