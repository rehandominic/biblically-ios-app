import Foundation

/// All shared state between the main app and the widget extension flows through this
/// single manager. Both targets read/write the same App Group UserDefaults suite.
struct SharedDataManager {

    static let appGroupID = "group.com.rehandominic.biblically"

    private static var defaults: UserDefaults {
        guard let ud = UserDefaults(suiteName: appGroupID) else {
            fatalError("App Group '\(appGroupID)' is not configured. Add the App Groups capability to both targets.")
        }
        return ud
    }

    // MARK: - Timeline Sequence
    //
    // The app pre-computes an ordered list of verse IDs and saves it here.
    // Every widget kind (home screen AND lock screen) reads this SAME list
    // and builds its WidgetKit timeline from it — so all widgets always
    // display the identical verse at any given moment.

    static func saveTimelineVerseIDs(_ ids: [Int]) {
        defaults.set(ids, forKey: Keys.timelineVerseIDs)
    }

    static func loadTimelineVerseIDs() -> [Int] {
        defaults.array(forKey: Keys.timelineVerseIDs) as? [Int] ?? []
    }

    /// The Date at which slot 0 of the current timeline became active.
    static func saveTimelineStartDate(_ date: Date) {
        defaults.set(date.timeIntervalSince1970, forKey: Keys.timelineStartDate)
    }

    static func loadTimelineStartDate() -> Date? {
        let ti = defaults.double(forKey: Keys.timelineStartDate)
        return ti > 0 ? Date(timeIntervalSince1970: ti) : nil
    }

    // MARK: - Current Verse (always equals the verse at slot 0 of the timeline)

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

    // MARK: - Private Key Namespace

    private enum Keys {
        static let timelineVerseIDs  = "timelineVerseIDs"
        static let timelineStartDate = "timelineStartDate"
        static let currentVerse      = "currentVerse"
        static let refreshInterval   = "refreshInterval"
        static let selectedTheme     = "selectedTheme"
    }
}
