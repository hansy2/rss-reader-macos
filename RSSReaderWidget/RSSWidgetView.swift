import WidgetKit
import SwiftUI

struct RSSWidgetView: View {
    let entry: ArticleTimelineEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(articles: entry.articles)
        case .systemMedium:
            MediumWidgetView(articles: entry.articles)
        case .systemLarge:
            LargeWidgetView(articles: entry.articles)
        default:
            MediumWidgetView(articles: entry.articles)
        }
    }
}

// MARK: - Small (1 Artikel)

private struct SmallWidgetView: View {
    let articles: [WidgetArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "dot.radiowaves.up.forward")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("RSS Reader")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let article = articles.first {
                Spacer(minLength: 0)
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                Text(article.feedTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let date = article.publishedAt {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Spacer()
                Text("Keine Artikel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(articles.first?.url)
    }
}

// MARK: - Medium (3 Artikel)

private struct MediumWidgetView: View {
    let articles: [WidgetArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "dot.radiowaves.up.forward")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("RSS Reader")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if let date = articles.first?.publishedAt {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.bottom, 6)

            if articles.isEmpty {
                Spacer()
                Text("Keine Artikel vorhanden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(Array(articles.prefix(3).enumerated()), id: \.element.id) { index, article in
                    if index > 0 {
                        Divider().padding(.vertical, 4)
                    }
                    Link(destination: article.url ?? URL(string: "rssreader://")!) {
                        ArticleWidgetRow(article: article, showFeedTitle: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Large (7 Artikel)

private struct LargeWidgetView: View {
    let articles: [WidgetArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "dot.radiowaves.up.forward")
                    .foregroundStyle(.secondary)
                Text("RSS Reader")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Neueste Artikel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            if articles.isEmpty {
                Spacer()
                Text("Keine Artikel vorhanden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(Array(articles.prefix(7).enumerated()), id: \.element.id) { index, article in
                    if index > 0 {
                        Divider().padding(.vertical, 3)
                    }
                    Link(destination: article.url ?? URL(string: "rssreader://")!) {
                        ArticleWidgetRow(article: article, showFeedTitle: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Shared Row

private struct ArticleWidgetRow: View {
    let article: WidgetArticle
    let showFeedTitle: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(article.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            if showFeedTitle {
                HStack {
                    Text(article.feedTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let date = article.publishedAt {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}
