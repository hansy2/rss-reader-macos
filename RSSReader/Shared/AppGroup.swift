import Foundation

enum AppGroupConfig {
    static let appGroupID = "group.com.rssreader.shared"

    static var containerURL: URL {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }
}
