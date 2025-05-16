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
    else
        print_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    print_message "Detected OS: $OS"
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
        else
            curl -s https://ohmyposh.dev/install.sh | bash -s
        fi
        
        print_success "Oh My Posh installed successfully"
    else
        print_success "Oh My Posh is already installed"
    fi
}

# Function to install Nerd Font
install_nerd_font() {
    print_message "Checking for Nerd Font..."
    FONT_INSTALLED=false
    
    if [[ "$OS" == "macOS" ]]; then
        if brew list | grep -q "font-hack-nerd-font"; then
            FONT_INSTALLED=true
        else
            print_message "Installing Hack Nerd Font..."
            brew tap homebrew/cask-fonts
            brew install --cask font-hack-nerd-font
        fi
    else
        # For Linux, check if any Nerd Font is installed
        if fc-list | grep -i "nerd" > /dev/null; then
            FONT_INSTALLED=true
        else
            print_message "Installing Hack Nerd Font..."
            # Create fonts directory if it doesn't exist
            mkdir -p ~/.local/share/fonts
            
            # Download and install Hack Nerd Font
            curl -fLo "Hack Regular Nerd Font Complete.ttf" \
                https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete.ttf
            
            mv "Hack Regular Nerd Font Complete.ttf" ~/.local/share/fonts/
            
            # Update font cache
            fc-cache -fv
        fi
    fi
    
    if [[ "$FONT_INSTALLED" == true ]]; then
        print_success "Nerd Font is already installed"
    else
        print_success "Nerd Font installed successfully"
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
        git clone https://github.com/kartikshankar/kartikshankar-ohmyposh-theme.git "$REPO_DIR"
        print_success "Theme repository cloned successfully"
    else
        print_message "Updating existing theme repository..."
        cd "$REPO_DIR" && git pull
        print_success "Theme repository updated successfully"
    fi
    
    THEME_PATH="$REPO_DIR/kartikshankar.omp.json"
    print_success "Theme path: $THEME_PATH"
}

# Function to configure the shell
configure_shell() {
    SHELL_CONFIGURED=false
    
    # Detect current shell
    CURRENT_SHELL=$(basename "$SHELL")
    print_message "Detected shell: $CURRENT_SHELL"
    
    # Configure based on shell type
    case "$CURRENT_SHELL" in
        zsh)
            CONFIG_FILE="$HOME/.zshrc"
            CONFIG_LINE="eval \"\$(oh-my-posh init zsh --config '$THEME_PATH')\""
            ;;
        bash)
            if [[ "$OS" == "macOS" ]]; then
                CONFIG_FILE="$HOME/.bash_profile"
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
            sed -i.bak "s|oh-my-posh init.*|$CONFIG_LINE|g" "$CONFIG_FILE"
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
    
    # Detect OS
    detect_os
    
    # Install dependencies based on OS
    if [[ "$OS" == "macOS" ]]; then
        install_homebrew
    else
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
    echo ""
}

# Run the main function
main 