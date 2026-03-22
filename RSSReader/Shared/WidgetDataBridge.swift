import Foundation
import WidgetKit

/// Leichtgewichtiges Artikel-Objekt für den Widget-Datenaustausch.
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
    /// Gemeinsame JSON-Datei im App-Group-Container (shared zwischen App und Widget)
    private static var sharedFileURL: URL {
        let container = AppGroupConfig.containerURL
        try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
        return container.appending(path: "widget.json")
    }

    /// Schreibt die neuesten Artikel als JSON-Datei und aktualisiert das Widget.
    public static func write(articles: [WidgetArticle]) {
        guard let data = try? JSONEncoder().encode(articles) else { return }
        try? data.write(to: sharedFileURL, options: .atomic)
        WidgetCenter.shared.reloadTimelines(ofKind: "RSSReaderWidget")
    }

    /// Liest die gespeicherten Artikel aus der JSON-Datei.
    public static func read() -> [WidgetArticle] {
        guard
            let data = try? Data(contentsOf: sharedFileURL),
            let articles = try? JSONDecoder().decode([WidgetArticle].self, from: data)
        else { return [] }
        return articles
    }
}
