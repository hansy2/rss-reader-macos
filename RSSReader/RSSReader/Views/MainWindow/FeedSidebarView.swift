import SwiftUI
import SwiftData

struct FeedSidebarView: View {
    @Binding var selectedFeed: Feed?
    let selectedGroup: FeedGroup?
    let showAllFeeds: Bool

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Feed.title) private var allFeeds: [Feed]

    @State private var showAddFeed = false
    @State private var newFeedURL = ""
    @State private var searchText = ""

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
        List(selection: $selectedFeed) {
            Section {
                ForEach(filteredFeeds) { feed in
                    FeedRowView(feed: feed)
                        .tag(feed)
                        .contextMenu {
                            Button("Bearbeiten") {
                                // TODO: Feed bearbeiten
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
        .searchable(text: $searchText, prompt: "Feeds durchsuchen")
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
