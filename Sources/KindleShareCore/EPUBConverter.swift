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
        let fileManager = FileManager.default
        let conversionFolder = fileManager.temporaryDirectory
            .appendingPathComponent("KindleShareConversions", isDirectory: true)
        try fileManager.createDirectory(at: conversionFolder, withIntermediateDirectories: true)

        let outputURL = conversionFolder
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("azw3")

        defer {
            try? fileManager.removeItem(at: outputURL)
        }

        try convert(epubURL: epubURL, outputURL: outputURL)

        guard let data = try? Data(contentsOf: outputURL) else {
            throw BookDownloadPreparationError.fileReadFailed
        }

        return data
    }

    public func convert(epubURL: URL, outputURL: URL) throws {
        guard let executableURL else {
            throw BookDownloadPreparationError.epubConversionUnavailable
        }

        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["convert", epubURL.path, outputURL.path, "--to", "azw3", "--quiet"]

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
            throw BookDownloadPreparationError.epubConversionFailed(errorText?.isEmpty == false ? errorText! : "boko exited with status \(process.terminationStatus).")
        }
    }

    public static func defaultExecutableURL() -> URL? {
        let environmentPath = ProcessInfo.processInfo.environment["KINDLE_SHARE_BOKO"]
        let absoluteCandidates = [
            environmentPath,
            Bundle.main.resourceURL?
                .appendingPathComponent("Boko", isDirectory: true)
                .appendingPathComponent("boko")
                .path,
            Bundle.main.resourceURL?
                .appendingPathComponent("Boko", isDirectory: true)
                .appendingPathComponent("boko.exe")
                .path,
            "/opt/homebrew/bin/boko",
            "/usr/local/bin/boko",
            "/usr/bin/boko"
        ].compactMap { $0 }

        if let executable = firstExecutableURL(in: absoluteCandidates) {
            return executable
        }

        let pathSeparator = ProcessInfo.processInfo.operatingSystemVersionString.contains("Windows") ? ";" : ":"
        let pathFolders = ProcessInfo.processInfo.environment["PATH"]?
            .split(separator: Character(pathSeparator))
            .map(String.init) ?? []

        for folder in pathFolders {
            for executableName in ["boko", "boko.exe"] {
                let executableURL = URL(fileURLWithPath: folder)
                    .appendingPathComponent(executableName)
                if FileManager.default.isExecutableFile(atPath: executableURL.path) {
                    return executableURL
                }
            }
        }

        return nil
    }

    static func firstExecutableURL(in paths: [String]) -> URL? {
        paths
            .map(URL.init(fileURLWithPath:))
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}
