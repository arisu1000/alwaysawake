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
    ICONSET_DIR="$TMPDIR/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"

    cat <<'EOF_SWIFT' > "$TMPDIR/make_iconset.swift"
import Cocoa

let args = CommandLine.arguments
if args.count < 3 {
    print("Usage: make_iconset <input_png> <output_iconset_dir>")
    exit(1)
}

guard let image = NSImage(contentsOfFile: args[1]) else {
    print("Cannot read image"); exit(1)
}

let outputDir = args[2]
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let newSize = NSSize(width: CGFloat(size), height: CGFloat(size))
    let newImage = NSImage(size: newSize)
    newImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(origin: .zero, size: newSize),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy, fraction: 1.0)
    newImage.unlockFocus()

    if let tiffRep = newImage.tiffRepresentation,
       let bitmapRep = NSBitmapImageRep(data: tiffRep),
       let pngData = bitmapRep.representation(using: .png, properties: [:]) {
        let outPath = (outputDir as NSString).appendingPathComponent(name)
        try? pngData.write(to: URL(fileURLWithPath: outPath))
    }
}
print("Iconset created successfully")
EOF_SWIFT

    swiftc -module-cache-path "$TMPDIR/module-cache" -O "$TMPDIR/make_iconset.swift" -o "$TMPDIR/make_iconset"
    "$TMPDIR/make_iconset" "$ICON_SOURCE" "$ICONSET_DIR"
    iconutil -c icns "$ICONSET_DIR" -o "${RESOURCES_DIR}/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
fi

echo "Signing the application bundle..."
codesign --force --deep --sign - "${TARGET_DIR}"

echo "Build complete! App is located at: $(pwd)/${TARGET_DIR}"

