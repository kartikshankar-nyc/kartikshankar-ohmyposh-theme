# Oh My Posh Theme Installer for Windows
# Run as administrator for best results

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

# Function to install Winget if not available
function Install-Winget {
    if (Test-CommandExists winget) {
        Write-ColorMessage "Winget is already installed" "SUCCESS"
        return $true
    }
    
    Write-ColorMessage "Winget not found. Attempting to install..." "WARNING"
    
    # Check if we're on Windows 10 or later
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
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

# Function to install Windows Terminal if not available
function Install-WindowsTerminal {
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

# Function to install Oh My Posh
function Install-OhMyPosh {
    if (Test-CommandExists oh-my-posh) {
        Write-ColorMessage "Oh My Posh is already installed" "SUCCESS"
        return
    }
    
    Write-ColorMessage "Installing Oh My Posh..."
    
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

# Function to install Nerd Font
function Install-NerdFont {
    Write-ColorMessage "Checking for Nerd Font..."
    
    # Use Oh My Posh to install Hack Nerd Font
    if (-not (Test-Path -Path "$env:LOCALAPPDATA\oh-my-posh\fonts\Hack.zip" -PathType Leaf)) {
        Write-ColorMessage "Installing Hack Nerd Font..."
        oh-my-posh font install Hack
        Write-ColorMessage "Hack Nerd Font installed successfully" "SUCCESS"
    }
    else {
        Write-ColorMessage "Hack Nerd Font is already installed" "SUCCESS"
    }
    
    # Reminder to configure terminal
    Write-ColorMessage "Remember to configure your terminal to use 'Hack Nerd Font'" "WARNING"
}

# Function to clone the repository
function Clone-Repository {
    # Create directory for Oh My Posh themes
    $themesDir = Join-Path $env:USERPROFILE ".oh-my-posh-themes"
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

# Function to configure Command Prompt
function Configure-Cmd {
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

# Function to apply theme to current PowerShell session
function Apply-Theme {
    Write-ColorMessage "Applying theme to current PowerShell session..."
    oh-my-posh init pwsh --config $script:themePath | Invoke-Expression
    Write-ColorMessage "Theme applied to current PowerShell session" "SUCCESS"
}

# Main function
function Main {
    Write-Host "`n============== Kartik's Oh My Posh Theme Installer ==============`n" -ForegroundColor Magenta
    
    Write-ColorMessage "Starting installation process..."
    
    # Check if running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-ColorMessage "Not running as administrator. Some installations might fail." "WARNING"
    }
    
    # Install dependencies
    Install-Winget
    Install-WindowsTerminal
    Install-Git
    Install-OhMyPosh
    Install-NerdFont
    
    # Clone repository and configure shells
    Clone-Repository
    Configure-PowerShell
    Configure-Cmd
    
    # Apply theme to current session
    Apply-Theme
    
    Write-Host "`n============== Installation Complete ==============`n" -ForegroundColor Magenta
    Write-ColorMessage "If you don't see the theme applied correctly, please restart your terminal."
    Write-ColorMessage "Be sure to configure your terminal app to use 'Hack Nerd Font'."
    Write-ColorMessage "For Windows Terminal, go to Settings > Profile > Appearance > Font Face > select 'Hack Nerd Font'"
}

# Run the main function
Main 