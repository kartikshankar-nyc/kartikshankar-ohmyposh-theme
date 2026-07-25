#!/usr/bin/env bash
#
# Installer for Kartik's Oh My Posh theme.
#
# Supports macOS, Linux, WSL, and Git Bash on Windows, across zsh and bash.
#
# Usage:
#   ./install.sh [options]
#
#   --shell <zsh|bash|all>  Which shell(s) to configure. Defaults to your login
#                           shell as reported by $SHELL.
#   --no-font               Skip Nerd Font installation.
#   --local                 Use the theme file next to this script instead of
#                           cloning into ~/.oh-my-posh-themes. Implied when the
#                           script is run from inside a clone of the repo.
#   --dry-run               Report what would change without writing anything.
#   -h, --help              Show this help.
#
set -euo pipefail

REPO_URL="https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme.git"
THEME_FILE="kartikshankar.omp.json"
INSTALL_DIR="${HOME}/.oh-my-posh-themes/kartikshankar-ohmyposh-theme"

# The config we write is delimited by these markers so that re-running the
# installer replaces exactly our block and never rewrites unrelated lines.
MARKER_BEGIN="# >>> kartikshankar oh-my-posh theme >>>"
MARKER_END="# <<< kartikshankar oh-my-posh theme <<<"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# PATH as inherited, before this script modifies it. Used to decide whether the
# user's shell will actually be able to find oh-my-posh.
ORIGINAL_PATH="${PATH}"

# Options
OPT_SHELL=""
OPT_NO_FONT=false
OPT_LOCAL=false
OPT_DRY_RUN=false

# Discovered state
OS=""
IS_WSL=false
IS_GIT_BASH=false
THEME_PATH=""
CONFIGURED_FILES=()
FONT_OK=false

# ---------------------------------------------------------------- output ----

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
    BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; NC=""
fi

info()    { printf '%s[INFO]%s %s\n'    "$BLUE"   "$NC" "$1"; }
success() { printf '%s[SUCCESS]%s %s\n' "$GREEN"  "$NC" "$1"; }
warn()    { printf '%s[WARNING]%s %s\n' "$YELLOW" "$NC" "$1" >&2; }
error()   { printf '%s[ERROR]%s %s\n'   "$RED"    "$NC" "$1" >&2; }
die()     { error "$1"; exit 1; }

usage() {
    cat <<'EOF'
Installer for Kartik's Oh My Posh theme.

Supports macOS, Linux, WSL, and Git Bash on Windows, across zsh and bash.

Usage:
  ./install.sh [options]

  --shell <zsh|bash|all>  Which shell(s) to configure. Defaults to your login
                          shell as reported by $SHELL.
  --no-font               Skip Nerd Font installation.
  --local                 Use the theme file next to this script instead of
                          cloning into ~/.oh-my-posh-themes. Implied when the
                          script is run from inside a clone of the repo.
  --dry-run               Report what would change without writing anything.
  -h, --help              Show this help.
EOF
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

# Quote a string for safe literal inclusion inside single quotes in a shell file.
shell_quote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

# path_contains_dir <path-list> <dir> -- true if <dir> is an entry in <path-list>.
# Wrapping both sides in colons makes first, middle, and last entries match while
# rejecting partial matches such as /usr/local/bin inside /usr/local/bin2.
path_contains_dir() {
    case ":$1:" in
        *":$2:"*) return 0 ;;
        *)        return 1 ;;
    esac
}

# ------------------------------------------------------------ arg parsing ----

while [[ $# -gt 0 ]]; do
    case "$1" in
        --shell)
            [[ $# -ge 2 ]] || die "--shell requires an argument (zsh, bash, or all)"
            OPT_SHELL="$2"; shift 2 ;;
        --shell=*) OPT_SHELL="${1#*=}"; shift ;;
        --no-font) OPT_NO_FONT=true; shift ;;
        --local)   OPT_LOCAL=true; shift ;;
        --dry-run) OPT_DRY_RUN=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) error "Unknown option: $1"; echo; usage; exit 2 ;;
    esac
done

case "$OPT_SHELL" in
    ""|zsh|bash|all) ;;
    *) die "--shell must be one of: zsh, bash, all (got '$OPT_SHELL')" ;;
esac

# -------------------------------------------------------------- platform ----

detect_platform() {
    case "${OSTYPE:-}" in
        darwin*)        OS="macOS" ;;
        linux*)         OS="Linux" ;;
        msys*|cygwin*)  OS="Windows"; IS_GIT_BASH=true ;;
        *)
            # Fall back to uname when OSTYPE is unset or unfamiliar.
            case "$(uname -s 2>/dev/null || echo unknown)" in
                Darwin)             OS="macOS" ;;
                Linux)              OS="Linux" ;;
                MINGW*|MSYS*|CYGWIN*) OS="Windows"; IS_GIT_BASH=true ;;
                *) die "Unsupported operating system: ${OSTYPE:-$(uname -s)}" ;;
            esac ;;
    esac

    # WSL reports Linux. Match case-insensitively: WSL1 kernels say "Microsoft",
    # WSL2 kernels say "microsoft-standard-WSL2".
    if [[ "$OS" == "Linux" && -r /proc/version ]] && grep -qi microsoft /proc/version; then
        IS_WSL=true
    fi

    local label="$OS"
    [[ "$IS_WSL" == true ]] && label="$OS (WSL)"
    [[ "$IS_GIT_BASH" == true ]] && label="$OS (Git Bash)"
    info "Platform: $label"
}

# Decide which shells to configure. The key correctness point: the shell running
# this script is always bash (see the shebang), so $BASH_VERSION tells us nothing
# about the user. $SHELL is the login shell and is what we must target.
resolve_target_shells() {
    local -a shells=()

    if [[ -n "$OPT_SHELL" ]]; then
        if [[ "$OPT_SHELL" == "all" ]]; then
            shells=(zsh bash)
        else
            shells=("$OPT_SHELL")
        fi
    else
        case "$(basename "${SHELL:-}")" in
            zsh)  shells=(zsh) ;;
            bash) shells=(bash) ;;
            "")
                warn "\$SHELL is not set; defaulting to bash."
                warn "Re-run with --shell zsh if you use zsh."
                shells=(bash) ;;
            *)
                warn "Login shell '$(basename "$SHELL")' is not supported by this installer."
                warn "Supported: zsh, bash. Configure it manually with the line printed at the end."
                shells=() ;;
        esac
    fi

    TARGET_SHELLS=("${shells[@]+"${shells[@]}"}")
    if [[ ${#TARGET_SHELLS[@]} -gt 0 ]]; then
        info "Will configure: ${TARGET_SHELLS[*]} (login shell: $(basename "${SHELL:-unknown}"))"
    fi
}

# The rc file a given shell reads for interactive sessions.
rc_file_for() {
    case "$1" in
        zsh)  printf '%s\n' "${ZDOTDIR:-$HOME}/.zshrc" ;;
        # On macOS, Terminal.app and iTerm2 start bash as a *login* shell, which
        # reads .bash_profile and not .bashrc. Elsewhere .bashrc is correct.
        bash)
            if [[ "$OS" == "macOS" ]]; then
                printf '%s\n' "$HOME/.bash_profile"
            else
                printf '%s\n' "$HOME/.bashrc"
            fi ;;
        *) return 1 ;;
    esac
}

# ------------------------------------------------------------ oh-my-posh ----

ensure_oh_my_posh() {
    if command_exists oh-my-posh; then
        success "Oh My Posh is installed ($(oh-my-posh --version 2>/dev/null || echo 'version unknown'))"
        return 0
    fi

    info "Installing Oh My Posh..."
    if [[ "$OPT_DRY_RUN" == true ]]; then
        info "[dry-run] would install Oh My Posh"
        return 0
    fi

    if [[ "$OS" == "macOS" ]] && command_exists brew; then
        brew install oh-my-posh || warn "Homebrew install of Oh My Posh failed; trying the official script."
    fi

    if ! command_exists oh-my-posh; then
        # The official installer places the binary in ~/.local/bin by default.
        curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin" \
            || die "Oh My Posh installation failed. Install it manually: https://ohmyposh.dev/docs/installation"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    command_exists oh-my-posh \
        || die "Oh My Posh was installed but is not on PATH. Add its install directory to PATH and re-run."
    success "Oh My Posh installed ($(oh-my-posh --version 2>/dev/null || echo 'version unknown'))"
}

# ----------------------------------------------------------------- fonts ----

# True if the file starts with a TrueType/OpenType signature. This guards against
# the failure mode where a download silently produces an HTML error page that is
# non-empty, plausibly sized, and completely useless as a font.
is_truetype() {
    local magic
    magic=$(head -c 4 "$1" 2>/dev/null | od -An -tx1 2>/dev/null | tr -d ' \n') || return 1
    [[ "$magic" == "00010000" || "$magic" == "74727565" || "$magic" == "4f54544f" ]]
}

nerd_font_present() {
    if command_exists fc-list; then
        fc-list 2>/dev/null | grep -qi "nerd font" && return 0
    fi
    local dir
    for dir in "$HOME/Library/Fonts" "/Library/Fonts" \
               "$HOME/.local/share/fonts" "/usr/share/fonts" \
               "${LOCALAPPDATA:-}/Microsoft/Windows/Fonts" "${WINDIR:-}/Fonts"; do
        [[ -d "$dir" ]] || continue
        find "$dir" -maxdepth 2 -iname '*nerd*font*' -print -quit 2>/dev/null | grep -q . && return 0
    done
    return 1
}

install_bundled_fonts() {
    local fonts_dir="$SCRIPT_DIR/fonts"
    [[ -d "$fonts_dir" ]] || { error "Bundled fonts directory not found: $fonts_dir"; return 1; }

    local -a valid=()
    local f
    for f in "$fonts_dir"/*.ttf; do
        [[ -f "$f" ]] || continue
        if is_truetype "$f"; then
            valid+=("$f")
        else
            warn "Skipping $(basename "$f"): not a valid TrueType file."
        fi
    done

    if [[ ${#valid[@]} -eq 0 ]]; then
        error "No valid bundled font files found in $fonts_dir"
        return 1
    fi

    local dest=""
    case "$OS" in
        macOS) dest="$HOME/Library/Fonts" ;;
        Linux) dest="$HOME/.local/share/fonts" ;;
        Windows)
            info "Git Bash cannot install fonts directly."
            info "Open $fonts_dir in Explorer, select all .ttf files, right-click, and choose 'Install for all users'."
            return 1 ;;
    esac

    if [[ "$OPT_DRY_RUN" == true ]]; then
        info "[dry-run] would install ${#valid[@]} bundled fonts to $dest"
        return 0
    fi

    mkdir -p "$dest"
    cp "${valid[@]}" "$dest/"
    command_exists fc-cache && fc-cache -f >/dev/null 2>&1
    success "Installed ${#valid[@]} bundled fonts to $dest"
    return 0
}

ensure_nerd_font() {
    if [[ "$OPT_NO_FONT" == true ]]; then
        info "Skipping font installation (--no-font)."
        FONT_OK=true
        return 0
    fi

    if nerd_font_present; then
        success "A Nerd Font is already installed"
        FONT_OK=true
        return 0
    fi

    info "Installing Hack Nerd Font..."
    if [[ "$OPT_DRY_RUN" == true ]]; then
        info "[dry-run] would install Hack Nerd Font"
        FONT_OK=true
        return 0
    fi

    if [[ "$OS" == "macOS" ]] && command_exists brew; then
        brew install --cask font-hack-nerd-font >/dev/null 2>&1 || true
    fi

    if ! nerd_font_present && command_exists oh-my-posh; then
        oh-my-posh font install Hack >/dev/null 2>&1 || true
    fi

    if ! nerd_font_present; then
        warn "Network font installation did not succeed. Falling back to bundled fonts."
        install_bundled_fonts || true
    fi

    # Verify rather than assume. The previous version of this installer reported
    # success without ever checking that a font had landed.
    if nerd_font_present; then
        success "Hack Nerd Font installed"
        FONT_OK=true
    else
        warn "Could not install a Nerd Font automatically."
        warn "Install one manually from https://www.nerdfonts.com/font-downloads,"
        warn "or copy the files in $SCRIPT_DIR/fonts into your system font directory."
        FONT_OK=false
    fi
}

# ------------------------------------------------------------ theme file ----

resolve_theme_path() {
    # If the script sits next to the theme, use it in place. Cloning a second
    # copy into ~/.oh-my-posh-themes when the user already has one is confusing:
    # their edits would appear to do nothing.
    if [[ "$OPT_LOCAL" == true || -f "$SCRIPT_DIR/$THEME_FILE" ]]; then
        THEME_PATH="$SCRIPT_DIR/$THEME_FILE"
        [[ -f "$THEME_PATH" ]] || die "--local was given but $THEME_FILE is not next to this script."
        info "Using theme in place: $THEME_PATH"
        return 0
    fi

    command_exists git || die "git is required to fetch the theme. Install git and re-run."

    if [[ "$OPT_DRY_RUN" == true ]]; then
        THEME_PATH="$INSTALL_DIR/$THEME_FILE"
        info "[dry-run] would clone into $INSTALL_DIR"
        return 0
    fi

    if [[ -d "$INSTALL_DIR/.git" ]]; then
        info "Updating existing theme checkout..."
        git -C "$INSTALL_DIR" pull --ff-only \
            || warn "Could not update $INSTALL_DIR (local changes?). Continuing with the existing copy."
    else
        info "Cloning theme into $INSTALL_DIR..."
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" || die "Failed to clone $REPO_URL"
    fi

    THEME_PATH="$INSTALL_DIR/$THEME_FILE"
    [[ -f "$THEME_PATH" ]] || die "Theme file missing after checkout: $THEME_PATH"
}

# ----------------------------------------------------------- shell config ----

configure_shell() {
    local shell_name="$1"
    local rc init_line tmp backup path_line

    rc="$(rc_file_for "$shell_name")" || { warn "Don't know how to configure $shell_name"; return 1; }
    init_line="eval \"\$(oh-my-posh init $shell_name --config $(shell_quote "$THEME_PATH"))\""

    # If oh-my-posh lives somewhere the user's shell does not search, the init
    # line would fail with "command not found". Prepend its directory.
    path_line=""
    local omp_dir
    omp_dir="$(dirname "$(command -v oh-my-posh 2>/dev/null || echo /nonexistent)")"
    if [[ -d "$omp_dir" ]] && ! path_contains_dir "$ORIGINAL_PATH" "$omp_dir"; then
        path_line="export PATH=$(shell_quote "$omp_dir"):\$PATH"
    fi

    if [[ "$OPT_DRY_RUN" == true ]]; then
        info "[dry-run] would configure $rc with:"
        [[ -n "$path_line" ]] && printf '    %s\n' "$path_line"
        printf '    %s\n' "$init_line"
        return 0
    fi

    mkdir -p "$(dirname "$rc")"
    [[ -f "$rc" ]] || : > "$rc"

    # Already correct? Then leave the file completely alone.
    local path_ok=0
    [[ -z "$path_line" ]] || grep -Fqx "$path_line" "$rc" 2>/dev/null || path_ok=1
    if [[ $path_ok -eq 0 ]] && grep -Fqx "$init_line" "$rc" 2>/dev/null \
       && grep -Fqx "$MARKER_BEGIN" "$rc" 2>/dev/null; then
        success "$rc is already configured"
        CONFIGURED_FILES+=("$rc")
        return 0
    fi

    # Back up before the first modification of this file.
    backup="${rc}.bak-$(date +%Y%m%d%H%M%S)"
    cp "$rc" "$backup"

    # Strip any previous block of ours, then append a fresh one. Unrelated
    # oh-my-posh lines the user added by hand are deliberately left untouched.
    tmp="$(mktemp)"
    awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; next }
        skip != 1 { print }
    ' "$rc" > "$tmp"

    {
        printf '\n%s\n' "$MARKER_BEGIN"
        [[ -n "$path_line" ]] && printf '%s\n' "$path_line"
        printf '%s\n' "$init_line"
        printf '%s\n' "$MARKER_END"
    } >> "$tmp"

    mv "$tmp" "$rc"
    success "Configured $rc (backup: $(basename "$backup"))"
    CONFIGURED_FILES+=("$rc")

    # An unmanaged oh-my-posh line elsewhere in the file would win or conflict.
    if grep -n "oh-my-posh init" "$rc" | grep -Fqv "$init_line"; then
        warn "$rc contains another 'oh-my-posh init' line outside our block."
        warn "Remove it if the prompt does not look right."
    fi
}

# ------------------------------------------------------------------ main ----

main() {
    printf '\n%sKartik'"'"'s Oh My Posh theme installer%s\n\n' "$BOLD" "$NC"

    detect_platform
    resolve_target_shells

    if [[ "$OS" == "Linux" && "$OPT_DRY_RUN" == false ]] && ! command_exists git; then
        info "Installing git..."
        if   command_exists apt-get; then sudo apt-get update -qq && sudo apt-get install -y git fontconfig
        elif command_exists dnf;     then sudo dnf install -y git fontconfig
        elif command_exists yum;     then sudo yum install -y git fontconfig
        elif command_exists pacman;  then sudo pacman -Sy --noconfirm git fontconfig
        else warn "No supported package manager found. Install git and fontconfig manually."
        fi
    fi

    ensure_oh_my_posh
    ensure_nerd_font
    resolve_theme_path

    local sh
    for sh in ${TARGET_SHELLS[@]+"${TARGET_SHELLS[@]}"}; do
        configure_shell "$sh" || true
    done

    # ---- summary ----
    printf '\n%s%s%s\n' "$BOLD" "Installation complete" "$NC"
    printf '  Theme:  %s\n' "$THEME_PATH"
    if [[ ${#CONFIGURED_FILES[@]} -gt 0 ]]; then
        printf '  Config: %s\n' "${CONFIGURED_FILES[*]}"
    else
        printf '  Config: none written\n'
        printf '\n  Add this line to your shell config manually:\n'
        # shellcheck disable=SC2016  # $(...) is printed literally for the user to copy.
        printf '    eval "$(oh-my-posh init <your-shell> --config %s)"\n' "$(shell_quote "$THEME_PATH")"
    fi

    printf '\n%sNext steps%s\n' "$BOLD" "$NC"
    printf '  1. Set your terminal font to "Hack Nerd Font".\n'
    case "$OS" in
        macOS)   printf '     iTerm2:      Settings > Profiles > Text > Font\n'
                 printf '     Terminal:    Terminal > Settings > Profiles > Text > Font\n'
                 printf '     VS Code:     set terminal.integrated.fontFamily to "Hack Nerd Font"\n' ;;
        Linux)   printf '     GNOME Terminal: Preferences > Profile > Text > Custom font\n' ;;
        Windows) printf '     Windows Terminal: Settings > Profile > Appearance > Font face\n' ;;
    esac
    if [[ "$FONT_OK" != true ]]; then
        printf '     %sNo Nerd Font was detected. Icons will show as boxes until you install one.%s\n' "$YELLOW" "$NC"
    fi

    # This script runs in its own process, so it cannot change the prompt of the
    # shell that launched it. Say so instead of claiming the theme was applied.
    printf '  2. Restart your terminal, or reload the current shell:\n'
    if [[ ${#CONFIGURED_FILES[@]} -gt 0 ]]; then
        printf '       exec %s\n' "$(basename "${SHELL:-bash}")"
    fi
    printf '\n'
}

main "$@"
