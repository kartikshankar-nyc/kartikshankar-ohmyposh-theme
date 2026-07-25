#!/usr/bin/env bash
#
# Shared assertion helpers for the test suite.
#
# Source this from a test script:
#     source "$(dirname "${BASH_SOURCE[0]}")/test-lib.sh"
#
# Every assertion increments a counter. Call `finish` at the end of a test
# script to print the tally and exit non-zero if anything failed.
#
# The rule this suite follows: a check that cannot fail is not a test. Prefer
# executing the thing and inspecting the result over grepping the source for a
# keyword. An earlier version of this suite reported "52 passed, 0 failed"
# while the repository shipped four HTML error pages named *.ttf and an
# installer that wrote to the wrong file on macOS.

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
FAILED_NAMES=()

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    _RED=$'\033[0;31m'; _GREEN=$'\033[0;32m'; _YELLOW=$'\033[0;33m'
    _BLUE=$'\033[0;34m'; _BOLD=$'\033[1m'; _NC=$'\033[0m'
else
    _RED=""; _GREEN=""; _YELLOW=""; _BLUE=""; _BOLD=""; _NC=""
fi

section() { printf '\n%s== %s ==%s\n' "$_BLUE" "$1" "$_NC"; }

pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    printf '  %sPASS%s %s\n' "$_GREEN" "$_NC" "$1"
}

fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_NAMES+=("$1")
    printf '  %sFAIL%s %s\n' "$_RED" "$_NC" "$1"
    [[ $# -gt 1 ]] && printf '       %s\n' "$2"
    return 0
}

skip() {
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    printf '  %sSKIP%s %s\n' "$_YELLOW" "$_NC" "$1"
}

# assert_eq <expected> <actual> <description>
assert_eq() {
    if [[ "$1" == "$2" ]]; then
        pass "$3"
    else
        fail "$3" "expected: '$1'  actual: '$2'"
    fi
}

# assert_ne <not_expected> <actual> <description>
assert_ne() {
    if [[ "$1" != "$2" ]]; then
        pass "$3"
    else
        fail "$3" "value should not be '$1'"
    fi
}

# assert_contains <haystack> <needle> <description>
assert_contains() {
    if [[ "$1" == *"$2"* ]]; then
        pass "$3"
    else
        fail "$3" "expected to find '$2'"
    fi
}

# assert_not_contains <haystack> <needle> <description>
assert_not_contains() {
    if [[ "$1" != *"$2"* ]]; then
        pass "$3"
    else
        fail "$3" "did not expect to find '$2'"
    fi
}

# assert_true <command...> -- runs the command, passes on exit 0
# Usage: assert_true "description" command args...
assert_true() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        pass "$desc"
    else
        fail "$desc" "command failed: $*"
    fi
}

# assert_false "description" command args...
assert_false() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        fail "$desc" "command unexpectedly succeeded: $*"
    else
        pass "$desc"
    fi
}

assert_file_exists() {
    if [[ -f "$1" ]]; then pass "$2"; else fail "$2" "missing file: $1"; fi
}

# A real TrueType/OpenType file starts with one of these signatures. This is the
# check that a non-empty, plausibly sized HTML error page fails.
is_truetype() {
    local magic
    magic=$(head -c 4 "$1" 2>/dev/null | od -An -tx1 2>/dev/null | tr -d ' \n') || return 1
    [[ "$magic" == "00010000" || "$magic" == "74727565" || "$magic" == "4f54544f" ]]
}

# Strip ANSI escapes and shell prompt-escape wrappers from rendered output.
strip_ansi() {
    sed -e 's/\x1b\[[0-9;]*[A-Za-z]//g' -e 's/\x1b\][^\x07]*\x07//g' \
        -e 's/%{//g' -e 's/%}//g' -e 's/\\\[//g' -e 's/\\\]//g'
}

finish() {
    local total=$((TESTS_PASSED + TESTS_FAILED))
    printf '\n%s%s%s\n' "$_BOLD" "--------------------------------------------------" "$_NC"
    printf '  %spassed: %d%s   %sfailed: %d%s   %sskipped: %d%s   (of %d assertions)\n' \
        "$_GREEN" "$TESTS_PASSED" "$_NC" \
        "$_RED" "$TESTS_FAILED" "$_NC" \
        "$_YELLOW" "$TESTS_SKIPPED" "$_NC" "$total"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        printf '\n  Failed:\n'
        local n
        for n in "${FAILED_NAMES[@]}"; do printf '    - %s\n' "$n"; done
        printf '\n'
        exit 1
    fi
    printf '\n'
    exit 0
}
