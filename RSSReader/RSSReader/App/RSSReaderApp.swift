import SwiftUI
import SwiftData

@main
struct RSSReaderApp: App {
    @State private var fetchService = FeedFetchService()
    @State private var ruleEngine = RuleEngine()
    @State private var refreshManager = BackgroundRefreshManager()

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
        WindowGroup("RSSReader") {
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
        }
        .modelContainer(modelContainer)
        .commands {
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
        }

        MenuBarExtra("RSSReader", systemImage: "dot.radiowaves.up.forward") {
            MenuBarView()
                .environment(fetchService)
                .environment(ruleEngine)
                .modelContainer(modelContainer)
        }

        Window("Regeln", id: "rules") {
            RulesView()
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 720, height: 520)
        .defaultPosition(.center)

        Settings {
            SettingsView()
                .environment(refreshManager)
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
