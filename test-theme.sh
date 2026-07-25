#!/usr/bin/env bash
#
# Theme correctness: schema shape, segment configuration, and what Oh My Posh
# actually renders. Assertions run against the binary's output, not the source.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-lib.sh"

THEME="$SCRIPT_DIR/kartikshankar.omp.json"

command -v jq >/dev/null 2>&1 || { echo "jq is required to run this suite." >&2; exit 1; }

# ---------------------------------------------------------------------------
section "Theme file and JSON validity"
# ---------------------------------------------------------------------------

assert_file_exists "$THEME" "theme file exists"
assert_true "theme is valid JSON" jq -e . "$THEME"

# Every Nerd Font glyph must be an escaped \uXXXX sequence rather than a raw
# character, so the file stays readable in an editor without a Nerd Font.
if grep -qP '[\x{e000}-\x{f8ff}]' "$THEME" 2>/dev/null; then
    fail "theme uses \\uXXXX escapes for private-use glyphs" "found raw glyph characters"
elif LC_ALL=C grep -q $'[\xee-\xef]' "$THEME"; then
    fail "theme uses \\uXXXX escapes for private-use glyphs" "found raw glyph bytes"
else
    pass "theme uses \\uXXXX escapes for private-use glyphs"
fi

# ---------------------------------------------------------------------------
section "Schema conformance"
# ---------------------------------------------------------------------------

VERSION=$(jq -r '.version' "$THEME")
assert_eq "3" "$VERSION" "theme declares schema version 3"

assert_eq "3" "$(jq '.blocks | length' "$THEME")" "theme has 3 blocks"
assert_eq "left"  "$(jq -r '.blocks[0].alignment' "$THEME")" "block 0 is left-aligned"
assert_eq "right" "$(jq -r '.blocks[1].alignment' "$THEME")" "block 1 is right-aligned"
assert_eq "true"  "$(jq -r '.blocks[2].newline' "$THEME")"   "block 2 starts on a new line"

for seg in os session path git time text root; do
    COUNT=$(jq --arg s "$seg" '[.blocks[].segments[] | select(.type == $s)] | length' "$THEME")
    if [[ "$COUNT" -ge 1 ]]; then
        pass "segment type '$seg' is present"
    else
        fail "segment type '$seg' is present" "not found in theme"
    fi
done

# All colours must be 6-digit hex.
BAD_COLORS=$(jq -r '[.. | strings | select(startswith("#"))] | .[]' "$THEME" \
             | grep -vE '^#[0-9a-fA-F]{6}$' || true)
if [[ -z "$BAD_COLORS" ]]; then
    pass "all colour literals are 6-digit hex"
else
    fail "all colour literals are 6-digit hex" "invalid: $BAD_COLORS"
fi

# ---------------------------------------------------------------------------
section "OS segment icon keys"
# ---------------------------------------------------------------------------

# Oh My Posh names the macOS icon property 'macos'. 'darwin' is silently
# ignored: the segment falls back to a built-in default, so the theme appears
# to work on a Mac while the configured value does nothing.
OS_PROPS=$(jq -r '.blocks[0].segments[] | select(.type=="os") | .properties | keys | join(",")' "$THEME")
assert_contains     "$OS_PROPS" "macos"  "OS segment uses the 'macos' icon key"
assert_not_contains "$OS_PROPS" "darwin" "OS segment does not use the invalid 'darwin' key"
assert_contains     "$OS_PROPS" "linux"   "OS segment defines a linux icon"
assert_contains     "$OS_PROPS" "windows" "OS segment defines a windows icon"

OS_TEMPLATE=$(jq -r '.blocks[0].segments[] | select(.type=="os") | .template' "$THEME")
assert_contains     "$OS_TEMPLATE" "{{ .Icon }}" "OS segment renders {{ .Icon }}"
assert_not_contains "$OS_TEMPLATE" ".Os"         "OS segment avoids the removed .Os property"

# ---------------------------------------------------------------------------
section "No dead configuration"
# ---------------------------------------------------------------------------

# Properties that Oh My Posh does not recognise are silently discarded. They
# are misleading to anyone reading the theme and imply behaviour that is absent.
ROOT_PROPS=$(jq -r '.blocks[0].segments[] | select(.type=="root") | .properties // {} | keys | join(",")' "$THEME")
assert_eq "" "$ROOT_PROPS" "root segment carries no unsupported properties"

GIT_PROPS=$(jq -r '.blocks[0].segments[] | select(.type=="git") | .properties | keys | join(",")' "$THEME")
assert_not_contains "$GIT_PROPS" "fetch_stash_count" "git segment omits the unsupported fetch_stash_count"
assert_contains     "$GIT_PROPS" "fetch_status"      "git segment enables fetch_status"

PATH_PROPS=$(jq -r '.blocks[0].segments[] | select(.type=="path") | .properties | keys | join(",")' "$THEME")
assert_not_contains "$PATH_PROPS" "folder_icon" "path segment omits folder_icon (inert with style=folder)"

BG_COUNT=$(jq '.blocks[0].segments[] | select(.type=="git") | .background_templates | length' "$THEME")
assert_eq "4" "$BG_COUNT" "git segment defines 4 dynamic background templates"

# ---------------------------------------------------------------------------
section "Separator chaining"
# ---------------------------------------------------------------------------

# The OS segment is a diamond followed by powerline segments. If it also emits
# a trailing diamond, two separators render back to back with a colour gap
# between them.
OS_TRAILING=$(jq -r '.blocks[0].segments[] | select(.type=="os") | .trailing_diamond' "$THEME")
assert_eq "" "$OS_TRAILING" "OS segment has an empty trailing_diamond (next segment draws the join)"

# ---------------------------------------------------------------------------
section "Rendering"
# ---------------------------------------------------------------------------

if ! command -v oh-my-posh >/dev/null 2>&1; then
    skip "oh-my-posh not installed; skipping render assertions"
    finish
fi

RENDER=$(oh-my-posh print primary --config "$THEME" --shell bash 2>&1)
CLEAN=$(printf '%s' "$RENDER" | strip_ansi)

assert_true "primary prompt renders successfully" \
    oh-my-posh print primary --config "$THEME" --shell bash
assert_not_contains "$RENDER" "unable to create text" "no template errors in output"
assert_not_contains "$RENDER" "<nil>"                 "no nil values leak into output"
assert_contains     "$CLEAN"  "$(whoami)"             "output contains the current username"
assert_contains     "$CLEAN"  "❯"                     "output contains the prompt character"

# Count powerline separators (U+E0B0). Two adjacent ones indicate the doubled
# separator this theme previously rendered after the OS icon.
DOUBLE=$(printf '%s' "$CLEAN" | python3 -c "
import sys
s = sys.stdin.read()
sep = chr(0xE0B0)
print('yes' if sep + sep in s.replace(' ', '') else 'no')
" 2>/dev/null || echo "unknown")
if [[ "$DOUBLE" == "unknown" ]]; then
    skip "python3 unavailable; cannot check for doubled separators"
else
    assert_eq "no" "$DOUBLE" "no doubled powerline separators in rendered output"
fi

# ---------------------------------------------------------------------------
section "Git segment behaviour"
# ---------------------------------------------------------------------------

TMP_REPO=$(mktemp -d)
trap 'rm -rf "$TMP_REPO"' EXIT

(
    cd "$TMP_REPO" || exit 1
    git init -q
    git config user.email test@example.com
    git config user.name "Test"
    echo one > file.txt
    git add . && git commit -qm "initial"
) >/dev/null 2>&1

BRANCH_RENDER=$(cd "$TMP_REPO" && oh-my-posh print primary --config "$THEME" --shell bash 2>&1 | strip_ansi)
if printf '%s' "$BRANCH_RENDER" | grep -qE 'main|master'; then
    pass "git segment renders the branch name"
else
    fail "git segment renders the branch name" "output: $BRANCH_RENDER"
fi

# Dirty working tree must change the background colour to burnt sienna.
(cd "$TMP_REPO" && echo two >> file.txt)
DIRTY=$(cd "$TMP_REPO" && oh-my-posh print primary --config "$THEME" --shell bash 2>&1)
assert_contains "$DIRTY" "231;111;81" "dirty repo renders the burnt sienna background (#e76f51)"

# Stash count is displayed. .StashCount works without any extra property.
(cd "$TMP_REPO" && git stash -q) >/dev/null 2>&1
STASHED=$(cd "$TMP_REPO" && oh-my-posh print primary --config "$THEME" --shell bash 2>&1 | strip_ansi)
if printf '%s' "$STASHED" | grep -q '1'; then
    pass "git segment reports a stash entry"
else
    fail "git segment reports a stash entry" "output: $STASHED"
fi

# Outside a repository the git segment must disappear entirely.
NON_REPO=$(mktemp -d)
NO_GIT=$(cd "$NON_REPO" && oh-my-posh print primary --config "$THEME" --shell bash 2>&1)
rmdir "$NON_REPO" 2>/dev/null || true
assert_not_contains "$NO_GIT" "30;117;106" "git segment is hidden outside a repository"

# ---------------------------------------------------------------------------
section "Performance"
# ---------------------------------------------------------------------------

if command -v python3 >/dev/null 2>&1; then
    ELAPSED=$(python3 -c "
import subprocess, time
start = time.time()
for _ in range(5):
    subprocess.run(['oh-my-posh','print','primary','--config','$THEME','--shell','bash'],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print('%.3f' % ((time.time() - start) / 5))
")
    if python3 -c "exit(0 if $ELAPSED < 0.5 else 1)"; then
        pass "mean render time ${ELAPSED}s is under the 0.5s budget"
    else
        fail "mean render time ${ELAPSED}s is under the 0.5s budget" "too slow"
    fi
else
    skip "python3 unavailable; skipping performance measurement"
fi

finish
