<#
.SYNOPSIS
    Behavioural tests for install.ps1.

.DESCRIPTION
    Runs install.ps1 against a throwaway profile path and inspects the result.
    Cross-platform by design: install.ps1 supports Windows and macOS, so this
    suite runs on both and skips the Windows-only assertions elsewhere.

    Exits 0 only if every assertion passes.

.EXAMPLE
    pwsh -NoProfile -File ./test-install-ps1.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Passed = 0
$script:Failed = 0
$script:Skipped = 0
$script:Failures = [System.Collections.Generic.List[string]]::new()

function Write-Section { param([string]$Name) Write-Host "`n== $Name ==" -ForegroundColor Blue }

function Assert-Pass {
    param([string]$Message)
    $script:Passed++
    Write-Host "  PASS $Message" -ForegroundColor Green
}

function Assert-Fail {
    param([string]$Message, [string]$Detail = '')
    $script:Failed++
    $script:Failures.Add($Message)
    Write-Host "  FAIL $Message" -ForegroundColor Red
    if ($Detail) { Write-Host "       $Detail" }
}

function Assert-Skip {
    param([string]$Message)
    $script:Skipped++
    Write-Host "  SKIP $Message" -ForegroundColor Yellow
}

function Assert-True {
    param([bool]$Condition, [string]$Message, [string]$Detail = '')
    if ($Condition) { Assert-Pass $Message } else { Assert-Fail $Message $Detail }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -eq $Actual) { Assert-Pass $Message }
    else { Assert-Fail $Message "expected: '$Expected'  actual: '$Actual'" }
}

function Assert-Contains {
    param([string]$Haystack, [string]$Needle, [string]$Message)
    if ($Haystack -like "*$Needle*") { Assert-Pass $Message }
    else { Assert-Fail $Message "expected to find '$Needle'" }
}

$RepoRoot    = $PSScriptRoot
$InstallPs1  = Join-Path $RepoRoot 'install.ps1'
$ThemeFile   = Join-Path $RepoRoot 'kartikshankar.omp.json'
$MarkerBegin = '# >>> kartikshankar oh-my-posh theme >>>'

$Sandbox = Join-Path ([System.IO.Path]::GetTempPath()) "omp-ps1-tests-$(Get-Random)"
New-Item -ItemType Directory -Path $Sandbox -Force | Out-Null

# Run install.ps1 in a child pwsh with $PROFILE redirected at the sandbox.
function Invoke-Installer {
    param([string]$ProfilePath, [string[]]$ExtraArgs = @())
    $argList = ($ExtraArgs + @('-Local', '-NoFont')) -join ' '
    $script = "`$PROFILE = '$ProfilePath'; . '$InstallPs1' $argList"
    & pwsh -NoProfile -Command $script 2>&1 | Out-String
}

try {
    # -----------------------------------------------------------------------
    Write-Section 'Preconditions'
    # -----------------------------------------------------------------------

    Assert-True (Test-Path $InstallPs1) 'install.ps1 exists'
    Assert-True (Test-Path $ThemeFile)  'theme file exists'

    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $InstallPs1, [ref]$null, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count -eq 0) {
        Assert-Pass 'install.ps1 parses without syntax errors'
    } else {
        Assert-Fail 'install.ps1 parses without syntax errors' ($parseErrors[0].Message)
    }

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Assert-Fail 'oh-my-posh is available' 'install it before running this suite'
        throw 'oh-my-posh missing'
    }
    Assert-Pass 'oh-my-posh is available'

    # -----------------------------------------------------------------------
    Write-Section 'Dry run writes nothing'
    # -----------------------------------------------------------------------

    $dryProfile = Join-Path $Sandbox 'dry_profile.ps1'
    Set-Content -LiteralPath $dryProfile -Value "# original`n`$env:EDITOR = 'vim'"
    $before = (Get-FileHash -LiteralPath $dryProfile -Algorithm SHA256).Hash

    Invoke-Installer -ProfilePath $dryProfile -ExtraArgs @('-DryRun') | Out-Null

    $after = (Get-FileHash -LiteralPath $dryProfile -Algorithm SHA256).Hash
    Assert-Equal $before $after '-DryRun leaves the profile byte-identical'
    Assert-True (-not (Get-ChildItem -Path $Sandbox -Filter 'dry_profile.ps1.bak-*' -ErrorAction SilentlyContinue)) `
        '-DryRun creates no backup'

    # -----------------------------------------------------------------------
    Write-Section 'Configures the profile and preserves existing content'
    # -----------------------------------------------------------------------

    $profilePath = Join-Path $Sandbox 'profile.ps1'
    @(
        '# my existing profile'
        'Set-Alias ll Get-ChildItem'
        "`$env:EDITOR = 'vim'"
        "oh-my-posh init pwsh --config ~/some-other-theme.json | Invoke-Expression"
    ) -join "`n" | Set-Content -LiteralPath $profilePath

    $log = Invoke-Installer -ProfilePath $profilePath
    $content = Get-Content -LiteralPath $profilePath -Raw

    Assert-Contains $content 'Set-Alias ll'          'existing alias survives'
    Assert-Contains $content "`$env:EDITOR = 'vim'"  'existing EDITOR assignment survives'
    Assert-Contains $content 'some-other-theme.json' 'an unrelated oh-my-posh line is left intact'
    Assert-Contains $content $MarkerBegin            'the managed block is added'
    Assert-Contains $content 'kartikshankar.omp.json' 'the block references the theme file'
    Assert-Contains $log     "another 'oh-my-posh init' line" 'a conflicting init line is reported'

    $backups = @(Get-ChildItem -Path $Sandbox -Filter 'profile.ps1.bak-*' -ErrorAction SilentlyContinue)
    Assert-Equal 1 $backups.Count 'exactly one timestamped backup is written'

    # -----------------------------------------------------------------------
    Write-Section 'Idempotency'
    # -----------------------------------------------------------------------

    $firstHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
    Invoke-Installer -ProfilePath $profilePath | Out-Null
    $secondHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

    Assert-Equal $firstHash $secondHash 'a second run leaves the profile unchanged'

    $backupsAfter = @(Get-ChildItem -Path $Sandbox -Filter 'profile.ps1.bak-*' -ErrorAction SilentlyContinue)
    Assert-Equal 1 $backupsAfter.Count 'a second run creates no additional backup'

    $markerCount = ([regex]::Matches((Get-Content -LiteralPath $profilePath -Raw),
                    [regex]::Escape($MarkerBegin))).Count
    Assert-Equal 1 $markerCount 'exactly one managed block exists after two runs'

    # -----------------------------------------------------------------------
    Write-Section 'Generated line is valid PowerShell'
    # -----------------------------------------------------------------------

    $initLine = (Get-Content -LiteralPath $profilePath | Where-Object { $_ -match 'oh-my-posh init pwsh' })[0]
    $lineErrors = $null
    [System.Management.Automation.Language.Parser]::ParseInput(
        $initLine, [ref]$null, [ref]$lineErrors) | Out-Null
    Assert-Equal 0 $lineErrors.Count 'the generated init line parses as PowerShell'

    # Executing it must actually produce a prompt function.
    $promptProbe = & pwsh -NoProfile -Command "$initLine; if (Test-Path Function:\prompt) { 'HAS-PROMPT' }" 2>&1 | Out-String
    Assert-Contains $promptProbe 'HAS-PROMPT' 'executing the generated line defines a prompt function'

    # -----------------------------------------------------------------------
    Write-Section 'Block replacement when the theme path changes'
    # -----------------------------------------------------------------------

    $altRepo = Join-Path $Sandbox 'altrepo'
    New-Item -ItemType Directory -Path $altRepo -Force | Out-Null
    Copy-Item $InstallPs1 (Join-Path $altRepo 'install.ps1')
    Copy-Item $ThemeFile  (Join-Path $altRepo 'kartikshankar.omp.json')

    & pwsh -NoProfile -Command "`$PROFILE = '$profilePath'; . '$(Join-Path $altRepo 'install.ps1')' -Local -NoFont" 2>&1 | Out-Null

    $moved = Get-Content -LiteralPath $profilePath -Raw
    $movedCount = ([regex]::Matches($moved, [regex]::Escape($MarkerBegin))).Count
    Assert-Equal 1 $movedCount 'changing the theme path replaces the block rather than appending'
    Assert-Contains $moved $altRepo 'the block points at the new theme path'

    # -----------------------------------------------------------------------
    Write-Section 'Windows-specific behaviour'
    # -----------------------------------------------------------------------

    $onWindows = if ($PSVersionTable.PSVersion.Major -lt 6) { $true } else { $IsWindows }

    if (-not $onWindows) {
        Assert-Skip 'not running on Windows; skipping registry and CMD assertions'
    } else {
        # The installer must create the Command Processor key when absent rather
        # than failing, and must not clobber an existing AutoRun value.
        $regPath = 'HKCU:\Software\Microsoft\Command Processor'
        Assert-True (Test-Path $regPath -IsValid) 'the CMD registry path is well formed'

        $src = Get-Content -LiteralPath $InstallPs1 -Raw
        Assert-Contains $src 'New-Item -Path $regPath -Force' 'install.ps1 creates the CMD key when missing'
        Assert-Contains $src 'Not overwriting it'             'install.ps1 refuses to clobber an existing AutoRun'

        # Per-user font install needs no elevation; confirm that path exists.
        Assert-Contains $src 'Microsoft\Windows\Fonts' 'install.ps1 supports a per-user font directory'
    }

} finally {
    Remove-Item -LiteralPath $Sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host '--------------------------------------------------'
Write-Host ("  passed: {0}   failed: {1}   skipped: {2}" -f $script:Passed, $script:Failed, $script:Skipped)

if ($script:Failed -gt 0) {
    Write-Host ''
    Write-Host '  Failed:' -ForegroundColor Red
    $script:Failures | ForEach-Object { Write-Host "    - $_" }
    Write-Host ''
    exit 1
}
Write-Host ''
exit 0
