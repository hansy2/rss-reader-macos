import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(BackgroundRefreshManager.self) private var refreshManager

    @State private var selectedFormat: ExportFormat = .rssBackup
    @State private var errorMessage: String?

    enum ExportFormat: CaseIterable, Hashable {
        case rssBackup, opml

        var title: String {
            switch self {
            case .rssBackup: return "RSS Reader Backup (.rssbackup)"
            case .opml:      return "OPML (.opml)"
            }
        }

        var description: String {
            switch self {
            case .rssBackup: return "Feeds, Gruppen, Regeln & Einstellungen.\nNur für RSS Reader geeignet."
            case .opml:      return "Feeds & Gruppen. Kompatibel mit Reeder,\nNetNewsWire, Feedly, Inoreader u.v.m."
            }
        }

        var icon: String {
            switch self {
            case .rssBackup: return "externaldrive.badge.checkmark"
            case .opml:      return "arrow.left.arrow.right"
            }
        }

        var fileExtension: String {
            switch self {
            case .rssBackup: return "rssbackup"
            case .opml:      return "opml"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Exportieren als…")
                    .font(.headline)
            }

            // Format options
            VStack(spacing: 8) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    BackupOptionRow(
                        isSelected: selectedFormat == format,
                        icon: format.icon,
                        title: format.title,
                        description: format.description,
                        accentColor: .blue
                    ) { selectedFormat = format }
                }
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
                Button("Exportieren") { performExport() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private func performExport() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true

        let dateStr = { () -> String in
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: .now)
        }()

        switch selectedFormat {
        case .rssBackup:
            panel.allowedContentTypes = [UTType(filenameExtension: "rssbackup") ?? .data]
            panel.nameFieldStringValue = "RSSReader-Backup-\(dateStr).rssbackup"
        case .opml:
            panel.allowedContentTypes = [UTType(filenameExtension: "opml") ?? .xml]
            panel.nameFieldStringValue = "RSSReader-Feeds-\(dateStr).opml"
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data: Data
            switch selectedFormat {
            case .rssBackup:
                data = try BackupService.export(
                    from: context,
                    refreshIntervalMinutes: refreshManager.refreshIntervalMinutes
                )
            case .opml:
                data = try OPMLService.export(from: context)
            }
            try data.write(to: url, options: .atomic)
            dismiss()
        } catch {
            errorMessage = "Export fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}

// MARK: - Shared option row (used in Export- and ImportSheet)

struct BackupOptionRow: View {
    let isSelected: Bool
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? accentColor : Color.secondary.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? accentColor : .secondary.opacity(0.4))
                    .font(.system(size: 18))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? accentColor.opacity(0.07) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? accentColor.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
