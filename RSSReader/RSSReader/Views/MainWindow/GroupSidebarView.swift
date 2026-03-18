import SwiftUI
import SwiftData

struct GroupSidebarView: View {
    @Binding var selectedGroup: FeedGroup?
    @Binding var showAllFeeds: Bool

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeedGroup.sortOrder) private var groups: [FeedGroup]

    @State private var newGroupName = ""
    @State private var showAddGroup = false
    @State private var editingGroup: FeedGroup?
    @State private var editName = ""

    var body: some View {
        VStack(spacing: 0) {
            // Kopfzeile
            HStack {
                Text("Gruppen")
                    .font(.headline)
                Spacer()
                Button(action: { showAddGroup.toggle() }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Gruppenliste (scrollbar)
            ScrollView {
                LazyVStack(spacing: 2) {
                    // "Alle Feeds" Eintrag
                    GroupRow(
                        name: "Alle Feeds",
                        icon: "tray.2",
                        isSelected: showAllFeeds,
                        feedCount: nil
                    )
                    .onTapGesture {
                        showAllFeeds = true
                        selectedGroup = nil
                    }

                    Divider()
                        .padding(.vertical, 4)

                    // Einzelne Gruppen
                    ForEach(groups) { group in
                        GroupRow(
                            name: group.name,
                            icon: group.iconName,
                            isSelected: !showAllFeeds && selectedGroup?.id == group.id,
                            feedCount: group.feeds.count
                        )
                        .onTapGesture {
                            showAllFeeds = false
                            selectedGroup = group
                        }
                        .contextMenu {
                            Button("Umbenennen") {
                                editingGroup = group
                                editName = group.name
                            }
                            Button("Löschen", role: .destructive) {
                                deleteGroup(group)
                            }
                        }
                    }
                    .onMove(perform: moveGroups)
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }

            Divider()

            // Neue Gruppe hinzufügen
            if showAddGroup {
                HStack {
                    TextField("Gruppenname", text: $newGroupName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addGroup() }
                    Button("OK") { addGroup() }
                        .buttonStyle(.borderless)
                        .disabled(newGroupName.isEmpty)
                }
                .padding(8)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(item: $editingGroup) { group in
            VStack(spacing: 12) {
                Text("Gruppe umbenennen")
                    .font(.headline)
                TextField("Name", text: $editName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Abbrechen") { editingGroup = nil }
                    Spacer()
                    Button("Speichern") {
                        group.name = editName
                        try? modelContext.save()
                        editingGroup = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }

    private func addGroup() {
        guard !newGroupName.isEmpty else { return }
        let group = FeedGroup(name: newGroupName, sortOrder: groups.count)
        modelContext.insert(group)
        try? modelContext.save()
        newGroupName = ""
        showAddGroup = false
    }

    private func deleteGroup(_ group: FeedGroup) {
        // Feeds aus Gruppe entfernen, nicht löschen
        for feed in group.feeds {
            feed.group = nil
        }
        modelContext.delete(group)
        try? modelContext.save()

        if selectedGroup?.id == group.id {
            showAllFeeds = true
            selectedGroup = nil
        }
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var orderedGroups = groups
        orderedGroups.move(fromOffsets: source, toOffset: destination)
        for (index, group) in orderedGroups.enumerated() {
            group.sortOrder = index
        }
        try? modelContext.save()
    }
}

struct GroupRow: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let feedCount: Int?

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 20)
            Text(name)
                .lineLimit(1)
            Spacer()
            if let feedCount {
                Text("\(feedCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color.clear)
        .foregroundStyle(isSelected ? .white : .primary)
        .cornerRadius(6)
    }
}
