import Foundation
import WidgetKit

/// Manages verse fetching with an online-first, offline-fallback strategy.
///
/// Priority order:
///   1. bible-api.com  — full Bible, ~31,000 verses, requires internet
///   2. verses_kjv.json — 520 bundled verses, always available offline
///
/// Nothing is ever thrown to the UI. Every code path returns a verse.
@MainActor
final class VerseRepository: ObservableObject {

    static let shared = VerseRepository()

    /// The verse currently shown in the app and widgets — always non-nil after init.
    @Published var currentVerse: Verse?

    /// Whether a network fetch is in progress (drives a subtle loading indicator if desired).
    @Published var isFetching = false

    // MARK: - Favorites & Mode

    @Published var favorites: [Verse] = []
    @Published var widgetMode: WidgetMode = .auto
    @Published var useFavoritesOnly: Bool = false
    @Published var pinnedVerse: Verse? = nil

    private(set) var allVerses: [Verse] = []   // bundled fallback pool

    private init() {
        allVerses    = Self.loadBundledVerses()
        favorites    = SharedDataManager.loadFavorites()
        widgetMode   = SharedDataManager.loadWidgetMode()
        useFavoritesOnly = SharedDataManager.loadUseFavoritesOnly()
        pinnedVerse  = SharedDataManager.loadPinnedVerse()

        currentVerse = SharedDataManager.loadCurrentVerse() ?? randomBundledVerse()
        if let v = currentVerse { SharedDataManager.saveCurrentVerse(v) }

        // Generate a timeline on first launch so widgets have something to show.
        if SharedDataManager.loadTimeline().isEmpty {
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

    // MARK: - Favorites

    func isFavorite(_ verse: Verse) -> Bool {
        favorites.contains { $0.id == verse.id }
    }

    func addFavorite(_ verse: Verse) {
        guard !isFavorite(verse) else { return }
        favorites.append(verse)
        SharedDataManager.saveFavorites(favorites)
        generateAndSaveTimeline()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func removeFavorite(_ verse: Verse) {
        favorites.removeAll { $0.id == verse.id }
        SharedDataManager.saveFavorites(favorites)
        // If favorites-only mode is on and pool is now empty, disable it
        if useFavoritesOnly && favorites.isEmpty {
            useFavoritesOnly = false
            SharedDataManager.saveUseFavoritesOnly(false)
        }
        generateAndSaveTimeline()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Widget Mode

    func setWidgetMode(_ mode: WidgetMode) {
        widgetMode = mode
        SharedDataManager.saveWidgetMode(mode)
        generateAndSaveTimeline()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func setUseFavoritesOnly(_ value: Bool) {
        useFavoritesOnly = value
        SharedDataManager.saveUseFavoritesOnly(value)
        generateAndSaveTimeline()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func setPinnedVerse(_ verse: Verse) {
        pinnedVerse = verse
        SharedDataManager.savePinnedVerse(verse)
        generateAndSaveTimeline()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Bundled JSON

    static func loadBundledVerses() -> [Verse] {
        guard let url   = Bundle.main.url(forResource: "verses_kjv", withExtension: "json"),
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
        return await fetchVerseOnlineFor(reference: reference)
    }

    /// Fetches a specific reference (e.g. "John 3:16") from bible-api.com.
    func fetchVerseOnlineFor(reference: String) async -> Verse? {
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
              text: "For God so loved the world, that he gave his only begotten Son, " +
                    "that whosoever believeth in him should not perish, but have everlasting life.")
    }

    // MARK: - Shared Timeline (keeps all widgets in sync)

    /// Generates 12 full Verse objects and saves them to SharedDataManager
    /// so every widget kind builds an identical timeline from the same ordered array.
    @discardableResult
    func generateAndSaveTimeline(count: Int = 12) -> [Verse] {
        var verses: [Verse] = []

        switch widgetMode {

        case .pinned:
            // All slots show the pinned verse so the widget never rotates.
            let pinned = pinnedVerse ?? currentVerse ?? placeholderVerse()
            verses = Array(repeating: pinned, count: count)

        case .auto:
            // Slot 0 = the current verse (may be an online verse or bundled)
            if let current = currentVerse {
                verses.append(current)
            }

            if useFavoritesOnly && !favorites.isEmpty {
                // Rotate through the favorites pool
                var pool = favorites.filter { $0.id != currentVerse?.id }
                while verses.count < count {
                    if pool.isEmpty { pool = favorites }
                    if let pick = pool.randomElement() {
                        pool.removeAll { $0.id == pick.id }
                        verses.append(pick)
                    } else { break }
                }
            } else {
                // Remaining slots = random bundled verses (always available offline)
                var lastID = currentVerse?.id
                while verses.count < count {
                    let pool = allVerses.filter { $0.id != lastID }
                    guard let pick = pool.randomElement() else { break }
                    verses.append(pick)
                    lastID = pick.id
                }
            }
        }

        SharedDataManager.saveTimeline(verses)
        SharedDataManager.saveTimelineStartDate(Date())
        return verses
    }
}
