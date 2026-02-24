# Kartik's Oh My Posh Theme

A modern, cross-platform terminal prompt theme with dynamic OS icons, git status indicators, and a warm color palette. Works with Zsh, Bash, PowerShell, Command Prompt, and Git Bash.

![Theme Preview](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/preview.png)

### Theme in VS Code / Cursor IDE

![IDE Preview](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/ide-preview.png)

## Features

| Segment | Description | Preview |
|---------|-------------|---------|
| OS Icon | Auto-detects Windows, macOS, or Linux | ![Apple Icon](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/apple_icon.png) |
| Username | Current user with person icon | ![Username](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/username.png) |
| Hostname | Dynamic computer name | ![Computer Name](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/computer_name.png) |
| Root Indicator | Visible when running as root/admin | ![Root Indicator](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/root_indicator.png) |
| Directory | Current path with folder icon | ![Directory Path](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/directory_path.png) |
| Git Status | Branch, staged/unstaged changes with color-coded background | ![Git Status](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/git_status.png) |
| Time | Right-aligned clock | ![Time Display](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/time_display.png) |
| Prompt | Clean red `>` on a new line | ![Prompt Character](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/prompt_character.png) |

### Git Status Color Coding

The git segment background changes dynamically:

| State | Color | Hex |
|-------|-------|-----|
| Dirty (uncommitted changes) | Burnt Sienna | `#e76f51` |
| Ahead and behind remote | Sandy Brown | `#f4a261` |
| Ahead of remote | Persian Green | `#2a9d8f` |
| Behind remote | Saffron | `#e9c46a` |
| Clean | Dark Teal | `#1e756a` |

### Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| Charcoal | `#264653` | OS icon background |
| Persian Green | `#2a9d8f` | Username background |
| Saffron | `#e9c46a` | Directory background |
| Sandy Brown | `#f4a261` | Hostname background |
| Burnt Sienna | `#e76f51` | Root indicator, prompt character |
| Dark Teal | `#1e756a` | Git segment (clean) |
| Slate Blue | `#536878` | Time display |

## Quick Start

### macOS / Linux

```bash
git clone https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme.git
cd kartikshankar-ohmyposh-theme
./install.sh
```

The script handles everything: Homebrew (macOS), Oh My Posh, Hack Nerd Font, shell configuration, and theme activation.

### Windows (PowerShell)

```powershell
git clone https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme.git
cd kartikshankar-ohmyposh-theme
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\install.ps1
```

Run as Administrator for best results. The script installs Winget, Windows Terminal, Oh My Posh, Hack Nerd Font, and configures PowerShell, Command Prompt (requires [Clink](https://chrisant996.github.io/clink/)), and Git Bash.

## Manual Installation

### Prerequisites

| Platform | Package Manager | Install Command |
|----------|----------------|-----------------|
| macOS | Homebrew | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| Windows | Winget | Included with Windows 10 1809+ |
| Linux | apt/dnf/pacman | Already available |

### Step 1: Install Oh My Posh

**macOS:**
```bash
brew install oh-my-posh
```

**Windows:**
```powershell
winget install JanDeDobbeleer.OhMyPosh
```

**Linux:**
```bash
curl -s https://ohmyposh.dev/install.sh | bash -s
```

Verify: `oh-my-posh --version`

### Step 2: Install Hack Nerd Font

**macOS:**
```bash
brew install --cask font-hack-nerd-font
```

**Windows:**
```powershell
oh-my-posh font install Hack
```

**Linux:**
```bash
oh-my-posh font install Hack
```

If font installation fails (network issues, proxy), use the bundled fonts in the `fonts/` directory:
```bash
# macOS
cp fonts/*.ttf ~/Library/Fonts/

# Linux
mkdir -p ~/.local/share/fonts && cp fonts/*.ttf ~/.local/share/fonts/ && fc-cache -f
```

### Step 3: Configure Your Terminal Font

Set your terminal's font to **Hack Nerd Font**:

| Terminal | Setting Location |
|----------|-----------------|
| macOS Terminal.app | Terminal > Settings > Profiles > Font |
| iTerm2 | Settings > Profiles > Text > Font |
| Windows Terminal | Settings > Profile > Appearance > Font face |
| VS Code / Cursor | Settings > `terminal.integrated.fontFamily` > `'Hack Nerd Font'` |
| Alacritty | `font.normal.family: "Hack Nerd Font"` in config |
| Hyper | `fontFamily: '"Hack Nerd Font", monospace'` in `.hyper.js` |

### Step 4: Clone and Configure

```bash
mkdir -p ~/.oh-my-posh-themes
git clone https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme.git ~/.oh-my-posh-themes/kartikshankar-ohmyposh-theme
```

Add the appropriate line to your shell config:

**Zsh** (`~/.zshrc`):
```bash
eval "$(oh-my-posh init zsh --config ~/.oh-my-posh-themes/kartikshankar-ohmyposh-theme/kartikshankar.omp.json)"
```

**Bash** (`~/.bashrc` or `~/.bash_profile` on macOS):
```bash
eval "$(oh-my-posh init bash --config ~/.oh-my-posh-themes/kartikshankar-ohmyposh-theme/kartikshankar.omp.json)"
```

**PowerShell** (`$PROFILE`):
```powershell
oh-my-posh init pwsh --config '~/.oh-my-posh-themes/kartikshankar-ohmyposh-theme/kartikshankar.omp.json' | Invoke-Expression
```

**Command Prompt** (requires [Clink](https://chrisant996.github.io/clink/)):

Create `%USERPROFILE%\oh-my-posh.lua`:
```lua
load(io.popen('oh-my-posh init cmd --config "C:/Users/YourUsername/.oh-my-posh-themes/kartikshankar-ohmyposh-theme/kartikshankar.omp.json"'):read("*a"))()
```
Then set `HKCU\Software\Microsoft\Command Processor\AutoRun` to `%USERPROFILE%\oh-my-posh.lua`.

**Git Bash** (`~/.bashrc`):
```bash
eval "$(oh-my-posh init bash --config ~/.oh-my-posh-themes/kartikshankar-ohmyposh-theme/kartikshankar.omp.json)"
```

Restart your terminal or source the config file to apply.

## Bundled Nerd Fonts

The `fonts/` directory includes the complete Hack Nerd Font family as a fallback:
- Hack Regular Nerd Font Complete
- Hack Bold Nerd Font Complete
- Hack Italic Nerd Font Complete
- Hack Bold Italic Nerd Font Complete

Both installation scripts automatically fall back to these bundled fonts if network-based installation fails.

## Troubleshooting

### Boxes or question marks instead of icons

1. Verify the font is installed: `brew list --cask | grep font` (macOS) or `oh-my-posh font list` (Windows)
2. Make sure your terminal is configured to use `Hack Nerd Font`
3. Try the bundled fonts in `fonts/` if download-based installation failed

### "Failed to get nerd fonts release" error

Use the bundled fonts -- copy from `fonts/` to your system font directory (see Step 2 above).

### Theme not loading

1. Verify the path in your shell config file is correct
2. Check that the file exists: `ls ~/.oh-my-posh-themes/kartikshankar-ohmyposh-theme/kartikshankar.omp.json`
3. Run `oh-my-posh debug` for diagnostic info

### Slow terminal startup

Run `oh-my-posh debug` to identify bottlenecks. The theme typically renders in under 50ms.

### Command Prompt shows errors

Oh My Posh for Command Prompt requires [Clink](https://chrisant996.github.io/clink/). Install Clink first, then configure the `.lua` AutoRun script.

## Testing

Run the full test suite:
```bash
./run-all-tests.sh
```

This executes 4 test suites:
- `test-theme.sh` -- Theme JSON validation, segment presence, rendering, performance
- `test-dynamic-segments.sh` -- OS detection, hostname rendering, icon properties
- `test-installation-scripts.sh` -- Script syntax, cross-platform feature checks
- `test-comprehensive-validation.sh` -- 54-point deep validation of theme, installers, and docs

## Customization

Edit `kartikshankar.omp.json` to customize. The theme follows the [Oh My Posh v3 schema](https://ohmyposh.dev/docs/configuration/overview). Segment templates use Go template syntax. See the [segments documentation](https://ohmyposh.dev/docs/configuration/segment) for available properties.

## Getting Help

1. [Oh My Posh documentation](https://ohmyposh.dev/docs/)
2. [Oh My Posh GitHub](https://github.com/JanDeDobbeleer/oh-my-posh)
3. [Oh My Posh Discord](https://discord.gg/5JqnmUZBdw)
4. [Font Installation Guide](test_results/font_installation_guide.md)

## License

MIT

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
