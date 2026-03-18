import Foundation
import SwiftData

enum SharedModelContainer {
    static func create() throws -> ModelContainer {
        let schema = Schema([
            Feed.self,
            FeedGroup.self,
            FeedItem.self,
            Rule.self,
        ])

        let storeURL = AppGroupConfig.containerURL.appending(path: "RSSReader.store")

        let config = ModelConfiguration(
            "RSSReader",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [config])
    }
}
