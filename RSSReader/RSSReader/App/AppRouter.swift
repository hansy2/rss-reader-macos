import Foundation

/// Globaler Router für Deep Links (z.B. Widget → Artikel öffnen)
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()
    private init() {}

    /// GUID des Artikels der geöffnet werden soll
    var pendingArticleGUID: String?
}
