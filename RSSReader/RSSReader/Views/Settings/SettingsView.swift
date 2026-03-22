import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(BackgroundRefreshManager.self) private var refreshManager
    @Environment(\.modelContext) private var context

    @State private var showExportSheet = false
    @State private var importPreview: ImportPreview?
    @State private var importData: Data?
    @State private var importError: String?

    var body: some View {
        @Bindable var manager = refreshManager

        Form {
            Section {
                Picker("Intervall", selection: $manager.refreshIntervalMinutes) {
                    Text("Manuell").tag(0)
                    Text("5 Minuten").tag(5)
                    Text("15 Minuten").tag(15)
                    Text("30 Minuten").tag(30)
                    Text("1 Stunde").tag(60)
                    Text("2 Stunden").tag(120)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)
            } header: {
                Text("Automatische Aktualisierung")
            } footer: {
                if manager.refreshIntervalMinutes > 0 {
                    Text("Feeds werden alle \(intervalDescription(manager.refreshIntervalMinutes)) automatisch aktualisiert.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Feeds werden nur manuell aktualisiert (⌘R).")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Benachrichtigungen") {
                Button("Berechtigung für Benachrichtigungen anfordern") {
                    NotificationService().requestPermission()
                }
                .buttonStyle(.link)
            }

            Section {
                HStack(spacing: 12) {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Exportieren", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        openImportPanel()
                    } label: {
                        Label("Importieren", systemImage: "square.and.arrow.down")
                    }
                }

                if let error = importError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Datensicherung")
            } footer: {
                Text("Export als RSS Reader Backup (.rssbackup) oder OPML (.opml) für andere RSS-Reader.\nImport erkennt das Format automatisch.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 320)
        .sheet(isPresented: $showExportSheet) {
            ExportSheet()
                .environment(refreshManager)
        }
        .sheet(item: $importPreview) { preview in
            if let data = importData {
                ImportSheet(preview: preview, data: data)
                    .environment(refreshManager)
            }
        }
    }

    // MARK: - Import file picker

    private func openImportPanel() {
        importError = nil
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "rssbackup") ?? .data,
            UTType(filenameExtension: "opml") ?? .xml,
            .xml
        ]
        panel.message = "RSS Reader Backup (.rssbackup) oder OPML-Datei auswählen"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let ext = url.pathExtension.lowercased()

            if ext == "opml" || ext == "xml" {
                guard let preview = OPMLService.preview(data: data, fileName: fileName) else {
                    importError = "Die Datei konnte nicht als OPML gelesen werden."
                    return
                }
                importData = data
                importPreview = preview
            } else {
                // Try .rssbackup (JSON)
                let preview = try BackupService.preview(data: data, fileName: fileName)
                importData = data
                importPreview = preview
            }
        } catch {
            importError = "Datei konnte nicht gelesen werden: \(error.localizedDescription)"
        }
    }

    private func intervalDescription(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) Minuten"
        } else if minutes == 60 {
            return "eine Stunde"
        } else {
            return "\(minutes / 60) Stunden"
        }
    }
}
