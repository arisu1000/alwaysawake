# AlwaysAwake ☕️

**AlwaysAwake** is a sleek, lightweight macOS menu bar utility and command-line application that prevents your Mac from going to sleep or displaying the screensaver. 

![App Icon](AppIcon.icns)

## Features

- **Menu Bar Interactivity**: Start sleep prevention straight from your menu bar with preset durations.
- **Dynamic Icon Status**: The beautiful cup icon solidifies when the app is actively keeping your screen awake.
- **Inline Menu Bar Timer**: See exactly how much time is remaining directly next to the menu bar icon, so you don't even need to click to check the status.
- **Indefinite Mode**: Keep your computer awake continuously until you decide otherwise (indicated by a small `∞` next to the icon).
- **CLI Support**: Control the sleep assertion cleanly from the terminal for automation and scripting purposes.

## Installation and Usage

To use AlwaysAwake, locate the generated `AlwaysAwake.app` from the project directory and open it.

For easy access, you can drag and drop it into your `/Applications` directory.

### GUI (Menu Bar) Usage
1. Double-click `AlwaysAwake.app`.
2. A coffee cup icon `☕️` will appear in your top-right menu bar.
3. Click the icon to select your preferred duration to keep your Mac awake, or select "Keep Awake Indefinitely". 
4. The icon will fill in (`☕️` -> `☕️(Filled)`) to indicate the timer is active.

### CLI (Terminal) Usage
To run the application purely through the terminal without launching the Menu Bar GUI, you can invoke the executable directly:

```bash
# Display help and exact command usage
./AlwaysAwake.app/Contents/MacOS/AlwaysAwake --help

# Keep awake for a specific time in seconds (e.g., 1 hour = 3600 seconds)
./AlwaysAwake.app/Contents/MacOS/AlwaysAwake --duration 3600

# Keep awake indefinitely (Press Ctrl+C to terminate and allow sleep)
./AlwaysAwake.app/Contents/MacOS/AlwaysAwake --indefinite
```

## Compilation and Building

If you need to re-compile the source code:

1. Ensure you have the swift compiler installed (usually via Xcode command line tools).
2. Run the provided build script:
```bash
bash build.sh /path/to/your/icon.png
```
This script bypasses strict macOS sandbox issues, compiles the Swift source (`AlwaysAwake.swift`), generates the application folder structure, configures the `Info.plist` (hiding the app from the Dock with `LSUIElement`), and drops in the App Icon.

## Requirements
- macOS environment
- Swift compiler (for building)

## License
MIT License
