import Foundation

/// All shared state between the main app and the widget extension flows through this
/// single manager. Both targets read/write the same App Group UserDefaults suite.
struct SharedDataManager {

    static let appGroupID = "group.com.yourname.biblically"

    private static var defaults: UserDefaults {
        guard let ud = UserDefaults(suiteName: appGroupID) else {
            fatalError("App Group '\(appGroupID)' is not configured. Add the App Groups capability to both targets.")
        }
        return ud
    }

    // MARK: - Current Verse

    static func saveCurrentVerse(_ verse: Verse) {
        guard let data = try? JSONEncoder().encode(verse) else { return }
        defaults.set(data, forKey: Keys.currentVerse)
    }

    static func loadCurrentVerse() -> Verse? {
        guard let data = defaults.data(forKey: Keys.currentVerse) else { return nil }
        return try? JSONDecoder().decode(Verse.self, from: data)
    }

    // MARK: - Next Verse (pre-fetched)

    static func saveNextVerse(_ verse: Verse) {
        guard let data = try? JSONEncoder().encode(verse) else { return }
        defaults.set(data, forKey: Keys.nextVerse)
    }

    static func loadNextVerse() -> Verse? {
        guard let data = defaults.data(forKey: Keys.nextVerse) else { return nil }
        return try? JSONDecoder().decode(Verse.self, from: data)
    }

    // MARK: - Refresh Interval

    /// Saves the interval in hours.
    static func saveInterval(_ hours: Int) {
        defaults.set(hours, forKey: Keys.refreshInterval)
    }

    /// Returns the stored interval in hours, defaulting to 1 if never set.
    static func loadInterval() -> Int {
        let stored = defaults.integer(forKey: Keys.refreshInterval)
        return stored > 0 ? stored : 1
    }

    // MARK: - Theme

    static func saveTheme(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: Keys.selectedTheme)
    }

    static func loadTheme() -> AppTheme {
        guard let raw = defaults.string(forKey: Keys.selectedTheme),
              let theme = AppTheme(rawValue: raw) else { return .light }
        return theme
    }

    // MARK: - Last Verse ID (used to avoid repeats)

    static func saveLastVerseID(_ id: Int) {
        defaults.set(id, forKey: Keys.lastVerseID)
    }

    static func loadLastVerseID() -> Int? {
        let stored = defaults.integer(forKey: Keys.lastVerseID)
        return stored > 0 ? stored : nil
    }

    // MARK: - Private Key Namespace

    private enum Keys {
        static let currentVerse    = "currentVerse"
        static let nextVerse       = "nextVerse"
        static let refreshInterval = "refreshInterval"
        static let selectedTheme   = "selectedTheme"
        static let lastVerseID     = "lastVerseID"
    }
}
