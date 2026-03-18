import Foundation
import SwiftData

enum RuleConditionType: String, Codable, CaseIterable {
    case titleContains = "Titel enthält"
    case titleMatches = "Titel passt (Regex)"
    case authorEquals = "Autor ist"
    case contentContains = "Inhalt enthält"
    case anyNewArticle = "Jeder neue Artikel"
}

enum RuleConditionField: String, Codable, CaseIterable {
    case title = "Titel"
    case author = "Autor"
    case content = "Inhalt"
    case url = "URL"
}

enum RuleActionType: String, Codable, CaseIterable {
    case notification = "Benachrichtigung"
    case markAsStarred = "Als Favorit markieren"
    case playSound = "Sound abspielen"
    case runShortcut = "Kurzbefehl ausführen"
}

@Model
final class Rule {
    var name: String
    var isEnabled: Bool
    var conditionType: RuleConditionType
    var conditionValue: String
    var conditionField: RuleConditionField
    var actionType: RuleActionType
    var actionPayload: String?
    var createdAt: Date

    var scopeFeedURL: String?

    init(
        name: String,
        isEnabled: Bool = true,
        conditionType: RuleConditionType = .titleContains,
        conditionValue: String = "",
        conditionField: RuleConditionField = .title,
        actionType: RuleActionType = .notification,
        actionPayload: String? = nil,
        scopeFeedURL: String? = nil,
        createdAt: Date = .now
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.conditionType = conditionType
        self.conditionValue = conditionValue
        self.conditionField = conditionField
        self.actionType = actionType
        self.actionPayload = actionPayload
        self.scopeFeedURL = scopeFeedURL
        self.createdAt = createdAt
    }
}
