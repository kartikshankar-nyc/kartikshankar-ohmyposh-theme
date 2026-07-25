#!/usr/bin/env bash
#
# Repository integrity: bundled font validity, glyph coverage, documentation
# consistency, and hygiene checks across every tracked script.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test-lib.sh
source "$SCRIPT_DIR/test-lib.sh"

THEME="$SCRIPT_DIR/kartikshankar.omp.json"
README="$SCRIPT_DIR/README.md"
FONTS_DIR="$SCRIPT_DIR/fonts"

# ---------------------------------------------------------------------------
section "Bundled fonts are real fonts"
# ---------------------------------------------------------------------------

assert_true "fonts/ directory exists" test -d "$FONTS_DIR"

FONT_FILES=()
while IFS= read -r f; do FONT_FILES+=("$f"); done < <(find "$FONTS_DIR" -maxdepth 1 -name '*.ttf' | sort)

assert_eq "4" "${#FONT_FILES[@]}" "fonts/ contains 4 TTF files"

# The check that matters. A previous revision shipped four GitHub "404: Not
# Found" HTML pages named *.ttf: non-empty, ~282KB each, and completely inert.
# Size and existence checks all passed. Only the file signature catches it.
for f in "${FONT_FILES[@]}"; do
    name=$(basename "$f")
    if is_truetype "$f"; then
        pass "$name has a valid TrueType signature"
    else
        head4=$(head -c 4 "$f" | od -An -c | tr -s ' ')
        fail "$name has a valid TrueType signature" "leading bytes:$head4"
    fi
done

# Guard the specific historical failure explicitly.
for f in "${FONT_FILES[@]}"; do
    if head -c 512 "$f" 2>/dev/null | LC_ALL=C grep -qi "<!DOCTYPE\|<html"; then
        fail "$(basename "$f") is not an HTML document" "file contains HTML markup"
    else
        pass "$(basename "$f") is not an HTML document"
    fi
done

# Font family name must match what the docs tell people to select.
if command -v python3 >/dev/null 2>&1 && [[ ${#FONT_FILES[@]} -gt 0 ]]; then
    FAMILY=$(python3 - "$FONTS_DIR/HackNerdFont-Regular.ttf" <<'PYEOF'
import struct, sys
try:
    d = open(sys.argv[1], 'rb').read()
    n = struct.unpack('>H', d[4:6])[0]
    off = None
    for i in range(n):
        e = 12 + 16 * i
        if d[e:e+4] == b'name':
            off = struct.unpack('>I', d[e+8:e+12])[0]
    fmt, cnt, so = struct.unpack('>HHH', d[off:off+6])
    for i in range(cnt):
        r = off + 6 + 12 * i
        pid, eid, lid, nid, ln, o = struct.unpack('>HHHHHH', d[r:r+12])
        if nid == 1:
            raw = d[off+so+o:off+so+o+ln]
            print(raw.decode('utf-16-be') if pid == 3 else raw.decode('latin-1'))
            break
except Exception:
    print('PARSE-ERROR')
PYEOF
)
    assert_eq "Hack Nerd Font" "$FAMILY" "bundled font reports the family name documented in the README"
else
    skip "python3 unavailable or fonts missing; skipping font family check"
fi

# ---------------------------------------------------------------------------
section "Bundled fonts cover every glyph the theme uses"
# ---------------------------------------------------------------------------

if command -v python3 >/dev/null 2>&1 && [[ -f "$FONTS_DIR/HackNerdFont-Regular.ttf" ]]; then
    COVERAGE=$(python3 - "$FONTS_DIR/HackNerdFont-Regular.ttf" "$THEME" <<'PYEOF'
import json, re, struct, sys

font_path, theme_path = sys.argv[1], sys.argv[2]

# Collect every non-ASCII codepoint referenced by the theme.
raw = open(theme_path, encoding='utf-8').read()
needed = set()
for m in re.finditer(r'\\u([0-9a-fA-F]{4})', raw):
    needed.add(int(m.group(1), 16))
theme = json.loads(raw)
def walk(o):
    if isinstance(o, str):
        for ch in o:
            if ord(ch) > 0x2000:
                needed.add(ord(ch))
    elif isinstance(o, dict):
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
walk(theme)
# The git segment's default branch icon is supplied by Oh My Posh, not the theme.
needed.add(0xE0A0)

d = open(font_path, 'rb').read()
n = struct.unpack('>H', d[4:6])[0]
off = None
for i in range(n):
    e = 12 + 16 * i
    if d[e:e+4] == b'cmap':
        off = struct.unpack('>I', d[e+8:e+12])[0]

covered = set()
ntab = struct.unpack('>H', d[off+2:off+4])[0]
for i in range(ntab):
    r = off + 4 + 8 * i
    pid, eid, sub = struct.unpack('>HHI', d[r:r+8])
    t = off + sub
    fmt = struct.unpack('>H', d[t:t+2])[0]
    if fmt == 4:
        segX2 = struct.unpack('>H', d[t+6:t+8])[0]
        seg = segX2 // 2
        ends = [struct.unpack('>H', d[t+14+2*j:t+16+2*j])[0] for j in range(seg)]
        sst = t + 16 + segX2
        starts = [struct.unpack('>H', d[sst+2*j:sst+2+2*j])[0] for j in range(seg)]
        for s, e2 in zip(starts, ends):
            if e2 != 0xFFFF:
                covered.update(range(s, e2 + 1))
    elif fmt == 12:
        ng = struct.unpack('>I', d[t+12:t+16])[0]
        for j in range(ng):
            g = t + 16 + 12 * j
            s, e2, _ = struct.unpack('>III', d[g:g+12])
            if e2 - s < 70000:
                covered.update(range(s, e2 + 1))

missing = sorted(cp for cp in needed if cp not in covered)
print(' '.join('U+%04X' % cp for cp in missing) if missing else 'ALL-COVERED')
PYEOF
)
    if [[ "$COVERAGE" == "ALL-COVERED" ]]; then
        pass "every glyph referenced by the theme exists in the bundled font"
    else
        fail "every glyph referenced by the theme exists in the bundled font" "missing: $COVERAGE"
    fi
else
    skip "python3 unavailable; skipping glyph coverage check"
fi

# ---------------------------------------------------------------------------
section "Shell script hygiene"
# ---------------------------------------------------------------------------

for s in "$SCRIPT_DIR"/*.sh; do
    name=$(basename "$s")
    if bash -n "$s" 2>/dev/null; then
        pass "$name passes bash -n"
    else
        fail "$name passes bash -n" "$(bash -n "$s" 2>&1 | head -3)"
    fi
done

for s in "$SCRIPT_DIR"/*.sh; do
    name=$(basename "$s")
    if [[ -x "$s" ]]; then
        pass "$name is executable"
    else
        fail "$name is executable" "missing +x"
    fi
done

# Gate at warning severity, following sourced files (-x). Remaining `info` and
# `style` notes are intentional: literal $-expressions inside single-quoted grep
# patterns and assertion strings.
if command -v shellcheck >/dev/null 2>&1; then
    for s in "$SCRIPT_DIR"/*.sh; do
        name=$(basename "$s")
        if shellcheck -x -S warning "$s" >/dev/null 2>&1; then
            pass "$name passes shellcheck (warning severity)"
        else
            fail "$name passes shellcheck (warning severity)" "$(shellcheck -x -S warning "$s" 2>&1 | head -10)"
        fi
    done
else
    skip "shellcheck not installed (brew install shellcheck); skipping lint"
fi

# ---------------------------------------------------------------------------
section "Documentation consistency"
# ---------------------------------------------------------------------------

assert_file_exists "$README" "README.md exists"
assert_file_exists "$SCRIPT_DIR/LICENSE" "LICENSE exists"
assert_file_exists "$SCRIPT_DIR/CONTRIBUTING.md" "CONTRIBUTING.md exists"

README_TEXT=$(cat "$README")

# Every local file the README links to or embeds must exist.
BROKEN=""
while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    case "$target" in http*|\#*|mailto:*) continue ;; esac
    clean="${target%%#*}"
    [[ -z "$clean" ]] && continue
    [[ -e "$SCRIPT_DIR/$clean" ]] || BROKEN="$BROKEN $clean"
done < <(grep -oE '\]\([^)]+\)' "$README" | sed -E 's/^\]\(//; s/\)$//')

if [[ -z "$BROKEN" ]]; then
    pass "every local link and image in the README resolves"
else
    fail "every local link and image in the README resolves" "missing:$BROKEN"
fi

# The README must document the font family name the bundled files actually use.
assert_contains "$README_TEXT" "Hack Nerd Font" "README names the Hack Nerd Font family"

# The theme's prompt character must match what the README claims.
PROMPT_CHAR=$(jq -r '.blocks[2].segments[0].template' "$THEME" | tr -d ' ')
assert_eq "❯" "$PROMPT_CHAR" "theme's prompt character is the one documented"

# Deprecated Homebrew tap must not reappear; it was merged into homebrew/cask.
assert_not_contains "$README_TEXT" "brew tap homebrew/cask-fonts" \
    "README does not reference the retired homebrew/cask-fonts tap"
assert_not_contains "$(cat "$SCRIPT_DIR/install.sh")" "homebrew/cask-fonts" \
    "install.sh does not reference the retired homebrew/cask-fonts tap"

# The README must not promise an installer flag that does not exist.
for flag in "--shell" "--dry-run" "--local" "--no-font"; do
    if [[ "$README_TEXT" == *"$flag"* ]]; then
        if "$SCRIPT_DIR/install.sh" --help 2>&1 | grep -q -- "$flag"; then
            pass "README flag $flag is implemented by install.sh"
        else
            fail "README flag $flag is implemented by install.sh" "not in --help output"
        fi
    fi
done

# ---------------------------------------------------------------------------
section "Repository hygiene"
# ---------------------------------------------------------------------------

if command -v git >/dev/null 2>&1 && git -C "$SCRIPT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    TRACKED=$(git -C "$SCRIPT_DIR" ls-files)

    if printf '%s\n' "$TRACKED" | grep -q '\.bak$'; then
        fail "no .bak files are tracked" "$(printf '%s\n' "$TRACKED" | grep '\.bak$' | tr '\n' ' ')"
    else
        pass "no .bak files are tracked"
    fi

    # Scripts that reference files which no longer exist are dead weight.
    DEAD=""
    while IFS= read -r script; do
        [[ "$script" == *.sh ]] || continue
        while IFS= read -r ref; do
            [[ -e "$SCRIPT_DIR/$ref" ]] || DEAD="$DEAD $script->$ref"
        done < <(grep -ohE '(segment_images|fonts)/[A-Za-z0-9_.-]+' "$SCRIPT_DIR/$script" 2>/dev/null | sort -u)
    done < <(printf '%s\n' "$TRACKED")

    if [[ -z "$DEAD" ]]; then
        pass "no tracked script references a missing file"
    else
        fail "no tracked script references a missing file" "dangling:$DEAD"
    fi
else
    skip "not a git checkout; skipping repository hygiene checks"
fi

finish
