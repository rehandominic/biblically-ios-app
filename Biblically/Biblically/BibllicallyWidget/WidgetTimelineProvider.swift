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
        let intervalHours = SharedDataManager.loadInterval()
        let intervalSeconds = TimeInterval(intervalHours * 3_600)
        let theme = SharedDataManager.loadTheme()

        // Load verses directly from the bundle (works offline)
        let allVerses = loadBundledVerses()

        var entries: [VerseEntry] = []
        var entryDate = Date()
        var lastID = SharedDataManager.loadCurrentVerse()?.id

        for i in 0..<12 {
            let pool = allVerses.filter { $0.id != lastID }
            guard let pick = pool.randomElement() else { break }

            // First entry uses the currently stored verse if available
            let verse: Verse
            if i == 0, let current = SharedDataManager.loadCurrentVerse() {
                verse = current
            } else {
                verse = pick
            }

            entries.append(VerseEntry(date: entryDate, verse: verse, theme: theme))
            lastID = verse.id
            entryDate = entryDate.addingTimeInterval(intervalSeconds)
        }

        if entries.isEmpty {
            entries.append(placeholder(in: context))
            entryDate = Date().addingTimeInterval(intervalSeconds)
        }

        let timeline = Timeline(entries: entries, policy: .after(entryDate))
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
