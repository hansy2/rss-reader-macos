import Foundation
import SwiftData

enum SharedModelContainer {
    static func create() throws -> ModelContainer {
        let schema = Schema([
            Feed.self,
            FeedGroup.self,
            FeedItem.self,
            Rule.self,
            SmartFolder.self,
        ])

        let storeURL = AppGroupConfig.containerURL.appending(path: "RSSReader.store")

        let config = ModelConfiguration(
            "RSSReader",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema-Migration fehlgeschlagen (z.B. neues Modell oder neues Feld).
            // Store-Dateien löschen und neu anlegen — Feeds werden beim nächsten
            // Refresh automatisch wieder befüllt.
            let dir = storeURL.deletingLastPathComponent()
            let name = storeURL.lastPathComponent
            if let files = try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil
            ) {
                for file in files where file.lastPathComponent.hasPrefix(name) {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            return try ModelContainer(for: schema, configurations: [config])
        }
    }
}
