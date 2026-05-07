# Homebrew Tap

Homebrew tap for AkaraChen apps.

## aghub

Install the macOS app:

```sh
brew install --cask akarachen/tap/aghub
```

Or add the tap first:

```sh
brew tap akarachen/tap
brew install --cask aghub
```

## Updating aghub

Run the `update aghub cask` GitHub Actions workflow manually. It downloads the
latest macOS app release assets, updates the cask version and SHA-256 values,
and opens a pull request.

To run the updater locally:

```sh
scripts/update-aghub.sh
scripts/update-aghub.sh 1.2.3
```
