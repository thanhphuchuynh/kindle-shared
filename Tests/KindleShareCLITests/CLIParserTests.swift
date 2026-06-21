import Foundation
import Testing
@testable import KindleShareCLI

@Suite("CLI parser")
struct CLIParserTests {
    @Test("parses serve command with folder and custom port")
    func parsesServeCommandWithFolderAndPort() throws {
        let command = try CLIParser.parse([
            "serve",
            "--folder",
            "/Users/me/Books",
            "--port",
            "9090"
        ])

        #expect(command == .serve(folder: URL(filePath: "/Users/me/Books"), port: 9090))
    }

    @Test("uses port 8787 when port is omitted")
    func usesDefaultPort() throws {
        let command = try CLIParser.parse([
            "serve",
            "--folder",
            "/Users/me/Books"
        ])

        #expect(command == .serve(folder: URL(filePath: "/Users/me/Books"), port: 8787))
    }

    @Test("rejects missing folder")
    func rejectsMissingFolder() {
        #expect(throws: CLIParser.ParseError.self) {
            try CLIParser.parse(["serve"])
        }
    }
}
