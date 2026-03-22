import Foundation
import SwiftUI

enum ReadingTheme: String, CaseIterable {
    case standard = "Standard"
    case sepia    = "Sepia"
    case schwarz  = "Schwarz"

    var icon: String {
        switch self {
        case .standard: return "textformat"
        case .sepia:    return "book"
        case .schwarz:  return "moon.fill"
        }
    }

    var background: String {
        switch self {
        case .standard: return "unset"
        case .sepia:    return "#f4ecd8"
        case .schwarz:  return "#111111"
        }
    }

    var foreground: String {
        switch self {
        case .standard: return "inherit"
        case .sepia:    return "#5c4a1e"
        case .schwarz:  return "#e0e0e0"
        }
    }

    var link: String {
        switch self {
        case .standard: return "-apple-system-blue"
        case .sepia:    return "#8b4513"
        case .schwarz:  return "#6699ff"
        }
    }

    var colorScheme: String {
        switch self {
        case .standard: return "light dark"
        case .sepia:    return "light"
        case .schwarz:  return "dark"
        }
    }
}

@Observable
final class ReadingSettings {
    var fontSize: Int {
        didSet { UserDefaults.standard.set(fontSize, forKey: "readingFontSize") }
    }
    var theme: ReadingTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "readingTheme") }
    }

    init() {
        let savedSize = UserDefaults.standard.integer(forKey: "readingFontSize")
        fontSize = savedSize > 0 ? savedSize : 15
        let savedTheme = UserDefaults.standard.string(forKey: "readingTheme") ?? ""
        theme = ReadingTheme(rawValue: savedTheme) ?? .standard
    }

    static let shared = ReadingSettings()

    func increase() { if fontSize < 26 { fontSize += 1 } }
    func decrease() { if fontSize > 11 { fontSize -= 1 } }
}
