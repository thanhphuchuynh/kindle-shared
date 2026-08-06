import Foundation
import Testing
@testable import KindleShareCore

@Suite("EPUBConverter")
struct EPUBConverterTests {
    @Test("selects the first executable candidate")
    func selectsFirstExecutableCandidate() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let missingURL = folder.appendingPathComponent("missing-ebook-convert")
        let executableURL = folder.appendingPathComponent("ebook-convert")
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: executableURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executableURL.path)

        let selectedURL = EPUBConverter.firstExecutableURL(in: [missingURL.path, executableURL.path])

        #expect(selectedURL == executableURL)
    }
}
