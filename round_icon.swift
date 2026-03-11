import Cocoa

let args = CommandLine.arguments
if args.count < 3 {
    print("Usage: round_icon <input> <output>")
    exit(1)
}

let inputPath = args[1]
let outputPath = args[2]

guard let image = NSImage(contentsOfFile: inputPath) else {
    print("Could not read image")
    exit(1)
}

let width = image.size.width
let height = image.size.height

// Create a new image with true transparency
let newImage = NSImage(size: NSSize(width: width, height: height))
newImage.lockFocus()

// NSBezierPath for macOS App Icon squircle approximation (continuous corners)
let rect = NSRect(x: 0, y: 0, width: width, height: height)
let radius = width * 0.225 // Standard Apple icon corner radius ratio
let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

// Clip the drawing context to the rounded rectangle
path.addClip()

// Draw the original squarish image into the clipped context
image.draw(in: rect, from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)

newImage.unlockFocus()

// Export as PNG with alpha channel
if let tiffRepresentation = newImage.tiffRepresentation,
   let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Successfully created rounded transparent icon at \(outputPath)")
    } catch {
        print("Failed to write PNG data: \(error)")
        exit(1)
    }
} else {
    print("Failed to generate PNG representation")
    exit(1)
}
