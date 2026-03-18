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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feed hinzufügen")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Feed-URL")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("https://example.com/feed.rss", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await addFeed() } }
                    .autocorrectionDisabled()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Gruppe")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker("Gruppe", selection: $selectedGroupID) {
                    Text("Keine Gruppe").tag(nil as PersistentIdentifier?)
                    ForEach(groups) { group in
                        Text(group.name).tag(group.id as PersistentIdentifier?)
                    }
                }
                .labelsHidden()
            }

            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                }
                .font(.caption)
            }

            HStack {
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.escape)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Button("Hinzufügen") {
                    Task { await addFeed() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(urlText.isEmpty || isLoading)
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            selectedGroupID = selectedGroup?.id
        }
    }

    private func addFeed() async {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil else {
            errorMessage = "Ungültige URL"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let parser = FeedParser(data: data)
            let result = parser.parse()

            await MainActor.run {
                switch result {
                case .success(let parsedFeed):
                    let title: String
                    switch parsedFeed {
                    case .rss(let rss):   title = rss.title ?? url.host ?? "Unbekannter Feed"
                    case .atom(let atom): title = atom.title ?? url.host ?? "Unbekannter Feed"
                    case .json(let json): title = json.title ?? url.host ?? "Unbekannter Feed"
                    }

                    let feed = Feed(title: title, url: url)
                    if let groupID = selectedGroupID,
                       let group = groups.first(where: { $0.id == groupID }) {
                        feed.group = group
                    }
                    modelContext.insert(feed)
                    try? modelContext.save()
                    dismiss()

                case .failure:
                    errorMessage = "Kein gültiger RSS/Atom/JSON-Feed an dieser URL gefunden."
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Verbindung fehlgeschlagen: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
