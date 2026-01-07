# Vimualizer

Vimualizer is a real-time Head-Up Display (HUD) and productivity toolkit for Vim users on macOS. Built on the [Hammerspoon](https://www.hammerspoon.org/) automation engine, it visualizes your Vim keystrokes and motions as you type, providing instant feedback and helping you master your workflow.

> **Note:** This project was developed entirely by AI. It represents a collaboration between human conceptual direction and AI-driven implementation, showcasing the capabilities of modern agentic coding.

## Key Features

- **Real-time HUD & Key Buffer**: Instantly see your Vim keystrokes translated into human-readable actions. The interface dynamically updates to reflect your current mode (**Normal**, **Insert**, **Visual**, or **Pending**).
- **Vim Sensei (Trainer)**: A built-in practice mode designed to sharpen your muscle memory. It includes progressive difficulty levels ranging from basic motions to advanced text object manipulations.
- **Intelligent Text Expansion**: A Vim-friendly snippet engine that supports custom triggers and dynamic placeholders (e.g., `{{date}}`, `{{time}}`).
- **Usage Analytics**: Track your command frequency and visualize the efficiency of your Vim usage through "keystrokes saved" statistics.
- **Ghost Mode**: Features reactive opacity that automatically fades the UI during periods of inactivity, keeping your workspace clear of distractions.
- **Fully Customizable UI**:
  - **Drag-and-Drop**: Reposition the HUD and Key Buffer anywhere on your screen.
  - **Typography**: Choose your preferred UI and Code fonts directly from the settings.
  - **Scaling**: Adjust font sizes and alignment to match your screen resolution.
- **Smart Exclusions**: Easily disable Vimualizer for specific applications (like Terminal or Neovim) where a HUD might be redundant.

## Prerequisites

### 1. Install Hammerspoon
Vimualizer runs as a module for [Hammerspoon](https://www.hammerspoon.org/).

```bash
brew install --cask hammerspoon
```

### 2. Grant Accessibility Permissions
Hammerspoon requires Accessibility access to listen for keystroke events:
1. Open **System Settings** > **Privacy & Security** > **Accessibility**.
2. Toggle **Hammerspoon** to **ON**.

## Installation

### Automated Setup (Recommended)
Clone the repository and run the installation script:

```bash
chmod +x install.sh
./install.sh
```
*This script backs up your current `~/.hammerspoon/init.lua` to `init.lua.bak` and installs the Vimualizer modules.*

### Manual Setup
1. Copy the `modules` directory and `init.lua` to your `~/.hammerspoon/` folder.
2. If you have an existing configuration, you can rename the Vimualizer `init.lua` to `vimualizer.lua` and add `require("vimualizer")` to your main script.
3. Reload your Hammerspoon configuration.

## Usage

- **Open Settings**: Press `Cmd + Opt + P` to toggle the configuration panel.
- **HUD Placement**: Enter settings mode (`Cmd + Opt + P`) and drag the "DRAG ME" handles to reposition any UI element.
- **Toggle Features**: Use the settings panel to enable/disable specific modules like Ghost Mode, Snippets, or Analytics.
- **Vim Training**: Start a "Vim Sensei" session from the settings panel to practice your motions.

## Acknowledgments
This project was conceptualized by its human creator and implemented from scratch by Advanced Agentic AI.

---
*Happy Vimming!*