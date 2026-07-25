<#
.SYNOPSIS
    Installer for Kartik's Oh My Posh theme.

.DESCRIPTION
    Installs Oh My Posh and the Hack Nerd Font, then configures PowerShell and,
    on Windows, Command Prompt (via Clink) and Git Bash.

    Supports Windows and macOS. On Linux, use install.sh instead.

.PARAMETER NoFont
    Skip Nerd Font installation.

.PARAMETER Local
    Use the theme file next to this script instead of cloning into
    ~/.oh-my-posh-themes. Implied when the theme file is present alongside it.

.PARAMETER DryRun
    Report what would change without writing anything.

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [switch]$NoFont,
    [switch]$Local,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoUrl     = 'https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme.git'
$ThemeFile   = 'kartikshankar.omp.json'
$InstallDir  = Join-Path $HOME '.oh-my-posh-themes/kartikshankar-ohmyposh-theme'

# Our configuration is delimited by these markers so re-running replaces exactly
# our block and never rewrites unrelated lines in the user's profile.
$MarkerBegin = '# >>> kartikshankar oh-my-posh theme >>>'
$MarkerEnd   = '# <<< kartikshankar oh-my-posh theme <<<'

$script:OS              = 'Unknown'
$script:ThemePath       = ''
$script:ConfiguredFiles = [System.Collections.Generic.List[string]]::new()
$script:FontOk          = $false

# ---------------------------------------------------------------- output ----

function Write-Info    { param([string]$Message) Write-Host "[INFO] $Message"    -ForegroundColor Cyan }
function Write-Ok      { param([string]$Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warn    { param([string]$Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Err     { param([string]$Message) Write-Host "[ERROR] $Message"   -ForegroundColor Red }

function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# Native executables set $LASTEXITCODE; they do not throw, so try/catch around
# them silently "succeeds" on failure. Always test the exit code instead.
function Invoke-Native {
    param(
        [Parameter(Mandatory)][scriptblock]$Command,
        [string]$What = 'command'
    )
    try {
        & $Command 2>&1 | Out-Null
    } catch {
        Write-Warn "$What failed: $($_.Exception.Message)"
        return $false
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "$What failed with exit code $LASTEXITCODE"
        return $false
    }
    return $true
}

# -------------------------------------------------------------- platform ----

function Get-CurrentOS {
    # $IsWindows/$IsMacOS exist in PowerShell 6+. Windows PowerShell 5.1 is
    # always Windows and does not define them.
    if ($PSVersionTable.PSVersion.Major -lt 6) { return 'Windows' }
    if ($IsWindows) { return 'Windows' }
    if ($IsMacOS)   { return 'macOS' }
    if ($IsLinux)   { return 'Linux' }
    return 'Unknown'
}

function Test-Administrator {
    if ($script:OS -ne 'Windows') { return $false }
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ------------------------------------------------------------ oh-my-posh ----

function Install-OhMyPosh {
    if (Test-CommandExists 'oh-my-posh') {
        Write-Ok "Oh My Posh is installed ($(oh-my-posh --version))"
        return
    }
    Write-Info 'Installing Oh My Posh...'
    if ($DryRun) { Write-Info '[dry-run] would install Oh My Posh'; return }

    $installed = $false
    if ($script:OS -eq 'Windows') {
        if (Test-CommandExists 'winget') {
            $installed = Invoke-Native { winget install JanDeDobbeleer.OhMyPosh -e `
                --accept-source-agreements --accept-package-agreements } 'winget install of Oh My Posh'
            # winget updates the machine PATH; refresh it for this session.
            $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                        [Environment]::GetEnvironmentVariable('Path', 'User')
        }
        if (-not $installed) {
            Write-Info 'Falling back to the official installer script...'
            Invoke-Expression (Invoke-RestMethod -Uri 'https://ohmyposh.dev/install.ps1')
        }
    } elseif ($script:OS -eq 'macOS') {
        if (Test-CommandExists 'brew') {
            $installed = Invoke-Native { brew install oh-my-posh } 'Homebrew install of Oh My Posh'
        }
        if (-not $installed) {
            Write-Info 'Falling back to the official installer script...'
            Invoke-Expression (Invoke-RestMethod -Uri 'https://ohmyposh.dev/install.ps1')
        }
    }

    if (-not (Test-CommandExists 'oh-my-posh')) {
        throw 'Oh My Posh installation failed. Install it manually: https://ohmyposh.dev/docs/installation'
    }
    Write-Ok "Oh My Posh installed ($(oh-my-posh --version))"
}

# ----------------------------------------------------------------- fonts ----

# True if the file begins with a TrueType/OpenType signature. Guards against a
# download that silently produced an HTML error page with a .ttf extension.
function Test-TrueTypeFile {
    param([Parameter(Mandatory)][string]$Path)
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        try {
            $head = [byte[]]::new(4)
            if ($fs.Read($head, 0, 4) -ne 4) { return $false }
        } finally { $fs.Dispose() }
    } catch { return $false }

    $hex = ($head | ForEach-Object { $_.ToString('x2') }) -join ''
    return $hex -in @('00010000', '74727565', '4f54544f')
}

function Test-NerdFontPresent {
    $dirs = @()
    if ($script:OS -eq 'Windows') {
        $dirs += (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts')
        $dirs += (Join-Path $env:WINDIR 'Fonts')
    } elseif ($script:OS -eq 'macOS') {
        $dirs += (Join-Path $HOME 'Library/Fonts')
        $dirs += '/Library/Fonts'
    } else {
        $dirs += (Join-Path $HOME '.local/share/fonts')
        $dirs += '/usr/share/fonts'
    }
    foreach ($d in $dirs) {
        if (-not (Test-Path -LiteralPath $d)) { continue }
        $hit = Get-ChildItem -LiteralPath $d -Recurse -Depth 2 -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match '(?i)nerd.?font' } | Select-Object -First 1
        if ($hit) { return $true }
    }
    return $false
}

function Install-BundledFont {
    $fontsDir = Join-Path $PSScriptRoot 'fonts'
    if (-not (Test-Path -LiteralPath $fontsDir -PathType Container)) {
        Write-Err "Bundled fonts directory not found: $fontsDir"
        return $false
    }

    $valid = @(Get-ChildItem -LiteralPath $fontsDir -Filter '*.ttf' -File -ErrorAction SilentlyContinue |
               Where-Object {
                   if (Test-TrueTypeFile $_.FullName) { $true }
                   else { Write-Warn "Skipping $($_.Name): not a valid TrueType file."; $false }
               })

    if ($valid.Count -eq 0) {
        Write-Err "No valid bundled font files found in $fontsDir"
        return $false
    }

    if ($DryRun) { Write-Info "[dry-run] would install $($valid.Count) bundled fonts"; return $true }

    if ($script:OS -eq 'macOS') {
        $dest = Join-Path $HOME 'Library/Fonts'
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        $valid | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $dest -Force }
        Write-Ok "Installed $($valid.Count) bundled fonts to $dest"
        return $true
    }

    if ($script:OS -eq 'Windows') {
        if (-not (Test-Administrator)) {
            # Per-user font install needs no elevation on Windows 10 1809+.
            $dest = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
            $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        } else {
            $dest = Join-Path $env:WINDIR 'Fonts'
            $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        }
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

        foreach ($f in $valid) {
            $target = Join-Path $dest $f.Name
            try {
                Copy-Item -LiteralPath $f.FullName -Destination $target -Force
                $regValue = if (Test-Administrator) { $f.Name } else { $target }
                New-ItemProperty -Path $regPath `
                    -Name "$([System.IO.Path]::GetFileNameWithoutExtension($f.Name)) (TrueType)" `
                    -Value $regValue -PropertyType String -Force | Out-Null
            } catch {
                Write-Warn "Failed to install $($f.Name): $($_.Exception.Message)"
            }
        }
        Write-Ok "Installed bundled fonts to $dest"
        return $true
    }

    return $false
}

function Install-NerdFont {
    if ($NoFont) { Write-Info 'Skipping font installation (-NoFont).'; $script:FontOk = $true; return }

    if (Test-NerdFontPresent) { Write-Ok 'A Nerd Font is already installed'; $script:FontOk = $true; return }

    Write-Info 'Installing Hack Nerd Font...'
    if ($DryRun) { Write-Info '[dry-run] would install Hack Nerd Font'; $script:FontOk = $true; return }

    if ($script:OS -eq 'macOS' -and (Test-CommandExists 'brew')) {
        Invoke-Native { brew install --cask font-hack-nerd-font } 'Homebrew font install' | Out-Null
    }
    if (-not (Test-NerdFontPresent) -and (Test-CommandExists 'oh-my-posh')) {
        Invoke-Native { oh-my-posh font install Hack } 'oh-my-posh font install' | Out-Null
    }
    if (-not (Test-NerdFontPresent)) {
        Write-Warn 'Network font installation did not succeed. Falling back to bundled fonts.'
        Install-BundledFont | Out-Null
    }

    # Verify rather than assume.
    if (Test-NerdFontPresent) {
        Write-Ok 'Hack Nerd Font installed'
        $script:FontOk = $true
    } else {
        Write-Warn 'Could not install a Nerd Font automatically.'
        Write-Warn 'Install one from https://www.nerdfonts.com/font-downloads, or install the'
        Write-Warn "files in $(Join-Path $PSScriptRoot 'fonts') manually."
        $script:FontOk = $false
    }
}

# ------------------------------------------------------------ theme file ----

function Resolve-ThemePath {
    $localTheme = Join-Path $PSScriptRoot $ThemeFile
    if ($Local -or (Test-Path -LiteralPath $localTheme -PathType Leaf)) {
        if (-not (Test-Path -LiteralPath $localTheme -PathType Leaf)) {
            throw "-Local was given but $ThemeFile is not next to this script."
        }
        $script:ThemePath = $localTheme
        Write-Info "Using theme in place: $($script:ThemePath)"
        return
    }

    if (-not (Test-CommandExists 'git')) { throw 'git is required to fetch the theme.' }

    if ($DryRun) {
        $script:ThemePath = Join-Path $InstallDir $ThemeFile
        Write-Info "[dry-run] would clone into $InstallDir"
        return
    }

    if (Test-Path -LiteralPath (Join-Path $InstallDir '.git')) {
        Write-Info 'Updating existing theme checkout...'
        if (-not (Invoke-Native { git -C $InstallDir pull --ff-only } 'git pull')) {
            Write-Warn 'Could not update the existing checkout. Continuing with the current copy.'
        }
    } else {
        Write-Info "Cloning theme into $InstallDir..."
        New-Item -ItemType Directory -Path (Split-Path $InstallDir -Parent) -Force | Out-Null
        if (-not (Invoke-Native { git clone --depth 1 $RepoUrl $InstallDir } 'git clone')) {
            throw "Failed to clone $RepoUrl"
        }
    }

    $script:ThemePath = Join-Path $InstallDir $ThemeFile
    if (-not (Test-Path -LiteralPath $script:ThemePath)) {
        throw "Theme file missing after checkout: $($script:ThemePath)"
    }
}

# ----------------------------------------------------------- file editing ----

# Replace only our marked block, preserving everything else in the file.
function Set-ManagedBlock {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Line,
        [string]$Newline = "`n"
    )

    if ($DryRun) {
        Write-Info "[dry-run] would configure ${Path} with:"
        Write-Host "    $Line"
        return
    }

    New-Item -ItemType Directory -Path (Split-Path $Path -Parent) -Force | Out-Null
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType File -Path $Path -Force | Out-Null }

    $existing = @(Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)

    if (($existing -contains $Line) -and ($existing -contains $MarkerBegin)) {
        Write-Ok "$Path is already configured"
        $script:ConfiguredFiles.Add($Path)
        return
    }

    $backup = "$Path.bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item -LiteralPath $Path -Destination $backup -Force

    $kept = [System.Collections.Generic.List[string]]::new()
    $skip = $false
    foreach ($l in $existing) {
        if ($l -eq $MarkerBegin) { $skip = $true;  continue }
        if ($l -eq $MarkerEnd)   { $skip = $false; continue }
        if (-not $skip) { $kept.Add($l) }
    }
    $kept.Add('')
    $kept.Add($MarkerBegin)
    $kept.Add($Line)
    $kept.Add($MarkerEnd)

    [System.IO.File]::WriteAllText($Path, ($kept -join $Newline) + $Newline)
    Write-Ok "Configured $Path (backup: $(Split-Path $backup -Leaf))"
    $script:ConfiguredFiles.Add($Path)

    $stray = $kept | Where-Object { $_ -match 'oh-my-posh init' -and $_ -ne $Line }
    if ($stray) {
        Write-Warn "$Path contains another 'oh-my-posh init' line outside our block."
        Write-Warn 'Remove it if the prompt does not look right.'
    }
}

function Set-PowerShellProfile {
    $line = "oh-my-posh init pwsh --config '$($script:ThemePath)' | Invoke-Expression"
    Set-ManagedBlock -Path $PROFILE -Line $line -Newline ([Environment]::NewLine)
}

function Set-GitBashProfile {
    if ($script:OS -ne 'Windows') { return }
    $bashrc = Join-Path $env:USERPROFILE '.bashrc'
    $posix  = $script:ThemePath -replace '\\', '/'
    # Single-quoted in PowerShell so $(...) is not interpolated here; it must
    # reach the file literally for bash to evaluate.
    $line   = 'eval "$(oh-my-posh init bash --config ' + "'$posix'" + ')"'
    # Git Bash needs LF endings.
    Set-ManagedBlock -Path $bashrc -Line $line -Newline "`n"
}

function Set-CmdProfile {
    if ($script:OS -ne 'Windows') { return }

    $clink = (Test-CommandExists 'clink') -or
             (Test-Path (Join-Path $env:LOCALAPPDATA 'clink')) -or
             (Test-Path 'C:\Program Files (x86)\clink')
    if (-not $clink) {
        Write-Warn 'Clink is required for Oh My Posh in Command Prompt but was not found.'
        Write-Warn 'Install it from https://chrisant996.github.io/clink/ and re-run to enable CMD.'
        return
    }

    $posix   = $script:ThemePath -replace '\\', '/'
    $lua     = "load(io.popen('oh-my-posh init cmd --config `"$posix`"'):read(`"*a`"))()"
    $luaPath = Join-Path $env:USERPROFILE 'oh-my-posh.lua'

    if ($DryRun) { Write-Info "[dry-run] would write $luaPath and set the CMD AutoRun key"; return }

    Set-Content -LiteralPath $luaPath -Value $lua -Encoding ASCII

    $regPath  = 'HKCU:\Software\Microsoft\Command Processor'
    $regValue = '%USERPROFILE%\oh-my-posh.lua'
    # The key does not exist on a clean profile; Set-ItemProperty would fail.
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

    $current = (Get-ItemProperty -Path $regPath -Name 'AutoRun' -ErrorAction SilentlyContinue).AutoRun
    if ($current -eq $regValue) {
        Write-Ok 'Command Prompt is already configured'
    } elseif ($current) {
        Write-Warn "Command Prompt AutoRun is already set to: $current"
        Write-Warn "Not overwriting it. To enable the theme, chain $luaPath into that script."
    } else {
        Set-ItemProperty -Path $regPath -Name 'AutoRun' -Value $regValue
        Write-Ok 'Command Prompt configured'
    }
}

# ------------------------------------------------------------------ main ----

function Invoke-Main {
    $script:OS = Get-CurrentOS

    Write-Host ''
    Write-Host "Kartik's Oh My Posh theme installer" -ForegroundColor Magenta
    Write-Host ''
    Write-Info "Platform: $($script:OS)"

    if ($script:OS -eq 'Linux') {
        throw 'Use install.sh on Linux; this script supports Windows and macOS.'
    }
    if ($script:OS -eq 'Unknown') { throw 'Unsupported operating system.' }
    if ($script:OS -eq 'Windows' -and -not (Test-Administrator)) {
        Write-Info 'Not elevated. Fonts will be installed for the current user only.'
    }

    Install-OhMyPosh
    Install-NerdFont
    Resolve-ThemePath

    Set-PowerShellProfile
    if ($script:OS -eq 'Windows') {
        Set-CmdProfile
        Set-GitBashProfile
    }

    Write-Host ''
    Write-Host 'Installation complete' -ForegroundColor Magenta
    Write-Host "  Theme:  $($script:ThemePath)"
    if ($script:ConfiguredFiles.Count -gt 0) {
        Write-Host "  Config: $($script:ConfiguredFiles -join ', ')"
    } else {
        Write-Host '  Config: none written'
    }

    Write-Host ''
    Write-Host 'Next steps' -ForegroundColor Magenta
    Write-Host '  1. Set your terminal font to "Hack Nerd Font".'
    if ($script:OS -eq 'Windows') {
        Write-Host '     Windows Terminal: Settings > Profile > Appearance > Font face'
    } else {
        Write-Host '     iTerm2:   Settings > Profiles > Text > Font'
        Write-Host '     Terminal: Terminal > Settings > Profiles > Text > Font'
    }
    if (-not $script:FontOk) {
        Write-Warn '     No Nerd Font detected. Icons will show as boxes until you install one.'
    }
    # This script runs in its own scope; it cannot change the calling shell's
    # prompt. Say so rather than claiming the theme was applied.
    Write-Host '  2. Restart your terminal to load the new prompt.'
    Write-Host ''
}

Invoke-Main
