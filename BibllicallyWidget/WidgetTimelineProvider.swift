import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct VerseEntry: TimelineEntry {
    let date: Date
    let verse: Verse
    let theme: AppTheme
}

// MARK: - Timeline Provider

struct WidgetTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(
            date: .now,
            verse: Verse(
                id: 0,
                book: "John",
                chapter: 3,
                verse: 16,
                reference: "John 3:16",
                text: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."
            ),
            theme: .light
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        let verse = SharedDataManager.loadCurrentVerse() ?? placeholder(in: context).verse
        let theme = SharedDataManager.loadTheme()
        completion(VerseEntry(date: .now, verse: verse, theme: theme))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let theme         = SharedDataManager.loadTheme()
        let intervalHours = SharedDataManager.loadInterval()
        let intervalSecs  = TimeInterval(intervalHours * 3_600)

        // ── Read the single shared sequence ───────────────────────────────────
        // Both BibllicallyHomeWidget and BibllicallyLockScreenWidget call this
        // same provider. Because they both read the same saved IDs and the same
        // saved start date, they build identical timelines — every widget kind
        // will always show the same verse at the same time.
        let savedIDs   = SharedDataManager.loadTimelineVerseIDs()
        let startDate  = SharedDataManager.loadTimelineStartDate() ?? Date()
        let allVerses  = loadBundledVerses()
        let lookup     = Dictionary(uniqueKeysWithValues: allVerses.map { ($0.id, $0) })

        var entries: [VerseEntry] = []

        if !savedIDs.isEmpty {
            for (i, id) in savedIDs.enumerated() {
                guard let verse = lookup[id] else { continue }
                let entryDate = startDate.addingTimeInterval(TimeInterval(i) * intervalSecs)
                entries.append(VerseEntry(date: entryDate, verse: verse, theme: theme))
            }
        }

        // Fallback — should only happen on first install before the app has
        // been opened. Build a one-shot timeline from whatever is in UserDefaults.
        if entries.isEmpty {
            let fallback = SharedDataManager.loadCurrentVerse() ?? placeholder(in: context).verse
            entries.append(VerseEntry(date: .now, verse: fallback, theme: theme))
        }

        // Ask WidgetKit to refresh after the last entry expires.
        let nextRefresh = (entries.last?.date ?? .now).addingTimeInterval(intervalSecs)
        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
        completion(timeline)
    }

    // MARK: - Private

    private func loadBundledVerses() -> [Verse] {
        guard let url = Bundle.main.url(forResource: "verses_niv", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let verses = try? JSONDecoder().decode([Verse].self, from: data)
        else { return [] }
        return verses
    }
}
