import SwiftUI
import WebKit

struct ArticleDetailView: View {
    let item: FeedItem?

    var body: some View {
        if let item {
            VStack(spacing: 0) {
                // Kopfzeile
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .textSelection(.enabled)

                    HStack {
                        if let author = item.author {
                            Label(author, systemImage: "person")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let feedTitle = item.feed?.title {
                            Label(feedTitle, systemImage: "dot.radiowaves.up.forward")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let date = item.publishedAt {
                            Text(date, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 12) {
                        Button(action: { item.isStarred.toggle() }) {
                            Label(
                                item.isStarred ? "Favorit entfernen" : "Als Favorit",
                                systemImage: item.isStarred ? "star.fill" : "star"
                            )
                        }
                        .buttonStyle(.borderless)

                        Button(action: { item.isRead.toggle() }) {
                            Label(
                                item.isRead ? "Ungelesen" : "Gelesen",
                                systemImage: item.isRead ? "envelope" : "envelope.open"
                            )
                        }
                        .buttonStyle(.borderless)

                        if let url = item.url {
                            Button(action: { NSWorkspace.shared.open(url) }) {
                                Label("Im Browser öffnen", systemImage: "safari")
                            }
                            .buttonStyle(.borderless)

                            ShareLink(item: url) {
                                Label("Teilen", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding()

                Divider()

                // Inhalt
                if let html = item.contentHTML ?? item.itemDescription {
                    WebContentView(html: html)
                } else {
                    ContentUnavailableView(
                        "Kein Inhalt",
                        systemImage: "doc.text",
                        description: Text("Dieser Artikel hat keinen Inhalt zum Anzeigen.")
                    )
                }
            }
        } else {
            ContentUnavailableView(
                "Kein Artikel ausgewählt",
                systemImage: "newspaper",
                description: Text("Wähle einen Artikel aus der Liste, um ihn hier zu lesen.")
            )
        }
    }
}

struct WebContentView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            :root { color-scheme: light dark; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
                font-size: 15px;
                line-height: 1.6;
                padding: 16px;
                margin: 0;
                color: -apple-system-label;
                max-width: 100%;
                word-wrap: break-word;
            }
            img { max-width: 100%; height: auto; border-radius: 8px; }
            a { color: -apple-system-blue; }
            pre, code {
                background: rgba(128, 128, 128, 0.1);
                border-radius: 4px;
                padding: 2px 6px;
                font-size: 13px;
            }
            pre { padding: 12px; overflow-x: auto; }
            blockquote {
                border-left: 3px solid rgba(128, 128, 128, 0.3);
                margin-left: 0;
                padding-left: 16px;
                color: rgba(128, 128, 128, 0.8);
            }
        </style>
        </head>
        <body>
        \(html)
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}
