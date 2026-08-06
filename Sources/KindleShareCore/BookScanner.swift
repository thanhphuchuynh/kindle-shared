import Foundation

public struct BookScanner {
    public static let supportedExtensions: Set<String> = ["pdf", "epub", "mobi", "azw", "azw3"]

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func scan(folder: URL) throws -> [BookFile] {
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]
        let urls = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        )

        return try urls.compactMap { url in
            try makeBook(from: url, resourceKeys: resourceKeys)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func scan(files urls: [URL]) throws -> [BookFile] {
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]
        return try urls.compactMap { url in
            try makeBook(from: url, resourceKeys: resourceKeys)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func makeBook(from url: URL, resourceKeys: Set<URLResourceKey>) throws -> BookFile? {
        let values = try url.resourceValues(forKeys: resourceKeys)
        guard values.isRegularFile == true else { return nil }

        let fileExtension = url.pathExtension.lowercased()
        guard Self.supportedExtensions.contains(fileExtension) else { return nil }

        return BookFile(
            name: url.lastPathComponent,
            fileExtension: fileExtension,
            sizeInBytes: Int64(values.fileSize ?? 0),
            url: url
        )
    }
}
