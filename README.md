# Kindle Share

A small utility for sharing one local books folder with a Kindle over the same Wi-Fi network.

The macOS app keeps the native Finder-like UI. The CLI exposes the same local server workflow for macOS, Linux, and Windows-oriented builds.

Landing page: https://thanhphuchuynh.github.io/kindle-shared/

## Run

### macOS App

```bash
swift run KindleShare
```

Then:

1. Choose the folder that contains your books, or click `Add Books` to select individual files.
2. Click `Start`.
3. Open the shown URL on the Kindle browser.
4. Tap a book to download it.

Supported direct-download formats: `.pdf`, `.mobi`, `.azw`, `.azw3`.

EPUB files can be selected too. Kindle Share converts `.epub` to `.mobi` on download when a bundled converter or Calibre is available.

The server only shares files from the selected folder and listens on port `8787`.

### EPUB Conversion

Kindle browsers may reject raw EPUB downloads. Release builds can bundle Calibre's `ebook-convert` helper so users do not need to install anything separately.

To build a zip with the converter bundled, install Calibre on the build Mac:

```bash
brew install --cask calibre
./scripts/package-macos.sh
```

The packaging script copies `/Applications/calibre.app` into `KindleShare.app/Contents/Resources/Calibre/calibre.app` when it exists. That preserves Calibre's required launcher libraries, so users who install `KindleShare.app` do not need to install Calibre.

You can also point to a custom Calibre app:

```bash
KINDLE_SHARE_CALIBRE_APP=/path/to/calibre.app ./scripts/package-macos.sh
```

At runtime, Kindle Share checks the bundled Calibre runtime first, then common Calibre/Homebrew locations.

### CLI Server

```bash
swift run kindle-share serve --folder ~/Books --port 8787
```

Or build the binary:

```bash
swift build -c release --product kindle-share
.build/release/kindle-share serve --folder ~/Books --port 8787
```

More CLI notes are in [docs/cli.md](docs/cli.md).

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
