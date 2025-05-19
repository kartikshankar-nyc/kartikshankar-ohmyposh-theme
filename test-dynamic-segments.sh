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

# Test script for dynamic segment functionality in Kartik's Oh My Posh Theme
print_header "Testing Dynamic Segments in Kartik's Oh My Posh Theme"

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

# Test OS detection in the theme
print_header "OS Detection Test"

print_info "Detecting current OS..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    CURRENT_OS="darwin"
    EXPECTED_ICON="\uf179" # Apple icon
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CURRENT_OS="linux"
    EXPECTED_ICON="\uf17c" # Linux icon
elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]] || [[ "$OSTYPE" == "win"* ]]; then
    CURRENT_OS="windows"
    EXPECTED_ICON="\ue70f" # Windows icon
else
    CURRENT_OS="unknown"
    EXPECTED_ICON="\uf17a" # Generic icon
fi
print_success "Detected OS: $CURRENT_OS"

# Extract OS segment template from the theme file
print_info "Checking OS segment in theme..."
OS_SEGMENT=$(cat "$THEME_PATH" | jq -r '.blocks[0].segments[] | select(.type == "os") | .template')

if [[ -z "$OS_SEGMENT" ]]; then
    print_error "OS segment not found in theme"
    exit 1
fi
print_success "OS segment found in theme"

# Check if the OS segment contains conditional logic for different OS types
print_info "Verifying dynamic OS icon logic..."
if [[ "$OS_SEGMENT" == *"if eq .Os \"windows\""* ]] && \
   [[ "$OS_SEGMENT" == *"if eq .Os \"darwin\""* ]] && \
   [[ "$OS_SEGMENT" == *"if eq .Os \"linux\""* ]]; then
    print_success "Theme includes dynamic OS icon logic"
else
    print_error "Theme does not include proper dynamic OS icon logic"
    echo "Current template: $OS_SEGMENT"
    exit 1
fi

# Test hostname detection in the theme
print_header "Hostname Detection Test"

print_info "Detecting current hostname..."
CURRENT_HOSTNAME=$(hostname)
print_success "Detected hostname: $CURRENT_HOSTNAME"

# Extract hostname segment from the theme file
print_info "Checking hostname segment in theme..."
HOSTNAME_SEGMENT=$(cat "$THEME_PATH" | jq -r '.blocks[0].segments[] | select(.template | contains("HostName")) | .template')

if [[ -z "$HOSTNAME_SEGMENT" ]]; then
    print_error "Hostname segment not found in theme"
    exit 1
fi
print_success "Hostname segment found in theme"

# Check if the hostname segment uses the .HostName variable
print_info "Verifying dynamic hostname logic..."
if [[ "$HOSTNAME_SEGMENT" == *"{{ .HostName }}"* ]]; then
    print_success "Theme includes dynamic hostname logic"
else
    print_error "Theme does not use dynamic hostname"
    echo "Current template: $HOSTNAME_SEGMENT"
    exit 1
fi

# Test rendering with current OS and hostname
print_header "Rendering Test with Current System Values"

print_info "Rendering theme with current system values..."
RENDERED_OUTPUT=$(oh-my-posh print primary --config "$THEME_PATH")
echo "$RENDERED_OUTPUT"
echo ""

# Final validation
print_header "Test Results"

if [[ "$OS_SEGMENT" == *"if eq .Os \"windows\""* ]] && \
   [[ "$OS_SEGMENT" == *"if eq .Os \"darwin\""* ]] && \
   [[ "$OS_SEGMENT" == *"if eq .Os \"linux\""* ]] && \
   [[ "$HOSTNAME_SEGMENT" == *"{{ .HostName }}"* ]]; then
    print_success "Dynamic segments test passed! The theme adapts to different operating systems and hostnames."
else
    print_error "Dynamic segments test failed! Please review the theme configuration."
fi

echo ""
print_info "Note: The rendered output above should show your current OS icon and hostname correctly."
print_info "If you see placeholder characters or incorrect values, check your terminal's font configuration."
echo "" 