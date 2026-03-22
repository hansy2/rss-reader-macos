import Foundation

enum AppGroupConfig {
    /// "DCF47747Q6." – wird zur Laufzeit aus der Info.plist gelesen
    private static var teamPrefix: String {
        Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String ?? ""
    }

    static var appGroupID: String {
        "\(teamPrefix)group.com.rssreader.shared"
    }

    static var containerURL: URL {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }
}
