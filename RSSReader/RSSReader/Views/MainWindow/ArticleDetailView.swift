import SwiftUI
import WebKit

struct ArticleDetailView: View {
    let item: FeedItem?

    @Environment(\.modelContext) private var modelContext
    @State private var readingSettings = ReadingSettings.shared
    @State private var fullTextHTML: String?
    @State private var isLoadingFullText = false

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

                    HStack(spacing: 8) {
                        // Stern
                        Button(action: { item.isStarred.toggle(); try? modelContext.save() }) {
                            Image(systemName: item.isStarred ? "star.fill" : "star")
                                .foregroundStyle(item.isStarred ? .yellow : .secondary)
                        }
                        .buttonStyle(.borderless)
                        .help(item.isStarred ? "Favorit entfernen" : "Als Favorit markieren")

                        // Gelesen
                        Button(action: { item.isRead.toggle(); try? modelContext.save() }) {
                            Image(systemName: item.isRead ? "envelope" : "envelope.open")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help(item.isRead ? "Als ungelesen markieren" : "Als gelesen markieren")

                        if let url = item.url {
                            // Browser
                            Button(action: { NSWorkspace.shared.open(url) }) {
                                Image(systemName: "safari")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .help("Im Browser öffnen")

                            // Teilen
                            ShareLink(
                                item: url,
                                subject: Text(item.title),
                                message: Text(item.title)
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .help("Teilen")
                        }

                        Spacer()

                        // Volltext laden (falls aktiviert)
                        if item.feed?.fullTextEnabled == true, let url = item.url {
                            if isLoadingFullText {
                                ProgressView().scaleEffect(0.7).frame(width: 16, height: 16)
                            } else {
                                Button(action: { Task { await loadFullText(url: url) } }) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .help(fullTextHTML != nil ? "Volltext neu laden" : "Volltext laden")
                            }
                        }

                        Divider().frame(height: 16)

                        // Schriftgröße
                        HStack(spacing: 4) {
                            Button(action: { readingSettings.decrease() }) {
                                Image(systemName: "textformat.size.smaller")
                            }
                            .buttonStyle(.borderless)
                            .help("Schrift verkleinern")

                            Text("\(readingSettings.fontSize)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 20)

                            Button(action: { readingSettings.increase() }) {
                                Image(systemName: "textformat.size.larger")
                            }
                            .buttonStyle(.borderless)
                            .help("Schrift vergrößern")
                        }

                        // Theme-Picker
                        Picker("Lesemodus", selection: $readingSettings.theme) {
                            ForEach(ReadingTheme.allCases, id: \.self) { theme in
                                Image(systemName: theme.icon).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 90)
                        .help("Lesemodus wählen")
                    }
                }
                .padding()

                Divider()

                // Inhalt
                let htmlToShow = fullTextHTML ?? item.contentHTML ?? item.itemDescription
                if let html = htmlToShow {
                    WebContentView(html: html, fontSize: readingSettings.fontSize, theme: readingSettings.theme)
                } else {
                    ContentUnavailableView(
                        "Kein Inhalt",
                        systemImage: "doc.text",
                        description: Text("Dieser Artikel hat keinen Inhalt zum Anzeigen.")
                    )
                }
            }
            .onChange(of: item) { _, newItem in
                // Volltext zurücksetzen wenn Artikel wechselt
                fullTextHTML = nil
                // Automatisch laden wenn feed.fullTextEnabled
                if newItem.feed?.fullTextEnabled == true, let url = newItem.url {
                    Task { await loadFullText(url: url) }
                }
            }
            .onAppear {
                if item.feed?.fullTextEnabled == true, let url = item.url {
                    Task { await loadFullText(url: url) }
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

    // MARK: – Volltext

    private func loadFullText(url: URL) async {
        isLoadingFullText = true
        fullTextHTML = await FullTextService.fetchFullText(from: url)
        isLoadingFullText = false
    }
}

// MARK: – WKWebView

struct WebContentView: NSViewRepresentable {
    let html: String
    var fontSize: Int = 15
    var theme: ReadingTheme = .standard

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let bg     = theme.background
        let fg     = theme.foreground
        let link   = theme.link
        let scheme = theme.colorScheme

        let bgCSS = bg == "unset"
            ? "background: transparent;"
            : "background: \(bg);"

        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            :root { color-scheme: \(scheme); }
            html, body {
                \(bgCSS)
                color: \(fg);
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
                font-size: \(fontSize)px;
                line-height: 1.7;
                padding: 16px 20px;
                margin: 0;
                max-width: 100%;
                word-wrap: break-word;
            }
            img { max-width: 100%; height: auto; border-radius: 8px; }
            a { color: \(link); }
            pre, code {
                background: rgba(128,128,128,0.12);
                border-radius: 4px;
                padding: 2px 6px;
                font-size: \(max(fontSize - 2, 11))px;
            }
            pre { padding: 12px; overflow-x: auto; }
            blockquote {
                border-left: 3px solid rgba(128,128,128,0.35);
                margin-left: 0;
                padding-left: 16px;
                opacity: 0.8;
            }
            h1, h2, h3 { line-height: 1.3; }
            figure { margin: 12px 0; }
            figcaption { font-size: \(max(fontSize - 2, 11))px; opacity: 0.7; text-align: center; }
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
