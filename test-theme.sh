#!/bin/bash

# Simple script to test the Oh My Posh theme

echo "Testing Oh My Posh Theme: kartikshankar.omp.json"
echo "-----------------------------------------------"

# Check if Oh My Posh is installed
if ! command -v oh-my-posh &> /dev/null; then
    echo "Oh My Posh is not installed. Please install it first:"
    echo "  - macOS: brew install oh-my-posh"
    echo "  - Windows: winget install JanDeDobbeleer.OhMyPosh"
    echo "  - Linux: curl -s https://ohmyposh.dev/install.sh | bash -s"
    exit 1
fi

echo "✅ Oh My Posh is installed"

# Check for a Nerd Font
echo "⚠️  Make sure you have a Nerd Font installed and configured in your terminal"
echo "   Visit https://www.nerdfonts.com/ to download and install a Nerd Font"

# Get the absolute path of the theme file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_PATH="$SCRIPT_DIR/kartikshankar.omp.json"

# Check if the theme file exists
if [ ! -f "$THEME_PATH" ]; then
    echo "❌ Theme file not found at: $THEME_PATH"
    exit 1
fi

echo "✅ Theme file found at: $THEME_PATH"

# Preview the theme
echo "Previewing theme..."
echo "-----------------------------------------------"
oh-my-posh print primary --config "$THEME_PATH"
echo "-----------------------------------------------"

echo "To use this theme, add the following to your shell config file:"
echo ""
echo "Bash (~/.bashrc):"
echo "  eval \"\$(oh-my-posh init bash --config $THEME_PATH)\""
echo ""
echo "Zsh (~/.zshrc):"
echo "  eval \"\$(oh-my-posh init zsh --config $THEME_PATH)\""
echo ""
echo "PowerShell (\$PROFILE):"
echo "  oh-my-posh init pwsh --config $THEME_PATH | Invoke-Expression"
echo ""

echo "Happy terminal customizing! 🚀" 