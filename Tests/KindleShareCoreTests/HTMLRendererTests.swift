import Foundation
import Testing
@testable import KindleShareCore

@Suite("HTMLRenderer")
struct HTMLRendererTests {
    @Test("renders Kindle-friendly download links")
    func rendersKindleFriendlyDownloadLinks() {
        let books = [
            BookFile(
                name: "A Book.epub",
                fileExtension: "epub",
                sizeInBytes: 2_048,
                url: URL(filePath: "/tmp/A Book.epub")
            )
        ]

        let html = HTMLRenderer.renderIndex(books: books)

        #expect(html.contains("Kindle Share"))
        #expect(!html.contains("/download/A%20Book.epub"))
        #expect(html.contains("KindleShare - A Book.azw3"))
        #expect(html.contains("/download/KindleShare%20-%20A%20Book.azw3"))
        #expect(html.contains("EPUB -&gt; AZW3 on download"))
        #expect(html.contains("2 KB"))
    }
}
