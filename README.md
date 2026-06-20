# Kindle Share

A small macOS SwiftUI utility for sharing one local books folder with a Kindle over the same Wi-Fi network.

## Run

```bash
swift run KindleShare
```

Then:

1. Choose the folder that contains your books.
2. Click `Start`.
3. Open the shown URL on the Kindle browser.
4. Tap a book to download it.

Supported formats: `.pdf`, `.epub`, `.mobi`, `.azw`, `.azw3`.

The server only shares files from the selected folder and listens on port `8787`.

## Build A Mac App Zip

```bash
./scripts/package-macos.sh
```

This creates:

```text
dist/KindleShare.zip
```

Install notes for another Mac are in [docs/install-macos.md](docs/install-macos.md).

## Release From A Git Tag

Pushing a tag that starts with `v` runs GitHub Actions and publishes `KindleShare.zip` to a GitHub Release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow is in [.github/workflows/release.yml](.github/workflows/release.yml).
