import SwiftUI
import SwiftData

struct AssignGroupView: View {
    let feed: Feed

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \FeedGroup.sortOrder) private var groups: [FeedGroup]
    @State private var selectedGroupID: PersistentIdentifier?

    var body: some View {
        VStack(spacing: 16) {
            Text("Gruppe zuweisen")
                .font(.headline)

            Text("Feed: \(feed.title)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Picker("Gruppe", selection: $selectedGroupID) {
                Text("Keine Gruppe").tag(nil as PersistentIdentifier?)
                ForEach(groups) { group in
                    Label(group.name, systemImage: group.iconName)
                        .tag(group.id as PersistentIdentifier?)
                }
            }
            .labelsHidden()
            .pickerStyle(.radioGroup)

            HStack {
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Zuweisen") { assign() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            selectedGroupID = feed.group?.id
        }
    }

    private func assign() {
        if let id = selectedGroupID,
           let group = groups.first(where: { $0.id == id }) {
            feed.group = group
        } else {
            feed.group = nil
        }
        try? modelContext.save()
        dismiss()
    }
}
