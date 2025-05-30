# Kartik's Oh My Posh Theme

My favourite modern prompt theme - works across multiple shells with a beautiful color palette.

![Theme Preview](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/preview.png)

## Features

### OS-specific icons (Windows, macOS, Linux)
![Apple Icon](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/apple_icon.png)

### Username display with a person icon
![Username](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/username.png)

### Dynamic computer name with a computer icon
![Computer Name](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/computer_name.png)

### Root user indicator
![Root Indicator](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/root_indicator.png)

### Current directory path with folder icon
![Directory Path](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/directory_path.png)

### Git status information with Octocat icon
![Git Status](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/git_status.png)

### Time display on the right side
![Time Display](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/time_display.png)

### Clean prompt character for input
![Prompt Character](https://github.com/kartikshankar-nyc/kartikshankar-ohmyposh-theme/raw/main/segment_images/prompt_character.png)

## Color Palette

This theme uses a beautiful, harmonious palette:
- Charcoal: `#264653`
- Persian Green: `#2a9d8f`
- Saffron: `#e9c46a`
- Sandy Brown: `#f4a261`
- Burnt Sienna: `#e76f51`
- Dark Teal: `#1e756a`
- Slate Blue: `#536878`

## One-Click Installation

The easiest way to install this theme is using the provided installation scripts.

### macOS/Linux One-Click Install

1. Download this repository, open Terminal in the repository directory, and run:
   ```bash
   ./install.sh
   ```

2. The script will:
   - Check and install Homebrew (macOS) or required packages (Linux)
   - Install Oh My Posh if not already installed
   - Install Hack Nerd Font if not already installed
   - Configure your shell (.zshrc or .bashrc) automatically
   - Apply the theme to your current session

### Windows One-Click Install

1. Download this repository, open PowerShell (ideally as Administrator), navigate to the repository directory, and run:
   ```powershell
   # You may need to allow script execution first
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   
   # Run the installer
   .\install.ps1
   ```

2. The script will:
   - Install Winget if not present (may require interaction)
   - Install Windows Terminal if not present
   - Install Git if not present
   - Install Oh My Posh if not present
   - Install Hack Nerd Font
   - Configure PowerShell, Command Prompt, and Git Bash automatically
   - Apply the theme to your current session

## Bundled Nerd Fonts

This repository includes the Hack Nerd Font family in the `fonts` directory to ensure you can install the theme even in environments with limited internet access or when facing issues with font downloads.

The installation scripts will:
1. First try to install Hack Nerd Font using standard methods (Homebrew, Oh My Posh's font installer)
2. If those methods fail (e.g., network issues, proxy problems), the scripts will automatically fall back to installing the bundled fonts

The bundled fonts include:
- Hack Regular Nerd Font Complete
- Hack Bold Nerd Font Complete 
- Hack Italic Nerd Font Complete
- Hack Bold Italic Nerd Font Complete

For detailed font installation troubleshooting, see [Font Installation Guide](test_results/font_installation_guide.md).

## Complete Installation Guide

If you prefer to install manually or encounter issues with the one-click installers, follow the detailed guide below for your specific environment.

### macOS Installation

#### Prerequisites (If Starting from Scratch)

1. **Install Homebrew** (If not already installed):
   
   Open Terminal (press `Cmd+Space`, type "Terminal", and press Enter) and run:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   
   Follow the prompts to complete installation.
   
   After installation, make sure Homebrew is in your PATH by following the instructions shown at the end of the installation output, which typically involves running these two commands:
   ```bash
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

2. **Install Git** (If not already installed):
   ```bash
   brew install git
   ```

#### Installing Oh My Posh

1. **Install Oh My Posh**:
   ```bash
   brew install oh-my-posh
   ```

2. **Verify installation**:
   ```bash
   oh-my-posh --version
   ```
   
   You should see a version number displayed if the installation was successful.

#### Installing a Nerd Font

Nerd Fonts are essential for displaying the icons in the theme.

1. **Install a Nerd Font** (Hack is recommended):
   ```bash
   brew tap homebrew/cask-fonts
   brew install --cask font-hack-nerd-font
   ```

   If you encounter issues with the Homebrew installation, you can manually install the bundled Nerd Fonts:
   ```bash
   # Navigate to the fonts directory in the repository
   cd path/to/repository/fonts
   
   # Copy the fonts to your user fonts directory
   mkdir -p ~/Library/Fonts
   cp *.ttf ~/Library/Fonts/
   ```

2. **Configure Terminal to use the Nerd Font**:

   **For Terminal.app**:
   - Open Terminal
   - Go to Terminal > Settings... (or press `Cmd+,`)
   - Select the "Profiles" tab
   - Select your profile on the left
   - Click the "Font" button
   - Find and select "Hack Nerd Font" from the list
   - Click "OK" to save your changes

   **For iTerm2** (recommended - if not installed, run `brew install --cask iterm2`):
   - Open iTerm2
   - Go to iTerm2 > Settings... (or press `Cmd+,`)
   - Go to Profiles > Text
   - Click on "Font" and change it to "Hack Nerd Font"
   - Click "OK" to save your changes

   **For VS Code**:
   - Open VS Code
   - Press `Cmd+,` to open Settings
   - Search for "terminal font family"
   - In "Terminal > Integrated: Font Family", type `'Hack Nerd Font'`
   - Restart VS Code to apply changes

#### Installing the Theme

1. **Clone the repository**:
   ```bash
   # Navigate to your home directory
   cd ~
   
   # Create a folder for the theme (if you want to keep it organized)
   mkdir -p .oh-my-posh-themes
   
   # Navigate to that folder
   cd .oh-my-posh-themes
   
   # Clone the repository
   git clone https://github.com/kartikshankar/kartikshankar-ohmyposh-theme.git
   
   # Navigate into the repository
   cd kartikshankar-ohmyposh-theme
   ```

2. **Get the full path to the theme file** (we'll need this for the next step):
   ```bash
   echo "$(pwd)/kartikshankar.omp.json"
   ```
   
   Copy the output of this command as you'll need it in the next step.

#### Configuring Your Shell

Choose the instructions for your shell:

**For Zsh** (Default shell on macOS since Catalina):

1. **Edit your `~/.zshrc` file**:
   ```bash
   nano ~/.zshrc
   ```

2. **Add the following line** at the end of the file (replace the path with the one you copied in the previous step):
   ```bash
   eval "$(oh-my-posh init zsh --config ~/path/to/kartikshankar.omp.json)"
   ```

3. **Save and exit** by pressing `Ctrl+O`, then `Enter`, then `Ctrl+X`.

4. **Apply the changes**:
   ```bash
   source ~/.zshrc
   ```

**For Bash**:

1. **Edit your `~/.bash_profile` file**:
   ```bash
   nano ~/.bash_profile
   ```

2. **Add the following line** at the end of the file (replace the path with the one you copied previously):
   ```bash
   eval "$(oh-my-posh init bash --config ~/path/to/kartikshankar.omp.json)"
   ```

3. **Save and exit** by pressing `Ctrl+O`, then `Enter`, then `Ctrl+X`.

4. **Apply the changes**:
   ```bash
   source ~/.bash_profile
   ```

**For Git Bash on macOS**:

1. **Edit your `~/.bashrc` file** (create if it doesn't exist):
   ```bash
   touch ~/.bashrc  # Create if it doesn't exist
   nano ~/.bashrc
   ```

2. **Add the following line** at the end of the file (replace the path with the correct one):
   ```bash
   eval "$(oh-my-posh init bash --config ~/path/to/kartikshankar.omp.json)"
   ```

3. **Save and exit** by pressing `Ctrl+O`, then `Enter`, then `Ctrl+X`.

4. **Apply the changes**:
   ```bash
   source ~/.bashrc
   ```

**For PowerShell on macOS**:

1. First, ensure PowerShell is installed:
   ```bash
   brew install --cask powershell
   ```

2. **Open PowerShell**:
   ```bash
   pwsh
   ```

3. **Create a PowerShell profile if it doesn't exist**:
   ```powershell
   if (!(Test-Path -Path $PROFILE)) {
     New-Item -ItemType File -Path $PROFILE -Force
   }
   ```

4. **Edit your PowerShell profile**:
   ```powershell
   nano $PROFILE
   ```

5. **Add the following line** to the profile (replace the path with your actual theme path):
   ```powershell
   oh-my-posh init pwsh --config '~/path/to/kartikshankar.omp.json' | Invoke-Expression
   ```

6. **Save and exit** by pressing `Ctrl+O`, then `Enter`, then `Ctrl+X`.

7. **Apply the changes**:
   ```powershell
   . $PROFILE
   ```

#### Verifying the Installation

1. **Open a new terminal window** or tab to see your new theme in action.

2. If the prompt doesn't look right, check these common issues:
   - Make sure the Nerd Font is correctly set in your terminal
   - Try running `oh-my-posh debug` to check if Oh My Posh is working correctly
   - Verify the path to the theme file is correct

### Windows Installation

#### Prerequisites (If Starting from Scratch)

1. **Install Windows Terminal** (Recommended for best experience):
   - Open Microsoft Store
   - Search for "Windows Terminal"
   - Click "Get" or "Install"
   
   Alternatively, you can download it from the [Microsoft website](https://aka.ms/terminal).

2. **Install PowerShell 7** (Recommended, but PowerShell 5.1 also works):
   - Open Microsoft Store
   - Search for "PowerShell"
   - Select "PowerShell" (not "PowerShell Preview")
   - Click "Get" or "Install"
   
   Alternatively, you can download it from the [PowerShell GitHub](https://github.com/PowerShell/PowerShell/releases).

3. **Install Git** (if not already installed):
   - Download from [git-scm.com](https://git-scm.com/download/win)
   - Run the installer, using default options is fine

#### Installing Oh My Posh

1. **Open PowerShell** (Windows Terminal with PowerShell 7 is recommended).

2. **Install Oh My Posh using winget**:
   ```powershell
   winget install JanDeDobbeleer.OhMyPosh
   ```
   
   If winget is not available, you can use the installer script:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression
   scoop install oh-my-posh
   ```

3. **Restart your PowerShell/terminal** after installation.

4. **Verify installation**:
   ```powershell
   oh-my-posh --version
   ```

#### Installing a Nerd Font

1. **Install a Nerd Font using Oh My Posh**:
   ```powershell
   oh-my-posh font install
   ```
   
   This will open a menu. Choose "Hack" (recommended) or any other Nerd Font you prefer by typing its number and pressing Enter.

   If you encounter network issues or the above command fails, you can use the bundled fonts:
   ```powershell
   # Navigate to the fonts directory in the repository
   cd path\to\repository\fonts
   
   # Install the fonts by right-clicking and selecting "Install"
   # Or you can use the following to open the folder and install them manually
   explorer.exe .
   ```

2. **Configure Windows Terminal to use the Nerd Font**:
   - Open Windows Terminal
   - Click the dropdown arrow and select "Settings" (or press `Ctrl+,`)
   - Click on your profile (e.g., "PowerShell", "Command Prompt")
   - Scroll down to "Appearance"
   - Change "Font face" to "Hack Nerd Font" (or whichever font you installed)
   - Click "Save"
   - Restart Windows Terminal

   **For VS Code**:
   - Open VS Code
   - Press `Ctrl+,` to open Settings
   - Search for "terminal font family"
   - In "Terminal > Integrated: Font Family", type `'Hack Nerd Font'`
   - Restart VS Code to apply changes

#### Installing the Theme

1. **Create a folder for the theme**:
   ```powershell
   # Navigate to your Documents folder
   cd ~\Documents
   
   # Create a folder for the theme
   mkdir oh-my-posh-themes
   
   # Navigate to that folder
   cd oh-my-posh-themes
   ```

2. **Clone the repository**:
   ```powershell
   git clone https://github.com/kartikshankar/kartikshankar-ohmyposh-theme.git
   
   # Navigate into the repository
   cd kartikshankar-ohmyposh-theme
   ```

3. **Get the full path to the theme file**:
   ```powershell
   (Get-Item .\kartikshankar.omp.json).FullName
   ```
   
   Copy the output of this command as you'll need it in the next step.

#### Configuring Your Shell

**For PowerShell 7 or PowerShell 5.1**:

1. **Check if a PowerShell profile exists**:
   ```powershell
   Test-Path $PROFILE
   ```
   
   If this returns `False`, create the profile:
   ```powershell
   New-Item -Path $PROFILE -Type File -Force
   ```

2. **Edit your PowerShell profile**:
   ```powershell
   notepad $PROFILE
   ```
   
   If Notepad doesn't open your profile, try using VS Code or another text editor:
   ```powershell
   code $PROFILE  # If VS Code is installed
   ```

3. **Add the following line** to your profile (replace the path with the one you copied in the previous step):
   ```powershell
   oh-my-posh init pwsh --config "C:\Users\YourUsername\Documents\oh-my-posh-themes\kartikshankar-ohmyposh-theme\kartikshankar.omp.json" | Invoke-Expression
   ```

4. **Save and close** the file.

5. **Apply the changes**:
   ```powershell
   . $PROFILE
   ```

**For Command Prompt**:

1. **Create a Lua script for Command Prompt**:
   ```powershell
   $luaScript = @"
   load(io.popen('oh-my-posh init cmd --config "C:/Users/YourUsername/Documents/oh-my-posh-themes/kartikshankar-ohmyposh-theme/kartikshankar.omp.json"'):read("*a"))()
   "@
   
   # Replace the path with your actual path
   $luaScript = $luaScript -replace "C:/Users/YourUsername", $env:USERPROFILE.Replace('\', '/')
   
   # Save the script
   $luaScript | Out-File -FilePath "$env:USERPROFILE\oh-my-posh.lua" -Encoding utf8
   ```

2. **Set up Command Prompt to use the script**:
   - Open Registry Editor (`regedit`)
   - Navigate to `HKEY_CURRENT_USER\Software\Microsoft\Command Processor`
   - Right-click > New > String Value
   - Name: `AutoRun`
   - Value: `%USERPROFILE%\oh-my-posh.lua`

3. **Restart Command Prompt** to see the changes.

**For Git Bash on Windows**:

1. **Edit your Git Bash profile**:
   ```bash
   notepad ~/.bashrc
   ```
   
   If the file doesn't exist, it will be created.

2. **Add the following line** to the profile (replace the path with your actual theme path, and use forward slashes):
   ```bash
   eval "$(oh-my-posh init bash --config '/c/Users/YourUsername/Documents/oh-my-posh-themes/kartikshankar-ohmyposh-theme/kartikshankar.omp.json')"
   ```

3. **Save and close** the file.

4. **Apply the changes** by restarting Git Bash or running:
   ```bash
   source ~/.bashrc
   ```

#### Verifying the Installation

1. **Start a new instance** of your shell (PowerShell, Command Prompt, or Git Bash).

2. **Check if the theme is displayed correctly**.

3. If you see boxes or missing icons:
   - Make sure the Nerd Font is correctly set in your terminal
   - Try a different Nerd Font: `oh-my-posh font install` and choose another font
   - Use the bundled Nerd Fonts in the repository's `fonts` directory

#### Troubleshooting Windows Installation

1. **Icons not displaying correctly**:
   - Verify you're using a Nerd Font
   - Try running: `oh-my-posh font install` and choose a different font
   - Use the bundled Nerd Fonts in the repository's `fonts` directory

2. **Error when running the init command**:
   - Make sure the path to the theme file is correct
   - If using PowerShell, ensure execution policy allows scripts:
     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
     ```

3. **Path issues**:
   - Ensure you're using the correct path format:
     - PowerShell: `C:\Users\Username\path\to\theme.json` or `$env:USERPROFILE\path\to\theme.json`
     - Command Prompt (in Lua script): `C:/Users/Username/path/to/theme.json` (note the forward slashes)
     - Git Bash: `/c/Users/Username/path/to/theme.json` (Git Bash style paths)

4. **Font download issues**:
   - If you encounter the "failed to get nerd fonts release" error or other download issues, use the bundled fonts provided in the repository's `fonts` directory

## Customization

Feel free to customize this theme to your liking by modifying the JSON configuration file. For detailed documentation on all available options, refer to the [Oh My Posh documentation](https://ohmyposh.dev/docs/configuration/overview).

## Using VS Code Integrated Terminal

If you're using VS Code's integrated terminal, follow these additional steps:

### macOS:

1. Open VS Code settings (Cmd+,)
2. Search for "terminal font family"
3. Set "Terminal > Integrated: Font Family" to `'Hack Nerd Font'` (including the quotes)
4. Restart VS Code

### Windows:

1. Open VS Code settings (Ctrl+,)
2. Search for "terminal font family" 
3. Set "Terminal > Integrated: Font Family" to `'Hack Nerd Font'` (including the quotes)
4. Restart VS Code

## Using the Theme with Other Terminal Emulators

### For Alacritty (macOS/Windows/Linux):

1. Edit your `alacritty.yml` file
2. Under the `font` section, set:
   ```yaml
   font:
     normal:
       family: "Hack Nerd Font"
   ```

### For Hyper (macOS/Windows/Linux):

1. Edit `.hyper.js` in your home directory
2. Find the `fontFamily` setting and change to:
   ```js
   fontFamily: '"Hack Nerd Font", monospace',
   ```

## Troubleshooting Common Issues

### Font Issues

**Symptom**: Boxes or question marks instead of icons

**Solution**:
1. Verify you've installed a Nerd Font (`brew list | grep font` on macOS or `oh-my-posh font list` on Windows)
2. Make sure your terminal is configured to use the Nerd Font
3. Try a different Nerd Font if issues persist
4. Use the bundled Nerd Fonts in the repository's `fonts` directory

### Font Download Issues

**Symptom**: "Failed to get nerd fonts release" error when trying to download fonts

**Solution**:
1. You might have network connectivity issues or proxy restrictions
2. Use the bundled fonts in the repository's `fonts` directory
3. For Windows, navigate to the `fonts` folder and manually install the fonts
4. For macOS/Linux, copy the font files to your user's font directory

### Path Issues

**Symptom**: Oh My Posh not finding theme file

**Solution**:
1. Use the absolute path to the theme file
2. On Windows, make sure to use the correct path format (backslashes typically, forward slashes in Lua script)
3. Verify the file exists at the specified location

### Performance Issues

**Symptom**: Terminal is slow to start

**Solution**:
1. Run `oh-my-posh debug` to identify potential issues
2. Consider simplifying the theme by removing segments you don't need

## Test Results

This theme has been thoroughly tested to ensure it works correctly across different platforms and terminals. Test results and additional documentation can be found in the `test_results` directory:

- [Latest Test Summary](test_results/latest_test_summary.md) - Overall test results and recent improvements
- [Font Installation Guide](test_results/font_installation_guide.md) - Detailed guide for troubleshooting font issues
- [Test Run Output](test_results/test_run_output.txt) - Raw output from the latest test run

To run the tests yourself:
```bash
./run-all-tests.sh
```

## Getting Help

If you encounter issues with this theme:

1. Check the official [Oh My Posh documentation](https://ohmyposh.dev/docs/)
2. Visit the [Oh My Posh GitHub repository](https://github.com/JanDeDobbeleer/oh-my-posh)
3. Join the [Oh My Posh Discord community](https://discord.gg/5JqnmUZBdw)
4. Check our [Font Installation Guide](test_results/font_installation_guide.md) for font-specific issues

## License

MIT

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request. 
