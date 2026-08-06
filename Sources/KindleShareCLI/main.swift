import Foundation
import KindleShareCore

let usage = """
Kindle Share CLI

Usage:
  kindle-share serve --folder <path> [--port 8787]

Options:
  -f, --folder   Folder containing PDF, MOBI, AZW, AZW3, or EPUB files.
  -p, --port     HTTP port to serve on. Defaults to 8787.
"""

func run() throws {
    let command = try CLIParser.parse(Array(CommandLine.arguments.dropFirst()))

    switch command {
    case .serve(let folder, let port):
        let scanner = BookScanner()
        let books = try scanner.scan(folder: folder)
        let server = BookHTTPServer(port: port)

        try server.start(books: books)

        let host = LocalIPAddressProvider.localIPv4Address() ?? "127.0.0.1"
        print("Kindle Share is serving \(books.count) book\(books.count == 1 ? "" : "s").")
        print("Open this on Kindle: http://\(host):\(port)")
        print("EPUB downloads are converted to MOBI when Calibre's ebook-convert is installed.")
        print("Press Ctrl+C to stop.")

        RunLoop.current.run()
    }
}

do {
    try run()
} catch {
    fputs("\(error.localizedDescription)\n\n\(usage)\n", stderr)
    exit(1)
}
