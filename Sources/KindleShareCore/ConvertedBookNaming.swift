import Foundation

public enum ConvertedBookNaming {
    public static let outputPrefix = "KindleShare - "

    public static func azw3FileName(for epubURL: URL) -> String {
        outputPrefix + epubURL.deletingPathExtension().lastPathComponent + ".azw3"
    }

    public static func azw3URL(for epubURL: URL) -> URL {
        return epubURL
            .deletingLastPathComponent()
            .appendingPathComponent(azw3FileName(for: epubURL))
    }
}
