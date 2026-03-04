import Foundation

/// All shared state between the main app and the widget extension.
/// Both targets read/write the same App Group UserDefaults suite so they
/// always agree on which verse is active.
struct SharedDataManager {

    static let appGroupID = "group.com.rehandominic.Biblically"

    private static var defaults: UserDefaults {
        guard let ud = UserDefaults(suiteName: appGroupID) else {
            fatalError("App Group '\(appGroupID)' is not configured. " +
                       "Add the App Groups capability to both targets in Xcode.")
        }
        return ud
    }

    // MARK: - Full Timeline (ordered array of Verse objects)
    //
    // Storing complete Verse objects (not just IDs) means online verses fetched
    // from the API and offline bundled verses are handled identically.
    // Both widget kinds read this same array → always show the same verse.

    static func saveTimeline(_ verses: [Verse]) {
        guard let data = try? JSONEncoder().encode(verses) else { return }
        defaults.set(data, forKey: Keys.timeline)
    }

    static func loadTimeline() -> [Verse] {
        guard let data   = defaults.data(forKey: Keys.timeline),
              let verses = try? JSONDecoder().decode([Verse].self, from: data)
        else { return [] }
        return verses
    }

    /// The Date when slot 0 of the current timeline became active.
    static func saveTimelineStartDate(_ date: Date) {
        defaults.set(date.timeIntervalSince1970, forKey: Keys.timelineStartDate)
    }

    static func loadTimelineStartDate() -> Date? {
        let ti = defaults.double(forKey: Keys.timelineStartDate)
        return ti > 0 ? Date(timeIntervalSince1970: ti) : nil
    }

    // MARK: - Current Verse (always equals timeline slot 0)

    static func saveCurrentVerse(_ verse: Verse) {
        guard let data = try? JSONEncoder().encode(verse) else { return }
        defaults.set(data, forKey: Keys.currentVerse)
    }

    static func loadCurrentVerse() -> Verse? {
        guard let data = defaults.data(forKey: Keys.currentVerse) else { return nil }
        return try? JSONDecoder().decode(Verse.self, from: data)
    }

    // MARK: - Refresh Interval

    static func saveInterval(_ hours: Int) {
        defaults.set(hours, forKey: Keys.refreshInterval)
    }

    static func loadInterval() -> Int {
        let stored = defaults.integer(forKey: Keys.refreshInterval)
        return stored > 0 ? stored : 1
    }

    // MARK: - Theme

    static func saveTheme(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: Keys.selectedTheme)
    }

    static func loadTheme() -> AppTheme {
        guard let raw   = defaults.string(forKey: Keys.selectedTheme),
              let theme = AppTheme(rawValue: raw) else { return .light }
        return theme
    }

    // MARK: - Widget Mode

    static func saveWidgetMode(_ mode: WidgetMode) {
        defaults.set(mode.rawValue, forKey: Keys.widgetMode)
    }

    static func loadWidgetMode() -> WidgetMode {
        guard let raw  = defaults.string(forKey: Keys.widgetMode),
              let mode = WidgetMode(rawValue: raw) else { return .auto }
        return mode
    }

    // MARK: - Pinned Verse

    static func savePinnedVerse(_ verse: Verse) {
        guard let data = try? JSONEncoder().encode(verse) else { return }
        defaults.set(data, forKey: Keys.pinnedVerse)
    }

    static func loadPinnedVerse() -> Verse? {
        guard let data = defaults.data(forKey: Keys.pinnedVerse) else { return nil }
        return try? JSONDecoder().decode(Verse.self, from: data)
    }

    // MARK: - Favorites

    static func saveFavorites(_ verses: [Verse]) {
        guard let data = try? JSONEncoder().encode(verses) else { return }
        defaults.set(data, forKey: Keys.favorites)
    }

    static func loadFavorites() -> [Verse] {
        guard let data   = defaults.data(forKey: Keys.favorites),
              let verses = try? JSONDecoder().decode([Verse].self, from: data)
        else { return [] }
        return verses
    }

    // MARK: - Use Favorites Only

    static func saveUseFavoritesOnly(_ value: Bool) {
        defaults.set(value, forKey: Keys.useFavoritesOnly)
    }

    static func loadUseFavoritesOnly() -> Bool {
        defaults.bool(forKey: Keys.useFavoritesOnly)
    }

    // MARK: - Keys

    private enum Keys {
        static let timeline          = "timeline"
        static let timelineStartDate = "timelineStartDate"
        static let currentVerse      = "currentVerse"
        static let refreshInterval   = "refreshInterval"
        static let selectedTheme     = "selectedTheme"
        static let widgetMode        = "widgetMode"
        static let pinnedVerse       = "pinnedVerse"
        static let favorites         = "favorites"
        static let useFavoritesOnly  = "useFavoritesOnly"
    }
}
