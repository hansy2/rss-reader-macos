import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(FeedFetchService.self) private var fetchService
    @Environment(RuleEngine.self) private var ruleEngine
    @Environment(\.modelContext) private var modelContext

    @State private var selectedGroup: FeedGroup?
    @State private var selectedFeed: Feed?
    @State private var selectedItem: FeedItem?
    @State private var showAllFeeds = true
    @Environment(\.openWindow) private var openWindow
    @State private var router = AppRouter.shared

    @Query private var allItems: [FeedItem]

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
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: refreshAll) {
                    if fetchService.isFetching {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Label("Aktualisieren", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(fetchService.isFetching)
                .help("Alle Feeds aktualisieren (⌘R)")

                Button(action: { openWindow(id: "rules") }) {
                    Label("Regeln", systemImage: "slider.horizontal.3")
                }
                .help("Regeln verwalten")
            }
        }
        // Wenn App bereits läuft und URL reinkommt
        .onChange(of: router.pendingArticleGUID) { _, guid in
            guard let guid else { return }
            navigateToArticle(guid: guid)
        }
        // Wenn App kalt gestartet wird (Items noch nicht geladen beim ersten onOpenURL)
        .onChange(of: allItems) { _, _ in
            guard let guid = router.pendingArticleGUID else { return }
            navigateToArticle(guid: guid)
        }
        .onAppear {
            // Fallback: Falls GUID schon gesetzt war bevor View erschien
            if let guid = router.pendingArticleGUID {
                navigateToArticle(guid: guid)
            }
        }
    }

    private func navigateToArticle(guid: String) {
        // URLComponents already decoded the guid, so direct match is sufficient
        if let item = allItems.first(where: { $0.guid == guid }) {
            selectedFeed = item.feed
            selectedItem = item
            showAllFeeds = true
            selectedGroup = nil
            router.pendingArticleGUID = nil
        }
    }

    private func refreshAll() {
        Task {
            await fetchService.fetchAll(modelContext: modelContext, ruleEngine: ruleEngine)
        }
    }
}
