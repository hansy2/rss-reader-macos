import Foundation
import SwiftData

enum OPMLService {

    // MARK: - Export

    @MainActor
    static func export(from context: ModelContext) throws -> Data {
        let groups = try context.fetch(FetchDescriptor<FeedGroup>(sortBy: [SortDescriptor(\.sortOrder)]))
        let feeds  = try context.fetch(FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.title)]))

        var xml  = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<opml version=\"2.0\">\n"
        xml += "  <head>\n"
        xml += "    <title>RSS Reader Export</title>\n"
        xml += "    <dateCreated>\(rfc822())</dateCreated>\n"
        xml += "  </head>\n"
        xml += "  <body>\n"

        // Grouped feeds
        for group in groups {
            let groupFeeds = feeds.filter { $0.group?.name == group.name }
            guard !groupFeeds.isEmpty else { continue }
            xml += "    <outline text=\"\(esc(group.name))\" title=\"\(esc(group.name))\">\n"
            for feed in groupFeeds { xml += "      \(outlineTag(feed))\n" }
            xml += "    </outline>\n"
        }

        // Ungrouped feeds
        for feed in feeds where feed.group == nil {
            xml += "    \(outlineTag(feed))\n"
        }

        xml += "  </body>\n</opml>\n"
        return Data(xml.utf8)
    }

    private static func outlineTag(_ feed: Feed) -> String {
        var s = "<outline type=\"rss\""
        s += " text=\"\(esc(feed.title))\""
        s += " title=\"\(esc(feed.title))\""
        s += " xmlUrl=\"\(esc(feed.url.absoluteString))\""
        if let h = feed.siteURL { s += " htmlUrl=\"\(esc(h.absoluteString))\"" }
        s += "/>"
        return s
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&",  with: "&amp;")
         .replacingOccurrences(of: "<",  with: "&lt;")
         .replacingOccurrences(of: ">",  with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func rfc822() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f.string(from: .now)
    }

    // MARK: - Preview

    static func preview(data: Data, fileName: String) -> ImportPreview? {
        let helper = OPMLParserHelper()
        let parser = XMLParser(data: data)
        parser.delegate = helper
        parser.parse()
        guard !helper.feeds.isEmpty || parser.parserError == nil else { return nil }
        let groupNames = Set(helper.feeds.compactMap { $0.groupName })
        return ImportPreview(
            format: .opml,
            fileName: fileName,
            groupCount: groupNames.count,
            feedCount: helper.feeds.count,
            ruleCount: 0
        )
    }

    // MARK: - Import

    @MainActor
    static func importOPML(
        _ data: Data,
        into context: ModelContext,
        strategy: ImportStrategy
    ) throws {
        let helper = OPMLParserHelper()
        let parser = XMLParser(data: data)
        parser.delegate = helper
        parser.parse()

        if strategy == .replaceAll {
            try context.delete(model: Feed.self)
            try context.delete(model: FeedGroup.self)
        }

        let existingURLs = Set(
            try context.fetch(FetchDescriptor<Feed>()).map { $0.url.absoluteString }
        )
        let existingGroupList = try context.fetch(FetchDescriptor<FeedGroup>())
        var groupMap = Dictionary(uniqueKeysWithValues: existingGroupList.map { ($0.name, $0) })

        // Create missing groups
        let groupNames = Set(helper.feeds.compactMap { $0.groupName })
        for name in groupNames.sorted() where groupMap[name] == nil {
            let g = FeedGroup(name: name, sortOrder: groupMap.count)
            context.insert(g)
            groupMap[name] = g
        }

        // Insert feeds
        for f in helper.feeds where !existingURLs.contains(f.url) {
            guard let url = URL(string: f.url) else { continue }
            let feed = Feed(
                title: f.title.isEmpty ? f.url : f.title,
                url: url,
                siteURL: f.siteURL.flatMap(URL.init)
            )
            feed.group = f.groupName.flatMap { groupMap[$0] }
            context.insert(feed)
        }

        try context.save()
    }
}

// MARK: - OPML XML Parser (NSObject, not actor-isolated)

private class OPMLParserHelper: NSObject, XMLParserDelegate {
    struct ParsedFeed {
        let title: String
        let url: String
        let siteURL: String?
        let groupName: String?
    }

    var feeds: [ParsedFeed] = []

    // Stack tracks open <outline> elements: (isGroup, groupName?)
    private var stack: [(isGroup: Bool, name: String?)] = []

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        guard elementName == "outline" else { return }

        let text   = attributes["text"] ?? attributes["title"] ?? ""
        let xmlUrl = attributes["xmlUrl"]

        if let xmlUrl, !xmlUrl.isEmpty {
            // Feed outline
            let group = stack.last(where: { $0.isGroup })?.name
            feeds.append(ParsedFeed(
                title: text,
                url: xmlUrl,
                siteURL: attributes["htmlUrl"],
                groupName: group
            ))
            stack.append((isGroup: false, name: text))
        } else {
            // Folder / group outline
            stack.append((isGroup: true, name: text.isEmpty ? nil : text))
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        guard elementName == "outline" else { return }
        _ = stack.popLast()
    }
}
