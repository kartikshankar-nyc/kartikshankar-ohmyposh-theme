# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A custom Oh My Posh terminal prompt theme (`kartikshankar.omp.json`) with cross-platform
installers and a behavioural test suite. Oh My Posh is a prompt theme engine for any shell.
The theme uses Nerd Font glyphs and a fixed colour palette.

## Key Files

- `kartikshankar.omp.json` — the theme definition. This is the core artifact.
- `install.sh` — installer for macOS, Linux, WSL, and Git Bash
- `install.ps1` — installer for Windows and macOS (PowerShell)
- `test-lib.sh` — shared assertion helpers sourced by every test suite
- `fonts/` — genuine Hack Nerd Font v3.4.0 TTFs, with checksums in `fonts/README.md`
- `segment_images/` — hand-authored SVG mockups used by the README

## Theme Architecture

Three prompt blocks:

1. **Left, primary line**: OS icon (diamond) → username (powerline) → hostname → root
   indicator → directory → git status
2. **Right, primary line**: clock (diamond)
3. **New line**: red `❯` input prompt

The git segment uses `background_templates` to change colour with repository state:
dirty `#e76f51`, ahead+behind `#f4a261`, ahead `#2a9d8f`, behind `#e9c46a`, clean `#1e756a`.

### Colour palette

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

```bash
./run-all-tests.sh                 # all suites
./run-all-tests.sh theme           # suites matching a substring
./test-theme.sh                    # one suite directly

oh-my-posh print primary --config kartikshankar.omp.json   # preview
jq . kartikshankar.omp.json                                # validate JSON
./install.sh --dry-run                                     # preview installer changes
```

Tests require `oh-my-posh` and `jq`.

## Conventions That Matter Here

These encode bugs this repository has actually shipped. Preserve them.

- **The macOS OS-segment key is `macos`, not `darwin`.** Oh My Posh silently ignores
  unknown keys and falls back to a built-in icon, so `darwin` looks like it works on a Mac
  while doing nothing.
- **Never infer the user's shell from `$BASH_VERSION` inside a bash script.** It is always
  set. Use `$SHELL`. Getting this wrong writes the config to `~/.bash_profile` for zsh
  users, and the prompt silently never appears.
- **Never rewrite rc files with a greedy `sed`.** The installers manage a marked block
  (`# >>> kartikshankar oh-my-posh theme >>>` … `# <<< … <<<`), back the file up first, and
  leave everything outside the block untouched.
- **Verify, do not assume, that a font installed.** Check for the font afterwards rather
  than reporting success because a command ran.
- **Validate that font files are fonts.** Check the TrueType signature (`0x00010000`). This
  repository once shipped four GitHub 404 HTML pages named `*.ttf`; they were non-empty and
  correctly sized, and every existence and size check passed.
- **Icons in the theme JSON are `\uXXXX` escapes**, never raw characters, so the file is
  readable without a Nerd Font. A test enforces this.
- **The theme stays on `"version": 3` with `properties`** rather than the newer `options`
  key, for compatibility with older Oh My Posh builds. This is what `oh-my-posh config
  migrate` currently emits.

## Writing Tests

Assertions live in `test-lib.sh`. A test must execute the thing under test and inspect the
result. Grepping a script for a keyword is not a test — an earlier version of this suite
reported "52 passed, 0 failed" against a repository whose installer did not work on macOS
and whose bundled fonts were HTML.

For installer tests, run `install.sh` against a throwaway `HOME`. Override `ZDOTDIR` as
well: zsh honours it over `$HOME`, and leaving it set sends writes to the real home
directory.

## Installer Behaviour

Both installers: detect the platform → install Oh My Posh → install a Nerd Font (falling
back to `fonts/`) → resolve the theme path → write a marked block into the relevant shell
config → print the terminal-specific font instructions.

Neither claims to have applied the theme to the calling shell. They run in their own
process and cannot change the parent shell's prompt; they tell the user to restart instead.
