import Foundation
import SwiftData

@Model
final class SmartFolder {
    var name: String
    var sortOrder: Int
    var iconName: String
    var filterUnreadOnly: Bool
    var filterStarredOnly: Bool
    var filterFeedURLs: [String]   // leer = alle Feeds
    var filterKeyword: String      // leer = kein Stichwortfilter
    var createdAt: Date

    init(
        name: String,
        sortOrder: Int = 0,
        iconName: String = "folder.badge.gearshape",
        filterUnreadOnly: Bool = false,
        filterStarredOnly: Bool = false,
        filterFeedURLs: [String] = [],
        filterKeyword: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.sortOrder = sortOrder
        self.iconName = iconName
        self.filterUnreadOnly = filterUnreadOnly
        self.filterStarredOnly = filterStarredOnly
        self.filterFeedURLs = filterFeedURLs
        self.filterKeyword = filterKeyword
        self.createdAt = createdAt
    }
}
