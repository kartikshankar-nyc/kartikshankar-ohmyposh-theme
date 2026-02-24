#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..50})${NC}"
}

# Comprehensive test script for Kartik's Oh My Posh Theme
print_header "Testing Kartik's Oh My Posh Theme"

# Check if Oh My Posh is installed
print_info "Checking Oh My Posh installation..."
if ! command -v oh-my-posh &> /dev/null; then
    print_error "Oh My Posh is not installed. Please install it first:"
    echo "  - macOS: brew install oh-my-posh"
    echo "  - Windows: winget install JanDeDobbeleer.OhMyPosh"
    echo "  - Linux: curl -s https://ohmyposh.dev/install.sh | bash -s"
    exit 1
fi
print_success "Oh My Posh is installed ($(oh-my-posh --version))"

# Check for a Nerd Font
print_info "Checking for Nerd Font..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    if brew list --cask | grep -q "font-.*-nerd-font"; then
        print_success "Nerd Font is installed via Homebrew"
    else
        print_warning "No Nerd Font detected via Homebrew. Make sure you have one installed and configured in your terminal"
        echo "   Visit https://www.nerdfonts.com/ or run: brew install --cask font-hack-nerd-font"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if fc-list | grep -i "nerd" &> /dev/null; then
        print_success "Nerd Font is installed"
    else
        print_warning "No Nerd Font detected. Make sure you have one installed and configured in your terminal"
        echo "   Visit https://www.nerdfonts.com/ for installation instructions"
    fi
else
    print_warning "Nerd Font check not supported on this OS. Ensure you have a Nerd Font installed and configured."
    echo "   Visit https://www.nerdfonts.com/ for installation instructions"
fi

# Get the absolute path of the theme file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_PATH="$SCRIPT_DIR/kartikshankar.omp.json"

# Check if the theme file exists
print_info "Checking theme file..."
if [ ! -f "$THEME_PATH" ]; then
    print_error "Theme file not found at: $THEME_PATH"
    exit 1
fi
print_success "Theme file found at: $THEME_PATH"

# Validate JSON format
print_info "Validating theme JSON format..."
if ! cat "$THEME_PATH" | jq '.' &> /dev/null; then
    print_error "Invalid JSON format in the theme file"
    exit 1
fi
print_success "Theme JSON is valid"

# Check schema version
print_info "Checking theme schema version..."
SCHEMA_VERSION=$(cat "$THEME_PATH" | jq -r '.version')
if [[ "$SCHEMA_VERSION" -lt 2 ]]; then
    print_warning "Theme uses schema version $SCHEMA_VERSION. Version 2 or higher is recommended."
else
    print_success "Theme uses schema version $SCHEMA_VERSION"
fi

# Check for required blocks and segments
print_info "Checking theme structure..."
BLOCKS_COUNT=$(cat "$THEME_PATH" | jq '.blocks | length')
if [[ "$BLOCKS_COUNT" -lt 1 ]]; then
    print_error "Theme doesn't contain any blocks"
    exit 1
fi
print_success "Theme contains $BLOCKS_COUNT blocks"

# Check if essential segments are present
print_info "Checking for essential segments..."
SEGMENTS=$(cat "$THEME_PATH" | jq -r '.blocks[].segments[].type' | sort | uniq)
echo "Found segments: $SEGMENTS"

# Check for specific segments
for SEGMENT in "os" "session" "path" "git"; do
    if echo "$SEGMENTS" | grep -q "$SEGMENT"; then
        print_success "$SEGMENT segment is present"
    else
        print_warning "$SEGMENT segment is not present in the theme"
    fi
done

# Check terminal color support
print_info "Checking terminal color support..."
if [[ "$TERM" == *"256color"* ]] || [[ "$COLORTERM" == "truecolor" ]]; then
    print_success "Terminal supports rich colors (${TERM})"
else
    print_warning "Terminal may not support rich colors. Current: ${TERM}"
    echo "   For best results, use a terminal that supports 24-bit true color"
fi

# Try to render the theme for a preview
print_header "Theme Preview"
echo "Primary prompt:"
oh-my-posh print primary --config "$THEME_PATH"
echo ""

# Check secondary prompt if available 
if cat "$THEME_PATH" | jq -e '.secondary_prompt' &> /dev/null; then
    echo "Secondary prompt:"
    oh-my-posh print secondary --config "$THEME_PATH"
    echo ""
fi

# Test real-time segment updates
print_info "Testing real-time segment updates..."
echo "This might take a few seconds..."
(
    export POSH_THEME="$THEME_PATH"
    # Create a test git repo
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    cd "$TMP_DIR"
    git init &> /dev/null
    touch test.txt

    # Test git status segment
    git add . &> /dev/null
    echo "Git repo with staged changes:"
    oh-my-posh print primary --config "$THEME_PATH"
    echo ""

    cd - &> /dev/null
)

# Print usage instructions
print_header "Installation Instructions"
echo "To use this theme, add the following to your shell config file:"
echo ""

# Detect current shell
CURRENT_SHELL=$(basename "$SHELL")
print_info "Detected shell: $CURRENT_SHELL"

# Check if Oh My Posh is already configured in the shell
if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    CONFIG_FILE="$HOME/.zshrc"
    CONFIG_LINE="eval \"\$(oh-my-posh init zsh --config '$THEME_PATH')\""
    
    echo "For Zsh (~/.zshrc):"
    echo "  $CONFIG_LINE"
    
    if grep -q "oh-my-posh init" "$CONFIG_FILE" 2>/dev/null; then
        if grep -q "$THEME_PATH" "$CONFIG_FILE" 2>/dev/null; then
            print_success "Theme is already configured in your .zshrc"
        else
            print_warning "Oh My Posh is configured with a different theme in your .zshrc"
        fi
    fi
    
elif [[ "$CURRENT_SHELL" == "bash" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CONFIG_FILE="$HOME/.bash_profile"
    else
        CONFIG_FILE="$HOME/.bashrc"
    fi
    CONFIG_LINE="eval \"\$(oh-my-posh init bash --config '$THEME_PATH')\""
    
    echo "For Bash ($CONFIG_FILE):"
    echo "  $CONFIG_LINE"
    
    if grep -q "oh-my-posh init" "$CONFIG_FILE" 2>/dev/null; then
        if grep -q "$THEME_PATH" "$CONFIG_FILE" 2>/dev/null; then
            print_success "Theme is already configured in your $CONFIG_FILE"
        else
            print_warning "Oh My Posh is configured with a different theme in your $CONFIG_FILE"
        fi
    fi
fi

echo ""
echo "For PowerShell (\$PROFILE):"
echo "  oh-my-posh init pwsh --config '$THEME_PATH' | Invoke-Expression"
echo ""

# Performance check
print_header "Performance Check"
print_info "Testing theme rendering performance..."
# Use python3 for sub-second precision (portable across macOS and Linux)
if command -v python3 &> /dev/null; then
    START_TIME=$(python3 -c "import time; print(time.time())")
    oh-my-posh print primary --config "$THEME_PATH" > /dev/null
    END_TIME=$(python3 -c "import time; print(time.time())")
    RENDERING_TIME=$(python3 -c "print(f'{$END_TIME - $START_TIME:.3f}')")
    echo "Rendering time: ${RENDERING_TIME}s"

    if python3 -c "exit(0 if $RENDERING_TIME > 0.5 else 1)"; then
        print_warning "Theme rendering is a bit slow (${RENDERING_TIME}s > 0.5s)"
        echo "   Consider simplifying complex segments for better performance"
    else
        print_success "Theme rendering is fast (${RENDERING_TIME}s)"
    fi
else
    # Fallback: use bash SECONDS (integer-only, less precise)
    SECONDS=0
    oh-my-posh print primary --config "$THEME_PATH" > /dev/null
    RENDERING_TIME=$SECONDS
    echo "Rendering time: ~${RENDERING_TIME}s"

    if [[ $RENDERING_TIME -gt 0 ]]; then
        print_warning "Theme rendering is a bit slow (~${RENDERING_TIME}s > 0.5s)"
        echo "   Consider simplifying complex segments for better performance"
    else
        print_success "Theme rendering is fast (<1s)"
    fi
fi

print_header "Test Complete"
echo "Your theme is ready to be shared with the community! 🚀"
echo "For any issues or contributions, please refer to the README.md file." 