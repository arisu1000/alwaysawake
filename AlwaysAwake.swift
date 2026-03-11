import Cocoa
import IOKit.pwr_mgt

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var assertionID: IOPMAssertionID = 0
    var isActive: Bool = false
    var timeRemaining: TimeInterval = 0
    var countdownTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // macOS 11+ supports SF Symbols, which is perfect for menu bars.
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
            button.image = NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: "Disabled")?.withSymbolConfiguration(config)
            button.image?.isTemplate = true
        }
        
        constructMenu()
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        let statusMenuItem = NSMenuItem(title: "Status: Inactive", action: nil, keyEquivalent: "")
        statusMenuItem.tag = 100
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separator())
        
        let keepAwakeItem = NSMenuItem(title: "Keep Awake Indefinitely", action: #selector(toggleAwakeForever), keyEquivalent: "i")
        menu.addItem(keepAwakeItem)
        
        let durations = [
            ("5 Minutes", 5 * 60.0),
            ("15 Minutes", 15 * 60.0),
            ("30 Minutes", 30 * 60.0),
            ("1 Hour", 60 * 60.0),
            ("2 Hours", 120 * 60.0)
        ]
        
        for (label, duration) in durations {
            let item = NSMenuItem(title: "For \(label)", action: #selector(startTimerDuration(_:)), keyEquivalent: "")
            item.representedObject = duration
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func toggleAwakeForever(_ sender: NSMenuItem) {
        if isActive && timer == nil {
            stopAwake()
        } else {
            startAwake(duration: nil)
        }
    }
    
    @objc func startTimerDuration(_ sender: NSMenuItem) {
        if let duration = sender.representedObject as? TimeInterval {
            startAwake(duration: duration)
        }
    }
    
    func startAwake(duration: TimeInterval?) {
        stopAwake() // clears any existing assertion and timer
        
        let reasonForActivity = "AlwaysAwake App requested to keep screen awake" as CFString
        let success = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reasonForActivity, &assertionID)
        
        if success == kIOReturnSuccess {
            isActive = true
            if let button = statusItem.button {
                let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .bold)
                button.image = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Active")?.withSymbolConfiguration(config)
                button.image?.isTemplate = true
            }
            
            let statusMenuItem = statusItem.menu?.item(withTag: 100)
            
            if let dur = duration {
                timeRemaining = dur
                statusMenuItem?.title = "Status: \(formatTime(timeRemaining)) remaining"
                statusItem.button?.title = " " + formatTime(timeRemaining)
                
                timer = Timer.scheduledTimer(timeInterval: dur, target: self, selector: #selector(autoStop), userInfo: nil, repeats: false)
                
                countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
                RunLoop.main.add(countdownTimer!, forMode: .common)
            } else {
                statusMenuItem?.title = "Status: Active (Indefinite)"
                statusItem.button?.title = " ∞"
            }
        } else {
            print("Failed to create assertion")
        }
    }
    
    @objc func updateCountdown() {
        timeRemaining -= 1.0
        if timeRemaining >= 0 {
            if let statusMenuItem = statusItem.menu?.item(withTag: 100) {
                statusMenuItem.title = "Status: \(formatTime(timeRemaining)) remaining"
            }
            statusItem.button?.title = " " + formatTime(timeRemaining)
        }
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = (totalSeconds % 3600) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    @objc func autoStop() {
        stopAwake()
        let alert = NSAlert()
        alert.messageText = "Always Awake Timer Finished"
        alert.informativeText = "Your Mac is now allowed to sleep."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func stopAwake() {
        if isActive {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
            isActive = false
        }
        
        timer?.invalidate()
        timer = nil
        
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
            button.image = NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: "Disabled")?.withSymbolConfiguration(config)
            button.image?.isTemplate = true
            button.title = ""
        }
        statusItem.menu?.item(withTag: 100)?.title = "Status: Inactive"
    }
}

let args = CommandLine.arguments

// Check if running in CLI mode
if args.count > 1 {
    let flag = args[1]
    if flag == "--duration" || flag == "-d" {
        if args.count > 2, let duration = Double(args[2]) {
            print("Keeping Mac awake for \(duration) seconds... (Press Ctrl+C to stop)")
            var assertionID: IOPMAssertionID = 0
            let reasonForActivity = "AlwaysAwake CLI requested to keep screen awake" as CFString
            let success = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reasonForActivity, &assertionID)
            
            if success == kIOReturnSuccess {
                // Ensure sleep stops cleanly on Ctrl-C
                let signalHandler: @convention(c) (Int32) -> Void = { _ in
                    print("\nCaught interrupt signal. Releasing assertion & exiting.")
                    exit(0)
                }
                signal(SIGINT, signalHandler)
                
                Thread.sleep(forTimeInterval: duration)
                IOPMAssertionRelease(assertionID)
                print("Duration ended. Mac can now sleep.")
            } else {
                print("Failed to keep Mac awake.")
            }
        } else {
            print("Please specify a duration in seconds, e.g., 'AlwaysAwake --duration 3600'")
        }
    } else if flag == "--indefinite" || flag == "-i" {
        print("Keeping Mac awake indefinitely... (Press Ctrl+C to stop)")
        var assertionID: IOPMAssertionID = 0
        let reasonForActivity = "AlwaysAwake CLI requested to keep screen awake" as CFString
        let success = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reasonForActivity, &assertionID)
        
        if success == kIOReturnSuccess {
            let signalHandler: @convention(c) (Int32) -> Void = { _ in
                print("\nCaught interrupt signal. Releasing assertion & exiting.")
                exit(0)
            }
            signal(SIGINT, signalHandler)
            
            // Loop indefinitely
            RunLoop.main.run()
        } else {
            print("Failed to keep Mac awake.")
        }
    } else if flag == "--help" || flag == "-h" {
        print("Usage: AlwaysAwake [options]")
        print("Options:")
        print("  -d, --duration <seconds>   Keep Mac awake for a specific duration in seconds.")
        print("  -i, --indefinite           Keep Mac awake indefinitely, until Ctrl+C.")
        print("  -h, --help                 Show this help message.")
        print("\nRun without arguments to launch the Menu Bar app GUI.")
    } else {
        print("Unknown argument. Use --help for usage.")
    }
    exit(0)
}

// GUI Mode
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Hides from Dock
app.run()
