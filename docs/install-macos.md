# Install Kindle Share On Another Mac

Build the distributable zip:

```bash
./scripts/package-macos.sh
```

The output is:

```text
dist/KindleShare.zip
```

Send `KindleShare.zip` to the other Mac, unzip it, then move `KindleShare.app` to `/Applications`.

Release zips include the EPUB converter inside the app bundle. Users do not need to install Calibre separately.

If macOS blocks the app because it was downloaded from another machine, run:

```bash
xattr -dr com.apple.quarantine /Applications/KindleShare.app
```

Then open the app again. If macOS asks about local network or incoming connections, choose `Allow` so Kindle devices on the same Wi-Fi can reach the app.

## GitHub Release

This repo includes a GitHub Actions workflow that builds and uploads `KindleShare.zip` whenever a tag starting with `v` is pushed:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The release asset can be downloaded from the GitHub Releases page.

## Notes

- This build is ad-hoc signed, not notarized by Apple.
- EPUB conversion is bundled in release zips when Calibre is available on the build machine.
- `dist/` is a local build output and should not be committed to git.
- The GitHub Actions release uses the same `scripts/package-macos.sh` script as local packaging.
