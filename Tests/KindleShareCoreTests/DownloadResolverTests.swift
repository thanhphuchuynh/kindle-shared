import Foundation
import Testing
@testable import KindleShareCore

@Suite("DownloadResolver")
struct DownloadResolverTests {
    @Test("resolves encoded file names to known books")
    func resolvesEncodedFileNamesToKnownBooks() throws {
        let book = BookFile(
            name: "A Book.epub",
            fileExtension: "epub",
            sizeInBytes: 10,
            url: URL(filePath: "/tmp/A Book.epub")
        )

        let resolved = try #require(DownloadResolver(books: [book]).resolve(path: "/download/A%20Book.epub"))

        #expect(resolved == book)
    }

    @Test("rejects traversal and missing files")
    func rejectsTraversalAndMissingFiles() {
        let book = BookFile(
            name: "Safe.pdf",
            fileExtension: "pdf",
            sizeInBytes: 10,
            url: URL(filePath: "/tmp/Safe.pdf")
        )
        let resolver = DownloadResolver(books: [book])

        #expect(resolver.resolve(path: "/download/../Safe.pdf") == nil)
        #expect(resolver.resolve(path: "/download/Missing.pdf") == nil)
        #expect(resolver.resolve(path: "/other/Safe.pdf") == nil)
    }
}
