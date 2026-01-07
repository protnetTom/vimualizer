# Vimualizer (Swift Port)

This is a standalone native macOS application port of Vimualizer. It does **not** require Hammerspoon.

## Requirements
- macOS 14.0+
- Xcode 15+ (for building)

## logic
- **Input Monitoring**: Uses `CGEvent.tapCreate` to intercept global keystrokes. You must grant the app "Accessibility" or "Input Monitoring" permissions in System Settings -> Privacy & Security.
- **SwiftUI**: Uses modern SwiftUI for the floating HUD and Settings window.

## Building & Running

1.  **Build from Terminal**:
    ```bash
    cd VimualizerSwift
    swift build
    ```

2.  **Run**:
    ```bash
    .build/debug/Vimualizer
    ```

3.  **Permissions**:
    The first time you run it, it will print "Access Not Enabled" into the console if permissions are missing. Go to System Settings -> Privacy & Security -> Accessibility and add `Vimualizer` (or your Terminal if running from CLI).

## Project Structure
- `Sources/Vimualizer/VimualizerApp.swift`: Main Entry Point.
- `Sources/Vimualizer/VimLogic.swift`: Core Logic & Key Listener.
- `Sources/Vimualizer/HudView.swift`: Floating HUD UI.
- `Sources/Vimualizer/SettingsView.swift`: Preferences UI.
