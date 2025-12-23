#!/bin/bash

# ==============================================================================
# VIMUALIZER SETUP UTILITY
# ==============================================================================
# DISCLAIMER:
# This script is provided "as is", without warranty of any kind.
# It modifies system configurations by installing Homebrew and Hammerspoon.
# It will overwrite your current ~/.hammerspoon/init.lua.
#
# RUN AT YOUR OWN RISK.
# ==============================================================================

# ANSI Colors for nicer output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}WARNING: This script will install software and overwrite your Hammerspoon config.${NC}"
read -p "Are you sure you want to proceed? (y/n): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Setup aborted."
    exit 1
fi

# 0. CHECK FOR LOCAL LUA FILE
if [ ! -f "init.lua" ]; then
    echo -e "${RED}Error: 'init.lua' not found in the current directory.${NC}"
    echo "Please ensure the Vimualizer source code is saved as 'init.lua' alongside this script."
    exit 1
fi

echo "🚀 Starting setup..."

# 1. CHECK/INSTALL HOMEBREW
if ! command -v brew &> /dev/null; then
    echo "🍺 Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to path for Apple Silicon if needed
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}✅ Homebrew is already installed.${NC}"
fi

# 2. CHECK/INSTALL HAMMERSPOON
if ! ls /Applications/Hammerspoon.app &> /dev/null; then
    echo "🔨 Hammerspoon not found. Installing via Homebrew..."
    brew install --cask hammerspoon
else
    echo -e "${GREEN}✅ Hammerspoon is already installed.${NC}"
fi

# 3. DIRECTORY SETUP
echo "📂 Setting up directories..."
mkdir -p ~/.hammerspoon
mkdir -p ~/Documents/Vimualizer

# 4. BACKUP EXISTING CONFIG
if [ -f ~/.hammerspoon/init.lua ]; then
    echo -e "${YELLOW}⚠️  Existing configuration found. Backing up to init.lua.bak...${NC}"
    cp ~/.hammerspoon/init.lua ~/.hammerspoon/init.lua.bak
fi

# 5. INSTALL VIMUALIZER
echo "📦 Installing Vimualizer..."
cp init.lua ~/.hammerspoon/init.lua

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}       INSTALLATION COMPLETE              ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo "Please launch (or restart) Hammerspoon to start Vimualizer."