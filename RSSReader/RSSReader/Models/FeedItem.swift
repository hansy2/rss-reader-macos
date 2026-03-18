import Foundation
import SwiftData

@Model
final class FeedItem {
    @Attribute(.unique) var guid: String
    var title: String
    var itemDescription: String?
    @Attribute(.externalStorage) var contentHTML: String?
    var url: URL?
    var imageURL: URL?
    var author: String?
    var publishedAt: Date?
    var isRead: Bool
    var isStarred: Bool
    var fetchedAt: Date

    var feed: Feed?

    init(
        guid: String,
        title: String,
        itemDescription: String? = nil,
        contentHTML: String? = nil,
        url: URL? = nil,
        imageURL: URL? = nil,
        author: String? = nil,
        publishedAt: Date? = nil,
        isRead: Bool = false,
        isStarred: Bool = false,
        fetchedAt: Date = .now
    ) {
        self.guid = guid
        self.title = title
        self.itemDescription = itemDescription
        self.contentHTML = contentHTML
        self.url = url
        self.imageURL = imageURL
        self.author = author
        self.publishedAt = publishedAt
        self.isRead = isRead
        self.isStarred = isStarred
        self.fetchedAt = fetchedAt
    }
}
