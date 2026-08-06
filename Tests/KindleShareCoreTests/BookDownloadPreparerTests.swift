import Foundation
import Testing
@testable import KindleShareCore

@Suite("BookDownloadPreparer")
struct BookDownloadPreparerTests {
    @Test("passes through Kindle-ready files")
    func passesThroughKindleReadyFiles() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }

        let bookURL = folder.appendingPathComponent("Ready.azw3")
        try Data("azw3 data".utf8).write(to: bookURL)

        let book = BookFile(
            name: "Ready.azw3",
            fileExtension: "azw3",
            sizeInBytes: 9,
            url: bookURL
        )

        let prepared = try BookDownloadPreparer(converter: MockEPUBConverter(result: .success(Data()))).prepare(book: book)

        #expect(prepared.fileName == "Ready.azw3")
        #expect(prepared.fileExtension == "azw3")
        #expect(String(data: prepared.data, encoding: .utf8) == "azw3 data")
    }

    @Test("converts EPUB files to MOBI downloads")
    func convertsEPUBFilesToMOBIDownloads() throws {
        let book = BookFile(
            name: "A Book.epub",
            fileExtension: "epub",
            sizeInBytes: 10,
            url: URL(filePath: "/tmp/A Book.epub")
        )

        let prepared = try BookDownloadPreparer(
            converter: MockEPUBConverter(result: .success(Data("mobi data".utf8)))
        ).prepare(book: book)

        #expect(prepared.fileName == "A Book.mobi")
        #expect(prepared.fileExtension == "mobi")
        #expect(String(data: prepared.data, encoding: .utf8) == "mobi data")
    }

    @Test("reports unavailable EPUB conversion")
    func reportsUnavailableEPUBConversion() throws {
        let book = BookFile(
            name: "A Book.epub",
            fileExtension: "epub",
            sizeInBytes: 10,
            url: URL(filePath: "/tmp/A Book.epub")
        )

        #expect(throws: BookDownloadPreparationError.epubConversionUnavailable) {
            try BookDownloadPreparer(
                converter: MockEPUBConverter(result: .failure(.epubConversionUnavailable))
            ).prepare(book: book)
        }
    }

    private func temporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}

private struct MockEPUBConverter: EPUBConverting {
    let result: Result<Data, BookDownloadPreparationError>

    func convert(epubURL: URL) throws -> Data {
        try result.get()
    }
}
