import SwiftUI
import Carbon

class VimLogic: ObservableObject {
    static let shared = VimLogic()

    // published properties update the UI automatically
    @Published var keyHistory: [String] = []
    @Published var currentState: String = "NORMAL"
    @Published var currentActionDescription: String = ""
    
    // Config (would load from defaults)
    @Published var isMasterEnabled: Bool = true
    @Published var isHudEnabled: Bool = true
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    init() {
        setupEventTap()
    }
    
    func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        // C-style callback bridge
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let mySelf = Unmanaged<VimLogic>.fromOpaque(refcon).takeUnretainedValue()
            
            if type == .keyDown {
                // Handle Key Down
                if let event = mySelf.handleKeyDown(event: event) {
                    return Unmanaged.passUnretained(event)
                } else {
                    // Start of a potential Vim sequence, suppress if necessary or just log?
                    // For visualization only, we usually pass the event through (return event)
                    // unless we are implementing a blocker.
                    return Unmanaged.passUnretained(event)
                }
            }
            return Unmanaged.passUnretained(event)
        }
        
        // Create the Tap
        // We pass 'self' as a pointer to the callback so we can access instance methods
        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: refcon
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = tap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    func handleKeyDown(event: CGEvent) -> CGEvent? {
        // 1. Check for Global Hotkey (Alt+Cmd+P) to open settings
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Cmd + Option (Alt)
        let isGlobalSettings = flags.contains(.maskCommand) && flags.contains(.maskAlternate)
        
        if isGlobalSettings && keyCode == 35 { // 35 is 'p'
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                // Open Settings Window
                if #available(macOS 13.0, *) {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } else {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
            }
            return nil // Consume this event
        }

        if !isMasterEnabled { return event }
        
        // 2. Process Key for Vim Logic
        let keyChar = keyCodeToString(keyCode)
        
        DispatchQueue.main.async {
            self.updateHistory(key: keyChar)
        }
        
        return event
    }
    
    func updateHistory(key: String) {
        keyHistory.append(key)
        if keyHistory.count > 10 {
            keyHistory.removeFirst()
        }
    }
    
    // Simplified mapping
    func keyCodeToString(_ code: Int64) -> String {
        switch code {
        case 53: return "Esc"
        case 0: return "a"
        case 1: return "s"
        case 2: return "d"
        case 3: return "f"
        case 4: return "h"
        case 5: return "g"
        case 6: return "z"
        case 7: return "x"
        case 8: return "c"
        case 9: return "v"
        case 11: return "b"
        case 12: return "q"
        case 13: return "w"
        case 14: return "e"
        case 15: return "r"
        case 16: return "y"
        case 17: return "t"
        case 31: return "o"
        case 32: return "u"
        case 34: return "i"
        case 35: return "p"
        case 37: return "l"
        case 38: return "j"
        case 40: return "k"
        case 45: return "n"
        case 46: return "m"
        default: return "?"
        }
    }
}
