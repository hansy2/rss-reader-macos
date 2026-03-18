import Foundation
import SwiftData

@Observable
final class BackgroundRefreshManager {
    var refreshIntervalMinutes: Int = 15 {
        didSet { restart() }
    }

    private var refreshTask: Task<Void, Never>?
    private weak var fetchService: FeedFetchService?
    private weak var ruleEngine: RuleEngine?
    private var modelContext: ModelContext?

    func start(fetchService: FeedFetchService, ruleEngine: RuleEngine, modelContext: ModelContext) {
        self.fetchService = fetchService
        self.ruleEngine = ruleEngine
        self.modelContext = modelContext
        restart()
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func restart() {
        stop()
        guard refreshIntervalMinutes > 0 else { return }

        refreshTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self,
                      let fetchService = self.fetchService,
                      let ruleEngine = self.ruleEngine,
                      let modelContext = self.modelContext else { return }

                await fetchService.fetchAll(modelContext: modelContext, ruleEngine: ruleEngine)

                try? await Task.sleep(for: .seconds(self.refreshIntervalMinutes * 60))
            }
        }
    }
}
