import Foundation
import SwiftData
import FeedKit

// Reiner Werttyp – vollständig Sendable, keine SwiftData-Abhängigkeit
private struct ParsedItem: Sendable {
    let guid: String
    let title: String
    let itemDescription: String?
    let contentHTML: String?
    let url: URL?
    let imageURL: URL?
    let author: String?
    let publishedAt: Date?
}

@Observable
final class FeedFetchService {
    var isFetching = false
    var lastError: String?

    @MainActor
    func fetchAll(modelContext: ModelContext, ruleEngine: RuleEngine) async {
        isFetching = true
        defer { isFetching = false }
        lastError = nil

        let descriptor = FetchDescriptor<Feed>(predicate: #Predicate { $0.isEnabled })
        guard let feeds = try? modelContext.fetch(descriptor) else { return }

        // Nur Sendable-Werte (PersistentIdentifier + URL) über Task-Grenzen schicken
        let feedInfos: [(id: PersistentIdentifier, url: URL)] = feeds.map { ($0.persistentModelID, $0.url) }

        let results: [(PersistentIdentifier, [ParsedItem])] = await withTaskGroup(
            of: (PersistentIdentifier, [ParsedItem])?.self
        ) { group in
            for info in feedInfos {
                group.addTask { [weak self] in
                    guard let parsed = await self?.fetchAndParse(url: info.url) else { return nil }
                    return (info.id, parsed)
                }
            }
            var collected: [(PersistentIdentifier, [ParsedItem])] = []
            for await result in group {
                if let r = result { collected.append(r) }
            }
            return collected
        }

        // Zurück auf dem MainActor: SwiftData-Objekte erstellen
        let ruleDescriptor = FetchDescriptor<Rule>(predicate: #Predicate { $0.isEnabled })
        let rules = (try? modelContext.fetch(ruleDescriptor)) ?? []

        for (feedID, parsedItems) in results {
            guard let feed = modelContext.model(for: feedID) as? Feed else { continue }

            var newItems: [FeedItem] = []
            for p in parsedItems {
                let guid = p.guid
                let existingDescriptor = FetchDescriptor<FeedItem>(predicate: #Predicate { $0.guid == guid })
                if let existing = try? modelContext.fetch(existingDescriptor), !existing.isEmpty {
                    continue // preserve existing isRead/isStarred
                }
                let item = FeedItem(
                    guid: p.guid,
                    title: p.title,
                    itemDescription: p.itemDescription,
                    contentHTML: p.contentHTML,
                    url: p.url,
                    imageURL: p.imageURL,
                    author: p.author,
                    publishedAt: p.publishedAt
                )
                item.feed = feed
                modelContext.insert(item)
                newItems.append(item)
            }
            feed.lastFetchedAt = .now

            if !newItems.isEmpty {
                ruleEngine.evaluate(newItems: newItems, rules: rules)
            }
        }

        try? modelContext.save()
        updateWidget(modelContext: modelContext)
    }

    @MainActor
    func fetchSingleFeed(_ feed: Feed, modelContext: ModelContext, ruleEngine: RuleEngine? = nil) async {
        guard let parsed = await fetchAndParse(url: feed.url) else { return }
        let ruleDescriptor = FetchDescriptor<Rule>(predicate: #Predicate { $0.isEnabled })
        let rules = (try? modelContext.fetch(ruleDescriptor)) ?? []
        var newItems: [FeedItem] = []
        for p in parsed {
            let guid = p.guid
            let existingDescriptor = FetchDescriptor<FeedItem>(predicate: #Predicate { $0.guid == guid })
            if let existing = try? modelContext.fetch(existingDescriptor), !existing.isEmpty {
                continue // preserve existing isRead/isStarred
            }
            let item = FeedItem(
                guid: p.guid,
                title: p.title,
                itemDescription: p.itemDescription,
                contentHTML: p.contentHTML,
                url: p.url,
                imageURL: p.imageURL,
                author: p.author,
                publishedAt: p.publishedAt
            )
            item.feed = feed
            modelContext.insert(item)
            newItems.append(item)
        }
        feed.lastFetchedAt = .now
        if !newItems.isEmpty, let ruleEngine {
            ruleEngine.evaluate(newItems: newItems, rules: rules)
        }
        try? modelContext.save()
    }

    @MainActor
    private func updateWidget(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<FeedItem>(
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        guard let items = try? modelContext.fetch(descriptor) else { return }
        let widgetArticles = Array(items.prefix(20)).map {
            WidgetArticle(
                id: $0.guid,
                title: $0.title,
                feedTitle: $0.feed?.title ?? "",
                publishedAt: $0.publishedAt,
                url: $0.url
            )
        }
        WidgetDataBridge.write(articles: widgetArticles)
    }

    private func fetchAndParse(url: URL) async -> [ParsedItem]? {
        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            await MainActor.run { lastError = "Netzwerkfehler beim Laden von \(url.host ?? url.absoluteString)" }
            return nil
        }
        let result = FeedParser(data: data).parse()
        guard case .success(let feed) = result else {
            await MainActor.run { lastError = "Feed konnte nicht geparst werden: \(url.host ?? url.absoluteString)" }
            return nil
        }
        return mapToParsedItems(feed)
    }

    private func mapToParsedItems(_ feed: FeedKit.Feed) -> [ParsedItem] {
        switch feed {
        case .rss(let rss):
            return (rss.items ?? []).map { item in
                ParsedItem(
                    guid: item.guid?.value ?? item.link ?? UUID().uuidString,
                    title: item.title ?? "Ohne Titel",
                    itemDescription: item.description,
                    contentHTML: item.content?.contentEncoded,
                    url: item.link.flatMap(URL.init(string:)),
                    imageURL: item.enclosure?.attributes?.url.flatMap(URL.init(string:)),
                    author: item.author ?? item.dublinCore?.dcCreator,
                    publishedAt: item.pubDate
                )
            }
        case .atom(let atom):
            return (atom.entries ?? []).map { entry in
                ParsedItem(
                    guid: entry.id ?? entry.links?.first?.attributes?.href ?? UUID().uuidString,
                    title: entry.title ?? "Ohne Titel",
                    itemDescription: entry.summary?.value,
                    contentHTML: entry.content?.value,
                    url: entry.links?.first?.attributes?.href.flatMap(URL.init(string:)),
                    imageURL: nil,
                    author: entry.authors?.first?.name,
                    publishedAt: entry.published ?? entry.updated
                )
            }
        case .json(let json):
            return (json.items ?? []).map { item in
                ParsedItem(
                    guid: item.id ?? item.url ?? UUID().uuidString,
                    title: item.title ?? "Ohne Titel",
                    itemDescription: item.summary,
                    contentHTML: item.contentHtml,
                    url: item.url.flatMap(URL.init(string:)),
                    imageURL: item.image.flatMap(URL.init(string:)),
                    author: item.author?.name,
                    publishedAt: item.datePublished
                )
            }
        }
    }
}
