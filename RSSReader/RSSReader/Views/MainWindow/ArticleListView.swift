import SwiftUI
import SwiftData

struct ArticleListView: View {
    @Binding var selectedItem: FeedItem?
    let feed: Feed?
    var smartFolder: SmartFolder? = nil

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeedItem.publishedAt, order: .reverse) private var allItems: [FeedItem]

    @State private var filterMode: FilterMode = .alle
    @State private var searchText = ""

    enum FilterMode: String, CaseIterable {
        case alle      = "Alle"
        case ungelesen = "Ungelesen"
        case favoriten = "Favoriten"
    }

    // MARK: – Filtering

    private var filteredItems: [FeedItem] {
        var items = allItems

        // 1. Feed-Filter
        if let feed {
            items = items.filter { $0.feed?.id == feed.id }
        }

        // 2. Smart-Folder-Filter
        if let sf = smartFolder {
            if sf.filterUnreadOnly    { items = items.filter { !$0.isRead } }
            if sf.filterStarredOnly   { items = items.filter { $0.isStarred } }
            if !sf.filterFeedURLs.isEmpty {
                items = items.filter {
                    guard let url = $0.feed?.url.absoluteString else { return false }
                    return sf.filterFeedURLs.contains(url)
                }
            }
            if !sf.filterKeyword.isEmpty {
                items = items.filter {
                    $0.title.localizedCaseInsensitiveContains(sf.filterKeyword) ||
                    ($0.itemDescription?.localizedCaseInsensitiveContains(sf.filterKeyword) ?? false)
                }
            }
            // Heute-Filter
            if sf.name == "Heute" {
                let startOfDay = Calendar.current.startOfDay(for: .now)
                items = items.filter { ($0.publishedAt ?? .distantPast) >= startOfDay }
            }
        }

        // 3. Segmented-Filter
        switch filterMode {
        case .alle:      break
        case .ungelesen: items = items.filter { !$0.isRead }
        case .favoriten: items = items.filter { $0.isStarred }
        }

        // 4. Suche (Titel, Autor, Beschreibung)
        if !searchText.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.author?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.itemDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return items
    }

    private var isGlobalSearch: Bool {
        feed == nil && smartFolder == nil && !searchText.isEmpty
    }

    // MARK: – Body

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $filterMode) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            if filteredItems.isEmpty {
                emptyState
            } else {
                List(selection: $selectedItem) {
                    ForEach(filteredItems) { item in
                        ArticleRowView(item: item)
                            .tag(item)
                            .contextMenu { contextMenu(for: item) }
                    }
                }
                .listStyle(.plain)
                // Tastaturkürzel – nur aktiv wenn Liste den Fokus hat
                .onKeyPress("j") { selectNext(); return .handled }
                .onKeyPress("k") { selectPrev(); return .handled }
                .onKeyPress("m") { toggleRead();  return .handled }
                .onKeyPress("s") { toggleStar();  return .handled }
                .onKeyPress(.space) { openInBrowser(); return .handled }
            }
        }
        .searchable(text: $searchText, prompt: "Artikel durchsuchen")
        .navigationTitle(navigationTitle)
        .onChange(of: selectedItem) { _, newItem in
            if let newItem, !newItem.isRead {
                newItem.isRead = true
                try? modelContext.save()
            }
        }
    }

    // MARK: – Empty State

    @ViewBuilder
    private var emptyState: some View {
        if isGlobalSearch {
            ContentUnavailableView.search(text: searchText)
        } else if feed == nil && smartFolder == nil {
            ContentUnavailableView {
                Label("Feed oder Suche auswählen", systemImage: "arrow.left")
            } description: {
                Text("Wähle links einen Feed aus oder gib einen Suchbegriff ein.")
            }
        } else {
            ContentUnavailableView {
                Label("Keine Artikel", systemImage: "newspaper")
            } description: {
                Text("Keine Artikel für den ausgewählten Filter vorhanden.")
            }
        }
    }

    private var navigationTitle: String {
        if let sf = smartFolder { return sf.name }
        return feed?.title ?? "Artikel"
    }

    // MARK: – Context Menu

    @ViewBuilder
    private func contextMenu(for item: FeedItem) -> some View {
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
            Button("Im Browser öffnen") { NSWorkspace.shared.open(url) }
            Button("Link kopieren") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
            }
        }
    }

    // MARK: – Keyboard Actions

    private func selectNext() {
        let items = filteredItems
        guard !items.isEmpty else { return }
        if let current = selectedItem, let idx = items.firstIndex(of: current) {
            if idx + 1 < items.count { selectedItem = items[idx + 1] }
        } else {
            selectedItem = items.first
        }
    }

    private func selectPrev() {
        let items = filteredItems
        guard !items.isEmpty else { return }
        if let current = selectedItem, let idx = items.firstIndex(of: current) {
            if idx > 0 { selectedItem = items[idx - 1] }
        } else {
            selectedItem = items.first
        }
    }

    private func toggleRead() {
        guard let item = selectedItem else { return }
        item.isRead.toggle()
        try? modelContext.save()
    }

    private func toggleStar() {
        guard let item = selectedItem else { return }
        item.isStarred.toggle()
        try? modelContext.save()
    }

    private func openInBrowser() {
        guard let url = selectedItem?.url else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: – Row View

extension String {
    var strippedHTML: String {
        self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;",  with: "&")
            .replacingOccurrences(of: "&lt;",   with: "<")
            .replacingOccurrences(of: "&gt;",   with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;",  with: "'")
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
