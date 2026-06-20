# Kindle Share macOS Design

## Goal

Build a small native macOS app that lets the user share a selected books folder over the local Wi-Fi network. A Kindle on the same network can open the displayed IP address in its browser, view the available books, and download them directly.

## Scope

- Native macOS SwiftUI app.
- User chooses one folder to share.
- App lists supported book files from that folder.
- App runs a local HTTP server on port `8787`.
- App displays a Kindle-friendly URL such as `http://192.168.1.23:8787`.
- Kindle browser page shows a simple list of downloadable files.
- Supported extensions: `.pdf`, `.epub`, `.mobi`, `.azw`, `.azw3`.
- Server only exposes files inside the selected folder.

## Non-Goals

- No account system, password, or cloud sync.
- No Calibre database integration.
- No file conversion.
- No recursive folder browsing in the first version.
- No public internet exposure.

## User Experience

The first screen is the working app, not a landing page. It should feel like a polished macOS utility:

- A calm header with app name and server status.
- A primary folder picker section showing the selected folder and number of shareable files.
- A prominent Kindle URL section with copy action.
- A start/stop sharing control.
- A compact file list showing title, extension, and size.
- Empty states for "no folder selected" and "no supported books found".
- Error states for server startup failure or missing local IP.

The visual style should be native-feeling, quiet, and useful: translucent macOS material where appropriate, restrained color, crisp spacing, and controls that look at home on macOS.

## Architecture

### App Shell

`KindleShareApp` owns the SwiftUI app entry point and creates the main window.

### View Model

`ShareViewModel` coordinates:

- selected folder URL
- discovered book files
- HTTP server lifecycle
- local IP detection
- copy-to-clipboard behavior
- user-facing status and errors

### Book Scanning

`BookScanner` reads only the selected folder and returns supported files with display name, extension, size, and URL. It does not recurse for the first version.

### HTTP Server

`BookHTTPServer` listens on `8787` using native Apple networking APIs. It responds to:

- `GET /` with a simple Kindle-friendly HTML page.
- `GET /download/<encoded-file-name>` with the matching file bytes.

The server rejects path traversal and unknown files.

### Local IP

`LocalIPAddressProvider` finds a non-loopback IPv4 address suitable for display. If none is found, the UI still allows sharing but shows a warning so the user can check Wi-Fi.

## Error Handling

- Folder cannot be read: show a clear inline message and keep sharing stopped.
- Port is already in use: show that port `8787` is unavailable.
- File disappears before download: return HTTP 404.
- Unsupported request: return HTTP 404 or 405.

## Verification

- Build the macOS app with Swift.
- Unit test book scanning for extension filtering and non-recursive behavior.
- Unit test request path decoding and file lookup safety.
- Manual smoke test: start sharing, request `/`, and download a sample file from localhost.
