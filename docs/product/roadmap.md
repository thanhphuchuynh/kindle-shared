# Kindle Share Product Roadmap

## Positioning

Kindle Share should be a tiny local-first Kindle companion:

> A local Wi-Fi book drop for Kindle. No cloud, no account, no Calibre library, no cable.

The product should stay smaller, calmer, and more focused than Calibre. It should do one workflow extremely well: choose books on a Mac, open a local address on Kindle, download.

## Product Principles

- Local-first by default.
- No account required.
- No cloud dependency for the core workflow.
- Apple-native macOS experience.
- Kindle browser page must be lightweight and E-ink friendly.
- Keep the core app simple before adding library-management features.

## Roadmap

### v1: Solid Local Sharing

- Share one selected folder over local Wi-Fi.
- Show local URL clearly.
- Download supported files from Kindle browser.
- Handle firewall, port busy, missing Wi-Fi, and no-folder states clearly.
- Package as a macOS app zip.
- Add app icon and GitHub tag-based releases.

### v1.1: Easier Device Access

- Show QR code for the share URL.
- Explore Bonjour/mDNS so users can try a friendly local address such as `kindle-share.local`.
- Auto-refresh when new books are added to the folder.
- Add optional recursive folder scanning.
- Improve Kindle web page for E-ink: larger tap targets, simple search, simple sorting.

### v1.2: Better Book Awareness

- Extract basic metadata when possible: title, author, format, size.
- Show cover thumbnails when available.
- Add recent downloads/history.
- Add lightweight tags or collections without becoming a full library manager.

### v2: Conversion And Send Options

- EPUB to Kindle-friendly format conversion, starting with optional Calibre integration.
- Explore Calibre CLI integration for conversion instead of reimplementing a conversion engine.
- Optional Send to Kindle integration for users who want Amazon cloud sync.
- Keep local sharing as the primary workflow.

### v3: Polished Distribution

- Notarized macOS app.
- Auto-update via Sparkle or similar.
- Menu bar/background sharing mode.
- Launch at login.
- Homebrew cask distribution.
- Simple product website and GitHub Releases.

## Security And Privacy

- Server should only expose files inside the selected folder.
- Keep path traversal protection.
- Bind to local network only where possible.
- Add optional PIN/passcode for the Kindle web page.
- Add auto-stop after a configurable duration.
- Be explicit in UI about what folder is being shared.

## Competitive Context

- Amazon Send to Kindle is convenient but cloud-based and account-based.
- Calibre Content Server is powerful but heavy and library-centric.
- USB transfer is reliable but manual and cable-based.

Kindle Share should win on simplicity: open app, choose folder, open URL on Kindle, download.
