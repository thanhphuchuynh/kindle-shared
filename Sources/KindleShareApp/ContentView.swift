import SwiftUI
import KindleShareCore

struct ContentView: View {
    @StateObject private var viewModel = ShareViewModel()

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 230, ideal: 260, max: 300)
        } detail: {
            detail
        }
        .navigationTitle("Kindle Share")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    viewModel.chooseFolder()
                } label: {
                    Label("Choose Folder", systemImage: "folder")
                }
                .disabled(viewModel.isLoading(.chooseFolder))

                Button {
                    viewModel.addBooks()
                } label: {
                    Label("Add Books", systemImage: "plus")
                }
                .disabled(viewModel.isLoading(.addBooks))

                Button {
                    viewModel.refreshBooksWithFeedback()
                } label: {
                    if viewModel.isLoading(.refresh) {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(!viewModel.hasSource)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.toggleSharing()
                } label: {
                    if viewModel.isLoading(.sharing) {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label(viewModel.isSharing ? "Stop Sharing" : "Start Sharing", systemImage: viewModel.isSharing ? "stop.fill" : "play.fill")
                    }
                }
                .disabled(!viewModel.hasSource)
            }
        }
        .onDisappear {
            viewModel.stopSharing()
        }
    }

    private var sidebar: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "book")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kindle Share")
                            .font(.headline)
                        Text("Local Wi-Fi transfer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Source") {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.folderName)
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text(viewModel.selectedFolder == nil ? "No folder selected" : "\(viewModel.books.count) books ready")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "folder")
                        .foregroundStyle(.tint)
                }

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Added Books")
                            .font(.callout.weight(.medium))

                        Text(viewModel.addedFilesCount == 0 ? "No individual books" : "\(viewModel.addedFilesCount) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "doc.badge.plus")
                        .foregroundStyle(.tint)
                }
            }

            Section("Server") {
                sidebarRow("Status", value: viewModel.isSharing ? "Sharing" : "Stopped", systemImage: viewModel.isSharing ? "checkmark.circle.fill" : "pause.circle")
                sidebarRow("Port", value: "8787", systemImage: "network")
                sidebarRow("Formats", value: "PDF MOBI AZW", systemImage: "doc.text")
                sidebarRow("EPUB", value: "Converts to MOBI", systemImage: "arrow.triangle.2.circlepath")
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Same Wi-Fi required", systemImage: "wifi")
                        .font(.callout.weight(.semibold))
                    Text("Open the Kindle browser and enter the address shown in the main view.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.sidebar)
    }

    private var detail: some View {
        HSplitView {
            VStack(spacing: 0) {
                connectionHeader

                Divider()

                bookTable
            }
            .frame(minWidth: 580)

            previewPanel
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var connectionHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isSharing ? "Ready to share" : "Ready when you are")
                        .font(.title.bold())

                    Text(viewModel.statusSubtitle)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusBadge
            }

            GroupBox {
                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 7) {
                        Label("Kindle Browser URL", systemImage: "globe")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(viewModel.kindleURL)
                            .font(.system(size: 26, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .textSelection(.enabled)

                        Text(urlHelpText)
                            .font(.caption)
                            .foregroundStyle(viewModel.errorMessage == nil ? Color.secondary : Color.orange)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 16)

                    VStack(spacing: 8) {
                        Button {
                            viewModel.copyKindleURL()
                        } label: {
                            toolbarLikeLabel(
                                title: viewModel.isLoading(.copyURL) ? "Copied" : "Copy URL",
                                systemImage: viewModel.isLoading(.copyURL) ? "checkmark" : "doc.on.doc"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(viewModel.localAddress == nil)

                        Button {
                            viewModel.toggleSharing()
                        } label: {
                            if viewModel.isLoading(.sharing) {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text(viewModel.isSharing ? "Stopping" : "Starting")
                                }
                                .frame(minWidth: 126)
                            } else {
                                toolbarLikeLabel(
                                    title: viewModel.isSharing ? "Stop" : "Start",
                                    systemImage: viewModel.isSharing ? "stop.fill" : "play.fill"
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(!viewModel.hasSource)
                    }
                    .frame(width: 148)
                }
                .padding(8)
            }
        }
        .padding(24)
    }

    private var statusBadge: some View {
        Label(viewModel.isSharing ? "Sharing on" : "Stopped", systemImage: viewModel.isSharing ? "circle.fill" : "circle")
            .font(.callout.weight(.semibold))
            .foregroundStyle(viewModel.isSharing ? .green : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
    }

    private var bookTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Shared Books")
                    .font(.headline)

                Spacer()

                if viewModel.hasSource {
                    Text("\(viewModel.books.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            if !viewModel.hasSource {
                ContentUnavailableView("Choose books to share", systemImage: "folder.badge.plus", description: Text("Use the toolbar to choose a folder or add individual books."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.books.isEmpty {
                ContentUnavailableView("No supported books", systemImage: "doc.text.magnifyingglass", description: Text("Supported formats are PDF, MOBI, AZW, AZW3, and EPUB with Calibre conversion."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.books, selection: $viewModel.selectedBookIDs) {
                    TableColumn("Name") { book in
                        Label {
                            Text(book.name)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } icon: {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.tint)
                        }
                    }

                    TableColumn("Format") { book in
                        Text(book.fileExtension.uppercased())
                            .foregroundStyle(.secondary)
                    }
                    .width(80)

                    TableColumn("Size") { book in
                        Text(book.displaySize)
                            .foregroundStyle(.secondary)
                    }
                    .width(90)

                    TableColumn("Status") { book in
                        if book.fileExtension.lowercased() == "epub" {
                            Text("Converts")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.orange.opacity(0.12), in: Capsule())
                        } else {
                            Text("Ready")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.green.opacity(0.12), in: Capsule())
                        }
                    }
                    .width(96)
                }
                .tableStyle(.inset)
            }
        }
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Preview")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Divider()

            if let book = viewModel.selectedBook {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: book.fileExtension.lowercased() == "epub" ? "book.pages" : "doc.text")
                            .font(.system(size: 34, weight: .regular))
                            .foregroundStyle(.tint)
                            .frame(width: 54, height: 54)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text(book.name)
                            .font(.title3.weight(.semibold))
                            .lineLimit(3)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }

                    Divider()

                    VStack(spacing: 10) {
                        previewRow("Format", value: book.fileExtension.uppercased(), systemImage: "doc")
                        previewRow("Size", value: book.displaySize, systemImage: "internaldrive")
                        previewRow("Download", value: downloadName(for: book), systemImage: "arrow.down.circle")
                        previewRow("Conversion", value: conversionStatus(for: book), systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button {
                        viewModel.revealSelectedBookInFinder()
                    } label: {
                        Label("Reveal in Finder", systemImage: "finder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Spacer()
                }
                .padding(18)
            } else {
                ContentUnavailableView("No Book Selected", systemImage: "sidebar.right", description: Text("Select a row to see file and conversion details."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func previewRow(_ title: String, value: String, systemImage: String) -> some View {
        Label {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 10)
                Text(value)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            .font(.callout)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
    }

    private func sidebarRow(_ title: String, value: String, systemImage: String) -> some View {
        Label {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
    }

    private func toolbarLikeLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .frame(maxWidth: .infinity)
    }

    private func downloadName(for book: BookFile) -> String {
        if book.fileExtension.lowercased() == "epub" {
            return book.url.deletingPathExtension().lastPathComponent + ".mobi"
        }

        return book.name
    }

    private func conversionStatus(for book: BookFile) -> String {
        book.fileExtension.lowercased() == "epub" ? "Bundled Calibre" : "Not needed"
    }

    private var urlHelpText: String {
        if let errorMessage = viewModel.errorMessage {
            return errorMessage
        }

        return "This address only works inside your local Wi-Fi network."
    }
}
