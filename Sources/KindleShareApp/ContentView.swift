import SwiftUI
import KindleShareCore

struct ContentView: View {
    @StateObject private var viewModel = ShareViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color(red: 0.89, green: 0.94, blue: 0.91)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                header
                folderSection
                kindleURLSection
                booksSection
            }
            .padding(28)
        }
        .onDisappear {
            viewModel.stopSharing()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Kindle Share")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("Share one books folder with your Kindle over local Wi-Fi.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                Circle()
                    .fill(viewModel.isSharing ? Color.green : Color.gray.opacity(0.55))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.statusTitle)
                        .font(.headline)
                    Text(viewModel.statusSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Books Folder")
                        .font(.headline)
                    Text(viewModel.folderName)
                        .foregroundStyle(viewModel.selectedFolder == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button {
                    viewModel.chooseFolder()
                } label: {
                    Label("Choose Folder", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 12) {
                metric(title: "Books", value: "\(viewModel.books.count)")
                metric(title: "Formats", value: "PDF EPUB MOBI AZW")
            }
        }
        .sectionStyle()
    }

    private var kindleURLSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Kindle Browser URL")
                        .font(.headline)
                    Text(viewModel.kindleURL)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .textSelection(.enabled)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        viewModel.copyKindleURL()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .disabled(viewModel.localAddress == nil)

                    Button {
                        viewModel.toggleSharing()
                    } label: {
                        Label(
                            viewModel.isSharing ? "Stop" : "Start",
                            systemImage: viewModel.isSharing ? "stop.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
            } else {
                Text("Open this address on the Kindle browser while both devices are on the same Wi-Fi.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .sectionStyle()
    }

    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Shared Books")
                    .font(.headline)

                Spacer()

                Button {
                    viewModel.refreshBooks()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.selectedFolder == nil)
            }

            if viewModel.selectedFolder == nil {
                emptyState("Choose a folder to see books here.", systemImage: "books.vertical")
            } else if viewModel.books.isEmpty {
                emptyState("No supported books found in this folder.", systemImage: "magnifyingglass")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.books) { book in
                            bookRow(book)
                        }
                    }
                }
                .frame(minHeight: 190)
            }
        }
        .sectionStyle()
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 8))
    }

    private func bookRow(_ book: BookFile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(.teal)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(book.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(book.fileExtension.uppercased()) · \(book.displaySize)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private func emptyState(_ text: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text(text)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 190)
    }
}

private extension View {
    func sectionStyle() -> some View {
        padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
    }
}
