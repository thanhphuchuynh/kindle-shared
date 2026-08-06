import Foundation
import NIO
import NIOHTTP1

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
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private let downloadPreparer: any BookDownloadPreparing
    private var channel: Channel?
    private var books: [BookFile] = []

    public init(port: UInt16 = 8787, downloadPreparer: any BookDownloadPreparing = BookDownloadPreparer()) {
        self.port = port
        self.downloadPreparer = downloadPreparer
    }

    deinit {
        stop()
        try? group.syncShutdownGracefully()
    }

    public func start(books: [BookFile]) throws {
        stop()
        self.books = books

        guard port > 0 else {
            throw ServerError.invalidPort
        }

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { [books, downloadPreparer] channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(BookHTTPHandler(books: books, downloadPreparer: downloadPreparer))
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

        do {
            channel = try bootstrap.bind(host: "0.0.0.0", port: Int(port)).wait()
            isRunning = true
        } catch {
            isRunning = false
            throw ServerError.listenerFailed("Could not start sharing on port \(port). \(error.localizedDescription)")
        }
    }

    public func stop() {
        if let channel {
            try? channel.close().wait()
        }
        channel = nil
        isRunning = false
    }
}

private final class BookHTTPHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let books: [BookFile]
    private let downloadPreparer: any BookDownloadPreparing
    private var requestHead: HTTPRequestHead?

    init(books: [BookFile], downloadPreparer: any BookDownloadPreparing) {
        self.books = books
        self.downloadPreparer = downloadPreparer
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .head(let head):
            requestHead = head
        case .body:
            break
        case .end:
            respond(context: context)
        }
    }

    private func respond(context: ChannelHandlerContext) {
        guard let requestHead else {
            sendTextResponse(context: context, status: .badRequest, body: "Bad Request")
            return
        }

        guard requestHead.method == .GET else {
            sendTextResponse(context: context, status: .methodNotAllowed, body: "Only GET is supported")
            return
        }

        if requestHead.uri == "/" {
            sendTextResponse(
                context: context,
                status: .ok,
                contentType: "text/html; charset=utf-8",
                body: HTMLRenderer.renderIndex(books: books)
            )
            return
        }

        if let book = DownloadResolver(books: books).resolve(path: requestHead.uri) {
            sendFileResponse(context: context, book: book)
            return
        }

        sendTextResponse(context: context, status: .notFound, body: "Not Found")
    }

    private func sendFileResponse(context: ChannelHandlerContext, book: BookFile) {
        let preparedDownload: PreparedBookDownload

        do {
            preparedDownload = try downloadPreparer.prepare(book: book)
        } catch BookDownloadPreparationError.epubConversionUnavailable {
            sendTextResponse(
                context: context,
                status: .notImplemented,
                body: "EPUB conversion requires Calibre on the sharing computer. Install Calibre, restart sharing, then try this download again."
            )
            return
        } catch let error as BookDownloadPreparationError {
            sendTextResponse(context: context, status: .internalServerError, body: error.localizedDescription)
            return
        } catch {
            sendTextResponse(context: context, status: .internalServerError, body: "Could not prepare this book for download.")
            return
        }

        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: mimeType(for: preparedDownload.fileExtension))
        headers.add(name: "Content-Length", value: "\(preparedDownload.data.count)")
        headers.add(name: "Content-Disposition", value: "attachment; filename=\"\(preparedDownload.fileName.headerEscaped)\"")
        headers.add(name: "Connection", value: "close")

        sendResponse(context: context, status: .ok, headers: headers, body: preparedDownload.data)
    }

    private func sendTextResponse(
        context: ChannelHandlerContext,
        status: HTTPResponseStatus,
        contentType: String = "text/plain; charset=utf-8",
        body: String
    ) {
        let bodyData = Data(body.utf8)
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: contentType)
        headers.add(name: "Content-Length", value: "\(bodyData.count)")
        headers.add(name: "Connection", value: "close")

        sendResponse(context: context, status: status, headers: headers, body: bodyData)
    }

    private func sendResponse(
        context: ChannelHandlerContext,
        status: HTTPResponseStatus,
        headers: HTTPHeaders,
        body: Data
    ) {
        context.write(wrapOutboundOut(.head(HTTPResponseHead(version: .http1_1, status: status, headers: headers))), promise: nil)

        var buffer = context.channel.allocator.buffer(capacity: body.count)
        buffer.writeBytes(body)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)

        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        context.close(promise: nil)
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
