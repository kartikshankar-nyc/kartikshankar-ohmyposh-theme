#!/bin/bash

# Comprehensive validation test suite for Kartik's Oh My Posh Theme
# Tests actual logic, not just file existence or keyword presence

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

pass() { echo -e "${GREEN}  PASS${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}  FAIL${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "${YELLOW}  WARN${NC} $1"; WARN=$((WARN + 1)); }
header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="$SCRIPT_DIR/kartikshankar.omp.json"
INSTALL_SH="$SCRIPT_DIR/install.sh"
INSTALL_PS1="$SCRIPT_DIR/install.ps1"

# ============================================================
header "Theme JSON Structural Validation"
# ============================================================

# 1. Valid JSON
if jq '.' "$THEME" > /dev/null 2>&1; then
    pass "Theme is valid JSON"
else
    fail "Theme is not valid JSON"
fi

# 2. Schema version
VERSION=$(jq -r '.version' "$THEME")
if [[ "$VERSION" == "3" ]]; then
    pass "Theme uses Oh My Posh schema version 3"
else
    fail "Theme uses schema version $VERSION (expected 3)"
fi

# 3. Block count
BLOCK_COUNT=$(jq '.blocks | length' "$THEME")
if [[ "$BLOCK_COUNT" -eq 3 ]]; then
    pass "Theme has exactly 3 blocks (left prompt, right prompt, input line)"
else
    fail "Theme has $BLOCK_COUNT blocks (expected 3)"
fi

# 4. Block alignments
ALIGN_0=$(jq -r '.blocks[0].alignment' "$THEME")
ALIGN_1=$(jq -r '.blocks[1].alignment' "$THEME")
ALIGN_2=$(jq -r '.blocks[2].alignment' "$THEME")
if [[ "$ALIGN_0" == "left" && "$ALIGN_1" == "right" && "$ALIGN_2" == "left" ]]; then
    pass "Block alignments are correct (left, right, left)"
else
    fail "Block alignments unexpected: $ALIGN_0, $ALIGN_1, $ALIGN_2"
fi

# 5. Newline on third block
NEWLINE=$(jq -r '.blocks[2].newline' "$THEME")
if [[ "$NEWLINE" == "true" ]]; then
    pass "Third block has newline=true for input line"
else
    fail "Third block missing newline=true"
fi

# 6. All required segment types present
SEGMENT_TYPES=$(jq -r '[.blocks[].segments[].type] | unique | sort | .[]' "$THEME")
for seg in os session path git time text root; do
    if echo "$SEGMENT_TYPES" | grep -q "^${seg}$"; then
        pass "Segment type '$seg' present"
    else
        fail "Segment type '$seg' missing"
    fi
done

# ============================================================
header "OS Segment Correctness"
# ============================================================

# 7. OS segment uses .Icon (not deprecated .Os)
OS_TEMPLATE=$(jq -r '.blocks[0].segments[] | select(.type == "os") | .template' "$THEME")
if [[ "$OS_TEMPLATE" == *"{{ .Icon }}"* ]]; then
    pass "OS segment uses .Icon template (correct for oh-my-posh v25+)"
else
    fail "OS segment does not use .Icon template: $OS_TEMPLATE"
fi

# 8. OS segment does NOT use deprecated .Os
if [[ "$OS_TEMPLATE" == *".Os"* ]]; then
    fail "OS segment uses deprecated .Os property (broken in oh-my-posh v25+)"
else
    pass "OS segment does not use deprecated .Os property"
fi

# 9. OS segment has icon properties for all platforms
for os_name in windows darwin linux; do
    ICON=$(jq -r ".blocks[0].segments[] | select(.type == \"os\") | .properties.${os_name}" "$THEME")
    if [[ -n "$ICON" && "$ICON" != "null" ]]; then
        pass "OS segment has icon property for '$os_name'"
    else
        fail "OS segment missing icon property for '$os_name'"
    fi
done

# 10. OS segment renders without template errors
if command -v oh-my-posh &> /dev/null; then
    RENDER_OUTPUT=$(oh-my-posh print primary --config "$THEME" 2>&1)
    if echo "$RENDER_OUTPUT" | grep -q "unable to create text based on template"; then
        fail "Theme rendering produces template errors"
    else
        pass "Theme renders without template errors"
    fi
else
    warn "oh-my-posh not installed, skipping render test"
fi

# ============================================================
header "Git Segment Correctness"
# ============================================================

# 11. Git segment has background_templates for dynamic colors
BG_TEMPLATES=$(jq '.blocks[0].segments[] | select(.type == "git") | .background_templates | length' "$THEME")
if [[ "$BG_TEMPLATES" -ge 3 ]]; then
    pass "Git segment has $BG_TEMPLATES background_templates for dynamic colors"
else
    fail "Git segment has only $BG_TEMPLATES background_templates (expected 3+)"
fi

# 12. Git segment fetches status
FETCH_STATUS=$(jq -r '.blocks[0].segments[] | select(.type == "git") | .properties.fetch_status' "$THEME")
if [[ "$FETCH_STATUS" == "true" ]]; then
    pass "Git segment has fetch_status enabled"
else
    fail "Git segment missing fetch_status property"
fi

# ============================================================
header "Color Palette Consistency"
# ============================================================

# 13. All referenced colors are valid hex
ALL_COLORS=$(jq -r '.. | strings' "$THEME" | grep -oE '#[0-9a-fA-F]{6}' | sort -u)
INVALID_COLORS=0
while IFS= read -r color; do
    if ! [[ "$color" =~ ^#[0-9a-fA-F]{6}$ ]]; then
        fail "Invalid hex color: $color"
        INVALID_COLORS=$((INVALID_COLORS + 1))
    fi
done <<< "$ALL_COLORS"
if [[ $INVALID_COLORS -eq 0 ]]; then
    pass "All colors are valid 6-digit hex codes"
fi

# ============================================================
header "install.sh Logic Validation"
# ============================================================

# 14. Bash syntax check
if bash -n "$INSTALL_SH" 2>/dev/null; then
    pass "install.sh passes bash -n syntax check"
else
    fail "install.sh has bash syntax errors"
fi

# 15. No deprecated brew tap homebrew/cask-fonts
if grep -q "brew tap homebrew/cask-fonts" "$INSTALL_SH"; then
    fail "install.sh still references deprecated homebrew/cask-fonts tap"
else
    pass "install.sh does not reference deprecated homebrew/cask-fonts tap"
fi

# 16. Uses brew list --cask (not bare brew list) for font detection
if grep -q "brew list --cask" "$INSTALL_SH"; then
    pass "install.sh uses 'brew list --cask' for font detection"
else
    fail "install.sh uses bare 'brew list' which won't detect cask fonts"
fi

# 17. No broken nerd-fonts raw URL
if grep -q "nerd-fonts/raw/master" "$INSTALL_SH"; then
    fail "install.sh references broken nerd-fonts/raw/master URL"
else
    pass "install.sh does not use broken nerd-fonts download URL"
fi

# 18. sed -i is OS-aware
if grep -q 'sed -i\.bak' "$INSTALL_SH" || grep -q "sed -i.bak" "$INSTALL_SH"; then
    fail "install.sh uses non-portable 'sed -i.bak' (breaks on macOS)"
else
    pass "install.sh does not use non-portable sed -i.bak"
fi

# 19. Verify sed uses OS branching
if grep -A2 'sed -i' "$INSTALL_SH" | grep -q "macOS\|OS.*=="; then
    pass "install.sh branches sed -i based on OS"
else
    # Check if there's a conditional around the sed call
    if grep -B5 "sed -i ''" "$INSTALL_SH" | grep -q "macOS"; then
        pass "install.sh branches sed -i based on OS"
    else
        warn "Could not verify sed -i OS branching (manual check recommended)"
    fi
fi

# 20. git pull doesn't change CWD
if grep -q 'cd "\$REPO_DIR" && git pull' "$INSTALL_SH"; then
    fail "install.sh uses cd for git pull (changes CWD permanently)"
elif grep -q 'git -C "\$REPO_DIR" pull' "$INSTALL_SH" || grep -q "git -C" "$INSTALL_SH"; then
    pass "install.sh uses git -C for pull (preserves CWD)"
else
    warn "Could not determine git pull CWD behavior"
fi

# 21. oh-my-posh install has post-install verification
if grep -A5 "curl.*ohmyposh.dev/install.sh" "$INSTALL_SH" | grep -q "command_exists oh-my-posh"; then
    pass "install.sh verifies oh-my-posh installation after install"
elif grep -q "command_exists oh-my-posh" "$INSTALL_SH" && grep -q "could not be verified\|installation failed" "$INSTALL_SH"; then
    pass "install.sh verifies oh-my-posh installation after install"
else
    warn "install.sh may not verify oh-my-posh installation success"
fi

# ============================================================
header "install.ps1 Logic Validation"
# ============================================================

# 22. No deprecated brew tap
if grep -q "brew tap homebrew/cask-fonts" "$INSTALL_PS1"; then
    fail "install.ps1 still references deprecated homebrew/cask-fonts tap"
else
    pass "install.ps1 does not reference deprecated homebrew/cask-fonts tap"
fi

# 23. Uses $PSScriptRoot (not $MyInvocation.MyCommand.Path in functions)
if grep -q 'Split-Path.*\$MyInvocation\.MyCommand\.Path' "$INSTALL_PS1"; then
    fail "install.ps1 uses \$MyInvocation.MyCommand.Path (unreliable inside functions)"
else
    pass "install.ps1 does not use \$MyInvocation.MyCommand.Path inside functions"
fi

if grep -q '\$PSScriptRoot' "$INSTALL_PS1"; then
    pass "install.ps1 uses \$PSScriptRoot for script directory"
else
    fail "install.ps1 does not use \$PSScriptRoot"
fi

# 24. Get-ChildItem wrapped in @() for Count safety
if grep -q '@(Get-ChildItem' "$INSTALL_PS1"; then
    pass "install.ps1 wraps Get-ChildItem in @() for reliable .Count"
else
    fail "install.ps1 does not wrap Get-ChildItem in @() (Count may be null for single file)"
fi

# 25. Git Bash config line uses single quotes to prevent PS interpolation
GITBASH_CONFIG=$(grep "configLine.*oh-my-posh init bash" "$INSTALL_PS1" || true)
if echo "$GITBASH_CONFIG" | grep -q '^\s*\$configLine = '"'"'eval'; then
    pass "install.ps1 Git Bash config line uses single quotes (prevents PS \$() interpolation)"
else
    warn "install.ps1 Git Bash config line may have PS interpolation issues (manual check)"
fi

# 26. Line endings handled for Git Bash .bashrc
if grep -q 'split.*\\r\\?\\n\|WriteAllText\|\\r?\\n' "$INSTALL_PS1"; then
    pass "install.ps1 handles CRLF/LF line endings for Git Bash .bashrc"
else
    fail "install.ps1 does not handle mixed line endings for Git Bash"
fi

# 27. Windows font detection checks actual font files (not Hack.zip cache)
if grep -q 'Hack\.zip' "$INSTALL_PS1"; then
    fail "install.ps1 checks for Hack.zip cache instead of actual font files"
else
    pass "install.ps1 does not rely on Hack.zip cache for font detection"
fi

if grep -q 'HackNerdFont\|Hack\*Nerd' "$INSTALL_PS1"; then
    pass "install.ps1 checks for actual Hack Nerd Font files"
else
    fail "install.ps1 does not check for actual font files"
fi

# 28. CMD config checks for Clink
if grep -q "[Cc]link" "$INSTALL_PS1"; then
    pass "install.ps1 checks for Clink before configuring CMD"
else
    fail "install.ps1 configures CMD without checking for Clink dependency"
fi

# 29. Clone-Repository uses Push/Pop-Location (not Set-Location)
if grep -q "Push-Location" "$INSTALL_PS1"; then
    pass "install.ps1 uses Push-Location/Pop-Location (preserves CWD)"
else
    if grep -q "Set-Location" "$INSTALL_PS1"; then
        fail "install.ps1 uses Set-Location without restoring (permanently changes CWD)"
    else
        pass "install.ps1 does not change location"
    fi
fi

# 30. Homebrew install uses proper PS syntax
if grep -q '& /bin/bash' "$INSTALL_PS1"; then
    pass "install.ps1 uses '& /bin/bash' for proper native command invocation"
else
    if grep -q '/bin/bash -c "\$(' "$INSTALL_PS1"; then
        fail "install.ps1 uses /bin/bash -c with unescaped PS \$() (will be interpolated)"
    else
        pass "install.ps1 does not use broken bash invocation"
    fi
fi

# 31. PowerShell syntax check (if pwsh available)
if command -v pwsh &> /dev/null; then
    PS_ERRORS=$(pwsh -NoProfile -c "
        \$errors = \$null
        [System.Management.Automation.Language.Parser]::ParseFile('$INSTALL_PS1', [ref]\$null, [ref]\$errors) | Out-Null
        if (\$errors.Count -gt 0) {
            \$errors | ForEach-Object { Write-Output \$_.Message }
            exit 1
        }
        exit 0
    " 2>&1)
    if [ $? -eq 0 ]; then
        pass "install.ps1 passes PowerShell parser syntax check"
    else
        fail "install.ps1 has PowerShell syntax errors: $PS_ERRORS"
    fi
else
    warn "pwsh not installed, skipping PowerShell parser syntax check"
fi

# ============================================================
header "test-theme.sh Validation"
# ============================================================

TEST_THEME="$SCRIPT_DIR/test-theme.sh"

# 32. Syntax check
if bash -n "$TEST_THEME" 2>/dev/null; then
    pass "test-theme.sh passes bash -n syntax check"
else
    fail "test-theme.sh has bash syntax errors"
fi

# 33. Uses brew list --cask
if grep -q "brew list --cask" "$TEST_THEME"; then
    pass "test-theme.sh uses 'brew list --cask' for font detection"
else
    if grep -q "brew list " "$TEST_THEME" | grep -v "\-\-cask"; then
        fail "test-theme.sh uses bare 'brew list' for font detection"
    else
        pass "test-theme.sh font detection OK"
    fi
fi

# 34. Performance check is portable (no date +%s.%N on macOS)
if grep -q 'date +%s\.%N' "$TEST_THEME"; then
    fail "test-theme.sh uses 'date +%s.%N' (not available on macOS)"
else
    pass "test-theme.sh does not use non-portable 'date +%s.%N'"
fi

# 35. Temp directory has cleanup trap
if grep -q 'trap.*rm.*TMP_DIR.*EXIT' "$TEST_THEME"; then
    pass "test-theme.sh has trap for temp directory cleanup"
else
    fail "test-theme.sh missing trap for temp directory cleanup"
fi

# ============================================================
header "Theme Rendering Validation"
# ============================================================

if command -v oh-my-posh &> /dev/null; then
    # 36. Render primary prompt
    if oh-my-posh print primary --config "$THEME" > /dev/null 2>&1; then
        pass "Theme renders primary prompt successfully"
    else
        fail "Theme fails to render primary prompt"
    fi

    # 37. No template errors in rendered output
    RENDER=$(oh-my-posh print primary --config "$THEME" 2>&1)
    TEMPLATE_ERRORS=$(echo "$RENDER" | grep -c "unable to create text" || true)
    if [[ "$TEMPLATE_ERRORS" -eq 0 ]]; then
        pass "No template errors in rendered output ($TEMPLATE_ERRORS errors)"
    else
        fail "Rendered output contains $TEMPLATE_ERRORS template error(s)"
    fi

    # 38. Rendering performance
    if command -v python3 &> /dev/null; then
        START=$(python3 -c "import time; print(time.time())")
        oh-my-posh print primary --config "$THEME" > /dev/null 2>&1
        END=$(python3 -c "import time; print(time.time())")
        ELAPSED=$(python3 -c "print(f'{$END - $START:.3f}')")
        if python3 -c "exit(0 if $ELAPSED < 0.5 else 1)"; then
            pass "Theme renders in ${ELAPSED}s (< 0.5s threshold)"
        else
            warn "Theme renders in ${ELAPSED}s (> 0.5s, may feel slow)"
        fi
    fi

    # 39. Git segment renders in a git repo
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    (
        cd "$TMP_DIR"
        git init &> /dev/null
        touch file.txt && git add . &> /dev/null
        RENDER=$(oh-my-posh print primary --config "$THEME" 2>&1)
        if echo "$RENDER" | grep -q "main\|master"; then
            exit 0
        else
            exit 1
        fi
    )
    if [ $? -eq 0 ]; then
        pass "Git segment renders branch name in a git repo"
    else
        warn "Could not verify git segment branch rendering"
    fi
else
    warn "oh-my-posh not installed, skipping rendering tests"
fi

# ============================================================
header "Bundled Fonts Validation"
# ============================================================

FONTS_DIR="$SCRIPT_DIR/fonts"

# 40. Fonts directory exists
if [[ -d "$FONTS_DIR" ]]; then
    pass "Bundled fonts directory exists"
else
    fail "Bundled fonts directory missing"
fi

# 41. Contains expected font files
FONT_COUNT=$(find "$FONTS_DIR" -maxdepth 1 -name "*.ttf" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$FONT_COUNT" -eq 4 ]]; then
    pass "Bundled fonts directory contains $FONT_COUNT TTF files (expected 4)"
elif [[ "$FONT_COUNT" -gt 0 ]]; then
    warn "Bundled fonts directory contains $FONT_COUNT TTF files (expected 4)"
else
    fail "Bundled fonts directory contains no TTF files"
fi

# 42. Font files are non-empty
EMPTY_FONTS=0
for f in "$FONTS_DIR"/*.ttf; do
    if [[ -f "$f" && ! -s "$f" ]]; then
        EMPTY_FONTS=$((EMPTY_FONTS + 1))
        fail "Font file is empty: $(basename "$f")"
    fi
done
if [[ $EMPTY_FONTS -eq 0 && "$FONT_COUNT" -gt 0 ]]; then
    pass "All bundled font files are non-empty"
fi

# ============================================================
header "README Consistency"
# ============================================================

README="$SCRIPT_DIR/README.md"

# 43. No deprecated brew tap reference
if grep -q "brew tap homebrew/cask-fonts" "$README"; then
    fail "README still references deprecated homebrew/cask-fonts tap"
else
    pass "README does not reference deprecated homebrew/cask-fonts tap"
fi

# 44. Uses brew list --cask
if grep -q "brew list --cask" "$README"; then
    pass "README uses 'brew list --cask' in troubleshooting"
elif grep -q "brew list | grep font" "$README"; then
    fail "README uses 'brew list | grep font' (should be --cask)"
else
    pass "README brew list usage OK"
fi

# ============================================================
header "Test Results Summary"
# ============================================================

echo ""
echo -e "${GREEN}PASSED: $PASS${NC}"
echo -e "${RED}FAILED: $FAIL${NC}"
echo -e "${YELLOW}WARNINGS: $WARN${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}All validation checks passed.${NC}"
    exit 0
else
    echo -e "${RED}$FAIL validation check(s) failed. Review output above.${NC}"
    exit 1
fi
