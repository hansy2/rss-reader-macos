import Foundation

// MARK: - Backup Format v1 (.rssbackup)

struct BackupDocument: Codable {
    let version: Int
    let exportedAt: Date
    let groups: [GroupBackup]
    let feeds: [FeedBackup]
    let rules: [RuleBackup]
    let settings: SettingsBackup

    init(groups: [GroupBackup], feeds: [FeedBackup], rules: [RuleBackup], settings: SettingsBackup) {
        self.version = 1
        self.exportedAt = .now
        self.groups = groups
        self.feeds = feeds
        self.rules = rules
        self.settings = settings
    }
}

struct GroupBackup: Codable {
    let name: String
    let sortOrder: Int
    let iconName: String
}

struct FeedBackup: Codable {
    let title: String
    let url: String
    let siteURL: String?
    let feedDescription: String?
    let refreshIntervalMinutes: Int
    let isEnabled: Bool
    let groupName: String?
}

struct RuleBackup: Codable {
    let name: String
    let isEnabled: Bool
    let conditionType: RuleConditionType
    let conditionValue: String
    let conditionField: RuleConditionField
    let actionType: RuleActionType
    let actionPayload: String?
    let scopeFeedURL: String?
}

struct SettingsBackup: Codable {
    let refreshIntervalMinutes: Int
}

// MARK: - Shared Import Types

enum ImportStrategy: Equatable {
    case merge
    case replaceAll
}

enum ImportFormat {
    case rssBackup
    case opml
}

struct ImportPreview: Identifiable {
    let id = UUID()
    let format: ImportFormat
    let fileName: String
    let groupCount: Int
    let feedCount: Int
    let ruleCount: Int
}
