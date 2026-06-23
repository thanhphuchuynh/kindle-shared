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

1. Choose the folder that contains your books.
2. Click `Start`.
3. Open the shown URL on the Kindle browser.
4. Tap a book to download it.

Supported formats: `.pdf`, `.epub`, `.mobi`, `.azw`, `.azw3`.

The server only shares files from the selected folder and listens on port `8787`.

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
