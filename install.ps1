# Oh My Posh Theme Installer for Windows and macOS (PowerShell)
# Run as administrator for best results on Windows

# Function to print colored messages
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    switch ($Type) {
        "INFO" { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        default { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
    }
}

# Function to check if a command exists
function Test-CommandExists {
    param (
        [string]$Command
    )
    
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to detect the operating system
function Get-OperatingSystem {
    if ($IsWindows -or (!$IsLinux -and !$IsMacOS -and [System.Environment]::OSVersion.Platform -eq "Win32NT")) {
        return "Windows"
    }
    elseif ($IsMacOS -or (!$IsLinux -and !$IsWindows -and [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX))) {
        return "macOS"
    }
    elseif ($IsLinux -or (!$IsMacOS -and !$IsWindows -and [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux))) {
        return "Linux"
    }
    else {
        return "Unknown"
    }
}

# Function to install Winget if not available (Windows only)
function Install-Winget {
    if (-not ($script:OS -eq "Windows")) {
        return $true
    }
    
    if (Test-CommandExists winget) {
        Write-ColorMessage "Winget is already installed" "SUCCESS"
        return $true
    }
    
    Write-ColorMessage "Winget not found. Attempting to install..." "WARNING"
    
    # Check if we're on Windows 10 or later
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($null -eq $osInfo) {
        Write-ColorMessage "Unable to detect Windows version. Please install Winget manually." "ERROR"
        return $false
    }
    
    $osVersion = [Version]$osInfo.Version
    
    if ($osVersion -lt [Version]"10.0.17763.0") {
        Write-ColorMessage "Winget requires Windows 10 1809 or later. Please upgrade Windows or install Oh My Posh manually." "ERROR"
        return $false
    }
    
    # Try to install winget from the Microsoft Store
    try {
        Write-ColorMessage "Opening Microsoft Store to install App Installer (which includes winget)..."
        Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
        
        Write-ColorMessage "Please complete the installation in the Microsoft Store and then press Enter to continue..." "WARNING"
        Read-Host | Out-Null
        
        if (Test-CommandExists winget) {
            Write-ColorMessage "Winget installed successfully" "SUCCESS"
            return $true
        }
        else {
            Write-ColorMessage "Winget installation could not be verified" "ERROR"
            return $false
        }
    }
    catch {
        Write-ColorMessage "Failed to open Microsoft Store: $_" "ERROR"
        return $false
    }
}

# Function to install Windows Terminal if not available (Windows only)
function Install-WindowsTerminal {
    if (-not ($script:OS -eq "Windows")) {
        return
    }
    
    # Check if Windows Terminal is installed
    $terminalInstalled = $false
    
    # Check via Get-AppxPackage
    try {
        if (Get-AppxPackage -Name Microsoft.WindowsTerminal) {
            $terminalInstalled = $true
        }
    }
    catch {
        # If Get-AppxPackage fails, try alternative method
    }
    
    # Check via program files as fallback
    if (-not $terminalInstalled) {
        if (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") {
            $terminalInstalled = $true
        }
    }
    
    if ($terminalInstalled) {
        Write-ColorMessage "Windows Terminal is already installed" "SUCCESS"
        return
    }
    
    Write-ColorMessage "Installing Windows Terminal..."
    
    # Try to install via winget
    if (Test-CommandExists winget) {
        winget install Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements
        Write-ColorMessage "Windows Terminal installed successfully" "SUCCESS"
    }
    else {
        Write-ColorMessage "Opening Microsoft Store to install Windows Terminal..."
        Start-Process "ms-windows-store://pdp/?ProductId=9n0dx20hk701"
        Write-ColorMessage "Please complete the installation in the Microsoft Store and then press Enter to continue..." "WARNING"
        Read-Host | Out-Null
    }
}

# Function to install Git if not available
function Install-Git {
    if (Test-CommandExists git) {
        Write-ColorMessage "Git is already installed" "SUCCESS"
        return
    }
    
    Write-ColorMessage "Installing Git..."
    
    if ($script:OS -eq "Windows") {
        # Try to install via winget
        if (Test-CommandExists winget) {
            winget install Git.Git --accept-source-agreements --accept-package-agreements
            
            # Add Git to PATH for current session
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            
            Write-ColorMessage "Git installed successfully" "SUCCESS"
        }
        else {
            Write-ColorMessage "Opening Git download page..."
            Start-Process "https://git-scm.com/download/win"
            Write-ColorMessage "Please download and install Git, then press Enter to continue..." "WARNING"
            Read-Host | Out-Null
            
            if (Test-CommandExists git) {
                Write-ColorMessage "Git installation verified" "SUCCESS"
            }
            else {
                Write-ColorMessage "Git installation could not be verified. Script will continue, but may fail later." "WARNING"
            }
        }
    }
    elseif ($script:OS -eq "macOS") {
        # Check for Homebrew
        if (Test-CommandExists brew) {
            Write-ColorMessage "Installing Git using Homebrew..."
            brew install git
        }
        else {
            Write-ColorMessage "Homebrew not found. Opening Git download page..."
            Start-Process "https://git-scm.com/download/mac"
            Write-ColorMessage "Please download and install Git, then press Enter to continue..." "WARNING"
            Read-Host | Out-Null
        }
        
        if (Test-CommandExists git) {
            Write-ColorMessage "Git installation verified" "SUCCESS"
        }
        else {
            Write-ColorMessage "Git installation could not be verified. Script will continue, but may fail later." "WARNING"
        }
    }
}

# Function to install Homebrew on macOS
function Install-Homebrew {
    if (-not ($script:OS -eq "macOS")) {
        return
    }
    
    if (Test-CommandExists brew) {
        Write-ColorMessage "Homebrew is already installed" "SUCCESS"
        return
    }
    
    Write-ColorMessage "Installing Homebrew..."
    try {
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for the current session
        if ((uname -m) -eq "arm64") {
            $homebrewPath = "/opt/homebrew/bin"
        }
        else {
            $homebrewPath = "/usr/local/bin"
        }
        
        # Update path for current session
        $env:PATH = "$homebrewPath:$env:PATH"
        
        Write-ColorMessage "Homebrew installed successfully" "SUCCESS"
    }
    catch {
        Write-ColorMessage "Failed to install Homebrew: $_" "ERROR"
    }
}

# Function to install Oh My Posh
function Install-OhMyPosh {
    if (Test-CommandExists oh-my-posh) {
        Write-ColorMessage "Oh My Posh is already installed" "SUCCESS"
        return
    }
    
    Write-ColorMessage "Installing Oh My Posh..."
    
    if ($script:OS -eq "Windows") {
        # Try to install via winget
        if (Test-CommandExists winget) {
            winget install JanDeDobbeleer.OhMyPosh --accept-source-agreements --accept-package-agreements
            
            # Add Oh My Posh to PATH for current session
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            
            Write-ColorMessage "Oh My Posh installed successfully" "SUCCESS"
        }
        else {
            # Fallback to direct installation
            Write-ColorMessage "Installing Oh My Posh using installer script..."
            
            Set-ExecutionPolicy Bypass -Scope Process -Force
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
            
            if (Test-CommandExists oh-my-posh) {
                Write-ColorMessage "Oh My Posh installed successfully" "SUCCESS"
            }
            else {
                Write-ColorMessage "Oh My Posh installation failed. Please install manually." "ERROR"
                exit 1
            }
        }
    }
    elseif ($script:OS -eq "macOS") {
        # Install on macOS
        if (Test-CommandExists brew) {
            Write-ColorMessage "Installing Oh My Posh using Homebrew..."
            brew install oh-my-posh
        }
        else {
            # Fallback to direct installation
            Write-ColorMessage "Installing Oh My Posh using installer script..."
            
            try {
                Invoke-Expression (Invoke-RestMethod -Uri https://ohmyposh.dev/install.ps1)
                
                if (Test-CommandExists oh-my-posh) {
                    Write-ColorMessage "Oh My Posh installed successfully" "SUCCESS"
                }
                else {
                    Write-ColorMessage "Oh My Posh installation failed. Please install manually." "ERROR"
                    exit 1
                }
            }
            catch {
                Write-ColorMessage "Failed to install Oh My Posh: $_" "ERROR"
                exit 1
            }
        }
    }
}

# Function to install bundled Nerd Fonts
function Install-BundledNerdFonts {
    Write-ColorMessage "Using bundled Nerd Fonts as fallback..." "INFO"
    
    # Get the script's directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $fontsDir = Join-Path -Path $scriptDir -ChildPath "fonts"
    
    if (-not (Test-Path -Path $fontsDir -PathType Container)) {
        Write-ColorMessage "Bundled fonts directory not found at: $fontsDir" "ERROR"
        return $false
    }
    
    # Check if there are font files in the directory
    $fontFiles = Get-ChildItem -Path $fontsDir -Filter "*.ttf" -ErrorAction SilentlyContinue
    if ($fontFiles.Count -eq 0) {
        Write-ColorMessage "No bundled font files found in: $fontsDir" "ERROR"
        return $false
    }
    
    if ($script:OS -eq "Windows") {
        # On Windows, we need to use the shell to install fonts
        Write-ColorMessage "Installing bundled fonts on Windows..."
        
        # Windows font directory
        $fontDestination = Join-Path $env:windir "Fonts"
        
        # Registry key for font registration
        $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        
        # Check for admin rights
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            Write-ColorMessage "Administrator privileges required to install fonts system-wide." "WARNING"
            Write-ColorMessage "Would you like to open the fonts folder for manual installation? (y/n)"
            $response = Read-Host
            if ($response -eq "y") {
                # Open the fonts directory for manual installation
                Invoke-Item $fontsDir
                Write-ColorMessage "Please install the fonts manually by selecting all files, right-clicking, and selecting 'Install'" "INFO"
                Write-ColorMessage "Press Enter when done..." "INFO"
                Read-Host | Out-Null
                return $true
            }
            return $false
        }
        
        # Install fonts with admin rights
        foreach ($fontFile in $fontFiles) {
            $fontName = [System.IO.Path]::GetFileNameWithoutExtension($fontFile.Name)
            $fontSourcePath = $fontFile.FullName
            $fontDestPath = Join-Path -Path $fontDestination -ChildPath $fontFile.Name
            
            try {
                # Copy the font to the Windows Fonts folder
                Copy-Item -Path $fontSourcePath -Destination $fontDestPath -Force
                
                # Register the font in the registry
                New-ItemProperty -Path $fontRegistryPath -Name "$fontName (TrueType)" -Value $fontFile.Name -PropertyType String -Force | Out-Null
                
                Write-ColorMessage "Installed font: $fontName" "SUCCESS"
            }
            catch {
                Write-ColorMessage "Failed to install font $fontName`: $_" "ERROR"
            }
        }
    }
    elseif ($script:OS -eq "macOS") {
        # On macOS, copy fonts to ~/Library/Fonts
        Write-ColorMessage "Installing bundled fonts to macOS user fonts directory..."
        
        $userFontsDir = Join-Path -Path $HOME -ChildPath "Library/Fonts"
        if (-not (Test-Path -Path $userFontsDir -PathType Container)) {
            New-Item -Path $userFontsDir -ItemType Directory -Force | Out-Null
        }
        
        foreach ($fontFile in $fontFiles) {
            $fontName = $fontFile.Name
            $fontDestPath = Join-Path -Path $userFontsDir -ChildPath $fontName
            
            try {
                Copy-Item -Path $fontFile.FullName -Destination $fontDestPath -Force
                Write-ColorMessage "Installed font: $fontName" "SUCCESS"
            }
            catch {
                Write-ColorMessage "Failed to install font $fontName`: $_" "ERROR"
            }
        }
    }
    
    Write-ColorMessage "Bundled fonts installed successfully" "SUCCESS"
    return $true
}

# Function to install Nerd Font
function Install-NerdFont {
    Write-ColorMessage "Checking for Nerd Font..."
    $fontInstalled = $false
    
    # Use Oh My Posh to install Hack Nerd Font
    if ($script:OS -eq "Windows") {
        if (-not (Test-Path -Path "$env:LOCALAPPDATA\oh-my-posh\fonts\Hack.zip" -PathType Leaf)) {
            Write-ColorMessage "Installing Hack Nerd Font..."
            try {
                oh-my-posh font install Hack
                $fontInstalled = $true
                Write-ColorMessage "Hack Nerd Font installed successfully" "SUCCESS"
            }
            catch {
                Write-ColorMessage "Failed to install Hack Nerd Font via Oh My Posh: $_" "WARNING"
                Write-ColorMessage "Trying to use bundled fonts..." "INFO"
                $fontInstalled = Install-BundledNerdFonts
            }
        }
        else {
            $fontInstalled = $true
            Write-ColorMessage "Hack Nerd Font is already installed" "SUCCESS"
        }
    }
    elseif ($script:OS -eq "macOS") {
        # Check if font is installed via Homebrew
        $fontInstalled = $false
        
        if (Test-CommandExists brew) {
            $brewFonts = brew list --cask 2>$null
            if ($brewFonts -match "font-hack-nerd-font") {
                $fontInstalled = $true
            }
        }
        
        if (-not $fontInstalled) {
            Write-ColorMessage "Installing Hack Nerd Font..."
            if (Test-CommandExists brew) {
                try {
                    brew tap homebrew/cask-fonts
                    brew install --cask font-hack-nerd-font
                    $fontInstalled = $true
                }
                catch {
                    Write-ColorMessage "Failed to install Hack Nerd Font via Homebrew: $_" "WARNING"
                    Write-ColorMessage "Trying to use bundled fonts..." "INFO"
                    $fontInstalled = Install-BundledNerdFonts
                }
            }
            else {
                # Use Oh My Posh font installer as fallback
                try {
                    oh-my-posh font install Hack
                    $fontInstalled = $true
                }
                catch {
                    Write-ColorMessage "Failed to install Hack Nerd Font via Oh My Posh: $_" "WARNING"
                    Write-ColorMessage "Trying to use bundled fonts..." "INFO"
                    $fontInstalled = Install-BundledNerdFonts
                }
            }
            
            if ($fontInstalled) {
                Write-ColorMessage "Hack Nerd Font installed successfully" "SUCCESS"
            }
        }
        else {
            Write-ColorMessage "Hack Nerd Font is already installed" "SUCCESS"
        }
    }
    
    # Reminder to configure terminal
    if ($fontInstalled) {
        Write-ColorMessage "Remember to configure your terminal to use 'Hack Nerd Font'" "INFO"
    }
    else {
        Write-ColorMessage "Could not install Nerd Font through any method." "WARNING"
        Write-ColorMessage "You'll need to install a Nerd Font manually from https://www.nerdfonts.com/" "WARNING"
    }
    
    return $fontInstalled
}

# Function to clone the repository
function Clone-Repository {
    # Create directory for Oh My Posh themes
    if ($script:OS -eq "Windows") {
        $themesDir = Join-Path $env:USERPROFILE ".oh-my-posh-themes"
    }
    else {
        $themesDir = Join-Path $HOME ".oh-my-posh-themes"
    }
    
    $repoDir = Join-Path $themesDir "kartikshankar-ohmyposh-theme"
    
    if (-not (Test-Path -Path $themesDir)) {
        Write-ColorMessage "Creating themes directory..."
        New-Item -Path $themesDir -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $repoDir)) {
        Write-ColorMessage "Cloning theme repository..."
        git clone https://github.com/kartikshankar/kartikshankar-ohmyposh-theme.git $repoDir
        Write-ColorMessage "Theme repository cloned successfully" "SUCCESS"
    }
    else {
        Write-ColorMessage "Updating existing theme repository..."
        Set-Location $repoDir
        git pull
        Write-ColorMessage "Theme repository updated successfully" "SUCCESS"
    }
    
    $script:themePath = Join-Path $repoDir "kartikshankar.omp.json"
    
    # Format path correctly for the current OS
    if ($script:OS -eq "macOS") {
        $script:themePath = $script:themePath.Replace("\", "/")
    }
    
    Write-ColorMessage "Theme path: $script:themePath" "SUCCESS"
}

# Function to configure PowerShell
function Configure-PowerShell {
    # Check if profile exists, create if it doesn't
    if (-not (Test-Path -Path $PROFILE)) {
        Write-ColorMessage "Creating PowerShell profile..."
        New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    }
    
    # Check if the configuration is already in the profile
    $configLine = "oh-my-posh init pwsh --config '$script:themePath' | Invoke-Expression"
    $profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
    
    if ($profileContent -like "*$script:themePath*") {
        Write-ColorMessage "PowerShell profile already configured to use the theme" "SUCCESS"
    }
    else {
        # Check if profile already has Oh My Posh configuration
        if ($profileContent -like "*oh-my-posh init*") {
            Write-ColorMessage "Updating existing Oh My Posh configuration..."
            $newContent = $profileContent -replace "oh-my-posh init.*", $configLine
            Set-Content -Path $PROFILE -Value $newContent
        }
        else {
            Write-ColorMessage "Adding Oh My Posh configuration to PowerShell profile..."
            Add-Content -Path $PROFILE -Value "`n# Oh My Posh configuration"
            Add-Content -Path $PROFILE -Value $configLine
        }
        
        Write-ColorMessage "PowerShell profile configured successfully" "SUCCESS"
    }
}

# Function to configure Command Prompt (Windows only)
function Configure-Cmd {
    if (-not ($script:OS -eq "Windows")) {
        return
    }
    
    Write-ColorMessage "Configuring Command Prompt..."
    
    # Create Lua script for CMD
    $luaScript = @"
load(io.popen('oh-my-posh init cmd --config "$($script:themePath.Replace('\', '/'))"'):read("*a"))()
"@
    
    $luaPath = Join-Path $env:USERPROFILE "oh-my-posh.lua"
    Set-Content -Path $luaPath -Value $luaScript
    
    # Set registry key for CMD
    $regPath = "HKCU:\Software\Microsoft\Command Processor"
    $regName = "AutoRun"
    $regValue = "%USERPROFILE%\oh-my-posh.lua"
    
    # Check if the key already exists
    $existingValue = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
    
    if ($existingValue -and $existingValue.AutoRun -eq $regValue) {
        Write-ColorMessage "Command Prompt already configured to use the theme" "SUCCESS"
    }
    else {
        Set-ItemProperty -Path $regPath -Name $regName -Value $regValue
        Write-ColorMessage "Command Prompt configured successfully" "SUCCESS"
    }
}

# Function to configure Git Bash (Windows only)
function Configure-GitBash {
    if (-not ($script:OS -eq "Windows")) {
        return
    }
    
    Write-ColorMessage "Configuring Git Bash..."
    
    # Path to .bashrc in Git Bash
    $gitBashProfile = Join-Path $env:USERPROFILE ".bashrc"
    
    # Create the file if it doesn't exist
    if (-not (Test-Path -Path $gitBashProfile)) {
        New-Item -Path $gitBashProfile -ItemType File -Force | Out-Null
    }
    
    # Prepare the config line - use forward slashes for Git Bash
    $themePath = $script:themePath.Replace('\', '/')
    $configLine = "eval `"$(oh-my-posh init bash --config '$themePath')`""
    
    # Check if the configuration is already in the file
    $profileContent = Get-Content -Path $gitBashProfile -Raw -ErrorAction SilentlyContinue
    
    if ($profileContent -like "*$themePath*") {
        Write-ColorMessage "Git Bash profile already configured to use the theme" "SUCCESS"
    }
    else {
        # Check if profile already has Oh My Posh configuration
        if ($profileContent -like "*oh-my-posh init*") {
            Write-ColorMessage "Updating existing Oh My Posh configuration in Git Bash profile..."
            $profileContent = ($profileContent -split "`n") | ForEach-Object {
                if ($_ -match "oh-my-posh init") {
                    $configLine
                }
                else {
                    $_
                }
            }
            $profileContent = $profileContent -join "`n"
            Set-Content -Path $gitBashProfile -Value $profileContent
        }
        else {
            Write-ColorMessage "Adding Oh My Posh configuration to Git Bash profile..."
            Add-Content -Path $gitBashProfile -Value "`n# Oh My Posh configuration"
            Add-Content -Path $gitBashProfile -Value $configLine
        }
        
        Write-ColorMessage "Git Bash profile configured successfully" "SUCCESS"
    }
}

# Function to apply theme to current PowerShell session
function Apply-Theme {
    Write-ColorMessage "Applying theme to current PowerShell session..."
    oh-my-posh init pwsh --config $script:themePath | Invoke-Expression
    Write-ColorMessage "Theme applied to current PowerShell session" "SUCCESS"
}

# Main function
function Main {
    # Detect OS
    $script:OS = Get-OperatingSystem
    
    Write-Host "`n============== Kartik's Oh My Posh Theme Installer ($script:OS) ==============`n" -ForegroundColor Magenta
    
    Write-ColorMessage "Starting installation process..."
    
    # Check if running as admin (Windows-specific)
    if ($script:OS -eq "Windows") {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-ColorMessage "Not running as administrator. Some installations might fail." "WARNING"
        }
    }
    
    # Install dependencies based on OS
    if ($script:OS -eq "Windows") {
        Install-Winget
        Install-WindowsTerminal
    }
    elseif ($script:OS -eq "macOS") {
        Install-Homebrew
    }
    
    Install-Git
    Install-OhMyPosh
    Install-NerdFont
    
    # Clone repository and configure shells
    Clone-Repository
    Configure-PowerShell
    
    # OS-specific configurations
    if ($script:OS -eq "Windows") {
        Configure-Cmd
        Configure-GitBash
    }
    
    # Apply theme to current session
    Apply-Theme
    
    Write-Host "`n============== Installation Complete ==============`n" -ForegroundColor Magenta
    Write-ColorMessage "If you don't see the theme applied correctly, please restart your terminal."
    Write-ColorMessage "Be sure to configure your terminal app to use 'Hack Nerd Font'."
    
    if ($script:OS -eq "Windows") {
        Write-ColorMessage "For Windows Terminal, go to Settings > Profile > Appearance > Font Face > select 'Hack Nerd Font'"
    }
    elseif ($script:OS -eq "macOS") {
        Write-ColorMessage "For Terminal.app, go to Terminal > Settings > Profiles > Font > select 'Hack Nerd Font'"
        Write-ColorMessage "For iTerm2, go to iTerm2 > Settings > Profiles > Text > Font > select 'Hack Nerd Font'"
    }
}

# Run the main function
Main 