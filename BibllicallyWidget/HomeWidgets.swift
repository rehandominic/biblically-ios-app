import WidgetKit
import SwiftUI

// MARK: - Single Home Screen Widget that covers small / medium / large

struct BibllicallyHomeWidget: Widget {
    let kind = "BibllicallyHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetTimelineProvider()) { entry in
            HomeWidgetEntryView(entry: entry)
                .containerBackground(entry.theme.backgroundColor, for: .widget)
        }
        .configurationDisplayName("Biblically")
        .description("Daily Bible verses on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Entry Router

struct HomeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: VerseEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        case .systemLarge:  LargeWidgetView(entry: entry)
        default:            MediumWidgetView(entry: entry)
        }
    }
}
