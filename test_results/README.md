# Test Results

This directory contains the results of test runs for the Kartik's Oh My Posh Theme.

## Latest Test Run

The file `test_run_output.txt` contains the output from the latest test run, which verifies:

1. **Theme Functionality**: Ensures the theme file is valid and contains all required segments.
2. **Dynamic Segments**: Verifies that OS detection and hostname detection work properly.
3. **Installation Scripts**: Confirms that installation scripts work across different platforms and shells.
4. **Bundled Fonts**: Checks that bundled Nerd Fonts are present and the installation scripts handle font fallbacks correctly.

## Running Tests

To run all tests yourself, from the repository root, execute:

```bash
./run-all-tests.sh
```

## Individual Tests

You can also run individual tests:

```bash
# Test the theme itself
./test-theme.sh

# Test dynamic segments (OS detection and hostname)
./test-dynamic-segments.sh

# Test installation scripts and bundled font functionality
./test-installation-scripts.sh
```

## Test Status

All tests are currently passing. The test suite verifies that:

- Theme properly detects and uses OS-specific icons
- Theme uses dynamic hostname instead of hardcoded values
- Installation scripts support all target platforms (Windows, macOS, Linux)
- Bundled Nerd Fonts are available as fallback when online downloads fail
- All shell types are supported (PowerShell, Bash, Zsh, CMD, Git Bash) 