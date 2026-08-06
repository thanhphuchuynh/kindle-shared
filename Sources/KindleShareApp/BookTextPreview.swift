import KindleShareCore
import SwiftUI

struct BookTextPreview: View {
    let book: BookFile

    @State private var state = PreviewState.loading

    var body: some View {
        Group {
            switch state {
            case .loading:
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading preview...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 260)
            case .loaded(let text):
                ScrollView {
                    Text(text)
                        .font(.system(.callout, design: .serif))
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(minHeight: 260)
                .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.quaternary)
                }
            case .failed(let message):
                ContentUnavailableView(
                    "Preview unavailable",
                    systemImage: "book.closed",
                    description: Text(message)
                )
                .frame(maxWidth: .infinity, minHeight: 260)
            }
        }
        .task(id: book.id) {
            await loadPreview()
        }
    }

    private func loadPreview() async {
        state = .loading

        do {
            let text = try await Task.detached {
                try BookTextPreviewRenderer.render(url: book.url)
            }.value
            state = .loaded(text)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

private enum PreviewState: Equatable {
    case loading
    case loaded(String)
    case failed(String)
}

private enum BookTextPreviewRenderer {
    static func render(url: URL) throws -> String {
        guard let executableURL = EPUBConverter.defaultExecutableURL() else {
            throw PreviewError.missingConverter
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("txt")
        defer {
            try? FileManager.default.removeItem(at: outputURL)
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["convert", url.path, outputURL.path, "--to", "txt", "--quiet"]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw PreviewError.failed(error.localizedDescription)
        }

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw PreviewError.failed(errorText?.isEmpty == false ? errorText! : "boko could not render this book.")
        }

        let data = try Data(contentsOf: outputURL)
        let rawText = String(data: data, encoding: .utf8) ?? ""
        let text = rawText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")

        guard !text.isEmpty else {
            throw PreviewError.failed("This book did not produce readable preview text.")
        }

        let previewLimit = 40_000
        if text.count > previewLimit {
            let endIndex = text.index(text.startIndex, offsetBy: previewLimit)
            return String(text[..<endIndex]) + "\n\nPreview truncated."
        }

        return text
    }
}

private enum PreviewError: LocalizedError {
    case missingConverter
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .missingConverter:
            "The bundled boko converter was not found."
        case .failed(let message):
            message
        }
    }
}
