import Foundation

struct DiscoveredFeed {
    let url: URL
    let title: String
}

enum FeedDiscoveryService {

    /// Versucht RSS/Atom-Feeds von einer beliebigen Website-URL zu finden.
    static func discover(from urlString: String) async -> [DiscoveredFeed] {
        var normalized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.lowercased().hasPrefix("http") {
            normalized = "https://" + normalized
        }
        guard let url = URL(string: normalized) else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let contentType = (response as? HTTPURLResponse)?
                .value(forHTTPHeaderField: "Content-Type") ?? ""

            // Direkt ein Feed?
            if contentType.contains("xml") || contentType.contains("rss") || contentType.contains("atom") || contentType.contains("json") {
                return [DiscoveredFeed(url: url, title: "Feed")]
            }

            // HTML nach <link rel="alternate"> durchsuchen
            guard let html = String(data: data, encoding: .utf8)
                          ?? String(data: data, encoding: .isoLatin1) else { return [] }
            return parseAlternateLinks(from: html, baseURL: url)
        } catch {
            return []
        }
    }

    // MARK: – HTML Parsing

    private static func parseAlternateLinks(from html: String, baseURL: URL) -> [DiscoveredFeed] {
        var feeds: [DiscoveredFeed] = []
        guard let linkRegex = try? NSRegularExpression(
            pattern: #"<link[^>]+>"#,
            options: .caseInsensitive
        ) else { return [] }

        let ns = html as NSString
        let matches = linkRegex.matches(
            in: html,
            range: NSRange(location: 0, length: ns.length)
        )

        for match in matches {
            let tag = ns.substring(with: match.range).lowercased()
            guard tag.contains("alternate"),
                  tag.contains("rss") || tag.contains("atom") || tag.contains("feed") else { continue }

            let original = ns.substring(with: match.range)
            if let href  = extractAttribute("href",  from: original),
               let feedURL = resolveURL(href, baseURL: baseURL) {
                let title = extractAttribute("title", from: original) ?? "RSS / Atom Feed"
                feeds.append(DiscoveredFeed(url: feedURL, title: title))
            }
        }
        return feeds
    }

    private static func extractAttribute(_ name: String, from tag: String) -> String? {
        let patterns = [
            "\(name)=['\"]([^'\"]+)['\"]",
            "\(name)=([^ >]+)"
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let ns = tag as NSString
            if let m = regex.firstMatch(in: tag, range: NSRange(location: 0, length: ns.length)),
               m.numberOfRanges > 1 {
                let r = m.range(at: 1)
                if r.location != NSNotFound {
                    return ns.substring(with: r)
                }
            }
        }
        return nil
    }

    private static func resolveURL(_ href: String, baseURL: URL) -> URL? {
        if href.lowercased().hasPrefix("http") {
            return URL(string: href)
        } else if href.hasPrefix("//") {
            return URL(string: "https:" + href)
        } else if href.hasPrefix("/") {
            var c = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            c?.path = href
            c?.query = nil
            return c?.url
        } else {
            return URL(string: href, relativeTo: baseURL)?.absoluteURL
        }
    }
}
