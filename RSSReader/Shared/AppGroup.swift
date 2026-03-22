import Foundation

enum AppGroupConfig {
    static let appGroupID = "DCF47747Q6.group.com.rssreader.shared"

    static var containerURL: URL {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }
}
