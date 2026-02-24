# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a custom Oh My Posh terminal prompt theme (`kartikshankar.omp.json`) with cross-platform installation scripts and a test suite. Oh My Posh is a prompt theme engine for any shell. The theme uses Nerd Font icons and a specific color palette.

## Key Files

- `kartikshankar.omp.json` - The theme definition (Oh My Posh v3 schema). This is the core artifact.
- `install.sh` - Bash installer for macOS/Linux/WSL/Git Bash
- `install.ps1` - PowerShell installer for Windows/macOS
- `fonts/` - Bundled Hack Nerd Font TTF files (fallback when network install fails)
- `segment_showcase.json` - Minimal Oh My Posh config used for generating segment preview images

## Theme Architecture

The theme (`kartikshankar.omp.json`) has 3 prompt blocks:

1. **Left-aligned primary line**: OS icon (diamond style) -> username (powerline) -> hostname (powerline) -> root indicator (powerline) -> directory path (powerline) -> git status (powerline with dynamic background colors)
2. **Right-aligned primary line**: Time display (diamond style)
3. **Newline input line**: Red `>` prompt character

The git segment uses `background_templates` to dynamically change color based on repository state (dirty = `#e76f51`, ahead+behind = `#f4a261`, ahead = `#2a9d8f`, behind = `#e9c46a`).

### Color Palette

| Name | Hex |
|------|-----|
| Charcoal | `#264653` |
| Persian Green | `#2a9d8f` |
| Saffron | `#e9c46a` |
| Sandy Brown | `#f4a261` |
| Burnt Sienna | `#e76f51` |
| Dark Teal | `#1e756a` |
| Slate Blue | `#536878` |

## Commands

### Run all tests
```bash
./run-all-tests.sh
```

### Run individual test suites
```bash
./test-theme.sh                  # Theme validation, JSON check, segment presence, rendering, performance
./test-dynamic-segments.sh       # OS detection, hostname dynamic logic, rendered output
./test-installation-scripts.sh   # Script existence, syntax, cross-platform feature checks
```

### Preview the theme
```bash
oh-my-posh print primary --config kartikshankar.omp.json
```

### Validate theme JSON
```bash
cat kartikshankar.omp.json | jq '.'
```

## Testing Requirements

- Tests require `oh-my-posh` and `jq` to be installed
- `test-theme.sh` creates a temporary git repo to test git segment rendering
- Tests are bash scripts that use exit codes (0 = pass, non-zero = fail)
- Cross-platform testing across shells (bash, zsh, PowerShell) is expected per CONTRIBUTING.md

## Installation Scripts

Both installers follow the same pattern: detect OS -> install package manager -> install Oh My Posh -> install Hack Nerd Font (with bundled font fallback) -> clone/update repo -> configure shell RC file -> apply theme.

- `install.sh` supports: macOS (Homebrew), Linux (apt/dnf/yum/pacman), WSL, Git Bash on Windows
- `install.ps1` supports: Windows (winget), macOS (Homebrew). Configures PowerShell, CMD (via Lua/registry), and Git Bash.

## Working with the Theme JSON

The theme follows the [Oh My Posh v3 schema](https://ohmyposh.dev/docs/configuration/overview). Segment templates use Go template syntax (`{{ .HostName }}`, `{{ .UserName }}`, `{{ .Path }}`, etc.). When modifying segments, preserve the powerline/diamond style chain and ensure Nerd Font unicode escapes are valid.
