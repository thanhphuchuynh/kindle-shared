# Kindle Share CLI

The CLI runs the same local book server without opening the macOS app UI.

```bash
kindle-share serve --folder ~/Books --port 8787
```

Then open the printed URL in the Kindle browser while the Kindle is on the same Wi-Fi network.

## Commands

```bash
kindle-share serve --folder <path> [--port 8787]
```

Options:

- `--folder`, `-f`: folder containing `.pdf`, `.epub`, `.mobi`, `.azw`, or `.azw3` files.
- `--port`, `-p`: HTTP port. Defaults to `8787`.

## Build

Debug:

```bash
swift build --product kindle-share
```

Release:

```bash
swift build -c release --product kindle-share
```

The server uses SwiftNIO instead of Apple's `Network` framework, so the CLI target is designed for cross-platform Swift builds. The macOS SwiftUI app remains macOS-only.

## Example

```bash
.build/release/kindle-share serve --folder ~/Books --port 8787
```

Example output:

```text
Kindle Share is serving 18 books.
Open this on Kindle: http://192.168.1.7:8787
Press Ctrl+C to stop.
```
