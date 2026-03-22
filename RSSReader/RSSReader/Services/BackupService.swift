import Foundation
import SwiftData

enum BackupService {

    // MARK: - Export

    @MainActor
    static func export(from context: ModelContext, refreshIntervalMinutes: Int) throws -> Data {
        let groups = try context.fetch(FetchDescriptor<FeedGroup>(sortBy: [SortDescriptor(\.sortOrder)]))
        let feeds  = try context.fetch(FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.title)]))
        let rules  = try context.fetch(FetchDescriptor<Rule>(sortBy: [SortDescriptor(\.name)]))

        let doc = BackupDocument(
            groups: groups.map {
                GroupBackup(name: $0.name, sortOrder: $0.sortOrder, iconName: $0.iconName)
            },
            feeds: feeds.map {
                FeedBackup(
                    title: $0.title,
                    url: $0.url.absoluteString,
                    siteURL: $0.siteURL?.absoluteString,
                    feedDescription: $0.feedDescription,
                    refreshIntervalMinutes: $0.refreshIntervalMinutes,
                    isEnabled: $0.isEnabled,
                    groupName: $0.group?.name
                )
            },
            rules: rules.map {
                RuleBackup(
                    name: $0.name,
                    isEnabled: $0.isEnabled,
                    conditionType: $0.conditionType,
                    conditionValue: $0.conditionValue,
                    conditionField: $0.conditionField,
                    actionType: $0.actionType,
                    actionPayload: $0.actionPayload,
                    scopeFeedURL: $0.scopeFeedURL
                )
            },
            settings: SettingsBackup(refreshIntervalMinutes: refreshIntervalMinutes)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(doc)
    }

    // MARK: - Preview

    static func preview(data: Data, fileName: String) throws -> ImportPreview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let doc = try decoder.decode(BackupDocument.self, from: data)
        return ImportPreview(
            format: .rssBackup,
            fileName: fileName,
            groupCount: doc.groups.count,
            feedCount: doc.feeds.count,
            ruleCount: doc.rules.count
        )
    }

    // MARK: - Import

    @MainActor
    static func importBackup(
        _ data: Data,
        into context: ModelContext,
        strategy: ImportStrategy,
        refreshManager: BackgroundRefreshManager
    ) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let doc = try decoder.decode(BackupDocument.self, from: data)

        if strategy == .replaceAll {
            try context.delete(model: Rule.self)
            try context.delete(model: Feed.self)
            try context.delete(model: FeedGroup.self)
        }

        // Build lookup maps for deduplication
        let existingURLs = Set(
            try context.fetch(FetchDescriptor<Feed>()).map { $0.url.absoluteString }
        )
        let existingGroupList = try context.fetch(FetchDescriptor<FeedGroup>())
        var groupMap = Dictionary(uniqueKeysWithValues: existingGroupList.map { ($0.name, $0) })

        // Insert missing groups
        for g in doc.groups where groupMap[g.name] == nil {
            let group = FeedGroup(name: g.name, sortOrder: g.sortOrder, iconName: g.iconName)
            context.insert(group)
            groupMap[g.name] = group
        }

        // Insert missing feeds
        for f in doc.feeds where !existingURLs.contains(f.url) {
            guard let url = URL(string: f.url) else { continue }
            let feed = Feed(
                title: f.title,
                url: url,
                siteURL: f.siteURL.flatMap(URL.init),
                feedDescription: f.feedDescription,
                refreshIntervalMinutes: f.refreshIntervalMinutes,
                isEnabled: f.isEnabled
            )
            feed.group = f.groupName.flatMap { groupMap[$0] }
            context.insert(feed)
        }

        // Insert rules
        let existingRuleNames: Set<String>
        if strategy == .merge {
            existingRuleNames = Set(try context.fetch(FetchDescriptor<Rule>()).map { $0.name })
        } else {
            existingRuleNames = []
        }
        for r in doc.rules where !existingRuleNames.contains(r.name) {
            context.insert(Rule(
                name: r.name,
                isEnabled: r.isEnabled,
                conditionType: r.conditionType,
                conditionValue: r.conditionValue,
                conditionField: r.conditionField,
                actionType: r.actionType,
                actionPayload: r.actionPayload,
                scopeFeedURL: r.scopeFeedURL
            ))
        }

        // Restore settings
        refreshManager.refreshIntervalMinutes = doc.settings.refreshIntervalMinutes

        try context.save()
    }
}
