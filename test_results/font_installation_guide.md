# Nerd Font Installation Guide and Troubleshooting

This guide focuses on solving common Nerd Font installation issues with Oh My Posh themes, specifically addressing the "failed to get nerd fonts release" error.

## Common Font Installation Issues

### 1. "Failed to get nerd fonts release" Error

**Problem**: When running `oh-my-posh font install` you encounter an error like:
```
failed to get nerd fonts release
```

**Causes**:
- Network connectivity issues
- Proxy or firewall restrictions
- GitHub API rate limiting
- Temporary GitHub outages

**Solutions**:
1. **Use Bundled Fonts (Recommended)**:
   - Our theme includes Hack Nerd Font files directly in the repository
   - The installation scripts will automatically use these bundled fonts when online installation fails
   - No additional action is required - the fallback happens automatically

2. **Manual Installation**:
   - Navigate to the `fonts` directory in this repository
   - For Windows: Right-click on the .ttf files and select "Install"
   - For macOS: Copy the .ttf files to `~/Library/Fonts/`
   - For Linux: Copy the .ttf files to `~/.local/share/fonts/` and run `fc-cache -fv`

3. **Configure Proxy** (if applicable):
   ```powershell
   # In PowerShell
   $env:HTTPS_PROXY="http://your-proxy-server:port/"
   $env:HTTP_PROXY="http://your-proxy-server:port/"
   ```
   
   ```bash
   # In Bash/Zsh
   export HTTPS_PROXY="http://your-proxy-server:port/"
   export HTTP_PROXY="http://your-proxy-server:port/"
   ```

### 2. Font Appears Installed But Icons Show as Boxes or Question Marks

**Problem**: You've installed the Nerd Font, but terminal still shows boxes or question marks instead of icons.

**Solutions**:
1. **Ensure Terminal Is Configured**:
   - Verify your terminal application is configured to use the Nerd Font
   - Windows Terminal: Settings > Profile > Appearance > Font Face > select "Hack Nerd Font"
   - macOS Terminal: Terminal > Settings > Profiles > Font > select "Hack Nerd Font"
   - VS Code: Settings > Terminal > Integrated: Font Family > set to "'Hack Nerd Font'"

2. **Try Different Font Variants**:
   - Some terminals work better with specific font variants
   - Try the regular, bold, or italic variants of Hack Nerd Font included in the `fonts` directory

3. **Verify Font Installation**:
   - Windows: Check in Control Panel > Fonts
   - macOS: Check in Font Book application
   - Linux: Run `fc-list | grep "Hack"`

## Font Configuration by Terminal

### Windows Terminal
```json
{
    "profiles": {
        "defaults": {
            "font": {
                "face": "Hack Nerd Font"
            }
        }
    }
}
```

### Visual Studio Code (settings.json)
```json
"terminal.integrated.fontFamily": "'Hack Nerd Font'"
```

### macOS Terminal
1. Terminal > Settings
2. Select the profile you're using
3. Click "Font"
4. Select "Hack Nerd Font"

### iTerm2
1. iTerm2 > Settings
2. Select Profiles > Text
3. Change Font to "Hack Nerd Font"

## Testing Font Installation

To verify your Nerd Font is working correctly:
```bash
oh-my-posh debug
```

This will show if Oh My Posh can detect and use your Nerd Font properly.

## Resources

- [Oh My Posh Font Documentation](https://ohmyposh.dev/docs/installation/fonts)
- [Nerd Fonts Repository](https://github.com/ryanoasis/nerd-fonts)
- [Hack Font Homepage](https://sourcefoundry.org/hack/)

## Font License Information

The bundled Hack Nerd Font is distributed under:
- Hack: MIT License
- Nerd Fonts: MIT License 