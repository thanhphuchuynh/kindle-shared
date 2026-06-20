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
                    viewModel.refreshBooksWithFeedback()
                } label: {
                    if viewModel.isLoading(.refresh) {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.selectedFolder == nil)
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
                .disabled(viewModel.selectedFolder == nil)
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
            }

            Section("Server") {
                sidebarRow("Status", value: viewModel.isSharing ? "Sharing" : "Stopped", systemImage: viewModel.isSharing ? "checkmark.circle.fill" : "pause.circle")
                sidebarRow("Port", value: "8787", systemImage: "network")
                sidebarRow("Formats", value: "PDF EPUB AZW", systemImage: "doc.text")
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
        VStack(spacing: 0) {
            connectionHeader

            Divider()

            bookTable
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
                        .disabled(viewModel.selectedFolder == nil)
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

                if viewModel.selectedFolder != nil {
                    Text("\(viewModel.books.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            if viewModel.selectedFolder == nil {
                ContentUnavailableView("Choose a books folder", systemImage: "folder", description: Text("Use the toolbar to choose the folder you want to share with Kindle."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.books.isEmpty {
                ContentUnavailableView("No supported books", systemImage: "doc.text.magnifyingglass", description: Text("Supported formats are PDF, EPUB, MOBI, AZW, and AZW3."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.books) {
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

                    TableColumn("Status") { _ in
                        Text("Ready")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.green.opacity(0.12), in: Capsule())
                    }
                    .width(96)
                }
                .tableStyle(.inset)
            }
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

    private var urlHelpText: String {
        if let errorMessage = viewModel.errorMessage {
            return errorMessage
        }

        return "This address only works inside your local Wi-Fi network."
    }
}
