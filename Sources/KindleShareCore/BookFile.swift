import Foundation

public struct BookFile: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let fileExtension: String
    public let sizeInBytes: Int64
    public let url: URL

    public init(name: String, fileExtension: String, sizeInBytes: Int64, url: URL) {
        self.id = name
        self.name = name
        self.fileExtension = fileExtension
        self.sizeInBytes = sizeInBytes
        self.url = url
    }

    public var displaySize: String {
        ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }
}
