import SwiftUI
import SwiftData

// MARK: - Rules List

struct RulesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Rule.createdAt) private var rules: [Rule]

    @State private var showAddRule = false
    @State private var editingRule: Rule?

    var body: some View {
        Group {
            if rules.isEmpty {
                ContentUnavailableView {
                    Label("Keine Regeln", systemImage: "slider.horizontal.3")
                } description: {
                    Text("Erstelle Regeln, um automatisch auf neue Artikel zu reagieren.")
                } actions: {
                    Button("Erste Regel erstellen") { showAddRule = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(rules) { rule in
                        RuleRowView(rule: rule)
                            .contentShape(Rectangle())
                            .onTapGesture { editingRule = rule }
                    }
                    .onDelete(perform: deleteRules)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Regeln")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fertig") { dismiss() }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: { showAddRule = true }) {
                    Label("Regel hinzufügen", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddRule) {
            NavigationStack {
                RuleEditView(rule: nil)
            }
        }
        .sheet(item: $editingRule) { rule in
            NavigationStack {
                RuleEditView(rule: rule)
            }
        }
    }

    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(rules[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Rule Row

struct RuleRowView: View {
    @Bindable var rule: Rule

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(rule.conditionType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(rule.actionType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("Aktiv", isOn: $rule.isEnabled)
                .labelsHidden()
                .onChange(of: rule.isEnabled) { _, _ in
                    try? rule.modelContext?.save()
                }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Rule Edit

struct RuleEditView: View {
    let rule: Rule?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Feed.title) private var feeds: [Feed]

    @State private var name = ""
    @State private var isEnabled = true
    @State private var conditionType: RuleConditionType = .titleContains
    @State private var conditionValue = ""
    @State private var conditionField: RuleConditionField = .title
    @State private var actionType: RuleActionType = .notification
    @State private var actionPayload = ""
    @State private var scopeFeedURL: String? = nil

    private var isEditing: Bool { rule != nil }
    private var canSave: Bool { !name.isEmpty && (conditionType == .anyNewArticle || !conditionValue.isEmpty) }

    var body: some View {
        Form {
            Section("Allgemein") {
                TextField("Name der Regel", text: $name)
                Toggle("Aktiv", isOn: $isEnabled)
            }

            Section("Bedingung") {
                Picker("Typ", selection: $conditionType) {
                    ForEach(RuleConditionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                if conditionType != .anyNewArticle {
                    if conditionType == .contentContains {
                        Picker("Feld", selection: $conditionField) {
                            ForEach(RuleConditionField.allCases, id: \.self) { field in
                                Text(field.rawValue).tag(field)
                            }
                        }
                    }
                    TextField("Suchwert", text: $conditionValue)
                }

                Picker("Feed einschränken", selection: $scopeFeedURL) {
                    Text("Alle Feeds").tag(nil as String?)
                    ForEach(feeds) { feed in
                        Text(feed.title).tag(feed.url.absoluteString as String?)
                    }
                }
            }

            Section("Aktion") {
                Picker("Typ", selection: $actionType) {
                    ForEach(RuleActionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                switch actionType {
                case .notification:
                    TextField("Benachrichtigungstext (leer = Artikeltitel)", text: $actionPayload)
                case .playSound:
                    TextField("Soundname (z.B. Basso, Ping, Pop)", text: $actionPayload)
                case .runShortcut:
                    TextField("Name des Kurzbefehls", text: $actionPayload)
                case .markAsStarred:
                    EmptyView()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(isEditing ? "Regel bearbeiten" : "Neue Regel")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { save() }
                    .disabled(!canSave)
            }
        }
        .frame(minWidth: 420, minHeight: 460)
        .onAppear { loadFromRule() }
    }

    private func loadFromRule() {
        guard let rule else { return }
        name = rule.name
        isEnabled = rule.isEnabled
        conditionType = rule.conditionType
        conditionValue = rule.conditionValue
        conditionField = rule.conditionField
        actionType = rule.actionType
        actionPayload = rule.actionPayload ?? ""
        scopeFeedURL = rule.scopeFeedURL
    }

    private func save() {
        let payload = actionPayload.trimmingCharacters(in: .whitespacesAndNewlines)

        if let rule {
            rule.name = name
            rule.isEnabled = isEnabled
            rule.conditionType = conditionType
            rule.conditionValue = conditionValue
            rule.conditionField = conditionField
            rule.actionType = actionType
            rule.actionPayload = payload.isEmpty ? nil : payload
            rule.scopeFeedURL = scopeFeedURL
        } else {
            let newRule = Rule(
                name: name,
                isEnabled: isEnabled,
                conditionType: conditionType,
                conditionValue: conditionValue,
                conditionField: conditionField,
                actionType: actionType,
                actionPayload: payload.isEmpty ? nil : payload,
                scopeFeedURL: scopeFeedURL
            )
            modelContext.insert(newRule)
        }

        try? modelContext.save()
        dismiss()
    }
}
