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
        notificationService.requestPermission()
    }

    var body: some Scene {
        WindowGroup("RSSReader") {
            ContentView()
                .environment(fetchService)
                .environment(ruleEngine)
                .environment(refreshManager)
                .onAppear {
                    refreshManager.start(
                        fetchService: fetchService,
                        ruleEngine: ruleEngine,
                        modelContext: modelContainer.mainContext
                    )
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

        Settings {
            SettingsView()
                .environment(refreshManager)
        }
    }
}
