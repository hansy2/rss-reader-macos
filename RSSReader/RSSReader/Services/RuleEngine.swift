import Foundation
import AppKit

@Observable
final class RuleEngine {
    private let notificationService = NotificationService()

    func evaluate(newItems: [FeedItem], rules: [Rule]) {
        for item in newItems {
            for rule in rules where rule.isEnabled {
                if matches(item: item, rule: rule) {
                    execute(rule: rule, item: item)
                }
            }
        }
    }

    private func matches(item: FeedItem, rule: Rule) -> Bool {
        // Feed-Scope prüfen
        if let scopeURL = rule.scopeFeedURL,
           let feedURL = item.feed?.url.absoluteString,
           scopeURL != feedURL {
            return false
        }

        switch rule.conditionType {
        case .anyNewArticle:
            return true

        case .titleContains:
            return item.title.localizedCaseInsensitiveContains(rule.conditionValue)

        case .titleMatches:
            guard let regex = try? NSRegularExpression(pattern: rule.conditionValue, options: .caseInsensitive) else {
                return false
            }
            let range = NSRange(item.title.startIndex..., in: item.title)
            return regex.firstMatch(in: item.title, range: range) != nil

        case .authorEquals:
            return item.author?.localizedCaseInsensitiveCompare(rule.conditionValue) == .orderedSame

        case .contentContains:
            let text: String
            switch rule.conditionField {
            case .title:
                text = item.title
            case .author:
                text = item.author ?? ""
            case .content:
                text = item.itemDescription ?? item.contentHTML ?? ""
            case .url:
                text = item.url?.absoluteString ?? ""
            }
            return text.localizedCaseInsensitiveContains(rule.conditionValue)
        }
    }

    private func execute(rule: Rule, item: FeedItem) {
        switch rule.actionType {
        case .notification:
            let body = rule.actionPayload ?? item.title
            notificationService.send(
                title: "Regel: \(rule.name)",
                body: body,
                feedTitle: item.feed?.title
            )

        case .markAsStarred:
            item.isStarred = true

        case .playSound:
            let soundName = rule.actionPayload ?? "Basso"
            if let sound = NSSound(named: NSSound.Name(soundName)) {
                sound.play()
            } else {
                NSSound.beep()
            }

        case .runShortcut:
            if let shortcutName = rule.actionPayload,
               let url = URL(string: "shortcuts://run-shortcut?name=\(shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
