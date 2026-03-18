import Foundation
import WidgetKit

/// Leichtgewichtiges Artikel-Objekt für den Widget-Datenaustausch via App Group UserDefaults.
public struct WidgetArticle: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let feedTitle: String
    public let publishedAt: Date?
    public let url: URL?

    public init(id: String, title: String, feedTitle: String, publishedAt: Date?, url: URL?) {
        self.id = id
        self.title = title
        self.feedTitle = feedTitle
        self.publishedAt = publishedAt
        self.url = url
    }
}

public enum WidgetDataBridge {
    private static let articlesKey = "com.rssreader.widget.latestArticles"
    private static let defaults = UserDefaults(suiteName: AppGroupConfig.appGroupID)

    /// Schreibt die neuesten Artikel in die App Group UserDefaults und aktualisiert das Widget.
    public static func write(articles: [WidgetArticle]) {
        guard let data = try? JSONEncoder().encode(articles) else { return }
        defaults?.set(data, forKey: articlesKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Liest die gespeicherten Artikel aus der App Group UserDefaults.
    public static func read() -> [WidgetArticle] {
        guard
            let data = defaults?.data(forKey: articlesKey),
            let articles = try? JSONDecoder().decode([WidgetArticle].self, from: data)
        else { return [] }
        return articles
    }
}
