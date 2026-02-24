#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
        OS="Windows"
        IS_GIT_BASH=true
    else
        print_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    print_message "Detected OS: $OS"

    # Detect if running in Windows Subsystem for Linux
    if [[ -f /proc/version ]] && grep -q Microsoft /proc/version; then
        print_message "Running in Windows Subsystem for Linux (WSL)"
        IS_WSL=true
    fi
}

# Function to detect shell
detect_shell() {
    # Get current shell
    if [[ -n "$BASH_VERSION" ]]; then
        CURRENT_SHELL="bash"
    elif [[ -n "$ZSH_VERSION" ]]; then
        CURRENT_SHELL="zsh"
    else
        CURRENT_SHELL=$(basename "$SHELL")
    fi
    print_message "Detected shell: $CURRENT_SHELL"
}

# Function to install Homebrew on macOS
install_homebrew() {
    if ! command_exists brew; then
        print_message "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ "$OS" == "macOS" ]]; then
            if [[ $(uname -m) == 'arm64' ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            else
                echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
        print_success "Homebrew installed successfully"
    else
        print_success "Homebrew is already installed"
    fi
}

# Function to install Linux package manager packages
install_linux_packages() {
    print_message "Installing required packages..."
    
    # Check which package manager is available
    if command_exists apt; then
        sudo apt update
        sudo apt install -y curl git fontconfig
    elif command_exists dnf; then
        sudo dnf install -y curl git fontconfig
    elif command_exists yum; then
        sudo yum install -y curl git fontconfig
    elif command_exists pacman; then
        sudo pacman -Sy curl git fontconfig --noconfirm
    else
        print_error "Unsupported package manager. Please install curl, git, and fontconfig manually."
        exit 1
    fi
    
    print_success "Required packages installed"
}

# Function to install Oh My Posh
install_oh_my_posh() {
    if ! command_exists oh-my-posh; then
        print_message "Installing Oh My Posh..."

        if [[ "$OS" == "macOS" ]]; then
            brew install oh-my-posh
        elif [[ "$OS" == "Windows" && "$IS_GIT_BASH" == true ]]; then
            # For Git Bash on Windows, recommend using the Windows installer
            print_message "For Git Bash on Windows, it's recommended to install Oh My Posh using the Windows installer."
            print_message "Would you like to open the Oh My Posh installer webpage? (y/n)"
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                start https://ohmyposh.dev/docs/installation/windows
                print_message "Please install Oh My Posh and then press Enter to continue..."
                read -r
            else
                print_message "Attempting to install Oh My Posh directly..."
                curl -s https://ohmyposh.dev/install.sh | bash -s
            fi
        else
            curl -s https://ohmyposh.dev/install.sh | bash -s
        fi

        if command_exists oh-my-posh; then
            print_success "Oh My Posh installed successfully"
        else
            print_error "Oh My Posh installation could not be verified. Please install it manually."
            print_error "Visit: https://ohmyposh.dev/docs/installation/linux"
            exit 1
        fi
    else
        print_success "Oh My Posh is already installed"
    fi
}

# Function to install Nerd Font using bundled fonts in the repository
install_bundled_fonts() {
    print_message "Using bundled Nerd Fonts as fallback..."
    
    # Get the repository directory
    REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    FONTS_DIR="$REPO_DIR/fonts"
    
    if [[ ! -d "$FONTS_DIR" ]]; then
        print_error "Bundled fonts directory not found at: $FONTS_DIR"
        return 1
    fi
    
    # Check if there are font files in the directory
    font_count=$(find "$FONTS_DIR" -name "*.ttf" | wc -l)
    if [[ $font_count -eq 0 ]]; then
        print_error "No bundled font files found in: $FONTS_DIR"
        return 1
    fi
    
    if [[ "$OS" == "macOS" ]]; then
        # On macOS, copy fonts to ~/Library/Fonts
        print_message "Installing bundled fonts to ~/Library/Fonts..."
        mkdir -p ~/Library/Fonts
        cp "$FONTS_DIR"/*.ttf ~/Library/Fonts/
    elif [[ "$OS" == "Linux" ]] || [[ "$IS_WSL" == true ]]; then
        # On Linux, copy fonts to ~/.local/share/fonts
        print_message "Installing bundled fonts to ~/.local/share/fonts..."
        mkdir -p ~/.local/share/fonts
        cp "$FONTS_DIR"/*.ttf ~/.local/share/fonts/
        
        # Update font cache
        fc-cache -fv > /dev/null
    elif [[ "$OS" == "Windows" && "$IS_GIT_BASH" == true ]]; then
        # For Git Bash on Windows
        print_message "On Windows, fonts need to be installed manually."
        print_message "Would you like to open the fonts directory to install manually? (y/n)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            explorer.exe "$(cygpath -w "$FONTS_DIR")"
            print_message "Please install the fonts and then press Enter to continue..."
            read -r
        fi
    fi
    
    print_success "Bundled fonts installed successfully"
    return 0
}

# Function to install Nerd Font
install_nerd_font() {
    print_message "Checking for Nerd Font..."
    FONT_INSTALLED=false
    
    if [[ "$OS" == "macOS" ]]; then
        if brew list --cask | grep -q "font-hack-nerd-font"; then
            FONT_INSTALLED=true
        else
            print_message "Installing Hack Nerd Font..."
            if brew install --cask font-hack-nerd-font; then
                FONT_INSTALLED=true
            else
                print_warning "Failed to install Hack Nerd Font via Homebrew. Trying bundled fonts..."
                if install_bundled_fonts; then
                    FONT_INSTALLED=true
                fi
            fi
        fi
    elif [[ "$OS" == "Windows" && "$IS_GIT_BASH" == true ]]; then
        # For Git Bash on Windows, recommend using the Oh My Posh font installer
        if command_exists oh-my-posh; then
            print_message "Would you like to install Hack Nerd Font? (y/n)"
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                if oh-my-posh font install Hack; then
                    FONT_INSTALLED=true
                else
                    print_warning "Failed to install Hack Nerd Font via Oh My Posh. Trying bundled fonts..."
                    if install_bundled_fonts; then
                        FONT_INSTALLED=true
                    fi
                fi
            else
                print_warning "Skipping font installation. You'll need a Nerd Font for the theme to display correctly."
                print_message "Would you like to install the bundled fonts instead? (y/n)"
                read -r response
                if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                    if install_bundled_fonts; then
                        FONT_INSTALLED=true
                    fi
                fi
            fi
        else
            print_warning "Oh My Posh not found. Trying to install bundled Nerd Fonts..."
            if install_bundled_fonts; then
                FONT_INSTALLED=true
            else
                print_warning "Please install a Nerd Font manually."
                print_warning "Visit: https://www.nerdfonts.com/font-downloads"
            fi
        fi
    else
        # For Linux, check if any Nerd Font is installed
        if fc-list | grep -i "nerd" > /dev/null; then
            FONT_INSTALLED=true
        else
            print_message "Installing Hack Nerd Font..."

            # Try oh-my-posh font installer first (official method)
            if command_exists oh-my-posh && oh-my-posh font install Hack; then
                FONT_INSTALLED=true
            else
                print_warning "Failed to install Hack Nerd Font via Oh My Posh. Trying bundled fonts..."
                if install_bundled_fonts; then
                    FONT_INSTALLED=true
                fi
            fi
        fi
    fi
    
    if [[ "$FONT_INSTALLED" == true ]]; then
        print_success "Nerd Font is installed"
    else
        print_warning "Unable to install Nerd Font. Please install one manually."
        print_warning "Visit: https://www.nerdfonts.com/font-downloads"
    fi
}

# Function to install Git
install_git() {
    if ! command_exists git; then
        print_message "Installing Git..."
        
        if [[ "$OS" == "macOS" ]]; then
            brew install git
        else
            # This will be handled by install_linux_packages
            :
        fi
        
        print_success "Git installed successfully"
    else
        print_success "Git is already installed"
    fi
}

# Function to clone the theme repository
clone_repository() {
    # Create directory for Oh My Posh themes
    THEMES_DIR="$HOME/.oh-my-posh-themes"
    REPO_DIR="$THEMES_DIR/kartikshankar-ohmyposh-theme"
    
    if [ ! -d "$THEMES_DIR" ]; then
        print_message "Creating themes directory..."
        mkdir -p "$THEMES_DIR"
    fi
    
    if [ ! -d "$REPO_DIR" ]; then
        print_message "Cloning theme repository..."
        git clone https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme.git "$REPO_DIR"
        print_success "Theme repository cloned successfully"
    else
        print_message "Updating existing theme repository..."
        git -C "$REPO_DIR" pull
        print_success "Theme repository updated successfully"
    fi
    
    THEME_PATH="$REPO_DIR/kartikshankar.omp.json"
    print_success "Theme path: $THEME_PATH"
}

# Function to configure the shell
configure_shell() {
    SHELL_CONFIGURED=false
    
    # Get reference to current shell
    CURRENT_SHELL=${CURRENT_SHELL:-$(basename "$SHELL")}
    
    # Configure based on shell type
    case "$CURRENT_SHELL" in
        zsh)
            CONFIG_FILE="$HOME/.zshrc"
            CONFIG_LINE="eval \"\$(oh-my-posh init zsh --config '$THEME_PATH')\""
            ;;
        bash)
            if [[ "$OS" == "macOS" ]]; then
                CONFIG_FILE="$HOME/.bash_profile"
            elif [[ "$OS" == "Windows" && "$IS_GIT_BASH" == true ]]; then
                CONFIG_FILE="$HOME/.bashrc"
                # Create .bashrc if it doesn't exist
                if [ ! -f "$CONFIG_FILE" ]; then
                    touch "$CONFIG_FILE"
                fi
            else
                CONFIG_FILE="$HOME/.bashrc"
            fi
            CONFIG_LINE="eval \"\$(oh-my-posh init bash --config '$THEME_PATH')\""
            ;;
        *)
            print_warning "Unsupported shell: $CURRENT_SHELL"
            print_warning "Please manually add the following line to your shell configuration file:"
            print_warning "eval \"\$(oh-my-posh init <your-shell> --config '$THEME_PATH')\""
            return
            ;;
    esac
    
    # Check if configuration is already in place
    if grep -q "oh-my-posh init.*$THEME_PATH" "$CONFIG_FILE" 2>/dev/null; then
        print_success "Shell already configured to use the theme"
        SHELL_CONFIGURED=true
    else
        # Check if Oh My Posh is configured with another theme
        if grep -q "oh-my-posh init" "$CONFIG_FILE" 2>/dev/null; then
            print_message "Updating existing Oh My Posh configuration..."
            if [[ "$OS" == "macOS" ]]; then
                sed -i '' "s|oh-my-posh init.*|$CONFIG_LINE|g" "$CONFIG_FILE"
            else
                sed -i "s|oh-my-posh init.*|$CONFIG_LINE|g" "$CONFIG_FILE"
            fi
        else
            print_message "Adding Oh My Posh configuration to $CONFIG_FILE..."
            echo "" >> "$CONFIG_FILE"
            echo "# Oh My Posh configuration" >> "$CONFIG_FILE"
            echo "$CONFIG_LINE" >> "$CONFIG_FILE"
        fi
        print_success "Shell configured successfully"
    fi
}

# Function to apply theme to current shell
apply_theme() {
    print_message "Applying theme to current shell..."
    eval "$(oh-my-posh init "$CURRENT_SHELL" --config "$THEME_PATH")"
    print_success "Theme applied to current shell"
}

# Main function
main() {
    print_message "Starting Oh My Posh Theme Installer"
    
    # Detect OS and shell
    detect_os
    detect_shell
    
    # Install dependencies based on OS
    if [[ "$OS" == "macOS" ]]; then
        install_homebrew
    elif [[ "$OS" == "Linux" ]] || [[ "$IS_WSL" == true ]]; then
        install_linux_packages
    fi
    
    # Install common dependencies
    install_git
    install_oh_my_posh
    install_nerd_font
    
    # Clone repository and configure shell
    clone_repository
    configure_shell
    
    # Apply theme to current shell
    apply_theme
    
    echo ""
    print_success "Installation complete!"
    print_message "If you don't see the theme applied correctly, please restart your terminal."
    print_message "You may also need to configure your terminal to use the Hack Nerd Font."
    
    # Additional instructions for Git Bash
    if [[ "$OS" == "Windows" && "$IS_GIT_BASH" == true ]]; then
        echo ""
        print_message "Git Bash-specific instructions:"
        print_message "1. Make sure your Git Bash terminal is configured to use a Nerd Font"
        print_message "2. You may need to edit the .bashrc file in your home directory"
        print_message "3. If you experience issues, try running the PowerShell installer (install.ps1) as administrator"
    fi
    
    echo ""
}

# Run the main function
main 