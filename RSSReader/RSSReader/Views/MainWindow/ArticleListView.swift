import SwiftUI
import SwiftData

struct ArticleListView: View {
    @Binding var selectedItem: FeedItem?
    let feed: Feed?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeedItem.publishedAt, order: .reverse) private var allItems: [FeedItem]

    @State private var filterMode: FilterMode = .alle
    @State private var searchText = ""

    enum FilterMode: String, CaseIterable {
        case alle = "Alle"
        case ungelesen = "Ungelesen"
        case favoriten = "Favoriten"
    }

    private var filteredItems: [FeedItem] {
        var items = allItems

        if let feed {
            items = items.filter { $0.feed?.id == feed.id }
        }

        switch filterMode {
        case .alle:
            break
        case .ungelesen:
            items = items.filter { !$0.isRead }
        case .favoriten:
            items = items.filter { $0.isStarred }
        }

        if !searchText.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter-Leiste
            Picker("Filter", selection: $filterMode) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            if filteredItems.isEmpty {
                ContentUnavailableView {
                    Label(
                        feed == nil ? "Wähle einen Feed aus" : "Keine Artikel",
                        systemImage: feed == nil ? "arrow.left" : "newspaper"
                    )
                } description: {
                    Text(feed == nil
                         ? "Wähle links einen Feed aus, um Artikel anzuzeigen."
                         : "Keine Artikel für den ausgewählten Filter vorhanden.")
                }
            } else {
                List(selection: $selectedItem) {
                    ForEach(filteredItems) { item in
                        ArticleRowView(item: item)
                            .tag(item)
                            .contextMenu {
                                Button(item.isRead ? "Als ungelesen markieren" : "Als gelesen markieren") {
                                    item.isRead.toggle()
                                    try? modelContext.save()
                                }
                                Button(item.isStarred ? "Favorit entfernen" : "Als Favorit markieren") {
                                    item.isStarred.toggle()
                                    try? modelContext.save()
                                }
                                if let url = item.url {
                                    Divider()
                                    Button("Im Browser öffnen") {
                                        NSWorkspace.shared.open(url)
                                    }
                                    Button("Link kopieren") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(url.absoluteString, forType: .string)
                                    }
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $searchText, prompt: "Artikel durchsuchen")
        .navigationTitle(feed?.title ?? "Artikel")
        .onChange(of: selectedItem) { _, newItem in
            if let newItem, !newItem.isRead {
                newItem.isRead = true
                try? modelContext.save()
            }
        }
    }
}

extension String {
    var strippedHTML: String {
        self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ArticleRowView: View {
    let item: FeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !item.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                }

                Text(item.title)
                    .font(.headline)
                    .fontWeight(item.isRead ? .regular : .bold)
                    .lineLimit(2)

                Spacer()

                if item.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }

            HStack {
                if let author = item.author {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let date = item.publishedAt {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let description = item.itemDescription {
                Text(description.strippedHTML)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
