import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ArticleEntry: TimelineEntry {
    let date: Date
    let articles: [WidgetArticle]
}

// MARK: - Provider

struct ArticleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ArticleEntry {
        ArticleEntry(date: .now, articles: [
            WidgetArticle(id: "1", title: "Beispiel-Artikel aus deinem RSS-Feed", feedTitle: "Heise Online", publishedAt: .now, url: nil),
            WidgetArticle(id: "2", title: "Noch ein interessanter Artikel", feedTitle: "Spiegel", publishedAt: .now, url: nil),
            WidgetArticle(id: "3", title: "Breaking News: Wichtige Meldung", feedTitle: "FAZ", publishedAt: .now, url: nil),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (ArticleEntry) -> Void) {
        let articles = context.isPreview ? placeholder(in: context).articles : WidgetDataBridge.read()
        completion(ArticleEntry(date: .now, articles: articles))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArticleEntry>) -> Void) {
        let articles = WidgetDataBridge.read()
        let entry = ArticleEntry(date: .now, articles: articles)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Entry View (dispatches by family)

struct RSSWidgetEntryView: View {
    var entry: ArticleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(articles: entry.articles)
        case .systemLarge:
            LargeWidgetView(articles: entry.articles)
        default:
            MediumWidgetView(articles: entry.articles)
        }
    }
}

// MARK: - Small (3 Artikel)

struct SmallWidgetView: View {
    let articles: [WidgetArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeader(count: articles.count)
            Divider()
            if articles.isEmpty {
                emptyState
            } else {
                ForEach(articles.prefix(3)) { article in
                    Text(article.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    if article.id != articles.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
    }

    private var emptyState: some View {
        Text("Noch keine Artikel")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Medium (4 Artikel mit Feed-Name + Zeit)

struct MediumWidgetView: View {
    let articles: [WidgetArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(count: articles.count)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)
            Divider()
            if articles.isEmpty {
                emptyState
            } else {
                ForEach(Array(articles.prefix(4).enumerated()), id: \.element.id) { index, article in
                    ArticleRowView(article: article)
                    if index < min(articles.count, 4) - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("RSSReader starten und Feeds hinzufügen")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Large (7 Artikel)

struct LargeWidgetView: View {
    let articles: [WidgetArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(count: articles.count)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
            Divider()
            if articles.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "newspaper")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Noch keine Artikel")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(Array(articles.prefix(7).enumerated()), id: \.element.id) { index, article in
                    ArticleRowView(article: article)
                    if index < min(articles.count, 7) - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Reusable Subviews

struct WidgetHeader: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dot.radiowaves.up.forward")
                .foregroundStyle(.blue)
                .font(.caption)
            Text("RSS Reader")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            Spacer()
            if count > 0 {
                Text("\(count) neu")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ArticleRowView: View {
    let article: WidgetArticle

    private var destination: URL {
        var components = URLComponents()
        components.scheme = "rssreader"
        components.host = "article"
        components.queryItems = [URLQueryItem(name: "id", value: article.id)]
        return components.url ?? URL(string: "rssreader://open")!
    }

    var body: some View {
        Link(destination: destination) {
            VStack(alignment: .leading, spacing: 2) {
                Text(article.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                HStack {
                    Text(article.feedTitle)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Spacer()
                    if let date = article.publishedAt {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget Entry Point

@main
struct RSSReaderWidgetBundle: Widget {
    let kind: String = "RSSReaderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArticleProvider()) { entry in
            RSSWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("RSS Reader")
        .description("Zeigt die neuesten Artikel deiner RSS-Feeds.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
