import Foundation
import Testing
@testable import KindleShareCore

@Suite("BookScanner")
struct BookScannerTests {
    @Test("returns supported book files in selected folder only")
    func returnsSupportedBookFilesInSelectedFolderOnly() throws {
        let folder = try TemporaryFolder()
        try folder.writeFile(named: "Clean Code.pdf", contents: "pdf")
        try folder.writeFile(named: "Novel.EPUB", contents: "epub")
        try folder.writeFile(named: "notes.txt", contents: "txt")
        try folder.createFolder(named: "Nested")
        try "nested".write(
            to: folder.url.appending(path: "Nested/Hidden.azw3"),
            atomically: true,
            encoding: .utf8
        )

        let books = try BookScanner().scan(folder: folder.url)

        #expect(books.map(\.name) == ["Clean Code.pdf", "Novel.EPUB"])
        #expect(books.map(\.fileExtension) == ["pdf", "epub"])
    }

    @Test("formats file size for display")
    func formatsFileSizeForDisplay() {
        let book = BookFile(
            name: "Small.pdf",
            fileExtension: "pdf",
            sizeInBytes: 1_024,
            url: URL(filePath: "/tmp/Small.pdf")
        )

        #expect(book.displaySize.contains("KB"))
    }
}

private struct TemporaryFolder {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func writeFile(named name: String, contents: String) throws {
        try contents.write(to: url.appending(path: name), atomically: true, encoding: .utf8)
    }

    func createFolder(named name: String) throws {
        try FileManager.default.createDirectory(
            at: url.appending(path: name, directoryHint: .isDirectory),
            withIntermediateDirectories: true
        )
    }
}
