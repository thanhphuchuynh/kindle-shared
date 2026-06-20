import AppKit
import Foundation
import KindleShareCore

@MainActor
final class ShareViewModel: ObservableObject {
    enum Action: Equatable {
        case chooseFolder
        case copyURL
        case refresh
        case sharing
    }

    @Published private(set) var selectedFolder: URL?
    @Published private(set) var books: [BookFile] = []
    @Published private(set) var isSharing = false
    @Published private(set) var localAddress = LocalIPAddressProvider.localIPv4Address()
    @Published private(set) var activeAction: Action?
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

    var statusTitle: String {
        isSharing ? "Sharing" : "Stopped"
    }

    var statusSubtitle: String {
        if isSharing {
            "Kindle can download \(books.count) book\(books.count == 1 ? "" : "s")."
        } else if selectedFolder == nil {
            "Choose a folder to begin."
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

    func select(folder: URL) {
        stopSharing()
        selectedFolder = folder
        refreshBooks()
    }

    func refreshBooks() {
        guard let selectedFolder else {
            books = []
            return
        }

        do {
            books = try scanner.scan(folder: selectedFolder)
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

    func startSharing() {
        guard selectedFolder != nil else {
            errorMessage = "Choose a books folder before starting sharing."
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
}
