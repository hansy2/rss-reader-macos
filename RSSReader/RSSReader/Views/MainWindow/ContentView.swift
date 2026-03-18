import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedGroup: FeedGroup?
    @State private var selectedFeed: Feed?
    @State private var selectedItem: FeedItem?
    @State private var showAllFeeds = true

    var body: some View {
        HStack(spacing: 0) {
            // Linke Seite: Feed-Navigation (3-spaltig)
            NavigationSplitView {
                FeedSidebarView(
                    selectedFeed: $selectedFeed,
                    selectedGroup: selectedGroup,
                    showAllFeeds: showAllFeeds
                )
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 350)
            } content: {
                ArticleListView(
                    selectedItem: $selectedItem,
                    feed: selectedFeed
                )
                .navigationSplitViewColumnWidth(min: 250, ideal: 320, max: 500)
            } detail: {
                ArticleDetailView(item: selectedItem)
            }

            Divider()

            // Rechte Seite: Gruppen-Sidebar (immer sichtbar)
            GroupSidebarView(
                selectedGroup: $selectedGroup,
                showAllFeeds: $showAllFeeds
            )
            .frame(minWidth: 160, idealWidth: 200, maxWidth: 300)
        }
        .frame(minWidth: 900, minHeight: 500)
    }
}
