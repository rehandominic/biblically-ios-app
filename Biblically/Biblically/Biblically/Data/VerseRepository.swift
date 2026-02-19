import Foundation
import WidgetKit

/// Handles loading verses from the bundled JSON and optionally refreshing from the network.
/// Use `VerseRepository.shared` from the main app. The widget extension reads directly
/// from the bundle + SharedDataManager without going through this class.
@MainActor
final class VerseRepository: ObservableObject {

    static let shared = VerseRepository()

    @Published var currentVerse: Verse?

    private(set) var allVerses: [Verse] = []

    private init() {
        allVerses = Self.loadBundledVerses()

        if let cached = SharedDataManager.loadCurrentVerse() {
            currentVerse = cached
        } else {
            pickAndSaveRandom()
        }
    }

    // MARK: - Public API

    func refreshCurrentVerse() {
        let old = currentVerse?.id
        pickAndSaveRandom(excluding: old)
        WidgetCenter.shared.reloadAllTimelines()

        // Silently fetch a network verse in the background
        if let verse = currentVerse {
            Task { await fetchNetworkVerse(reference: verse.reference) }
        }
    }

    /// Returns `count` random verses suitable for building a widget timeline.
    func versesForTimeline(count: Int) -> [Verse] {
        var results: [Verse] = []
        var lastID: Int? = SharedDataManager.loadLastVerseID()
        for _ in 0..<count {
            let pool = allVerses.filter { $0.id != lastID }
            if let pick = pool.randomElement() {
                results.append(pick)
                lastID = pick.id
            }
        }
        return results
    }

    // MARK: - Bundled JSON

    static func loadBundledVerses() -> [Verse] {
        guard let url = Bundle.main.url(forResource: "verses_niv", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let verses = try? JSONDecoder().decode([Verse].self, from: data)
        else { return [] }
        return verses
    }

    // MARK: - Private Helpers

    private func pickAndSaveRandom(excluding excludeID: Int? = nil) {
        let pool = allVerses.filter { $0.id != excludeID }
        guard let pick = pool.randomElement() else { return }
        currentVerse = pick
        SharedDataManager.saveCurrentVerse(pick)
        SharedDataManager.saveLastVerseID(pick.id)

        // Pre-save a next verse too
        let next = allVerses.filter { $0.id != pick.id }.randomElement()
        if let next { SharedDataManager.saveNextVerse(next) }
    }

    private func fetchNetworkVerse(reference: String) async {
        let encoded = reference
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? reference
        let urlString = "https://bible-api.com/\(encoded)?translation=nivuk"
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String,
               let ref  = json["reference"] as? String,
               let base = currentVerse {

                let updated = Verse(
                    id: base.id,
                    book: base.book,
                    chapter: base.chapter,
                    verse: base.verse,
                    reference: ref.trimmingCharacters(in: .whitespacesAndNewlines),
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                currentVerse = updated
                SharedDataManager.saveCurrentVerse(updated)
            }
        } catch {
            // Network unavailable — silently use cached verse
        }
    }
}
