import Foundation
import Network

public final class BookHTTPServer: @unchecked Sendable {
    public enum ServerError: LocalizedError {
        case invalidPort
        case listenerFailed(String)

        public var errorDescription: String? {
            switch self {
            case .invalidPort:
                "Port 8787 is unavailable."
            case .listenerFailed(let message):
                message
            }
        }
    }

    public private(set) var isRunning = false

    private let port: UInt16
    private var books: [BookFile] = []
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "kindle-share.http-server")

    public init(port: UInt16 = 8787) {
        self.port = port
    }

    public func start(books: [BookFile]) throws {
        stop()
        self.books = books

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw ServerError.invalidPort
        }

        let listener: NWListener
        do {
            listener = try NWListener(using: .tcp, on: nwPort)
        } catch {
            throw ServerError.listenerFailed("Could not start sharing on port \(port). \(error.localizedDescription)")
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection: connection)
        }

        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.isRunning = true
            case .failed, .cancelled:
                self?.isRunning = false
            default:
                break
            }
        }

        self.listener = listener
        listener.start(queue: queue)
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8_192) { [weak self] data, _, _, _ in
            guard let self else {
                connection.cancel()
                return
            }

            let response = self.response(for: data ?? Data())
            connection.send(content: response, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func response(for data: Data) -> Data {
        guard
            let request = String(data: data, encoding: .utf8),
            let requestLine = request.components(separatedBy: "\r\n").first
        else {
            return httpResponse(status: "400 Bad Request", body: "Bad Request")
        }

        let parts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
        guard parts.count >= 2 else {
            return httpResponse(status: "400 Bad Request", body: "Bad Request")
        }

        guard parts[0] == "GET" else {
            return httpResponse(status: "405 Method Not Allowed", body: "Only GET is supported")
        }

        if parts[1] == "/" {
            return httpResponse(
                status: "200 OK",
                contentType: "text/html; charset=utf-8",
                body: HTMLRenderer.renderIndex(books: books)
            )
        }

        if let book = DownloadResolver(books: books).resolve(path: parts[1]) {
            return fileResponse(book: book)
        }

        return httpResponse(status: "404 Not Found", body: "Not Found")
    }

    private func fileResponse(book: BookFile) -> Data {
        guard let body = try? Data(contentsOf: book.url) else {
            return httpResponse(status: "404 Not Found", body: "File Not Found")
        }

        var header = ""
        header += "HTTP/1.1 200 OK\r\n"
        header += "Content-Type: \(mimeType(for: book.fileExtension))\r\n"
        header += "Content-Length: \(body.count)\r\n"
        header += "Content-Disposition: attachment; filename=\"\(book.name.headerEscaped)\"\r\n"
        header += "Connection: close\r\n"
        header += "\r\n"

        var response = Data(header.utf8)
        response.append(body)
        return response
    }

    private func httpResponse(status: String, contentType: String = "text/plain; charset=utf-8", body: String) -> Data {
        let bodyData = Data(body.utf8)
        var response = ""
        response += "HTTP/1.1 \(status)\r\n"
        response += "Content-Type: \(contentType)\r\n"
        response += "Content-Length: \(bodyData.count)\r\n"
        response += "Connection: close\r\n"
        response += "\r\n"

        var data = Data(response.utf8)
        data.append(bodyData)
        return data
    }

    private func mimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "pdf":
            "application/pdf"
        case "epub":
            "application/epub+zip"
        case "mobi", "azw", "azw3":
            "application/octet-stream"
        default:
            "application/octet-stream"
        }
    }
}

private extension String {
    var headerEscaped: String {
        replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: "\"", with: "'")
            .replacingOccurrences(of: "\r", with: "_")
            .replacingOccurrences(of: "\n", with: "_")
    }
}
