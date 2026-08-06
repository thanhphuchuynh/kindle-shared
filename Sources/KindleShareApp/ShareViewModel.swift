import AppKit
import Foundation
import KindleShareCore
import UniformTypeIdentifiers

@MainActor
final class ShareViewModel: ObservableObject {
    enum Action: Equatable {
        case chooseFolder
        case addBooks
        case convertBooks
        case copyURL
        case refresh
        case sharing
    }

    @Published private(set) var selectedFolder: URL?
    @Published private(set) var selectedFiles: [URL] = []
    @Published private(set) var books: [BookFile] = []
    @Published private(set) var isSharing = false
    @Published private(set) var localAddress = LocalIPAddressProvider.localIPv4Address()
    @Published private(set) var activeAction: Action?
    @Published private(set) var convertingBookIDs = Set<BookFile.ID>()
    @Published private(set) var conversionMessage: String?
    @Published var selectedBookIDs = Set<BookFile.ID>()
    @Published var errorMessage: String?

    private let scanner = BookScanner()
    private let server = BookHTTPServer()
    private let port: UInt16 = 8787

    var kindleURL: String {
        guard let localAddress else { return "No Wi-Fi IP found" }
        return "http://\(localAddress):\(port)"
    }

    var folderName: String {
        selectedFolder?.lastPathComponent ?? "No folder selected"
    }

    var addedFilesCount: Int {
        selectedFiles.count
    }

    var hasSource: Bool {
        selectedFolder != nil || !selectedFiles.isEmpty
    }

    var selectedBook: BookFile? {
        guard let selectedBookID = selectedBookIDs.first else { return nil }
        return books.first { $0.id == selectedBookID }
    }

    var booksNeedingConversion: [BookFile] {
        books.filter { needsConversion($0) }
    }

    var convertedBooksCount: Int {
        books.filter { isConverted($0) }.count
    }

    var statusTitle: String {
        isSharing ? "Sharing" : "Stopped"
    }

    var statusSubtitle: String {
        if isSharing {
            "Kindle can download \(books.count) book\(books.count == 1 ? "" : "s")."
        } else if !hasSource {
            "Choose a folder or add books to begin."
        } else {
            "Ready to share on your local Wi-Fi."
        }
    }

    func chooseFolder() {
        activeAction = .chooseFolder
        defer { activeAction = nil }

        let panel = NSOpenPanel()
        panel.title = "Choose Books Folder"
        panel.prompt = "Choose"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        select(folder: url)
    }

    func addBooks() {
        activeAction = .addBooks
        defer { activeAction = nil }

        let panel = NSOpenPanel()
        panel.title = "Add Books"
        panel.prompt = "Add"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = BookScanner.supportedExtensions.compactMap { UTType(filenameExtension: $0) }

        guard panel.runModal() == .OK else { return }
        add(files: panel.urls)
    }

    func select(folder: URL) {
        stopSharing()
        selectedFolder = folder
        refreshBooks()
    }

    func add(files urls: [URL]) {
        stopSharing()
        selectedFiles = uniqueURLs(selectedFiles + urls)
        refreshBooks()
    }

    func refreshBooks() {
        guard hasSource else {
            books = []
            selectedBookIDs = []
            return
        }

        do {
            let folderBooks = try selectedFolder.map { try scanner.scan(folder: $0) } ?? []
            let fileBooks = try scanner.scan(files: selectedFiles)
            books = uniqueBooks(folderBooks + fileBooks)
            if let selectedBookID = selectedBookIDs.first, !books.contains(where: { $0.id == selectedBookID }) {
                selectedBookIDs = books.first.map { [$0.id] } ?? []
            } else if selectedBookIDs.isEmpty {
                selectedBookIDs = books.first.map { [$0.id] } ?? []
            }
            errorMessage = nil
            localAddress = LocalIPAddressProvider.localIPv4Address()
        } catch {
            books = []
            errorMessage = "Could not read that folder. Choose another folder and try again."
        }
    }

    func refreshBooksWithFeedback() {
        runActionFeedback(.refresh) { [weak self] in
            self?.refreshBooks()
        }
    }

    func toggleSharing() {
        runActionFeedback(.sharing) { [weak self] in
            self?.isSharing == true ? self?.stopSharing() : self?.startSharing()
        }
    }

    func convertBooksNow() {
        guard activeAction == nil else { return }

        let targets = booksNeedingConversion
        guard !targets.isEmpty else {
            conversionMessage = "All EPUB books are already converted."
            return
        }

        activeAction = .convertBooks
        conversionMessage = "Converting \(targets.count) EPUB book\(targets.count == 1 ? "" : "s")..."
        errorMessage = nil

        Task { @MainActor in
            defer {
                convertingBookIDs = []
                activeAction = nil
                refreshBooks()
            }

            for book in targets {
                convertingBookIDs = [book.id]

                do {
                    let outputURL = convertedURL(for: book)
                    try await Task.detached {
                        try EPUBConverter().convert(epubURL: book.url, outputURL: outputURL)
                    }.value
                } catch {
                    errorMessage = "Could not convert \(book.name). \(error.localizedDescription)"
                    conversionMessage = "Conversion stopped."
                    return
                }
            }

            conversionMessage = "Converted \(targets.count) EPUB book\(targets.count == 1 ? "" : "s") to MOBI."
        }
    }

    func startSharing() {
        guard hasSource else {
            errorMessage = "Choose a books folder or add books before starting sharing."
            return
        }

        guard !books.isEmpty else {
            errorMessage = "Add at least one supported book before starting sharing."
            return
        }

        refreshBooks()

        do {
            try server.start(books: books)
            isSharing = true
            errorMessage = localAddress == nil ? "Sharing is on, but no Wi-Fi IP was found." : nil
        } catch {
            isSharing = false
            errorMessage = error.localizedDescription
        }
    }

    func stopSharing() {
        server.stop()
        isSharing = false
    }

    func copyKindleURL() {
        runActionFeedback(.copyURL) { [weak self] in
            guard let self, self.localAddress != nil else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(self.kindleURL, forType: .string)
        }
    }

    func revealSelectedBookInFinder() {
        guard let selectedBook else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedBook.url])
    }

    func openSelectedBookPreview() {
        guard let selectedBook else { return }
        NSWorkspace.shared.open(selectedBook.url)
    }

    func needsConversion(_ book: BookFile) -> Bool {
        book.fileExtension.lowercased() == "epub" && !isConverted(book)
    }

    func isConverted(_ book: BookFile) -> Bool {
        book.fileExtension.lowercased() == "epub"
            && FileManager.default.fileExists(atPath: convertedURL(for: book).path)
    }

    func convertedURL(for book: BookFile) -> URL {
        book.url.deletingPathExtension().appendingPathExtension("mobi")
    }

    func downloadName(for book: BookFile) -> String {
        book.fileExtension.lowercased() == "epub"
            ? convertedURL(for: book).lastPathComponent
            : book.name
    }

    func conversionStatus(for book: BookFile) -> String {
        if convertingBookIDs.contains(book.id) {
            return "Converting"
        }

        if book.fileExtension.lowercased() != "epub" {
            return "Not needed"
        }

        return isConverted(book) ? "Converted" : "Needs conversion"
    }

    func isLoading(_ action: Action) -> Bool {
        activeAction == action
    }

    private func runActionFeedback(_ action: Action, operation: @escaping @MainActor () -> Void) {
        guard activeAction == nil else { return }

        activeAction = action
        operation()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            if activeAction == action {
                activeAction = nil
            }
        }
    }

    private func uniqueURLs(_ urls: [URL]) -> [URL] {
        var seen = Set<URL>()
        return urls.filter { url in
            let standardizedURL = url.standardizedFileURL
            guard !seen.contains(standardizedURL) else { return false }
            seen.insert(standardizedURL)
            return true
        }
    }

    private func uniqueBooks(_ books: [BookFile]) -> [BookFile] {
        var seenURLs = Set<URL>()
        var seenNames = Set<String>()

        return books.filter { book in
            let standardizedURL = book.url.standardizedFileURL
            let normalizedName = book.name.lowercased()
            guard !seenURLs.contains(standardizedURL), !seenNames.contains(normalizedName) else {
                return false
            }

            seenURLs.insert(standardizedURL)
            seenNames.insert(normalizedName)
            return true
        }
    }
}
