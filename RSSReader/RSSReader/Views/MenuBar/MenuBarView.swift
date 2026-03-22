import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(FeedFetchService.self) private var fetchService
    @Environment(RuleEngine.self) private var ruleEngine
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @Query(sort: \FeedItem.publishedAt, order: .reverse) private var allItems: [FeedItem]

    private var latestItems: [FeedItem] { Array(allItems.prefix(15)) }
    private var unreadCount: Int { allItems.filter { !$0.isRead }.count }

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: "dot.radiowaves.up.forward")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.blue)

                Text("RSS Reader")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                if fetchService.isFetching {
                    HStack(spacing: 5) {
                        ProgressView()
                            .scaleEffect(0.65)
                            .frame(width: 14, height: 14)
                        Text("Lädt…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if unreadCount > 0 {
                    Text("\(unreadCount) ungelesen")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)

            Divider()

            // ── Artikel-Liste ────────────────────────────────────
            if latestItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "newspaper")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("Keine Artikel vorhanden")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Feed hinzufügen und aktualisieren")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(latestItems) { item in
                            MenuBarArticleRow(item: item)
                            if item.id != latestItems.last?.id {
                                Divider()
                                    .padding(.leading, 38)
                            }
                        }
                    }
                }
                .frame(maxHeight: 340)
            }

            Divider()

            // ── Aktionen ─────────────────────────────────────────
            VStack(spacing: 2) {
                menuAction(
                    icon: "arrow.clockwise",
                    label: fetchService.isFetching ? "Wird aktualisiert…" : "Alle Feeds aktualisieren",
                    iconColor: .blue,
                    disabled: fetchService.isFetching,
                    action: refreshAll
                )

                menuAction(
                    icon: "macwindow",
                    label: "Hauptfenster öffnen",
                    iconColor: .primary,
                    action: openMainWindow
                )

                Divider()
                    .padding(.vertical, 2)

                menuAction(
                    icon: "power",
                    label: "Beenden",
                    iconColor: .red,
                    shortcut: "⌘Q",
                    action: { NSApp.terminate(nil) }
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(width: 360)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Hilfs-Views

    private func menuAction(
        icon: String,
        label: String,
        iconColor: Color,
        shortcut: String? = nil,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(disabled ? AnyShapeStyle(.tertiary) : AnyShapeStyle(iconColor))
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(disabled ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))

                Spacer()

                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(MenuActionButtonStyle())
        .disabled(disabled)
    }

    // MARK: - Aktionen

    private func refreshAll() {
        Task { @MainActor in
            await fetchService.fetchAll(modelContext: modelContext, ruleEngine: ruleEngine)
        }
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Artikel-Zeile

private struct MenuBarArticleRow: View {
    let item: FeedItem
    @State private var isHovered = false

    var body: some View {
        Button(action: openArticle) {
            HStack(alignment: .top, spacing: 10) {

                // Ungelesen-Punkt
                Circle()
                    .fill(item.isRead ? Color.clear : Color.blue)
                    .frame(width: 7, height: 7)
                    .padding(.top, 5)

                // Inhalt
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 13, weight: item.isRead ? .regular : .semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(item.isRead ? .secondary : .primary)

                    HStack(spacing: 0) {
                        if let feedTitle = item.feed?.title {
                            Text(feedTitle)
                                .font(.caption)
                                .foregroundStyle(.blue.opacity(0.8))
                                .lineLimit(1)
                        }
                        Spacer()
                        if let date = item.publishedAt {
                            Text(date, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                // Pfeil (nur bei Hover)
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .opacity(isHovered ? 1 : 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(isHovered ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private func openArticle() {
        item.isRead = true
        try? item.modelContext?.save()
        if let url = item.url {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Button Style für Menü-Aktionen

private struct MenuActionButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed
                            ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.3)
                            : isHovered
                                ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.12)
                                : Color.clear
                    )
            )
            .onHover { isHovered = $0 }
    }
}
