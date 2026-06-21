# Introducing Kindle Share: a local Wi-Fi book drop for Kindle

I wanted a smaller way to move books from my Mac to my Kindle.

There are already good tools for this. Amazon has Send to Kindle. Calibre has a powerful content server. USB transfer still works. But each option carries a little friction:

- Send to Kindle goes through the cloud.
- Calibre is excellent, but it is a full library manager.
- USB transfer needs a cable and a manual copy step.

Kindle Share is built for the smaller workflow:

> Choose a folder on your Mac. Start sharing. Open one local address on Kindle. Download the book.

No account. No cloud. No cable.

## How it works

Kindle Share starts a tiny local web server on your Mac. It only serves files from the folder you choose. When your Kindle is on the same Wi-Fi network, you open the Kindle browser and visit the address shown in the app.

From there, you get a simple list of supported files and can download them directly.

Supported formats today:

- PDF
- EPUB
- MOBI
- AZW
- AZW3

## Why local-first?

I like tools that do not require an account for a local job.

If the book is already on my Mac and the Kindle is already next to me, sending the file through a cloud service feels heavier than it needs to be. Kindle Share keeps that path local.

That also makes the app easier to reason about. The folder you choose is the folder being shared. Stop sharing, and the local server stops.

## What it is not

Kindle Share is not trying to replace Calibre. Calibre is a serious ebook library system with conversion, metadata, plugins, and deep device workflows.

Kindle Share is intentionally narrower. It is a small macOS utility for quick local transfer.

## Roadmap

The next things I want to explore:

- QR code for the Kindle URL.
- A friendlier local address using Bonjour/mDNS.
- Auto-refresh when new books appear in the folder.
- Better Kindle browser page for E-ink screens.
- Optional metadata and cover previews.

The principle stays the same: keep the core local, simple, and obvious.

## Try it

Download the latest build from GitHub Releases:

https://github.com/thanhphuchuynh/kindle-shared/releases

Source code:

https://github.com/thanhphuchuynh/kindle-shared
