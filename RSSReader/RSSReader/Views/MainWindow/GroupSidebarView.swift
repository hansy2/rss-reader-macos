import SwiftUI
import SwiftData

struct GroupSidebarView: View {
    @Binding var selectedGroup: FeedGroup?
    @Binding var showAllFeeds: Bool
    @Binding var selectedSmartFolder: SmartFolder?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeedGroup.sortOrder)    private var groups: [FeedGroup]
    @Query(sort: \SmartFolder.sortOrder) private var smartFolders: [SmartFolder]

    @State private var newGroupName = ""
    @State private var showAddGroup = false
    @State private var editingGroup: FeedGroup?
    @State private var editName = ""
    @State private var showAddSmartFolder = false
    @State private var editingSmartFolder: SmartFolder?

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

            // Hauptliste
            List {
                // Alle Feeds
                Section {
                    GroupRow(
                        name: "Alle Feeds",
                        icon: "tray.2",
                        isSelected: showAllFeeds && selectedSmartFolder == nil
                    )
                    .onTapGesture {
                        showAllFeeds = true
                        selectedGroup = nil
                        selectedSmartFolder = nil
                    }
                    .listRowSeparator(.hidden)

                    ForEach(groups) { group in
                        GroupRow(
                            name: group.name,
                            icon: group.iconName,
                            isSelected: !showAllFeeds && selectedGroup?.id == group.id && selectedSmartFolder == nil,
                            count: group.feeds.count
                        )
                        .onTapGesture {
                            showAllFeeds = false
                            selectedGroup = group
                            selectedSmartFolder = nil
                        }
                        .contextMenu {
                            Button("Umbenennen") {
                                editingGroup = group
                                editName = group.name
                            }
                            Button("Löschen", role: .destructive) { deleteGroup(group) }
                        }
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: moveGroups)
                }

                // Smart Folders
                Section {
                    ForEach(smartFolders) { sf in
                        GroupRow(
                            name: sf.name,
                            icon: sf.iconName,
                            isSelected: selectedSmartFolder?.id == sf.id
                        )
                        .onTapGesture {
                            selectedSmartFolder = sf
                            showAllFeeds = false
                            selectedGroup = nil
                        }
                        .contextMenu {
                            Button("Bearbeiten") { editingSmartFolder = sf }
                            Button("Löschen", role: .destructive) {
                                if selectedSmartFolder?.id == sf.id { selectedSmartFolder = nil }
                                modelContext.delete(sf)
                                try? modelContext.save()
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    .onMove(perform: moveSmartFolders)

                    Button(action: { showAddSmartFolder = true }) {
                        Label("Smart Folder hinzufügen", systemImage: "plus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                } header: {
                    Text("Smart Folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Neue Gruppe
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
        // Gruppe umbenennen
        .sheet(item: $editingGroup) { group in
            VStack(spacing: 12) {
                Text("Gruppe umbenennen").font(.headline)
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
        // Smart Folder erstellen / bearbeiten
        .sheet(isPresented: $showAddSmartFolder) {
            SmartFolderEditView(smartFolder: nil, existingCount: smartFolders.count)
        }
        .sheet(item: $editingSmartFolder) { sf in
            SmartFolderEditView(smartFolder: sf, existingCount: smartFolders.count)
        }
        .onAppear {
            // Standard Smart Folders beim ersten Start anlegen
            if smartFolders.isEmpty {
                let heute = SmartFolder(name: "Heute",           sortOrder: 0, iconName: "calendar",    filterUnreadOnly: false)
                let unread = SmartFolder(name: "Alle ungelesen", sortOrder: 1, iconName: "envelope",    filterUnreadOnly: true)
                let starred = SmartFolder(name: "Favoriten",     sortOrder: 2, iconName: "star",         filterStarredOnly: true)
                modelContext.insert(heute)
                modelContext.insert(unread)
                modelContext.insert(starred)
                try? modelContext.save()
            }
        }
    }

    // MARK: – Aktionen

    private func addGroup() {
        guard !newGroupName.isEmpty else { return }
        let group = FeedGroup(name: newGroupName, sortOrder: groups.count)
        modelContext.insert(group)
        try? modelContext.save()
        newGroupName = ""
        showAddGroup = false
    }

    private func deleteGroup(_ group: FeedGroup) {
        for feed in group.feeds { feed.group = nil }
        modelContext.delete(group)
        try? modelContext.save()
        if selectedGroup?.id == group.id { showAllFeeds = true; selectedGroup = nil }
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var ordered = groups
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, g) in ordered.enumerated() { g.sortOrder = i }
        try? modelContext.save()
    }

    private func moveSmartFolders(from source: IndexSet, to destination: Int) {
        var ordered = smartFolders
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, sf) in ordered.enumerated() { sf.sortOrder = i }
        try? modelContext.save()
    }
}

// MARK: – GroupRow

struct GroupRow: View {
    let name: String
    let icon: String
    let isSelected: Bool
    var count: Int? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 20)
            Text(name).lineLimit(1)
            Spacer()
            if let count {
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color.clear)
        .foregroundStyle(isSelected ? .white : .primary)
        .cornerRadius(6)
    }
}

// MARK: – Smart Folder Editor

struct SmartFolderEditView: View {
    let smartFolder: SmartFolder?
    let existingCount: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var iconName: String
    @State private var filterUnreadOnly: Bool
    @State private var filterStarredOnly: Bool
    @State private var filterKeyword: String

    private let iconOptions = [
        "folder.badge.gearshape", "star", "envelope", "calendar",
        "tag", "bookmark", "heart", "flame", "bolt", "globe"
    ]

    init(smartFolder: SmartFolder?, existingCount: Int) {
        self.smartFolder = smartFolder
        self.existingCount = existingCount
        _name = State(initialValue: smartFolder?.name ?? "")
        _iconName = State(initialValue: smartFolder?.iconName ?? "folder.badge.gearshape")
        _filterUnreadOnly = State(initialValue: smartFolder?.filterUnreadOnly ?? false)
        _filterStarredOnly = State(initialValue: smartFolder?.filterStarredOnly ?? false)
        _filterKeyword = State(initialValue: smartFolder?.filterKeyword ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(smartFolder == nil ? "Smart Folder erstellen" : "Smart Folder bearbeiten")
                .font(.headline)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text("Symbol").font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 8) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Button(action: { iconName = icon }) {
                            Image(systemName: icon)
                                .frame(width: 32, height: 32)
                                .background(iconName == icon ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                                .foregroundStyle(iconName == icon ? .white : .primary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Filter").font(.subheadline).foregroundStyle(.secondary)
                Toggle("Nur ungelesene Artikel", isOn: $filterUnreadOnly)
                Toggle("Nur Favoriten",           isOn: $filterStarredOnly)
                HStack {
                    Text("Stichwort:")
                    TextField("z.B. Apple, KI, Sport …", text: $filterKeyword)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Speichern") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty)
                    .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 360)
    }

    private func save() {
        if let sf = smartFolder {
            sf.name = name
            sf.iconName = iconName
            sf.filterUnreadOnly = filterUnreadOnly
            sf.filterStarredOnly = filterStarredOnly
            sf.filterKeyword = filterKeyword
        } else {
            let sf = SmartFolder(
                name: name,
                sortOrder: existingCount,
                iconName: iconName,
                filterUnreadOnly: filterUnreadOnly,
                filterStarredOnly: filterStarredOnly,
                filterKeyword: filterKeyword
            )
            modelContext.insert(sf)
        }
        try? modelContext.save()
        dismiss()
    }
}
