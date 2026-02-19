import Foundation
import WidgetKit

/// Manages verse fetching with an online-first, offline-fallback strategy.
///
/// Priority order:
///   1. bible-api.com  — full Bible, ~31,000 verses, requires internet
///   2. verses_niv.json — 520 bundled verses, always available offline
///
/// Nothing is ever thrown to the UI. Every code path returns a verse.
@MainActor
final class VerseRepository: ObservableObject {

    static let shared = VerseRepository()

    /// The verse currently shown in the app and widgets — always non-nil after init.
    @Published var currentVerse: Verse?

    /// Whether a network fetch is in progress (drives a subtle loading indicator if desired).
    @Published var isFetching = false

    private(set) var allVerses: [Verse] = []   // bundled fallback pool

    private init() {
        allVerses = Self.loadBundledVerses()
        currentVerse = SharedDataManager.loadCurrentVerse() ?? randomBundledVerse()
        if let v = currentVerse { SharedDataManager.saveCurrentVerse(v) }

        // Generate a timeline on first launch so widgets have something to show.
        if SharedDataManager.loadTimelineVerseIDs().isEmpty {
            generateAndSaveTimeline()
        }
    }

    // MARK: - Public API

    /// Fetch a fresh verse and rebuild the widget timeline.
    /// Tries the internet first; falls back to the bundled JSON silently.
    func refreshCurrentVerse() {
        guard !isFetching else { return }
        isFetching = true

        Task {
            let verse = await fetchVerseOnline() ?? randomBundledVerse()
            currentVerse = verse
            SharedDataManager.saveCurrentVerse(verse)
            generateAndSaveTimeline()
            WidgetCenter.shared.reloadAllTimelines()
            isFetching = false
        }
    }

    // MARK: - Bundled JSON

    static func loadBundledVerses() -> [Verse] {
        guard let url   = Bundle.main.url(forResource: "verses_niv", withExtension: "json"),
              let data  = try? Data(contentsOf: url),
              let list  = try? JSONDecoder().decode([Verse].self, from: data)
        else { return [] }
        return list
    }

    // MARK: - Network Fetch (online source)

    /// Picks a random reference from all 31,000+ Bible verses, fetches its text
    /// from bible-api.com, and returns a `Verse`. Returns `nil` on any failure.
    private func fetchVerseOnline() async -> Verse? {
        let reference = BibleIndex.randomReference()
        let encoded   = reference.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
                        ?? reference
        let urlString = "https://bible-api.com/\(encoded)?translation=kjv"

        guard let url = URL(string: urlString) else { return nil }

        // Short timeout — users shouldn't wait more than 6 s for a verse.
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 6
        config.timeoutIntervalForResource = 6
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(from: url)

            // Treat any non-200 as a failure (e.g. invalid verse reference).
            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else { return nil }

            guard let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text    = json["text"]      as? String,
                  let ref     = json["reference"] as? String,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }

            // Parse "Book Chapter:Verse" from the reference string.
            let (book, chapter, verse) = parseReference(ref)

            return Verse(
                id:        Int.random(in: 100_000...999_999), // unique ID for online verses
                book:      book,
                chapter:   chapter,
                verse:     verse,
                reference: ref.trimmingCharacters(in: .whitespacesAndNewlines),
                text:      text.trimmingCharacters(in: .whitespacesAndNewlines)
            )

        } catch {
            // Network unavailable, timeout, or any other error → return nil,
            // caller falls back to bundled JSON automatically.
            return nil
        }
    }

    /// Parses "Romans 8:28" → ("Romans", 8, 28). Returns ("", 0, 0) on failure.
    private func parseReference(_ ref: String) -> (String, Int, Int) {
        // Reference format: "Book Name Chapter:Verse"
        // e.g. "1 Corinthians 13:4" or "John 3:16"
        let parts = ref.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
        guard parts.count == 2,
              let verseNum = Int(parts[1].trimmingCharacters(in: .whitespaces))
        else { return ("", 0, 0) }

        let left       = parts[0].components(separatedBy: " ")
        guard left.count >= 2,
              let chapterNum = Int(left.last ?? "")
        else { return ("", 0, 0) }

        let bookName = left.dropLast().joined(separator: " ")
        return (bookName, chapterNum, verseNum)
    }

    // MARK: - Bundled Fallback

    private func randomBundledVerse(excluding excludeID: Int? = nil) -> Verse {
        let pool = allVerses.filter { $0.id != excludeID }
        return pool.randomElement() ?? allVerses.first ?? placeholderVerse()
    }

    private func placeholderVerse() -> Verse {
        Verse(id: 1, book: "John", chapter: 3, verse: 16,
              reference: "John 3:16",
              text: "For God so loved the world that he gave his one and only Son, " +
                    "that whoever believes in him shall not perish but have eternal life.")
    }

    // MARK: - Shared Timeline (keeps all widgets in sync)

    /// Generates 12 verse references, saves their IDs/references to SharedDataManager
    /// so every widget kind builds an identical timeline from the same data.
    @discardableResult
    func generateAndSaveTimeline(count: Int = 12) -> [Int] {
        var ids: [Int] = []

        // Slot 0 = the current verse
        if let current = currentVerse {
            ids.append(current.id)
        }

        // Remaining slots = random bundled verses (always available offline)
        var lastID = currentVerse?.id
        while ids.count < count {
            let pool = allVerses.filter { $0.id != lastID }
            guard let pick = pool.randomElement() else { break }
            ids.append(pick.id)
            lastID = pick.id
        }

        SharedDataManager.saveTimelineVerseIDs(ids)
        SharedDataManager.saveTimelineStartDate(Date())
        return ids
    }
}
