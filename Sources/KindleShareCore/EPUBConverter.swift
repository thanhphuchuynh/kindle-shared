import Foundation

public protocol EPUBConverting: Sendable {
    func convert(epubURL: URL) throws -> Data
}

public struct EPUBConverter: EPUBConverting {
    private let executableURL: URL?

    public init(
        executableURL: URL? = EPUBConverter.defaultExecutableURL()
    ) {
        self.executableURL = executableURL
    }

    public func convert(epubURL: URL) throws -> Data {
        guard let executableURL else {
            throw BookDownloadPreparationError.epubConversionUnavailable
        }

        let fileManager = FileManager.default
        let conversionFolder = fileManager.temporaryDirectory
            .appendingPathComponent("KindleShareConversions", isDirectory: true)
        try fileManager.createDirectory(at: conversionFolder, withIntermediateDirectories: true)

        let outputURL = conversionFolder
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mobi")

        defer {
            try? fileManager.removeItem(at: outputURL)
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = [epubURL.path, outputURL.path]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw BookDownloadPreparationError.epubConversionFailed(error.localizedDescription)
        }

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw BookDownloadPreparationError.epubConversionFailed(errorText?.isEmpty == false ? errorText! : "ebook-convert exited with status \(process.terminationStatus).")
        }

        guard let data = try? Data(contentsOf: outputURL) else {
            throw BookDownloadPreparationError.fileReadFailed
        }

        return data
    }

    public static func defaultExecutableURL() -> URL? {
        let environmentPath = ProcessInfo.processInfo.environment["KINDLE_SHARE_EBOOK_CONVERT"]
        let absoluteCandidates = [
            environmentPath,
            "/Applications/calibre.app/Contents/MacOS/ebook-convert",
            "/opt/homebrew/bin/ebook-convert",
            "/usr/local/bin/ebook-convert",
            "/usr/bin/ebook-convert"
        ].compactMap { $0 }

        if let executable = absoluteCandidates
            .map(URL.init(fileURLWithPath:))
            .first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) {
            return executable
        }

        let pathSeparator = ProcessInfo.processInfo.operatingSystemVersionString.contains("Windows") ? ";" : ":"
        let pathFolders = ProcessInfo.processInfo.environment["PATH"]?
            .split(separator: Character(pathSeparator))
            .map(String.init) ?? []

        for folder in pathFolders {
            for executableName in ["ebook-convert", "ebook-convert.exe"] {
                let executableURL = URL(fileURLWithPath: folder)
                    .appendingPathComponent(executableName)
                if FileManager.default.isExecutableFile(atPath: executableURL.path) {
                    return executableURL
                }
            }
        }

        return nil
    }
}
