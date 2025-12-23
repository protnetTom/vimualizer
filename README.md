# Vimualizer

**Vimualizer** is a heads-up display (HUD) for macOS that visualizes Vim motions and commands in real-time. It acts as a visual buffer, showing keystrokes and translating obscure Vim chords into human-readable descriptions on your screen.

## Prerequisites

Vimualizer runs on the **Hammerspoon** automation engine for macOS.

### 1. Install Hammerspoon

You can install Hammerspoon via Homebrew or by downloading it manually:

* **Homebrew:**
    ```bash
    brew install --cask hammerspoon
    ```
* **Manual Download:**
  Download the latest release from [Hammerspoon.org](https://www.hammerspoon.org/).

### 2. Grant Permissions

For Vimualizer to intercept keystrokes and display the HUD, Hammerspoon requires **Accessibility** permissions.

1. Open **Hammerspoon**.
2. Navigate to **System Settings** > **Privacy & Security** > **Accessibility**.
3. Ensure the toggle next to **Hammerspoon** is turned **ON**.

## Installation

### 1. Locate Config Folder

Open your terminal or Finder and navigate to the Hammerspoon configuration directory:
`~/.hammerspoon`

*(Note: If the folder doesn't exist, launch Hammerspoon once to generate it).*

### 2. Install Script

1. Create a file named `init.lua` inside `~/.hammerspoon/`.
2. Paste the entire **Vimualizer** Lua script into this file.

> **Tip:** If you already use Hammerspoon for other scripts, save the Vimualizer code into a separate file (e.g., `vimualizer.lua`) and add the line `require("vimualizer")` to your main `init.lua`.

### 3. Reload Configuration

1. Click the **Hammerspoon icon** in your macOS menu bar.
2. Select **Reload Config**.
3. You should see an alert on your screen: *"Vimualizer Loaded"*.

## Usage

| Action | Shortcut / Trigger |
| :--- | :--- |
| **Open Settings** | `Cmd` + `Option` + `P` |
| **Move HUD** | Click and drag the "DRAG ME" handle on the text buffer. |
| **Move Popup** | Click and drag the "DRAG ME" handle on the suggestion popup. |

### Settings Panel

* **Save:** Manually saves your font size and position preferences to `~/Documents/Vimualizer/settings.json`.
* **Exclusions:** Manage a list of apps (like Terminal, iTerm, or VS Code) where you want Vimualizer to automatically disable itself.
* **Text Size:** Use the `+` and `-` buttons to adjust the HUD readability.

## Troubleshooting

* **HUD not appearing?**
  Ensure Hammerspoon has Accessibility permissions. If it is already checked, try unchecking it and re-checking it in System Settings to reset the permission.

* **Keys blocked/stuck?**
  If your `Escape` key stops working, ensure you are using the latest version of the script which includes the `return false` fix in the event tap logic.

* **Settings not saving?**
  Check that the folder `~/Documents/Vimualizer` exists. The script attempts to create it, but file system permissions may vary.