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
    @State private var showRules = false

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

                Button(action: { showRules = true }) {
                    Label("Regeln", systemImage: "slider.horizontal.3")
                }
                .help("Regeln verwalten")
            }
        }
        .sheet(isPresented: $showRules) {
            NavigationStack {
                RulesView()
            }
            .frame(minWidth: 500, minHeight: 400)
        }
    }

    private func refreshAll() {
        Task {
            await fetchService.fetchAll(modelContext: modelContext, ruleEngine: ruleEngine)
        }
    }
}
