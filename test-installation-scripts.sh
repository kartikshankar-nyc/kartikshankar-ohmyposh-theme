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

# Test script for installation scripts in Kartik's Oh My Posh Theme
print_header "Testing Installation Scripts in Kartik's Oh My Posh Theme"

# Get the absolute path of the directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if installation scripts exist
print_info "Checking installation scripts..."

BASH_SCRIPT="$SCRIPT_DIR/install.sh"
POWERSHELL_SCRIPT="$SCRIPT_DIR/install.ps1"

if [ ! -f "$BASH_SCRIPT" ]; then
    print_error "Bash installation script not found at: $BASH_SCRIPT"
    exit 1
fi
print_success "Bash installation script found at: $BASH_SCRIPT"

if [ ! -f "$POWERSHELL_SCRIPT" ]; then
    print_error "PowerShell installation script not found at: $POWERSHELL_SCRIPT"
    exit 1
fi
print_success "PowerShell installation script found at: $POWERSHELL_SCRIPT"

# Check if the scripts are executable
print_info "Checking if scripts are executable..."

if [ ! -x "$BASH_SCRIPT" ]; then
    print_warning "Bash script is not executable. Setting permissions..."
    chmod +x "$BASH_SCRIPT"
    if [ -x "$BASH_SCRIPT" ]; then
        print_success "Permissions set successfully"
    else
        print_error "Failed to set permissions"
    fi
else
    print_success "Bash script is executable"
fi

# Check if bundled fonts directory exists
print_header "Checking Bundled Fonts"

FONTS_DIR="$SCRIPT_DIR/fonts"
print_info "Checking for bundled fonts directory..."

if [ ! -d "$FONTS_DIR" ]; then
    print_error "Bundled fonts directory not found at: $FONTS_DIR"
else
    print_success "Bundled fonts directory found at: $FONTS_DIR"
    
    # Check for font files
    print_info "Checking for bundled font files..."
    FONT_COUNT=$(find "$FONTS_DIR" -name "*.ttf" | wc -l)
    
    if [ "$FONT_COUNT" -eq 0 ]; then
        print_error "No font files found in bundled fonts directory"
    else
        print_success "Found $FONT_COUNT font files in bundled fonts directory"
    fi
    
    # Check if README exists for the fonts
    if [ -f "$FONTS_DIR/README.md" ]; then
        print_success "README file exists for the bundled fonts"
    else
        print_warning "No README file for the bundled fonts. Consider adding documentation."
    fi
fi

# Check if bash script includes bundled font installation
print_info "Checking for bundled font installation in bash script..."
if grep -q "install_bundled_fonts" "$BASH_SCRIPT"; then
    print_success "Bash script includes bundled font installation function"
    
    # Check if the function is used as a fallback
    if grep -q "Failed.*Trying bundled fonts\|Unable to.*bundled" "$BASH_SCRIPT"; then
        print_success "Bash script uses bundled fonts as fallback when online installation fails"
    else
        print_warning "Bash script might not be using bundled fonts as a fallback properly"
    fi
else
    print_error "Bash script does not include bundled font installation function"
fi

# Check if PowerShell script includes bundled font installation
print_info "Checking for bundled font installation in PowerShell script..."
if grep -q "Install-BundledNerdFonts" "$POWERSHELL_SCRIPT"; then
    print_success "PowerShell script includes bundled font installation function"
    
    # Check if the function is used as a fallback
    if grep -q "Failed.*bundled fonts\|Trying to use bundled" "$POWERSHELL_SCRIPT"; then
        print_success "PowerShell script uses bundled fonts as fallback when online installation fails"
    else
        print_warning "PowerShell script might not be using bundled fonts as a fallback properly"
    fi
else
    print_error "PowerShell script does not include bundled font installation function"
fi

# Check Bash script for cross-platform compatibility
print_header "Checking Bash Script for Cross-Platform Support"

print_info "Checking for Git Bash support..."
if grep -q "msys\|cygwin" "$BASH_SCRIPT"; then
    print_success "Script includes Git Bash detection"
else
    print_error "Script doesn't include Git Bash detection"
fi

print_info "Checking for WSL support..."
if grep -q "WSL\|Microsoft" "$BASH_SCRIPT"; then
    print_success "Script includes WSL detection"
else
    print_error "Script doesn't include WSL detection"
fi

print_info "Checking for shell detection..."
if grep -q "BASH_VERSION\|ZSH_VERSION" "$BASH_SCRIPT"; then
    print_success "Script includes shell type detection"
else
    print_error "Script doesn't include proper shell detection"
fi

print_info "Checking configuration file logic..."
if grep -q "CONFIG_FILE.*bash_profile\|bashrc\|zshrc" "$BASH_SCRIPT"; then
    print_success "Script handles different shell config files"
else
    print_error "Script doesn't handle different shell config files"
fi

# Check PowerShell script for cross-platform compatibility
print_header "Checking PowerShell Script for Cross-Platform Support"

print_info "Checking for OS detection..."
if grep -q "Get-OperatingSystem\|IsWindows\|IsMacOS\|IsLinux" "$POWERSHELL_SCRIPT"; then
    print_success "Script includes OS detection"
else
    print_error "Script doesn't include OS detection"
fi

print_info "Checking for macOS support..."
if grep -q "macOS\|Homebrew" "$POWERSHELL_SCRIPT"; then
    print_success "Script includes macOS support"
else
    print_error "Script doesn't include macOS support"
fi

print_info "Checking for Windows Terminal configuration..."
if grep -q "WindowsTerminal\|wt.exe" "$POWERSHELL_SCRIPT"; then
    print_success "Script configures Windows Terminal"
else
    print_error "Script doesn't configure Windows Terminal"
fi

print_info "Checking for Git Bash configuration..."
if grep -q "Configure-GitBash\|.bashrc" "$POWERSHELL_SCRIPT"; then
    print_success "Script configures Git Bash"
else
    print_error "Script doesn't configure Git Bash"
fi

print_info "Checking for Command Prompt configuration..."
if grep -q "Configure-Cmd\|Command Processor" "$POWERSHELL_SCRIPT"; then
    print_success "Script configures Command Prompt"
else
    print_error "Script doesn't configure Command Prompt"
fi

# Syntax check for bash script
print_header "Syntax Check for Bash Script"

print_info "Checking bash script syntax..."
if bash -n "$BASH_SCRIPT"; then
    print_success "Bash script syntax is valid"
else
    print_error "Bash script contains syntax errors"
    exit 1
fi

# Syntax check for PowerShell script (if pwsh is available)
print_header "Syntax Check for PowerShell Script"

if command -v pwsh &> /dev/null; then
    print_info "Checking PowerShell script syntax..."
    # Use the PowerShell parser for actual syntax validation
    PS_ERRORS=$(pwsh -NoProfile -c "
        \$errors = \$null
        [System.Management.Automation.Language.Parser]::ParseFile('$POWERSHELL_SCRIPT', [ref]\$null, [ref]\$errors) | Out-Null
        if (\$errors.Count -gt 0) {
            \$errors | ForEach-Object { Write-Output \$_.Message }
            exit 1
        }
        exit 0
    " 2>&1)
    if [ $? -eq 0 ]; then
        print_success "PowerShell script syntax is valid"
    else
        print_error "PowerShell script contains syntax errors:"
        echo "  $PS_ERRORS"
    fi
else
    print_warning "PowerShell (pwsh) is not installed, skipping syntax check for PowerShell script"
fi

# Summary
print_header "Installation Scripts Test Summary"

ISSUES=0
# Bash script checks
if ! grep -q "msys\|cygwin" "$BASH_SCRIPT" || ! grep -q "WSL\|Microsoft" "$BASH_SCRIPT" || ! grep -q "BASH_VERSION\|ZSH_VERSION" "$BASH_SCRIPT" || ! grep -q "CONFIG_FILE.*bash_profile\|bashrc\|zshrc" "$BASH_SCRIPT"; then
    ISSUES=$((ISSUES + 1))
fi

# PowerShell script checks
if ! grep -q "Get-OperatingSystem\|IsWindows\|IsMacOS\|IsLinux" "$POWERSHELL_SCRIPT" || ! grep -q "macOS\|Homebrew" "$POWERSHELL_SCRIPT" || ! grep -q "Configure-GitBash\|.bashrc" "$POWERSHELL_SCRIPT" || ! grep -q "Configure-Cmd\|Command Processor" "$POWERSHELL_SCRIPT"; then
    ISSUES=$((ISSUES + 1))
fi

# Bundled font checks
if [ ! -d "$FONTS_DIR" ] || [ "$FONT_COUNT" -eq 0 ] || ! grep -q "install_bundled_fonts" "$BASH_SCRIPT" || ! grep -q "Install-BundledNerdFonts" "$POWERSHELL_SCRIPT"; then
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    print_success "All installation script tests passed! The scripts support multiple platforms and shells."
else
    print_warning "Some installation script tests failed. Review the issues above."
fi

echo ""
print_info "Note: These tests only check for the presence of cross-platform features."
print_info "For a complete validation, you should test the scripts on actual target platforms."
echo "" 