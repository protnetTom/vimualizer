import SwiftUI

@main
struct VimualizerApp: App {
    // Shared Logic Singleton
    @StateObject private var logic = VimLogic.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Native Preferences Window (Cmd+,)
        Settings {
            SettingsView()
                .environmentObject(logic)
                .frame(width: 450, height: 600) // Fixed size for prefs
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var hudWindow: NSPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Regular App Mode (Shows in Dock)
        NSApp.setActivationPolicy(.regular)
        
        // request permissions...
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        AXIsProcessTrustedWithOptions(options)
        
        // Create Floating Panel
        let hudView = HudView().environmentObject(VimLogic.shared)
        
        hudWindow = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 600, height: 200),
            styleMask: [.borderless, .nonactivatingPanel], // Borderless + Non-activating
            backing: .buffered,
            defer: false
        )
        
        hudWindow.level = .floating // ALWAYS ON TOP
        hudWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hudWindow.backgroundColor = .clear
        hudWindow.isOpaque = false
        hudWindow.hasShadow = false // View has its own shadow
        hudWindow.contentView = NSHostingView(rootView: hudView)
        hudWindow.center()
        hudWindow.makeKeyAndOrderFront(nil)
        
        print("Vimualizer Started with Floating HUD")
    }
}
