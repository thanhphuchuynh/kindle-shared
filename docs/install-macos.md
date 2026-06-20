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

If macOS blocks the app because it was downloaded from another machine, run:

```bash
xattr -dr com.apple.quarantine /Applications/KindleShare.app
```

Then open the app again. If macOS asks about local network or incoming connections, choose `Allow` so Kindle devices on the same Wi-Fi can reach the app.

## Notes

- This build is ad-hoc signed, not notarized by Apple.
- `dist/` is a local build output and should not be committed to git.
- To share through GitHub, push the source code and attach `dist/KindleShare.zip` to a GitHub Release.
