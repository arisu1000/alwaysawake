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
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"
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
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

if [ -f "$ICON_SOURCE" ]; then
    echo "Converting App Icon to standard .icns format..."
    cat <<'EOF_SWIFT' > "$TMPDIR/make_icns.swift"
import Cocoa
import CoreGraphics
import UniformTypeIdentifiers

let args = CommandLine.arguments
if args.count < 3 { exit(1) }

guard let sourceImage = NSImage(contentsOfFile: args[1]) else { exit(1) }
guard let tiffData = sourceImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let cgImage = bitmap.cgImage else { exit(1) }

let url = URL(fileURLWithPath: args[2])
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "com.apple.icns" as CFString, 1, nil) else { exit(1) }

CGImageDestinationAddImage(dest, cgImage, nil)
CGImageDestinationFinalize(dest)
EOF_SWIFT

    swiftc -module-cache-path "$TMPDIR/module-cache" -O "$TMPDIR/make_icns.swift" -o "$TMPDIR/make_icns"
    "$TMPDIR/make_icns" "$ICON_SOURCE" "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "Signing the application bundle..."
codesign --force --deep --sign - "${TARGET_DIR}"

echo "Build complete! App is located at: $(pwd)/${TARGET_DIR}"

