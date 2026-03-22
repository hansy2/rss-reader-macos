import SwiftUI
import SwiftData

// MARK: - Rules Main View

struct RulesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Rule.createdAt) private var rules: [Rule]

    @State private var selectedRule: Rule?
    @State private var isAdding = false

    var body: some View {
        NavigationSplitView {
            // Linke Spalte: Regelliste
            ruleList
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 280)
        } detail: {
            // Rechte Spalte: Bearbeitung / Leer
            Group {
                if isAdding {
                    RuleEditView(rule: nil, onSave: { newRule in
                        selectedRule = newRule
                        isAdding = false
                    }, onCancel: {
                        isAdding = false
                    })
                } else if let rule = selectedRule {
                    RuleEditView(rule: rule, onSave: { _ in }, onCancel: {
                        selectedRule = nil
                    })
                    .id(rule.id)
                } else {
                    noSelectionView
                }
            }
            .frame(minWidth: 400)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 660, minHeight: 480)
    }

    // MARK: Regelliste

    private var ruleList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Regeln")
                    .font(.headline)
                Spacer()
                Button(action: addRule) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Neue Regel")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if rules.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Keine Regeln")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Klicke auf + um eine\nRegel zu erstellen.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(selection: $selectedRule) {
                    ForEach(rules) { rule in
                        RuleRowView(rule: rule)
                            .tag(rule)
                    }
                    .onDelete(perform: deleteRules)
                }
                .listStyle(.sidebar)
            }

            Divider()

            // Footer mit Delete-Button
            HStack {
                Button(action: deleteSelected) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(selectedRule == nil)
                .help("Ausgewählte Regel löschen")
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var noSelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Keine Regel ausgewählt")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Wähle links eine Regel aus oder\nerstelle eine neue mit +")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button("Neue Regel") { addRule() }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func addRule() {
        selectedRule = nil
        isAdding = true
    }

    private func deleteSelected() {
        guard let rule = selectedRule else { return }
        selectedRule = nil
        modelContext.delete(rule)
        try? modelContext.save()
    }

    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            if selectedRule?.id == rules[index].id { selectedRule = nil }
            modelContext.delete(rules[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Rule Row

struct RuleRowView: View {
    @Bindable var rule: Rule

    var body: some View {
        HStack(spacing: 10) {
            // Farb-Icon je nach Aktion
            Image(systemName: rule.actionType.iconName)
                .foregroundStyle(.white)
                .font(.caption)
                .frame(width: 24, height: 24)
                .background(rule.actionType.color)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundStyle(rule.isEnabled ? .primary : .secondary)

                HStack(spacing: 4) {
                    Text(rule.conditionType.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                    Text(rule.actionType.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: $rule.isEnabled)
                .labelsHidden()
                .scaleEffect(0.8)
                .onChange(of: rule.isEnabled) { _, _ in
                    try? rule.modelContext?.save()
                }
        }
        .padding(.vertical, 2)
        .opacity(rule.isEnabled ? 1 : 0.6)
    }
}

// MARK: - Rule Edit View (inline, kein Sheet)

struct RuleEditView: View {
    let rule: Rule?
    let onSave: (Rule) -> Void
    let onCancel: () -> Void

    @Environment(\.modelContext) private var modelContext
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
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (conditionType == .anyNewArticle || !conditionValue.isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                HStack {
                    Text(isEditing ? "Regel bearbeiten" : "Neue Regel")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Toggle("Aktiv", isOn: $isEnabled)
                        .toggleStyle(.switch)
                }

                Divider()

                // Allgemein
                formSection(title: "Name", icon: "tag") {
                    TextField("z.B. Breaking News benachrichtigen", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                // Bedingung
                formSection(title: "Bedingung", icon: "text.magnifyingglass") {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Typ", selection: $conditionType) {
                            ForEach(RuleConditionType.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if conditionType != .anyNewArticle {
                            if conditionType == .contentContains {
                                Picker("Feld", selection: $conditionField) {
                                    ForEach(RuleConditionField.allCases, id: \.self) {
                                        Text($0.rawValue).tag($0)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            TextField(
                                conditionType == .titleMatches ? "Regulärer Ausdruck" : "Suchwert",
                                text: $conditionValue
                            )
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: conditionType == .titleMatches ? .monospaced : .default))
                        }

                        // Feed-Einschränkung
                        if !feeds.isEmpty {
                            HStack {
                                Image(systemName: "dot.radiowaves.up.forward")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Picker("Feed", selection: $scopeFeedURL) {
                                    Text("Alle Feeds").tag(nil as String?)
                                    ForEach(feeds) { feed in
                                        Text(feed.title).tag(feed.url.absoluteString as String?)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                }

                Divider()

                // Aktion
                formSection(title: "Aktion", icon: "bolt") {
                    VStack(alignment: .leading, spacing: 10) {
                        // Aktion-Buttons
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(RuleActionType.allCases, id: \.self) { type in
                                actionButton(type: type)
                            }
                        }

                        // Payload
                        switch actionType {
                        case .notification:
                            TextField("Nachrichtentext (leer = Artikeltitel)", text: $actionPayload)
                                .textFieldStyle(.roundedBorder)
                        case .playSound:
                            Picker("Sound", selection: $actionPayload) {
                                ForEach(["Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"], id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                        case .runShortcut:
                            TextField("Name des Kurzbefehls", text: $actionPayload)
                                .textFieldStyle(.roundedBorder)
                        case .markAsStarred:
                            EmptyView()
                        }
                    }
                }

                Spacer(minLength: 20)

                // Buttons
                HStack {
                    if isEditing {
                        Button("Abbrechen", role: .cancel) { onCancel() }
                            .buttonStyle(.bordered)
                    }
                    Spacer()
                    Button(isEditing ? "Speichern" : "Regel erstellen") { save() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canSave)
                }
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { loadFromRule() }
    }

    // MARK: Hilfs-Views

    private func formSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            content()
        }
    }

    private func actionButton(type: RuleActionType) -> some View {
        Button(action: { actionType = type }) {
            HStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .foregroundStyle(actionType == type ? .white : type.color)
                    .font(.callout)
                Text(type.rawValue)
                    .font(.callout)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(actionType == type ? type.color : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(actionType == type ? type.color : Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .foregroundStyle(actionType == type ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: Logik

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
            try? modelContext.save()
            onSave(rule)
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
            try? modelContext.save()
            onSave(newRule)
        }
    }
}

// MARK: - Extensions für Icons & Farben

extension RuleActionType {
    var iconName: String {
        switch self {
        case .notification:   return "bell.fill"
        case .markAsStarred:  return "star.fill"
        case .playSound:      return "speaker.wave.2.fill"
        case .runShortcut:    return "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }

    var color: Color {
        switch self {
        case .notification:   return .blue
        case .markAsStarred:  return .orange
        case .playSound:      return .purple
        case .runShortcut:    return .green
        }
    }
}
