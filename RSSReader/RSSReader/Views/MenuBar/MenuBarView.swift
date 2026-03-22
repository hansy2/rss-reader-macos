import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(FeedFetchService.self) private var fetchService
    @Environment(RuleEngine.self) private var ruleEngine
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FeedItem.publishedAt, order: .reverse) private var allItems: [FeedItem]

    private var latestItems: [FeedItem] {
        Array(allItems.prefix(12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Label("RSS Reader", systemImage: "dot.radiowaves.up.forward")
                    .font(.headline)
                Spacer()
                if fetchService.isFetching {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Neueste Artikel
            if latestItems.isEmpty {
                Text("Keine Artikel vorhanden")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(latestItems) { item in
                            MenuBarArticleRow(item: item)
                            if item.id != latestItems.last?.id {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
            }

            Divider()

            // Aktionen
            Button(action: refreshAll) {
                Label(
                    fetchService.isFetching ? "Wird aktualisiert…" : "Alle aktualisieren",
                    systemImage: "arrow.clockwise"
                )
            }
            .disabled(fetchService.isFetching)

            Button("Hauptfenster öffnen") {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }

            Divider()

            Button("Beenden") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .frame(width: 340)
    }

    private func refreshAll() {
        Task { @MainActor in
            await fetchService.fetchAll(modelContext: modelContext, ruleEngine: ruleEngine)
        }
    }
}

private struct MenuBarArticleRow: View {
    let item: FeedItem

    var body: some View {
        Button(action: openArticle) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 6) {
                    if !item.isRead {
                        Circle()
                            .fill(.blue)
                            .frame(width: 7, height: 7)
                            .padding(.top, 4)
                    } else {
                        Spacer().frame(width: 7)
                    }

                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(item.isRead ? .regular : .semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    if let feedTitle = item.feed?.title {
                        Text(feedTitle)
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
                .padding(.leading, 13)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openArticle() {
        item.isRead = true
        try? item.modelContext?.save()
        if let url = item.url {
            NSWorkspace.shared.open(url)
        }
    }
}
