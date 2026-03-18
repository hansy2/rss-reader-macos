import Foundation
import SwiftData

@Model
final class FeedGroup {
    var name: String
    var sortOrder: Int
    var iconName: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Feed.group)
    var feeds: [Feed] = []

    init(name: String, sortOrder: Int = 0, iconName: String = "folder", createdAt: Date = .now) {
        self.name = name
        self.sortOrder = sortOrder
        self.iconName = iconName
        self.createdAt = createdAt
    }
}
