#!/usr/bin/env bash
#
# Dynamic segment behaviour: values that change with the environment (OS icon,
# hostname, username, working directory, root state, clock).
#
# These assertions substitute a sentinel value into a copy of the theme and
# check that it appears in the rendered output. That proves the configuration
# key is actually wired up, which a source-level grep cannot.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test-lib.sh
source "$SCRIPT_DIR/test-lib.sh"

THEME="$SCRIPT_DIR/kartikshankar.omp.json"

command -v jq >/dev/null 2>&1 || { echo "jq is required to run this suite." >&2; exit 1; }
if ! command -v oh-my-posh >/dev/null 2>&1; then
    echo "oh-my-posh is required to run this suite." >&2
    exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# render <config-file> -> plain text with escapes stripped
render() {
    oh-my-posh print primary --config "$1" --shell bash 2>&1 | strip_ansi
}

# Build a variant of the theme with a jq filter applied.
variant() {
    local out="$WORK/variant.json"
    jq "$1" "$THEME" > "$out" || return 1
    printf '%s\n' "$out"
}

case "$OSTYPE" in
    darwin*) HOST_OS="macos" ;;
    linux*)  HOST_OS="linux" ;;
    msys*|cygwin*) HOST_OS="windows" ;;
    *)       HOST_OS="unknown" ;;
esac

# ---------------------------------------------------------------------------
section "OS segment resolves the current platform"
# ---------------------------------------------------------------------------

# On Linux, Oh My Posh prefers a distro-specific icon key (ubuntu, fedora,
# arch...) and only falls back to the generic "linux" key when it does not
# recognise the distribution. Target whichever key actually applies here.
# See https://ohmyposh.dev/docs/segments/system/os
ICON_KEY="$HOST_OS"
if [[ "$HOST_OS" == "linux" && -r /etc/os-release ]]; then
    DISTRO_ID=$(. /etc/os-release 2>/dev/null && printf '%s' "${ID:-}")
    if [[ -n "$DISTRO_ID" ]]; then
        # Does the schema know this distro? Probe it with a sentinel.
        PROBE=$(variant ".blocks[0].segments[0].properties.\"${DISTRO_ID}\" = \"DISTROPROBE\"")
        if [[ -n "$PROBE" ]] && render "$PROBE" | grep -q "DISTROPROBE"; then
            ICON_KEY="$DISTRO_ID"
        fi
    fi
fi

if [[ "$HOST_OS" == "unknown" ]]; then
    skip "unrecognised platform $OSTYPE; cannot assert OS icon wiring"
else
    pass "detected host platform: $HOST_OS (icon key in effect: $ICON_KEY)"

    # Substituting a sentinel for the key in effect must change the output.
    CFG=$(variant ".blocks[0].segments[0].properties.\"${ICON_KEY}\" = \"OSSENTINEL\"")
    OUT=$(render "$CFG")
    assert_contains "$OUT" "OSSENTINEL" "the '${ICON_KEY}' icon key drives the rendered OS icon"

    # And the other platforms' keys must NOT affect this machine's output.
    for other in macos linux windows; do
        [[ "$other" == "$HOST_OS" ]] && continue
        CFG=$(variant ".blocks[0].segments[0].properties.${other} = \"WRONGOS\"")
        OUT=$(render "$CFG")
        assert_not_contains "$OUT" "WRONGOS" "the '${other}' icon key does not apply on ${HOST_OS}"
    done

    # Each platform key must carry a distinct glyph. Compare inside jq rather
    # than with `sort -u`: in a UTF-8 locale, BSD sort assigns no collation
    # weight to Private Use Area codepoints and reports all three glyphs as
    # equal, which made this pass under C.UTF-8 and fail on a macOS CI runner.
    UNIQUE=$(jq -r '.blocks[0].segments[0].properties
                    | [.macos, .linux, .windows] | unique | length' "$THEME")
    assert_eq "3" "$UNIQUE" "macos, linux, and windows use three distinct icons"
fi

# ---------------------------------------------------------------------------
section "Session segments reflect the live environment"
# ---------------------------------------------------------------------------

BASE=$(render "$THEME")

assert_contains "$BASE" "$(whoami)" "username segment shows the current user"

# Oh My Posh renders the short hostname; compare against the first label.
SHORT_HOST=$(hostname -s 2>/dev/null || hostname 2>/dev/null || uname -n 2>/dev/null || true)
SHORT_HOST=${SHORT_HOST%%.*}

THEME_TEXT=$(cat "$THEME")
if [[ -z "$SHORT_HOST" ]]; then
    # Guard explicitly: an empty needle makes both of the assertions below
    # meaningless (one passes vacuously, the other always fails).
    skip "could not determine the hostname on this system"
else
    assert_contains "$BASE" "$SHORT_HOST" "hostname segment shows the live hostname"
    # The hostname must come from the template, not be baked in as a literal.
    assert_not_contains "$THEME_TEXT" "$SHORT_HOST" "hostname is not hardcoded in the theme file"
fi
assert_contains "$THEME_TEXT" "{{ .HostName }}" "hostname segment uses the .HostName template"
assert_contains "$THEME_TEXT" "{{ .UserName }}" "username segment uses the .UserName template"

# ---------------------------------------------------------------------------
section "Path segment tracks the working directory"
# ---------------------------------------------------------------------------

DIR_A="$WORK/alpha"; DIR_B="$WORK/beta"
mkdir -p "$DIR_A" "$DIR_B"

OUT_A=$(cd "$DIR_A" && render "$THEME")
OUT_B=$(cd "$DIR_B" && render "$THEME")

assert_contains "$OUT_A" "alpha" "path segment shows the current folder (alpha)"
assert_contains "$OUT_B" "beta"  "path segment shows the current folder (beta)"
assert_not_contains "$OUT_A" "beta" "path segment does not leak a stale directory"

# style=folder means only the leaf directory is shown, not the full path.
assert_not_contains "$OUT_A" "$WORK/alpha" "path segment uses folder style, not the full path"

# ---------------------------------------------------------------------------
section "Root segment"
# ---------------------------------------------------------------------------

# The root segment renders only for uid 0. Identify it by its bolt glyph
# (U+F0E7) rather than its background colour: #e76f51 is shared with the
# dirty-repository git background, so a colour check reports a false positive
# in any repository with uncommitted changes.
HAS_BOLT=$(printf '%s' "$BASE" | python3 -c "
import sys
print('yes' if chr(0xF0E7) in sys.stdin.read() else 'no')
" 2>/dev/null || echo "unknown")

if [[ "$HAS_BOLT" == "unknown" ]]; then
    skip "python3 unavailable; cannot check the root indicator glyph"
elif [[ "$(id -u)" -eq 0 ]]; then
    assert_eq "yes" "$HAS_BOLT" "root indicator is shown when running as root"
else
    assert_eq "no" "$HAS_BOLT" "root indicator is hidden for a non-root user"
fi

# ---------------------------------------------------------------------------
section "Time segment"
# ---------------------------------------------------------------------------

TIME_FMT=$(jq -r '.blocks[1].segments[0].properties.time_format' "$THEME")
assert_eq "15:04:05" "$TIME_FMT" "time segment uses a 24-hour HH:MM:SS layout"

if printf '%s' "$BASE" | grep -qE '[0-2][0-9]:[0-5][0-9]:[0-5][0-9]'; then
    pass "time segment renders a HH:MM:SS timestamp"
else
    fail "time segment renders a HH:MM:SS timestamp" "output: $BASE"
fi

# The clock must advance between renders.
T1=$(render "$THEME" | grep -oE '[0-2][0-9]:[0-5][0-9]:[0-5][0-9]' | head -1)
sleep 1.1
T2=$(render "$THEME" | grep -oE '[0-2][0-9]:[0-5][0-9]:[0-5][0-9]' | head -1)
assert_ne "$T1" "$T2" "time segment advances between renders (not a cached literal)"

# ---------------------------------------------------------------------------
section "Shell compatibility"
# ---------------------------------------------------------------------------

# Oh My Posh emits shell-specific prompt-escape wrappers. Each supported shell
# must produce output without errors.
for sh in bash zsh pwsh; do
    OUT=$(oh-my-posh print primary --config "$THEME" --shell "$sh" 2>&1)
    if [[ -n "$OUT" ]] && ! printf '%s' "$OUT" | grep -qi "error\|unable to"; then
        pass "renders cleanly for --shell $sh"
    else
        fail "renders cleanly for --shell $sh" "output: $OUT"
    fi
done

# zsh needs %{...%} wrappers so it can compute the prompt width correctly.
ZSH_OUT=$(oh-my-posh print primary --config "$THEME" --shell zsh 2>&1)
assert_contains "$ZSH_OUT" '%{' "zsh output includes prompt-width escape wrappers"

BASH_OUT=$(oh-my-posh print primary --config "$THEME" --shell bash 2>&1)
assert_contains "$BASH_OUT" '\[' "bash output includes non-printing escape markers"

finish
