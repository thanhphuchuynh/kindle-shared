import Foundation

public struct PreparedBookDownload: Sendable {
    public let data: Data
    public let fileName: String
    public let fileExtension: String

    public init(data: Data, fileName: String, fileExtension: String) {
        self.data = data
        self.fileName = fileName
        self.fileExtension = fileExtension
    }
}

public protocol BookDownloadPreparing: Sendable {
    func prepare(book: BookFile) throws -> PreparedBookDownload
}

public enum BookDownloadPreparationError: LocalizedError, Equatable {
    case epubConversionUnavailable
    case epubConversionFailed(String)
    case fileReadFailed

    public var errorDescription: String? {
        switch self {
        case .epubConversionUnavailable:
            "EPUB conversion requires boko. Install or bundle boko so Kindle Share can convert EPUB files to AZW3 before download."
        case .epubConversionFailed(let message):
            "Could not convert EPUB for Kindle. \(message)"
        case .fileReadFailed:
            "Could not read the selected book file."
        }
    }
}

public struct BookDownloadPreparer: BookDownloadPreparing {
    private let converter: any EPUBConverting

    public init(converter: any EPUBConverting = EPUBConverter()) {
        self.converter = converter
    }

    public func prepare(book: BookFile) throws -> PreparedBookDownload {
        if book.fileExtension.lowercased() == "epub" {
            let convertedURL = book.url.deletingPathExtension().appendingPathExtension("azw3")
            if FileManager.default.fileExists(atPath: convertedURL.path) {
                guard let data = try? Data(contentsOf: convertedURL) else {
                    throw BookDownloadPreparationError.fileReadFailed
                }

                return PreparedBookDownload(
                    data: data,
                    fileName: convertedURL.lastPathComponent,
                    fileExtension: "azw3"
                )
            }

            let data = try converter.convert(epubURL: book.url)
            return PreparedBookDownload(
                data: data,
                fileName: book.url.deletingPathExtension().lastPathComponent + ".azw3",
                fileExtension: "azw3"
            )
        }

        guard let data = try? Data(contentsOf: book.url) else {
            throw BookDownloadPreparationError.fileReadFailed
        }

        return PreparedBookDownload(
            data: data,
            fileName: book.name,
            fileExtension: book.fileExtension
        )
    }
}
