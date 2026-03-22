import Foundation
import SwiftData

@Model
final class Feed {
    var title: String
    var url: URL
    var siteURL: URL?
    var feedDescription: String?
    var imageURL: URL?
    var lastFetchedAt: Date?
    var refreshIntervalMinutes: Int
    var isEnabled: Bool
    var fullTextEnabled: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FeedItem.feed)
    var items: [FeedItem] = []

    var group: FeedGroup?

    init(
        title: String,
        url: URL,
        siteURL: URL? = nil,
        feedDescription: String? = nil,
        imageURL: URL? = nil,
        refreshIntervalMinutes: Int = 0,
        isEnabled: Bool = true,
        fullTextEnabled: Bool = false,
        createdAt: Date = .now
    ) {
        self.title = title
        self.url = url
        self.siteURL = siteURL
        self.feedDescription = feedDescription
        self.imageURL = imageURL
        self.refreshIntervalMinutes = refreshIntervalMinutes
        self.isEnabled = isEnabled
        self.fullTextEnabled = fullTextEnabled
        self.createdAt = createdAt
    }

    var unreadCount: Int {
        items.filter { !$0.isRead }.count
    }
}
