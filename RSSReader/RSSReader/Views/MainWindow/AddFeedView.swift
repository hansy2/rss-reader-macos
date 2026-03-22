import SwiftUI
import SwiftData
import FeedKit

struct AddFeedView: View {
    let selectedGroup: FeedGroup?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \FeedGroup.sortOrder) private var groups: [FeedGroup]

    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedGroupID: PersistentIdentifier?
    @State private var discoveredFeeds: [DiscoveredFeed] = []
    @State private var showDiscovery = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feed hinzufügen")
                .font(.headline)

            urlSection
            groupSection

            if showDiscovery && !discoveredFeeds.isEmpty {
                discoverySection
            }

            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    Text(error).foregroundStyle(.red)
                }
                .font(.caption)
            }

            buttonRow
        }
        .padding()
        .frame(width: 440)
        .onAppear { selectedGroupID = selectedGroup?.id }
    }

    // MARK: – Sections

    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Feed-URL oder Website-Adresse")
                .font(.subheadline).foregroundStyle(.secondary)
            TextField("https://example.com/feed.rss", text: $urlText)
                .textFieldStyle(.roundedBorder)
                .onSubmit { Task { await addFeed() } }
                .autocorrectionDisabled()
            Text("Normale Website-Adressen werden automatisch nach Feeds durchsucht.")
                .font(.caption).foregroundStyle(.tertiary)
        }
    }

    private var groupSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gruppe").font(.subheadline).foregroundStyle(.secondary)
            Picker("Gruppe", selection: $selectedGroupID) {
                Text("Keine Gruppe").tag(nil as PersistentIdentifier?)
                ForEach(groups) { group in
                    Text(group.name).tag(group.id as PersistentIdentifier?)
                }
            }
            .labelsHidden()
        }
    }

    private var discoverySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gefundene Feeds – bitte auswählen:")
                .font(.subheadline).foregroundStyle(.secondary)
            DiscoveredFeedList(feeds: discoveredFeeds) { feed in
                Task { await addDiscoveredFeed(feed) }
            }
        }
    }

    private var buttonRow: some View {
        HStack {
            Button("Abbrechen") { dismiss() }.keyboardShortcut(.escape)
            Spacer()
            if isLoading { ProgressView().scaleEffect(0.8) }
            Button("Hinzufügen") { Task { await addFeed() } }
                .buttonStyle(.borderedProminent)
                .disabled(urlText.isEmpty || isLoading)
                .keyboardShortcut(.return)
        }
    }

    // MARK: – Aktionen

    private func addFeed() async {
        discoveredFeeds = []
        showDiscovery = false

        var trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.lowercased().hasPrefix("http") { trimmed = "https://" + trimmed }

        guard let url = URL(string: trimmed) else {
            errorMessage = "Ungültige URL"; return
        }

        isLoading = true
        errorMessage = nil

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = FeedParser(data: data).parse()
            await MainActor.run {
                switch result {
                case .success(let pf):
                    let title: String
                    switch pf {
                    case .rss(let r):   title = r.title  ?? url.host ?? "Feed"
                    case .atom(let a):  title = a.title  ?? url.host ?? "Feed"
                    case .json(let j):  title = j.title  ?? url.host ?? "Feed"
                    }
                    insertFeed(url: url, title: title)
                case .failure:
                    isLoading = false
                    Task { await runDiscovery(from: trimmed) }
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                Task { await runDiscovery(from: trimmed) }
            }
        }
    }

    private func runDiscovery(from urlString: String) async {
        await MainActor.run { isLoading = true }
        let found = await FeedDiscoveryService.discover(from: urlString)
        await MainActor.run {
            isLoading = false
            if found.isEmpty {
                errorMessage = "Kein RSS/Atom-Feed an dieser Adresse gefunden."
            } else if found.count == 1 {
                Task { await addDiscoveredFeed(found[0]) }
            } else {
                discoveredFeeds = found
                showDiscovery = true
            }
        }
    }

    private func addDiscoveredFeed(_ discovered: DiscoveredFeed) async {
        isLoading = true
        errorMessage = nil
        do {
            let (data, _) = try await URLSession.shared.data(from: discovered.url)
            let result = FeedParser(data: data).parse()
            await MainActor.run {
                let title: String
                switch result {
                case .success(let pf):
                    switch pf {
                    case .rss(let r):  title = r.title  ?? discovered.title
                    case .atom(let a): title = a.title  ?? discovered.title
                    case .json(let j): title = j.title  ?? discovered.title
                    }
                case .failure: title = discovered.title
                }
                insertFeed(url: discovered.url, title: title)
            }
        } catch {
            await MainActor.run { errorMessage = "Feed konnte nicht geladen werden."; isLoading = false }
        }
    }

    private func insertFeed(url: URL, title: String) {
        let urlString = url.absoluteString
        // SwiftData #Predicate kann keine berechneten Eigenschaften wie .absoluteString
        // auf URL-Feldern verwenden → alle Feeds laden und im Speicher vergleichen.
        let descriptor = FetchDescriptor<Feed>()
        if let all = try? modelContext.fetch(descriptor),
           all.contains(where: { $0.url.absoluteString == urlString }) {
            errorMessage = "Dieser Feed ist bereits vorhanden."; isLoading = false; return
        }
        let feed = Feed(title: title, url: url)
        if let gid = selectedGroupID, let group = groups.first(where: { $0.id == gid }) {
            feed.group = group
        }
        modelContext.insert(feed)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: – Separate View für Discovery-Liste (löst ViewBuilder-Typ-Inferenz-Problem)

private struct DiscoveredFeedList: View {
    let feeds: [DiscoveredFeed]
    let onSelect: (DiscoveredFeed) -> Void

    var body: some View {
        VStack(spacing: 4) {
            // enumerated() + Array umgeht den ForEach-Binding-Inferenz-Fehler des Compilers
            ForEach(Array(feeds.enumerated()), id: \.offset) { offset, feed in
                Button(action: { onSelect(feed) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(feed.title)
                                .font(.subheadline).fontWeight(.medium)
                            Text(feed.url.absoluteString)
                                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "plus.circle").foregroundStyle(Color.accentColor)
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
