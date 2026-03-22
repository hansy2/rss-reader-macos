import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct RSSReaderApp: App {
    @State private var fetchService = FeedFetchService()
    @State private var ruleEngine = RuleEngine()
    @State private var refreshManager = BackgroundRefreshManager()
    @State private var showExportSheet = false
    @State private var importPreview: ImportPreview?
    @State private var importData: Data?

    private let notificationService = NotificationService()
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try SharedModelContainer.create()
        } catch {
            fatalError("SwiftData container konnte nicht erstellt werden: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup("RSSReader", id: "main") {
            ContentView()
                .environment(fetchService)
                .environment(ruleEngine)
                .environment(refreshManager)
                .onAppear {
                    notificationService.requestPermission()
                    refreshManager.start(
                        fetchService: fetchService,
                        ruleEngine: ruleEngine,
                        modelContext: modelContainer.mainContext
                    )
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .sheet(isPresented: $showExportSheet) {
                    ExportSheet()
                        .environment(refreshManager)
                        .modelContainer(modelContainer)
                }
                .sheet(item: $importPreview) { preview in
                    if let data = importData {
                        ImportSheet(preview: preview, data: data)
                            .environment(refreshManager)
                            .modelContainer(modelContainer)
                    }
                }
        }
        .modelContainer(modelContainer)
        .commands {
            // About-Fenster überschreiben
            CommandGroup(replacing: .appInfo) {
                Button("Über RSSReader") {
                    openAboutWindow()
                }
            }
            CommandGroup(after: .newItem) {
                Button("Alle Feeds aktualisieren") {
                    Task {
                        await fetchService.fetchAll(
                            modelContext: modelContainer.mainContext,
                            ruleEngine: ruleEngine
                        )
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            CommandGroup(after: .importExport) {
                Button("Backup exportieren…") {
                    showExportSheet = true
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Importieren…") {
                    openImportPanel()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra("RSSReader", systemImage: "dot.radiowaves.up.forward") {
            MenuBarView()
                .environment(fetchService)
                .environment(ruleEngine)
                .modelContainer(modelContainer)
        }
        .menuBarExtraStyle(.window)

        Window("Regeln", id: "rules") {
            RulesView()
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 720, height: 520)
        .defaultPosition(.center)

        Settings {
            SettingsView()
                .environment(refreshManager)
                .modelContainer(modelContainer)
        }
    }

    private func openAboutWindow() {
        let existing = NSApp.windows.first { $0.title == "Über RSSReader" }
        if let w = existing {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = NSHostingController(rootView: AboutView())
        let window = NSWindow(contentViewController: controller)
        window.title = "Über RSSReader"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openImportPanel() {
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
                guard let preview = OPMLService.preview(data: data, fileName: fileName) else { return }
                importData = data
                importPreview = preview
            } else {
                let preview = try BackupService.preview(data: data, fileName: fileName)
                importData = data
                importPreview = preview
            }
        } catch {
            print("Import error: \(error)")
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "rssreader" else { return }

        // Hauptfenster zuerst in den Vordergrund
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
            break
        }

        if url.host == "article",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let guid = components.queryItems?.first(where: { $0.name == "id" })?.value {
            // guid is already decoded by URLComponents
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AppRouter.shared.pendingArticleGUID = guid
            }
        }
    }
}
