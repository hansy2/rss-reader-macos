import Foundation

enum FullTextService {

    /// Lädt die vollständige Webseite und extrahiert den Hauptinhalt als HTML.
    static func fetchFullText(from url: URL) async -> String? {
        do {
            var request = URLRequest(url: url)
            request.setValue(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
                forHTTPHeaderField: "User-Agent"
            )
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8)
                          ?? String(data: data, encoding: .isoLatin1) else { return nil }
            return extractMainContent(from: html)
        } catch {
            return nil
        }
    }

    // MARK: – Content Extraction

    private static func extractMainContent(from html: String) -> String? {
        // Reihenfolge: <article>, <main>, div mit content-Klassen, body
        let blockSelectors: [(String, String)] = [
            (#"<article[^>]*>"#, "</article>"),
            (#"<main[^>]*>"#,    "</main>"),
            (#"<div[^>]+class=["\'][^"\']*\b(?:article-body|post-content|entry-content|article-content|story-body|content-body)\b[^"\']*["\'][^>]*>"#, "</div>"),
            (#"<div[^>]+class=["\'][^"\']*\bcontent\b[^"\']*["\'][^>]*>"#, "</div>")
        ]

        for (openPattern, closeTag) in blockSelectors {
            if let block = extractBlock(html: html, openPattern: openPattern, closeTag: closeTag) {
                return removeScriptsAndStyles(from: block)
            }
        }

        // Fallback: kompletten <body>-Inhalt
        if let body = extractBlock(html: html, openPattern: #"<body[^>]*>"#, closeTag: "</body>") {
            return removeScriptsAndStyles(from: body)
        }

        return nil
    }

    private static func extractBlock(html: String, openPattern: String, closeTag: String) -> String? {
        guard let openRegex = try? NSRegularExpression(
            pattern: openPattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return nil }

        let ns = html as NSString
        guard let match = openRegex.firstMatch(
            in: html,
            range: NSRange(location: 0, length: ns.length)
        ) else { return nil }

        let startIdx = match.range.location
        let searchFrom = html.index(
            html.startIndex,
            offsetBy: min(startIdx + match.range.length, html.count)
        )

        guard let closeRange = html.range(
            of: closeTag,
            options: .caseInsensitive,
            range: searchFrom..<html.endIndex
        ) else { return nil }

        let end = html.distance(from: html.startIndex, to: closeRange.upperBound)
        let content = ns.substring(with: NSRange(location: startIdx, length: end - startIdx))
        return content.isEmpty ? nil : content
    }

    private static func removeScriptsAndStyles(from html: String) -> String {
        var result = html
        for pattern in [
            #"<script[^>]*>[\s\S]*?</script>"#,
            #"<style[^>]*>[\s\S]*?</style>"#,
            #"<noscript[^>]*>[\s\S]*?</noscript>"#
        ] {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(location: 0, length: (result as NSString).length),
                    withTemplate: ""
                )
            }
        }
        return result
    }
}
