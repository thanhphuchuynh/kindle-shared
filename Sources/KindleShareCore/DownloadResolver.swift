import Foundation

public struct DownloadResolver: Sendable {
    private let booksByName: [String: BookFile]

    public init(books: [BookFile]) {
        booksByName = Dictionary(
            books.flatMap { book -> [(String, BookFile)] in
                var names = [(book.name, book)]
                if book.fileExtension.lowercased() == "epub" {
                    names.append((ConvertedBookNaming.azw3FileName(for: book.url), book))
                }
                return names
            },
            uniquingKeysWith: { existing, _ in existing }
        )
    }

    public func resolve(path: String) -> BookFile? {
        let prefix = "/download/"
        guard path.hasPrefix(prefix) else { return nil }

        let encodedName = String(path.dropFirst(prefix.count))
        guard
            !encodedName.isEmpty,
            !encodedName.contains("/"),
            !encodedName.contains("\\"),
            let decodedName = encodedName.removingPercentEncoding,
            decodedName == URL(fileURLWithPath: decodedName).lastPathComponent,
            !decodedName.contains("..")
        else {
            return nil
        }

        return booksByName[decodedName]
    }
}
