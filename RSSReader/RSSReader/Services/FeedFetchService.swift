import Foundation
import SwiftData
import FeedKit

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

        await withTaskGroup(of: (Feed, [FeedItem])?.self) { group in
            for feed in feeds {
                group.addTask { [weak self] in
                    guard let items = await self?.fetchFeed(feed) else { return nil }
                    return (feed, items)
                }
            }

            for await result in group {
                guard let (feed, newItems) = result else { continue }
                for item in newItems {
                    item.feed = feed
                    modelContext.insert(item)
                }
                feed.lastFetchedAt = .now

                // Regeln prüfen
                let ruleDescriptor = FetchDescriptor<Rule>(predicate: #Predicate { $0.isEnabled })
                if let rules = try? modelContext.fetch(ruleDescriptor) {
                    ruleEngine.evaluate(newItems: newItems, rules: rules)
                }
            }
        }

        try? modelContext.save()
        updateWidget(modelContext: modelContext)
    }

    @MainActor
    func fetchSingleFeed(_ feed: Feed, modelContext: ModelContext) async {
        guard let newItems = await fetchFeed(feed) else { return }
        for item in newItems {
            item.feed = feed
            modelContext.insert(item)
        }
        feed.lastFetchedAt = .now
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

    private func fetchFeed(_ feed: Feed) async -> [FeedItem]? {
        guard let (data, _) = try? await URLSession.shared.data(from: feed.url) else {
            return nil
        }

        let parser = FeedParser(data: data)
        let result = parser.parse()

        switch result {
        case .success(let parsedFeed):
            return mapToFeedItems(parsedFeed)
        case .failure:
            return nil
        }
    }

    private func mapToFeedItems(_ parsedFeed: FeedKit.Feed) -> [FeedItem] {
        var items: [FeedItem] = []

        switch parsedFeed {
        case .rss(let rssFeed):
            for rssItem in rssFeed.items ?? [] {
                let guid = rssItem.guid?.value ?? rssItem.link ?? UUID().uuidString
                let item = FeedItem(
                    guid: guid,
                    title: rssItem.title ?? "Ohne Titel",
                    itemDescription: rssItem.description,
                    contentHTML: rssItem.content?.contentEncoded,
                    url: rssItem.link.flatMap(URL.init(string:)),
                    imageURL: rssItem.enclosure?.attributes?.url.flatMap(URL.init(string:)),
                    author: rssItem.author ?? rssItem.dublinCore?.dcCreator,
                    publishedAt: rssItem.pubDate
                )
                items.append(item)
            }

        case .atom(let atomFeed):
            for entry in atomFeed.entries ?? [] {
                let guid = entry.id ?? entry.links?.first?.attributes?.href ?? UUID().uuidString
                let link = entry.links?.first?.attributes?.href
                let item = FeedItem(
                    guid: guid,
                    title: entry.title ?? "Ohne Titel",
                    itemDescription: entry.summary?.value,
                    contentHTML: entry.content?.value,
                    url: link.flatMap(URL.init(string:)),
                    author: entry.authors?.first?.name,
                    publishedAt: entry.published ?? entry.updated
                )
                items.append(item)
            }

        case .json(let jsonFeed):
            for jsonItem in jsonFeed.items ?? [] {
                let guid = jsonItem.id ?? jsonItem.url ?? UUID().uuidString
                let item = FeedItem(
                    guid: guid,
                    title: jsonItem.title ?? "Ohne Titel",
                    itemDescription: jsonItem.summary,
                    contentHTML: jsonItem.contentHtml,
                    url: jsonItem.url.flatMap(URL.init(string:)),
                    imageURL: jsonItem.image.flatMap(URL.init(string:)),
                    author: jsonItem.author?.name,
                    publishedAt: jsonItem.datePublished
                )
                items.append(item)
            }
        }

        return items
    }
}
