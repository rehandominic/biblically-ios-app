import Foundation
import WidgetKit

/// Handles loading verses from the bundled JSON and optionally refreshing from the network.
/// Use `VerseRepository.shared` from the main app. The widget extension reads directly
/// from the bundle + SharedDataManager without going through this class.
@MainActor
final class VerseRepository: ObservableObject {

    static let shared = VerseRepository()

    /// The verse that is active right now — matches exactly what every widget is showing.
    @Published var currentVerse: Verse?

    private(set) var allVerses: [Verse] = []

    private init() {
        allVerses = Self.loadBundledVerses()
        currentVerse = resolveCurrentVerse()

        // First-launch: no timeline saved yet — generate one now.
        if SharedDataManager.loadTimelineVerseIDs().isEmpty {
            generateAndSaveTimeline()
        }
    }

    // MARK: - Public API

    /// Pick a new random verse, rebuild the shared timeline, and reload all widgets.
    func refreshCurrentVerse() {
        generateAndSaveTimeline(excluding: currentVerse?.id)
        currentVerse = resolveCurrentVerse()
        WidgetCenter.shared.reloadAllTimelines()

        if let verse = currentVerse {
            Task { await fetchNetworkVerse(reference: verse.reference) }
        }
    }

    // MARK: - Bundled JSON

    static func loadBundledVerses() -> [Verse] {
        guard let url = Bundle.main.url(forResource: "verses_niv", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let verses = try? JSONDecoder().decode([Verse].self, from: data)
        else { return [] }
        return verses
    }

    // MARK: - Private

    /// Generates 12 verse IDs in random order, saves them to SharedDataManager along
    /// with a start date of `now`, then updates the stored `currentVerse`.
    @discardableResult
    private func generateAndSaveTimeline(excluding excludeID: Int? = nil, count: Int = 12) -> [Int] {
        var ids: [Int] = []
        var lastID = excludeID

        while ids.count < count {
            let pool = allVerses.filter { $0.id != lastID }
            guard let pick = pool.randomElement() else { break }
            ids.append(pick.id)
            lastID = pick.id
        }

        let startDate = Date()
        SharedDataManager.saveTimelineVerseIDs(ids)
        SharedDataManager.saveTimelineStartDate(startDate)

        // Keep currentVerse key in sync with slot 0 for any code that reads it directly.
        if let firstID = ids.first, let verse = allVerses.first(where: { $0.id == firstID }) {
            SharedDataManager.saveCurrentVerse(verse)
        }

        return ids
    }

    /// Computes which verse slot is active right now and returns that verse.
    /// This is what both the app UI and the widgets agree on.
    private func resolveCurrentVerse() -> Verse? {
        let ids = SharedDataManager.loadTimelineVerseIDs()
        guard !ids.isEmpty else { return SharedDataManager.loadCurrentVerse() }

        let startDate  = SharedDataManager.loadTimelineStartDate() ?? Date()
        let interval   = TimeInterval(SharedDataManager.loadInterval() * 3_600)
        let elapsed    = max(0, Date().timeIntervalSince(startDate))
        let slot       = min(Int(elapsed / interval), ids.count - 1)

        return allVerses.first { $0.id == ids[slot] }
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
