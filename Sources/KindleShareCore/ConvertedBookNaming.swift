import Foundation

public enum ConvertedBookNaming {
    public static let outputPrefix = "KindleShare - "

    public static func azw3URL(for epubURL: URL) -> URL {
        let baseName = epubURL.deletingPathExtension().lastPathComponent
        return epubURL
            .deletingLastPathComponent()
            .appendingPathComponent(outputPrefix + baseName)
            .appendingPathExtension("azw3")
    }
}
