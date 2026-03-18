import SwiftUI
import SwiftData

struct FeedSidebarView: View {
    @Binding var selectedFeed: Feed?
    let selectedGroup: FeedGroup?
    let showAllFeeds: Bool

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Feed.title) private var allFeeds: [Feed]

    @State private var showAddFeed = false
    @State private var searchText = ""
    @State private var renamingFeed: Feed?
    @State private var renameText = ""
    @State private var assigningFeed: Feed?

    private var filteredFeeds: [Feed] {
        var feeds = allFeeds

        if !showAllFeeds, let group = selectedGroup {
            feeds = feeds.filter { $0.group?.id == group.id }
        }

        if !searchText.isEmpty {
            feeds = feeds.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        return feeds
    }

    var body: some View {
        VStack(spacing: 0) {
            // Inline-Suchfeld (kein .searchable(), da NavigationSplitView nur einen
            // Search-Toolbar-Eintrag erlaubt – ArticleListView belegt diesen bereits)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Feeds durchsuchen", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            List(selection: $selectedFeed) {
                Section {
                    ForEach(filteredFeeds) { feed in
                    FeedRowView(feed: feed)
                        .tag(feed)
                        .contextMenu {
                            Button("Umbenennen") {
                                renamingFeed = feed
                                renameText = feed.title
                            }
                            Button("Gruppe zuweisen…") {
                                assigningFeed = feed
                            }
                            if feed.group != nil {
                                Button("Aus Gruppe entfernen") {
                                    feed.group = nil
                                    try? modelContext.save()
                                }
                            }
                            Divider()
                            Button("Alle als gelesen markieren") {
                                for item in feed.items {
                                    item.isRead = true
                                }
                                try? modelContext.save()
                            }
                            Divider()
                            Button("Löschen", role: .destructive) {
                                if selectedFeed?.id == feed.id {
                                    selectedFeed = nil
                                }
                                modelContext.delete(feed)
                                try? modelContext.save()
                            }
                        }
                }
            } header: {
                HStack {
                    Text(showAllFeeds ? "Alle Feeds" : (selectedGroup?.name ?? "Feeds"))
                    Spacer()
                    Text("\(filteredFeeds.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            }
            .listStyle(.sidebar)
        }
        .toolbar {
            ToolbarItem {
                Button(action: { showAddFeed.toggle() }) {
                    Label("Feed hinzufügen", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Feeds")
        .sheet(isPresented: $showAddFeed) {
            AddFeedView(selectedGroup: selectedGroup)
        }
        .sheet(item: $renamingFeed) { feed in
            VStack(spacing: 16) {
                Text("Feed umbenennen")
                    .font(.headline)
                TextField("Name", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveFeedRename(feed) }
                HStack {
                    Button("Abbrechen") { renamingFeed = nil }
                        .keyboardShortcut(.escape)
                    Spacer()
                    Button("Speichern") { saveFeedRename(feed) }
                        .buttonStyle(.borderedProminent)
                        .disabled(renameText.isEmpty)
                        .keyboardShortcut(.return)
                }
            }
            .padding()
            .frame(width: 320)
        }
        .sheet(item: $assigningFeed) { feed in
            AssignGroupView(feed: feed)
        }
    }

    private func saveFeedRename(_ feed: Feed) {
        guard !renameText.isEmpty else { return }
        feed.title = renameText
        try? modelContext.save()
        renamingFeed = nil
    }
}


struct FeedRowView: View {
    let feed: Feed

    var body: some View {
        HStack {
            if let imageURL = feed.imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "dot.radiowaves.up.forward")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "dot.radiowaves.up.forward")
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feed.title)
                    .lineLimit(1)
                if let description = feed.feedDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if feed.unreadCount > 0 {
                Text("\(feed.unreadCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
    }
}
