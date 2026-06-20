# Kindle Share macOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS SwiftUI app that shares one selected books folder over local HTTP for Kindle downloads.

**Architecture:** Use a Swift Package with a macOS executable target and a small testable core library. The core handles scanning, file resolution, IP detection, HTML rendering, and HTTP serving; the SwiftUI target owns the polished macOS window and app lifecycle.

**Tech Stack:** Swift 6, SwiftUI, Network.framework, XCTest, Foundation.

---

## File Structure

- `Package.swift`: Swift package manifest for app, core library, and tests.
- `Sources/KindleShareApp/KindleShareApp.swift`: macOS app entry point.
- `Sources/KindleShareApp/ContentView.swift`: main SwiftUI screen.
- `Sources/KindleShareApp/ShareViewModel.swift`: observable UI state and actions.
- `Sources/KindleShareCore/BookFile.swift`: shared book model and formatting helpers.
- `Sources/KindleShareCore/BookScanner.swift`: one-folder non-recursive supported-file scanner.
- `Sources/KindleShareCore/DownloadResolver.swift`: safe mapping from URL path to selected book file.
- `Sources/KindleShareCore/HTMLRenderer.swift`: Kindle-friendly index page.
- `Sources/KindleShareCore/LocalIPAddressProvider.swift`: local IPv4 discovery.
- `Sources/KindleShareCore/BookHTTPServer.swift`: small local HTTP server on port `8787`.
- `Tests/KindleShareCoreTests/BookScannerTests.swift`: scanner tests.
- `Tests/KindleShareCoreTests/DownloadResolverTests.swift`: path safety tests.
- `Tests/KindleShareCoreTests/HTMLRendererTests.swift`: HTML smoke tests.

### Task 1: Package Skeleton

**Files:**
- Create: `Package.swift`
- Create: `Sources/KindleShareCore/BookFile.swift`
- Create: `Sources/KindleShareApp/KindleShareApp.swift`
- Create: `Sources/KindleShareApp/ContentView.swift`

- [ ] Create the package manifest with one executable app target, one core target, and one test target.
- [ ] Add placeholder SwiftUI app and view that compile.
- [ ] Run: `swift build`
- [ ] Expected: build succeeds.

### Task 2: Book Scanner

**Files:**
- Modify: `Sources/KindleShareCore/BookFile.swift`
- Create: `Sources/KindleShareCore/BookScanner.swift`
- Create: `Tests/KindleShareCoreTests/BookScannerTests.swift`

- [ ] Write tests for supported extensions, ignored nested files, and display size formatting.
- [ ] Run: `swift test --filter BookScannerTests`
- [ ] Expected: tests fail before implementation.
- [ ] Implement `BookScanner.scan(folder:)`.
- [ ] Run: `swift test --filter BookScannerTests`
- [ ] Expected: tests pass.

### Task 3: Download Resolver and HTML

**Files:**
- Create: `Sources/KindleShareCore/DownloadResolver.swift`
- Create: `Sources/KindleShareCore/HTMLRenderer.swift`
- Create: `Tests/KindleShareCoreTests/DownloadResolverTests.swift`
- Create: `Tests/KindleShareCoreTests/HTMLRendererTests.swift`

- [ ] Write tests for encoded file names, traversal rejection, missing file rejection, and index HTML links.
- [ ] Run: `swift test --filter DownloadResolverTests`
- [ ] Expected: tests fail before implementation.
- [ ] Implement resolver and renderer.
- [ ] Run: `swift test --filter KindleShareCoreTests`
- [ ] Expected: tests pass.

### Task 4: Local HTTP Server

**Files:**
- Create: `Sources/KindleShareCore/BookHTTPServer.swift`
- Create: `Sources/KindleShareCore/LocalIPAddressProvider.swift`

- [ ] Implement a `Network.framework` listener on port `8787`.
- [ ] Serve `GET /` as HTML from `HTMLRenderer`.
- [ ] Serve `GET /download/<encoded-file-name>` with file bytes.
- [ ] Return small HTTP error responses for unknown methods, unknown paths, and missing files.
- [ ] Run: `swift build`
- [ ] Expected: build succeeds.

### Task 5: macOS UI

**Files:**
- Modify: `Sources/KindleShareApp/ContentView.swift`
- Create: `Sources/KindleShareApp/ShareViewModel.swift`

- [ ] Build a polished SwiftUI utility window with folder picker, status, Kindle URL, copy button, start/stop button, and file list.
- [ ] Wire folder selection to `BookScanner`.
- [ ] Wire sharing controls to `BookHTTPServer`.
- [ ] Use `LocalIPAddressProvider` for displayed URL.
- [ ] Run: `swift build`
- [ ] Expected: build succeeds.

### Task 6: Verification

**Files:**
- Modify only if verification reveals defects.

- [ ] Run: `swift test`
- [ ] Expected: all tests pass.
- [ ] Run: `swift build`
- [ ] Expected: app builds successfully.
- [ ] Create temporary sample files and smoke test the HTTP server from localhost if practical.
- [ ] Run: `git status --short`
- [ ] Expected: only intended files changed.
