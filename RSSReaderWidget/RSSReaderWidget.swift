import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct ArticleTimelineEntry: TimelineEntry {
    let date: Date
    let articles: [WidgetArticle]
}

// MARK: - Timeline Provider

struct ArticleTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ArticleTimelineEntry {
        ArticleTimelineEntry(
            date: .now,
            articles: [
                WidgetArticle(id: "1", title: "Beispielartikel: Neue Entwicklungen im Tech-Bereich", feedTitle: "Tech News", publishedAt: .now, url: nil),
                WidgetArticle(id: "2", title: "Wirtschaftsnachrichten: Märkte im Überblick", feedTitle: "Wirtschaft", publishedAt: .now.addingTimeInterval(-300), url: nil),
                WidgetArticle(id: "3", title: "Wetter morgen: Sonnig mit leichtem Wind", feedTitle: "Wetter", publishedAt: .now.addingTimeInterval(-600), url: nil),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ArticleTimelineEntry) -> Void) {
        completion(ArticleTimelineEntry(date: .now, articles: WidgetDataBridge.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArticleTimelineEntry>) -> Void) {
        let articles = WidgetDataBridge.read()
        let entry = ArticleTimelineEntry(date: .now, articles: articles)
        // Alle 15 Minuten neu laden
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Definition

@main
struct RSSReaderWidget: Widget {
    let kind = "RSSReaderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArticleTimelineProvider()) { entry in
            RSSWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("RSS Reader")
        .description("Zeigt die neuesten Artikel aus deinen abonnierten Feeds.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
