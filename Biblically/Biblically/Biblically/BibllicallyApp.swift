import SwiftUI
import WidgetKit

@main
struct BibllicallyApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Write a default interval if this is the first launch
                    if SharedDataManager.loadInterval() == 0 {
                        SharedDataManager.saveInterval(1)
                    }
                    // Seed the current verse if none is stored yet
                    if SharedDataManager.loadCurrentVerse() == nil {
                        let verses = VerseRepository.loadBundledVerses()
                        if let verse = verses.randomElement() {
                            SharedDataManager.saveCurrentVerse(verse)
                        }
                    }
                    // Sync the home screen with whatever the widget is showing
                    VerseRepository.shared.syncCurrentVerseWithWidget()
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}
