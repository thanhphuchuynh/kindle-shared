import SwiftUI
import KindleShareCore

struct ContentView: View {
    @StateObject private var viewModel = ShareViewModel()

    private let columns = [
        GridItem(.flexible(minimum: 260), spacing: 0),
        GridItem(.fixed(86), spacing: 0),
        GridItem(.fixed(86), spacing: 0),
        GridItem(.fixed(92), spacing: 0)
    ]

    var body: some View {
        VStack(spacing: 0) {
            titleBar

            HStack(spacing: 0) {
                sidebar
                mainWorkspace
            }
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.hairline.opacity(0.85), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 28, y: 18)
        .padding(12)
        .background(Color.black.opacity(0.04))
        .onDisappear {
            viewModel.stopSharing()
        }
    }

    private var titleBar: some View {
        HStack {
            HStack(spacing: 8) {
                trafficLight(.red)
                trafficLight(.yellow)
                trafficLight(.green)
            }
            .frame(width: 88, alignment: .leading)

            Spacer()

            Text("Kindle Share")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.muted)

            Spacer()

            Color.clear.frame(width: 88, height: 1)
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background(AppColor.titleBar)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 22) {
            brandBlock
            folderPanel
            quickStats
            wifiNote
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .frame(width: 278)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColor.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppColor.hairline)
                .frame(width: 1)
        }
    }

    private var brandBlock: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(AppColor.inverse)

                Image(systemName: "book")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(AppColor.inverseText)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Kindle Share")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColor.ink)

                Text("Local Wi-Fi transfer")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColor.muted)
            }
        }
    }

    private var folderPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Books folder")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColor.muted)

            HStack(spacing: 10) {
                Image(systemName: "folder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.accent)

                Text(viewModel.folderName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.selectedFolder == nil ? AppColor.muted : AppColor.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Button {
                viewModel.chooseFolder()
            } label: {
                Label("Choose Folder", systemImage: "folder.badge.plus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColor.inverseText)
            .background(AppColor.ink, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .padding(14)
        .background(AppColor.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.hairline, lineWidth: 1)
        }
    }

    private var quickStats: some View {
        VStack(spacing: 10) {
            statRow("Books ready", value: "\(viewModel.books.count)")
            statRow("Server port", value: "8787")
            statRow("Formats", value: "PDF EPUB AZW")
        }
    }

    private var wifiNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Same Wi-Fi required")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColor.accent)

            Text("Open the browser on Kindle and enter the address shown on the right.")
                .font(.system(size: 12))
                .lineSpacing(2)
                .foregroundStyle(AppColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.accentSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var mainWorkspace: some View {
        VStack(alignment: .leading, spacing: 22) {
            workspaceHeader
            urlPanel
            booksHeader
            booksTable
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColor.workspace)
    }

    private var workspaceHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.isSharing ? "Ready to share" : "Ready when you are")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColor.ink)

                Text(viewModel.statusSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.muted)
            }

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isSharing ? AppColor.accent : AppColor.muted.opacity(0.5))
                    .frame(width: 8, height: 8)

                Text(viewModel.isSharing ? "Sharing on" : "Stopped")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(viewModel.isSharing ? AppColor.accent : AppColor.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(viewModel.isSharing ? AppColor.accentSoft : AppColor.panel, in: Capsule())
        }
    }

    private var urlPanel: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Type this on Kindle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColor.inverseMuted)

                Text(viewModel.kindleURL)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.inverseText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .textSelection(.enabled)

                Text(urlHelpText)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColor.inverseSecondary)
            }

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Button {
                    viewModel.copyKindleURL()
                } label: {
                    Label("Copy URL", systemImage: "doc.on.doc")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColor.inverse)
                .background(AppColor.inverseText, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .disabled(viewModel.localAddress == nil)

                Button {
                    viewModel.toggleSharing()
                } label: {
                    Label(viewModel.isSharing ? "Stop" : "Start", systemImage: viewModel.isSharing ? "stop.fill" : "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColor.inverseText)
                .background(AppColor.inverseButton, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            }
            .frame(width: 150)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(AppColor.inverse, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var booksHeader: some View {
        HStack {
            Text("Shared books")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppColor.ink)

            Spacer()

            Button {
                viewModel.refreshBooks()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 12)
                    .frame(height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColor.ink)
            .background(AppColor.panel, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(AppColor.hairline, lineWidth: 1)
            }
            .disabled(viewModel.selectedFolder == nil)
        }
    }

    private var booksTable: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 0) {
                tableHeader("Title")
                tableHeader("Format")
                tableHeader("Size")
                tableHeader("Status")
            }
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(AppColor.tableHeader)
            .overlay(alignment: .bottom) {
                Rectangle().fill(AppColor.hairline).frame(height: 1)
            }

            if viewModel.selectedFolder == nil {
                emptyState("Choose a folder to see books here.", systemImage: "books.vertical")
            } else if viewModel.books.isEmpty {
                emptyState("No supported books found in this folder.", systemImage: "magnifyingglass")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.books) { book in
                            bookRow(book)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 292)
        .background(AppColor.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.hairline, lineWidth: 1)
        }
    }

    private func bookRow(_ book: BookFile) -> some View {
        LazyVGrid(columns: columns, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
                    .frame(width: 18)

                Text(book.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            tableCell(book.fileExtension.uppercased(), monospaced: true)
            tableCell(book.displaySize, monospaced: true)

            HStack {
                Text("Ready")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
                    .padding(.horizontal, 12)
                    .frame(height: 26)
                    .background(AppColor.accentSoft, in: Capsule())

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColor.rowDivider).frame(height: 1)
        }
    }

    private func tableHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(AppColor.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tableCell(_ text: String, monospaced: Bool = false) -> some View {
        Text(text)
            .font(monospaced ? .system(size: 12, design: .monospaced) : .system(size: 12))
            .foregroundStyle(AppColor.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppColor.muted)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppColor.ink)
                .lineLimit(1)
        }
    }

    private func trafficLight(_ color: TrafficLightColor) -> some View {
        Circle()
            .fill(color.fill)
            .frame(width: 12, height: 12)
    }

    private func emptyState(_ text: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppColor.muted.opacity(0.72))

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColor.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
    }

    private var urlHelpText: String {
        if let errorMessage = viewModel.errorMessage {
            return errorMessage
        }

        return "This address only works inside your home Wi-Fi network."
    }
}

private enum TrafficLightColor {
    case red
    case yellow
    case green

    var fill: Color {
        switch self {
        case .red: Color(red: 1.0, green: 0.37, blue: 0.34)
        case .yellow: Color(red: 1.0, green: 0.74, blue: 0.18)
        case .green: Color(red: 0.16, green: 0.78, blue: 0.25)
        }
    }
}

private enum AppColor {
    static let surface = Color(red: 0.965, green: 0.961, blue: 0.949)
    static let titleBar = Color(red: 0.945, green: 0.941, blue: 0.925)
    static let sidebar = Color(red: 0.925, green: 0.918, blue: 0.894)
    static let workspace = Color(red: 0.984, green: 0.980, blue: 0.969)
    static let panel = Color.white
    static let ink = Color(red: 0.122, green: 0.137, blue: 0.157)
    static let muted = Color(red: 0.412, green: 0.439, blue: 0.467)
    static let hairline = Color(red: 0.847, green: 0.839, blue: 0.812)
    static let rowDivider = Color(red: 0.925, green: 0.922, blue: 0.902)
    static let tableHeader = Color(red: 0.953, green: 0.949, blue: 0.933)
    static let accent = Color(red: 0.122, green: 0.478, blue: 0.353)
    static let accentSoft = Color(red: 0.902, green: 0.953, blue: 0.925)
    static let inverse = Color(red: 0.094, green: 0.129, blue: 0.114)
    static let inverseButton = Color(red: 0.165, green: 0.204, blue: 0.184)
    static let inverseText = Color(red: 0.969, green: 0.980, blue: 0.973)
    static let inverseMuted = Color(red: 0.686, green: 0.784, blue: 0.729)
    static let inverseSecondary = Color(red: 0.788, green: 0.839, blue: 0.812)
}
