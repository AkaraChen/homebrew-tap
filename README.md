# Homebrew Tap

Homebrew tap for AkaraChen apps.

## aghub

Install the macOS app:

```sh
brew install --cask akarachen/tap/aghub
```

## 2code

Install the macOS app:

```sh
brew install --cask akarachen/tap/2code
```

Or add the tap first:

```sh
brew tap akarachen/tap
brew install --cask aghub
brew install --cask 2code
```

## Updating casks

Run the `update aghub cask` or `update 2code cask` GitHub Actions workflow
manually. It updates the cask version and SHA-256 values from the latest macOS
app release assets, then opens a pull request.

To run the updaters locally:

```sh
scripts/update-aghub.sh
scripts/update-aghub.sh 1.2.3
scripts/update-2code.sh
scripts/update-2code.sh 1.2.3
```
