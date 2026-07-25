# Contributing

Thanks for considering a contribution. Issues and pull requests are both welcome.

## Before you open a pull request

Run the full suite. It must be green:

```bash
./run-all-tests.sh
```

It needs `oh-my-posh` and `jq`. If you changed an installer, also check it against a
throwaway home directory rather than your own:

```bash
./install.sh --dry-run
```

## Development guidelines

- **Test behaviour, not source text.** Assertions should run the thing and inspect the
  result. Grepping a script for a keyword passes whether or not the code works — an
  earlier version of this suite reported "52 passed, 0 failed" while the installer did not
  work on macOS and the bundled fonts were HTML error pages.
- **Add a regression test with any bug fix**, and confirm it fails before your fix and
  passes after. That check is the point of the test.
- **Keep icons as `\uXXXX` escapes** in `kartikshankar.omp.json`, never raw characters, so
  the file stays readable without a Nerd Font. A test enforces this.
- **Do not add unsupported keys to the theme.** Oh My Posh silently discards them, which
  implies behaviour that does not exist. Check the
  [schema](https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json)
  first.
- **Installers must never rewrite lines they did not add.** Edits go inside the managed
  block, the file is backed up first, and a repeat run must be a no-op.
- `install.sh` must parse under bash 3.2, which is what macOS ships.

## Testing across platforms

The suite runs on the platform you are on. If you can, verify changes on more than one of
macOS, Linux, and Windows, and in more than one shell, before submitting. Note in the pull
request what you actually tested and what you did not — that is more useful than a claim of
full coverage.

## Pull request process

1. Fork and branch: `git checkout -b fix/short-description`
2. Make your change and add or update tests
3. Run `./run-all-tests.sh`
4. Open a pull request describing the problem, the fix, and how you verified it
