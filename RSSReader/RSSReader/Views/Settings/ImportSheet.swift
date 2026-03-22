import SwiftUI
import SwiftData

struct ImportSheet: View {
    let preview: ImportPreview
    let data: Data

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(BackgroundRefreshManager.self) private var refreshManager

    @State private var strategy: ImportStrategy = .merge
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Importieren")
                    .font(.headline)
            }

            // File preview
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Label(preview.fileName, systemImage: preview.format == .rssBackup ? "externaldrive" : "globe")
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)

                    Divider()

                    HStack(spacing: 20) {
                        if preview.feedCount > 0 {
                            statBadge(
                                value: preview.feedCount,
                                label: preview.feedCount == 1 ? "Feed" : "Feeds",
                                icon: "dot.radiowaves.up.forward"
                            )
                        }
                        if preview.groupCount > 0 {
                            statBadge(
                                value: preview.groupCount,
                                label: preview.groupCount == 1 ? "Gruppe" : "Gruppen",
                                icon: "folder"
                            )
                        }
                        if preview.ruleCount > 0 {
                            statBadge(
                                value: preview.ruleCount,
                                label: preview.ruleCount == 1 ? "Regel" : "Regeln",
                                icon: "bolt"
                            )
                        }
                    }

                    if preview.format == .opml {
                        Label("Regeln werden von OPML nicht unterstützt.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Strategy selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategie")
                    .font(.subheadline.weight(.medium))

                BackupOptionRow(
                    isSelected: strategy == .merge,
                    icon: "arrow.triangle.merge",
                    title: "Zusammenführen",
                    description: "Neue Feeds und Gruppen hinzufügen,\nDuplikate werden übersprungen.",
                    accentColor: .green
                ) { strategy = .merge }

                BackupOptionRow(
                    isSelected: strategy == .replaceAll,
                    icon: "trash.fill",
                    title: "Alles ersetzen",
                    description: "Vorhandene Feeds, Gruppen & Regeln werden\ngelöscht und durch den Import ersetzt. ⚠️",
                    accentColor: .orange
                ) { strategy = .replaceAll }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Importieren") { performImport() }
                    .buttonStyle(.borderedProminent)
                    .disabled(isImporting)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    @ViewBuilder
    private func statBadge(value: Int, label: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
            Text("\(value)")
                .font(.subheadline.weight(.bold))
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func performImport() {
        isImporting = true
        errorMessage = nil
        do {
            switch preview.format {
            case .rssBackup:
                try BackupService.importBackup(
                    data,
                    into: context,
                    strategy: strategy,
                    refreshManager: refreshManager
                )
            case .opml:
                try OPMLService.importOPML(data, into: context, strategy: strategy)
            }
            dismiss()
        } catch {
            errorMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
            isImporting = false
        }
    }
}
