#!/usr/bin/env bash
#
# Runs every test suite and reports a combined result.
#
# Exits 0 only if all suites pass. Suites are independent; a failure in one does
# not stop the others, so a single run reports every problem.
#
# Usage:
#   ./run-all-tests.sh            # run everything
#   ./run-all-tests.sh theme      # run suites whose name matches 'theme'
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
    MAGENTA=$'\033[0;35m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; MAGENTA=""; BOLD=""; NC=""
fi

SUITES=(
    "test-theme.sh"
    "test-dynamic-segments.sh"
    "test-installation-scripts.sh"
    "test-comprehensive-validation.sh"
)

FILTER="${1:-}"

# Preflight: report missing tooling once rather than failing four times.
MISSING=()
command -v oh-my-posh >/dev/null 2>&1 || MISSING+=("oh-my-posh")
command -v jq         >/dev/null 2>&1 || MISSING+=("jq")
if [[ ${#MISSING[@]} -gt 0 ]]; then
    printf '%s[ERROR]%s Required tooling is missing: %s\n' "$RED" "$NC" "${MISSING[*]}" >&2
    printf '  macOS:  brew install %s\n' "${MISSING[*]}" >&2
    printf '  Linux:  see https://ohmyposh.dev/docs/installation/linux and your package manager for jq\n' >&2
    exit 1
fi

printf '\n%s%s%s\n' "$BOLD$MAGENTA" "Kartik's Oh My Posh theme - test suite" "$NC"
printf '  oh-my-posh %s\n' "$(oh-my-posh --version 2>/dev/null || echo unknown)"
printf '  bash %s on %s\n\n' "${BASH_VERSION%%(*}" "$(uname -s)"

FAILED_SUITES=()
PASSED_SUITES=()
SKIPPED_SUITES=()

for suite in "${SUITES[@]}"; do
    if [[ -n "$FILTER" && "$suite" != *"$FILTER"* ]]; then
        SKIPPED_SUITES+=("$suite")
        continue
    fi

    if [[ ! -f "$SCRIPT_DIR/$suite" ]]; then
        printf '%s[ERROR]%s Suite not found: %s\n' "$RED" "$NC" "$suite"
        FAILED_SUITES+=("$suite")
        continue
    fi

    printf '%s%s>>> %s%s\n' "$BOLD" "$MAGENTA" "$suite" "$NC"

    # Invoke through bash so the suite runs even without the executable bit.
    # (The previous runner ran `chmod +x *.sh`, which silently changed the mode
    # of install.sh and every other script in the directory as a side effect.)
    if bash "$SCRIPT_DIR/$suite"; then
        PASSED_SUITES+=("$suite")
    else
        FAILED_SUITES+=("$suite")
    fi
done

printf '\n%s%s%s\n' "$BOLD$MAGENTA" "==================== summary ====================" "$NC"

for s in ${PASSED_SUITES[@]+"${PASSED_SUITES[@]}"}; do
    printf '  %sPASS%s %s\n' "$GREEN" "$NC" "$s"
done
for s in ${FAILED_SUITES[@]+"${FAILED_SUITES[@]}"}; do
    printf '  %sFAIL%s %s\n' "$RED" "$NC" "$s"
done
for s in ${SKIPPED_SUITES[@]+"${SKIPPED_SUITES[@]}"}; do
    printf '  %sSKIP%s %s (filtered out)\n' "$YELLOW" "$NC" "$s"
done

printf '\n'
if [[ ${#FAILED_SUITES[@]} -eq 0 ]]; then
    printf '  %sAll %d suite(s) passed.%s\n\n' "$GREEN" "${#PASSED_SUITES[@]}" "$NC"
    exit 0
fi

printf '  %s%d of %d suite(s) failed.%s\n\n' \
    "$RED" "${#FAILED_SUITES[@]}" "$(( ${#FAILED_SUITES[@]} + ${#PASSED_SUITES[@]} ))" "$NC"
exit 1
