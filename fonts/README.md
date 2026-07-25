# Bundled Hack Nerd Font

These are the real Hack Nerd Font TrueType files, bundled so the theme can render
correctly on a machine where the network font install is blocked (corporate proxy,
offline VM, locked-down build agent).

## Provenance

| | |
|---|---|
| Upstream | [ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |
| Release | `v3.4.0` |
| Asset | `Hack.zip` |
| Font version | Hack `3.003`, patched with Nerd Fonts `3.4.0` |
| Family name | `Hack Nerd Font` |

The family name is what you type into your terminal's font setting. It is identical to
what `brew install --cask font-hack-nerd-font` and `oh-my-posh font install Hack`
produce, so a bundled install and a network install are interchangeable.

## Contents

| File | Style | SHA-256 |
|------|-------|---------|
| `HackNerdFont-Regular.ttf` | Regular | `7e6b5d86baee613984b10cef14c8d6aee86c976a3d1cbd87abffd424d6ec4c64` |
| `HackNerdFont-Bold.ttf` | Bold | `7fb835cbd3273d509868dcd4e03eab3dc98679ac0bdffd52ef23411244396082` |
| `HackNerdFont-Italic.ttf` | Italic | `b65edfcbdce25a6f359b6ad129f51fc0b7c59e4893676fc3b75a4f49e3a12b18` |
| `HackNerdFont-BoldItalic.ttf` | Bold Italic | `1a6fdc79f82beb3ca3a0bc2088568a24b094b55f0f93cbf9731bf8e1ede85d6b` |

Verify them at any time:

```bash
cd fonts && shasum -a 256 -c <<'EOF'
7e6b5d86baee613984b10cef14c8d6aee86c976a3d1cbd87abffd424d6ec4c64  HackNerdFont-Regular.ttf
7fb835cbd3273d509868dcd4e03eab3dc98679ac0bdffd52ef23411244396082  HackNerdFont-Bold.ttf
b65edfcbdce25a6f359b6ad129f51fc0b7c59e4893676fc3b75a4f49e3a12b18  HackNerdFont-Italic.ttf
1a6fdc79f82beb3ca3a0bc2088568a24b094b55f0f93cbf9731bf8e1ede85d6b  HackNerdFont-BoldItalic.ttf
EOF
```

`test-comprehensive-validation.sh` also checks each file's TrueType magic number
(`0x00010000`) on every run. That check exists because a previous revision of this
repository shipped four HTML "404: Not Found" pages saved with a `.ttf` extension. They
were the right size and non-empty, so nothing caught it, and the fallback silently
installed nothing.

## Manual installation

```bash
# macOS
cp fonts/*.ttf ~/Library/Fonts/

# Linux
mkdir -p ~/.local/share/fonts && cp fonts/*.ttf ~/.local/share/fonts/ && fc-cache -f
```

On Windows, select all four files in Explorer, right-click, and choose **Install for all
users**.

Then set your terminal's font to **Hack Nerd Font**.

## License

Hack is licensed under the [MIT License](https://github.com/source-foundry/Hack/blob/master/LICENSE.md)
(with the Bitstream Vera license applying to derived glyphs). The Nerd Fonts patcher and
its glyph sets are licensed under the [MIT License](https://github.com/ryanoasis/nerd-fonts/blob/master/LICENSE).
Both permit redistribution. These files are unmodified upstream release artifacts.
