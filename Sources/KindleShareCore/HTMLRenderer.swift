import Foundation

public enum HTMLRenderer {
    public static func renderIndex(books: [BookFile]) -> String {
        let rows = books.map { book in
            let formatLabel = book.fileExtension.lowercased() == "epub"
                ? "EPUB -> AZW3 on download"
                : book.fileExtension.uppercased()

            return """
            <li>
              <a href="/download/\(book.name.urlPathEncoded)">\(book.name.htmlEscaped)</a>
              <span>\(formatLabel.htmlEscaped) · \(book.displaySize.htmlEscaped)</span>
            </li>
            """
        }
        .joined(separator: "\n")

        let content = rows.isEmpty
            ? "<p class=\"empty\">No supported books found in the selected folder.</p>"
            : "<ul>\n\(rows)\n</ul>"

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Kindle Share</title>
          <style>
            body { font-family: Georgia, serif; margin: 2rem; line-height: 1.45; color: #1f2933; }
            h1 { font-size: 1.8rem; margin-bottom: .25rem; }
            p { color: #52606d; }
            ul { list-style: none; padding: 0; }
            li { border-top: 1px solid #d9e2ec; padding: 1rem 0; }
            a { display: block; font-size: 1.2rem; color: #0b5cad; text-decoration: none; }
            span { display: block; color: #627d98; margin-top: .25rem; }
            .empty { margin-top: 2rem; }
          </style>
        </head>
        <body>
          <h1>Kindle Share</h1>
          <p>Tap a book to download it to this Kindle. EPUB files are converted to AZW3 when boko is bundled or installed on the sharing computer.</p>
          \(content)
        </body>
        </html>
        """
    }
}

extension String {
    var urlPathEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }

    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
