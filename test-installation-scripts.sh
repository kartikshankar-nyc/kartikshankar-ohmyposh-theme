#!/usr/bin/env bash
#
# Installer behaviour.
#
# install.sh is executed against a throwaway HOME and its effects are inspected.
# The previous version of this file grepped the installer's source for keywords,
# which reported success while the installer wrote the theme into ~/.bash_profile
# for users whose login shell was zsh.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test-lib.sh
source "$SCRIPT_DIR/test-lib.sh"

INSTALL_SH="$SCRIPT_DIR/install.sh"
INSTALL_PS1="$SCRIPT_DIR/install.ps1"

MARKER_BEGIN="# >>> kartikshankar oh-my-posh theme >>>"

SANDBOX_ROOT=$(mktemp -d)
trap 'rm -rf "$SANDBOX_ROOT"' EXIT

# Run install.sh with a private HOME. ZDOTDIR must be overridden too: zsh honours
# it over $HOME, and leaving it set would send writes to the real home directory.
run_installer() {
    local home="$1"; shift
    mkdir -p "$home"
    env -u ZDOTDIR HOME="$home" "$@" "$INSTALL_SH" --no-font --local >"$home/.installer.log" 2>&1
    return $?
}

# ---------------------------------------------------------------------------
section "Static checks"
# ---------------------------------------------------------------------------

assert_file_exists "$INSTALL_SH"  "install.sh exists"
assert_file_exists "$INSTALL_PS1" "install.ps1 exists"
assert_true "install.sh is executable" test -x "$INSTALL_SH"
assert_true "install.sh passes bash -n" bash -n "$INSTALL_SH"

# macOS ships bash 3.2; the installer must parse under it.
if [[ -x /bin/bash ]]; then
    assert_true "install.sh parses under /bin/bash (3.2 on macOS)" /bin/bash -n "$INSTALL_SH"
fi

assert_true "install.sh sets a strict mode" grep -q "set -euo pipefail" "$INSTALL_SH"

# The old installer rewrote every line matching 'oh-my-posh init' with a greedy
# sed, destroying unrelated user configuration.
if grep -qE "sed -i.*oh-my-posh init" "$INSTALL_SH"; then
    fail "install.sh does not rewrite rc files with a greedy sed" "found a sed -i on oh-my-posh lines"
else
    pass "install.sh does not rewrite rc files with a greedy sed"
fi

# Shell selection must come from the login shell, not from the interpreter
# running the script (which is always bash).
if grep -qE 'if \[\[ -n "\$BASH_VERSION" \]\]' "$INSTALL_SH"; then
    fail "install.sh does not infer the user's shell from \$BASH_VERSION" \
         "\$BASH_VERSION is always set inside a #!/usr/bin/env bash script"
else
    pass "install.sh does not infer the user's shell from \$BASH_VERSION"
fi

if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck -x -S warning "$INSTALL_SH" >/dev/null 2>&1; then
        pass "install.sh passes shellcheck (warning severity)"
    else
        fail "install.sh passes shellcheck (warning severity)" \
             "$(shellcheck -x -S warning "$INSTALL_SH" 2>&1 | head -20)"
    fi
else
    skip "shellcheck not installed (brew install shellcheck)"
fi

# ---------------------------------------------------------------------------
section "PATH membership helper"
# ---------------------------------------------------------------------------

# If oh-my-posh is installed somewhere the login shell does not search, the
# generated init line fails with "command not found". install.sh adds a PATH
# export in that case, gated on this helper. Test it directly: the branch that
# uses it is only reachable after a real network install.
# shellcheck disable=SC1090  # path is dynamic by design
pc_test() {
    bash -c '
        path_contains_dir() {
            case ":$1:" in
                *":$2:"*) return 0 ;;
                *)        return 1 ;;
            esac
        }
        path_contains_dir "$1" "$2"
    ' _ "$1" "$2"
}

# Confirm the definition under test matches the one shipped in install.sh.
if grep -q 'path_contains_dir() {' "$INSTALL_SH" && grep -q '\*":\$2:"\*) return 0' "$INSTALL_SH"; then
    pass "install.sh defines path_contains_dir with colon-wrapped matching"
else
    fail "install.sh defines path_contains_dir with colon-wrapped matching" "helper missing or changed"
fi

assert_true  "matches a middle PATH entry" pc_test "/usr/bin:/opt/homebrew/bin:/bin" "/opt/homebrew/bin"
assert_true  "matches the first PATH entry" pc_test "/opt/homebrew/bin:/usr/bin" "/opt/homebrew/bin"
assert_true  "matches the last PATH entry"  pc_test "/usr/bin:/opt/homebrew/bin" "/opt/homebrew/bin"
assert_true  "matches a single-entry PATH"  pc_test "/opt/homebrew/bin" "/opt/homebrew/bin"
assert_false "rejects a directory not present" pc_test "/usr/bin:/bin" "$HOME/.local/bin"
# The trap a naive substring check falls into.
assert_false "rejects a partial-prefix match" pc_test "/usr/local/bin2:/bin" "/usr/local/bin"
assert_false "rejects a partial-suffix match" pc_test "/opt/x/usr/local/bin:/bin" "/usr/local/bin"
assert_false "rejects an empty PATH" pc_test "" "/usr/local/bin"

# ---------------------------------------------------------------------------
section "CLI contract"
# ---------------------------------------------------------------------------

HELP_OUT=$("$INSTALL_SH" --help 2>&1)
assert_contains "$HELP_OUT" "--shell"   "--help documents --shell"
assert_contains "$HELP_OUT" "--dry-run" "--help documents --dry-run"
assert_not_contains "$HELP_OUT" "set -euo" "--help does not leak script source"

"$INSTALL_SH" --shell tcsh >/dev/null 2>&1
assert_ne "0" "$?" "an unsupported --shell value exits non-zero"

"$INSTALL_SH" --bogus-flag >/dev/null 2>&1
assert_ne "0" "$?" "an unknown flag exits non-zero"

# ---------------------------------------------------------------------------
section "Dry run writes nothing"
# ---------------------------------------------------------------------------

DRY_HOME="$SANDBOX_ROOT/dry"
mkdir -p "$DRY_HOME"
printf 'export EXISTING=1\n' > "$DRY_HOME/.zshrc"
BEFORE=$(md5 -q "$DRY_HOME/.zshrc" 2>/dev/null || md5sum "$DRY_HOME/.zshrc" | cut -d' ' -f1)

env -u ZDOTDIR HOME="$DRY_HOME" SHELL=/bin/zsh "$INSTALL_SH" \
    --no-font --local --dry-run >"$DRY_HOME/.log" 2>&1

AFTER=$(md5 -q "$DRY_HOME/.zshrc" 2>/dev/null || md5sum "$DRY_HOME/.zshrc" | cut -d' ' -f1)
assert_eq "$BEFORE" "$AFTER" "--dry-run leaves the rc file byte-identical"
assert_true "--dry-run creates no backup files" \
    bash -c "! ls '$DRY_HOME'/.zshrc.bak-* >/dev/null 2>&1"

# ---------------------------------------------------------------------------
section "Targets the login shell, not the interpreter"
# ---------------------------------------------------------------------------

# This is the regression that broke installs on macOS: the script runs under
# bash, so a naive check configures .bash_profile for a zsh user.
ZSH_HOME="$SANDBOX_ROOT/zshuser"
run_installer "$ZSH_HOME" SHELL=/bin/zsh
assert_true "zsh login shell configures ~/.zshrc" test -f "$ZSH_HOME/.zshrc"
if [[ -f "$ZSH_HOME/.zshrc" ]] && grep -q "oh-my-posh init zsh" "$ZSH_HOME/.zshrc"; then
    pass "the zsh rc file receives a 'zsh' init line"
else
    fail "the zsh rc file receives a 'zsh' init line" "$(cat "$ZSH_HOME/.zshrc" 2>/dev/null)"
fi
assert_false "zsh login shell does not touch ~/.bash_profile" test -f "$ZSH_HOME/.bash_profile"

BASH_HOME="$SANDBOX_ROOT/bashuser"
run_installer "$BASH_HOME" SHELL=/bin/bash
if [[ -f "$BASH_HOME/.bash_profile" ]] || [[ -f "$BASH_HOME/.bashrc" ]]; then
    pass "bash login shell configures a bash rc file"
else
    fail "bash login shell configures a bash rc file" "no bash rc file created"
fi
assert_false "bash login shell does not touch ~/.zshrc" test -f "$BASH_HOME/.zshrc"

# --shell overrides detection.
BOTH_HOME="$SANDBOX_ROOT/both"
mkdir -p "$BOTH_HOME"
env -u ZDOTDIR HOME="$BOTH_HOME" SHELL=/bin/zsh "$INSTALL_SH" \
    --no-font --local --shell all >"$BOTH_HOME/.log" 2>&1
assert_true "--shell all configures zsh"  test -f "$BOTH_HOME/.zshrc"
assert_true "--shell all configures bash" bash -c \
    "test -f '$BOTH_HOME/.bash_profile' -o -f '$BOTH_HOME/.bashrc'"

# ---------------------------------------------------------------------------
section "Preserves existing configuration"
# ---------------------------------------------------------------------------

KEEP_HOME="$SANDBOX_ROOT/keep"
mkdir -p "$KEEP_HOME"
cat > "$KEEP_HOME/.zshrc" <<'EOF'
export PATH="$HOME/bin:$PATH"
alias ll='ls -la'
eval "$(oh-my-posh init zsh --config ~/some-other-theme.json)"
export EDITOR=vim
EOF

run_installer "$KEEP_HOME" SHELL=/bin/zsh
RC=$(cat "$KEEP_HOME/.zshrc")

assert_contains "$RC" 'export PATH="$HOME/bin:$PATH"' "existing PATH export survives"
assert_contains "$RC" "alias ll='ls -la'"             "existing alias survives"
assert_contains "$RC" "export EDITOR=vim"             "existing EDITOR export survives"
assert_contains "$RC" "some-other-theme.json"         "an unrelated oh-my-posh line is left intact"
assert_contains "$RC" "$MARKER_BEGIN"                 "our managed block is added"

assert_true "a timestamped backup is written" \
    bash -c "ls '$KEEP_HOME'/.zshrc.bak-* >/dev/null 2>&1"

LOG=$(cat "$KEEP_HOME/.installer.log")
assert_contains "$LOG" "another 'oh-my-posh init' line" "a conflicting init line is reported to the user"

# ---------------------------------------------------------------------------
section "Idempotency"
# ---------------------------------------------------------------------------

IDEM_HOME="$SANDBOX_ROOT/idem"
run_installer "$IDEM_HOME" SHELL=/bin/zsh
FIRST=$(md5 -q "$IDEM_HOME/.zshrc" 2>/dev/null || md5sum "$IDEM_HOME/.zshrc" | cut -d' ' -f1)
BACKUPS_1=$(find "$IDEM_HOME" -maxdepth 1 -name '.zshrc.bak-*' 2>/dev/null | wc -l | tr -d ' ')

run_installer "$IDEM_HOME" SHELL=/bin/zsh
SECOND=$(md5 -q "$IDEM_HOME/.zshrc" 2>/dev/null || md5sum "$IDEM_HOME/.zshrc" | cut -d' ' -f1)
BACKUPS_2=$(find "$IDEM_HOME" -maxdepth 1 -name '.zshrc.bak-*' 2>/dev/null | wc -l | tr -d ' ')

assert_eq "$FIRST" "$SECOND" "a second run leaves the rc file unchanged"
assert_eq "$BACKUPS_1" "$BACKUPS_2" "a second run creates no additional backup"

MARKER_COUNT=$(grep -c "$MARKER_BEGIN" "$IDEM_HOME/.zshrc")
assert_eq "1" "$MARKER_COUNT" "exactly one managed block exists after two runs"

# ---------------------------------------------------------------------------
section "Block replacement when the theme path changes"
# ---------------------------------------------------------------------------

MOVE_HOME="$SANDBOX_ROOT/move"
run_installer "$MOVE_HOME" SHELL=/bin/zsh

ALT_REPO="$SANDBOX_ROOT/altrepo"
mkdir -p "$ALT_REPO"
cp "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/kartikshankar.omp.json" "$ALT_REPO/"
env -u ZDOTDIR HOME="$MOVE_HOME" SHELL=/bin/zsh "$ALT_REPO/install.sh" \
    --no-font --local >"$MOVE_HOME/.log2" 2>&1

assert_eq "1" "$(grep -c "$MARKER_BEGIN" "$MOVE_HOME/.zshrc")" \
    "changing the theme path replaces the block instead of appending one"
assert_contains "$(cat "$MOVE_HOME/.zshrc")" "$ALT_REPO" "the block points at the new theme path"
assert_not_contains "$(cat "$MOVE_HOME/.zshrc")" "$SCRIPT_DIR/kartikshankar.omp.json" \
    "the previous theme path is removed"

# ---------------------------------------------------------------------------
section "Generated init line is valid shell"
# ---------------------------------------------------------------------------

INIT_LINE=$(grep "oh-my-posh init zsh" "$IDEM_HOME/.zshrc" | head -1)
if command -v zsh >/dev/null 2>&1; then
    assert_true "the generated zsh init line is syntactically valid" \
        zsh -n -c "$INIT_LINE"
else
    # zsh is not installed on every CI image; the line is still generated and
    # asserted structurally above.
    skip "zsh not installed; cannot syntax-check the generated zsh init line"
fi

BASH_LINE=$(grep -h "oh-my-posh init bash" "$BOTH_HOME/.bash_profile" "$BOTH_HOME/.bashrc" 2>/dev/null | head -1)
if [[ -n "$BASH_LINE" ]]; then
    assert_true "the generated bash init line is syntactically valid" \
        bash -n -c "$BASH_LINE"
else
    skip "no bash init line to validate"
fi

# ---------------------------------------------------------------------------
section "install.ps1"
# ---------------------------------------------------------------------------

if command -v pwsh >/dev/null 2>&1; then
    # Test the command directly rather than inspecting $? afterwards.
    if PS_ERR=$(pwsh -NoProfile -c "
        \$errors = \$null
        [System.Management.Automation.Language.Parser]::ParseFile('$INSTALL_PS1', [ref]\$null, [ref]\$errors) | Out-Null
        if (\$errors.Count -gt 0) { \$errors | ForEach-Object { \$_.Message }; exit 1 }
        exit 0" 2>&1); then
        pass "install.ps1 parses without syntax errors"
    else
        fail "install.ps1 parses without syntax errors" "$PS_ERR"
    fi

    # install.ps1 supports Windows and macOS and exits early on Linux by design,
    # so only exercise it where it is meant to run. pwsh is preinstalled on Linux
    # CI images, which would otherwise make these fail for the wrong reason.
    case "$OSTYPE" in
        darwin*|msys*|cygwin*) PS1_RUNNABLE=true ;;
        *)                     PS1_RUNNABLE=false ;;
    esac

    if [[ "$PS1_RUNNABLE" != true ]]; then
        skip "install.ps1 targets Windows and macOS; not executing it on this platform"

        # It must refuse clearly rather than fail obscurely.
        LINUX_OUT=$(pwsh -NoProfile -c ". '$INSTALL_PS1' -Local -NoFont" 2>&1 || true)
        assert_contains "$LINUX_OUT" "install.sh" "install.ps1 redirects Linux users to install.sh"
    else
        # Exercise the profile block editor against a throwaway profile.
        PS_PROFILE="$SANDBOX_ROOT/profile.ps1"
        printf "Set-Alias ll Get-ChildItem\n\$env:EDITOR = 'vim'\n" > "$PS_PROFILE"

        pwsh -NoProfile -c "\$PROFILE = '$PS_PROFILE'; . '$INSTALL_PS1' -Local -NoFont" >/dev/null 2>&1
        PS_CONTENT=$(cat "$PS_PROFILE")
        assert_contains "$PS_CONTENT" "Set-Alias ll"  "install.ps1 preserves existing profile content"
        assert_contains "$PS_CONTENT" "$MARKER_BEGIN" "install.ps1 adds its managed block"

        pwsh -NoProfile -c "\$PROFILE = '$PS_PROFILE'; . '$INSTALL_PS1' -Local -NoFont" >/dev/null 2>&1
        assert_eq "1" "$(grep -c "$MARKER_BEGIN" "$PS_PROFILE")" "install.ps1 is idempotent"
    fi
else
    skip "pwsh not installed; skipping install.ps1 execution tests"
fi

# Native command failures do not raise in PowerShell, so try/catch around them
# reports success on failure. The installer must check $LASTEXITCODE.
assert_true "install.ps1 checks \$LASTEXITCODE for native commands" \
    grep -q 'LASTEXITCODE' "$INSTALL_PS1"
assert_true "install.ps1 sets Set-StrictMode" grep -q "Set-StrictMode" "$INSTALL_PS1"

finish
