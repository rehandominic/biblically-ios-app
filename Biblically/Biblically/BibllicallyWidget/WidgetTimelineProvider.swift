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

    // Shown while WidgetKit is loading a real snapshot
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

    // Single snapshot for widget gallery previews
    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        let verse = SharedDataManager.loadCurrentVerse() ?? placeholder(in: context).verse
        let theme = SharedDataManager.loadTheme()
        completion(VerseEntry(date: .now, verse: verse, theme: theme))
    }

    // Full timeline for live widget updates
    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let intervalHours   = SharedDataManager.loadInterval()
        let intervalSeconds = TimeInterval(intervalHours * 3_600)
        let theme           = SharedDataManager.loadTheme()

        // Read the pre-computed shared timeline — same array for every widget kind.
        // Anchored to the same startDate so all widgets flip to the next verse in unison.
        let savedVerses = SharedDataManager.loadTimeline()
        let startDate   = SharedDataManager.loadTimelineStartDate() ?? Date()

        var entries: [VerseEntry] = []

        if savedVerses.isEmpty {
            // Fallback: show the current verse until the app generates a proper timeline.
            let verse = SharedDataManager.loadCurrentVerse() ?? placeholder(in: context).verse
            entries.append(VerseEntry(date: startDate, verse: verse, theme: theme))
        } else {
            for (index, verse) in savedVerses.enumerated() {
                let entryDate = startDate.addingTimeInterval(TimeInterval(index) * intervalSeconds)
                entries.append(VerseEntry(date: entryDate, verse: verse, theme: theme))
            }
        }

        // Ask WidgetKit to reload once the last entry has expired.
        let refreshDate = startDate.addingTimeInterval(TimeInterval(savedVerses.count) * intervalSeconds)
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}
