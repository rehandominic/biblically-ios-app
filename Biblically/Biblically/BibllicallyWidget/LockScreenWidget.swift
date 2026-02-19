import WidgetKit
import SwiftUI

// MARK: - Lock Screen Widget (iOS 16+ accessory families)

struct BibllicallyLockScreenWidget: Widget {
    let kind = "BibllicallyLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetTimelineProvider()) { entry in
            LockScreenEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Biblically Lock Screen")
        .description("Bible verse reference on your lock screen.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

// MARK: - Lock Screen Entry Router

struct LockScreenEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: VerseEntry

    var body: some View {
        switch family {
        case .accessoryRectangular: AccessoryRectangularView(entry: entry)
        case .accessoryCircular:    AccessoryCircularView(entry: entry)
        case .accessoryInline:      AccessoryInlineView(entry: entry)
        default:                    AccessoryRectangularView(entry: entry)
        }
    }
}

// MARK: - accessoryRectangular

struct AccessoryRectangularView: View {
    let entry: VerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.verse.text)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .lineLimit(2)
            Text(entry.verse.reference)
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - accessoryCircular

struct AccessoryCircularView: View {
    let entry: VerseEntry

    /// Abbreviated book name for the circular widget (e.g. "Jn 3:16")
    private var shortRef: String {
        let parts = entry.verse.reference.split(separator: " ")
        guard parts.count >= 2 else { return entry.verse.reference }
        let book = abbreviate(String(parts[0]))
        let chapterVerse = parts.dropFirst().joined(separator: " ")
        return "\(book) \(chapterVerse)"
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text(shortRef)
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .padding(4)
        }
    }

    private func abbreviate(_ book: String) -> String {
        let map: [String: String] = [
            "Genesis":"Gn","Exodus":"Ex","Leviticus":"Lv","Numbers":"Nm",
            "Deuteronomy":"Dt","Joshua":"Jos","Judges":"Jgs","Ruth":"Ru",
            "Samuel":"Sm","Kings":"Kgs","Chronicles":"Chr","Ezra":"Ezr",
            "Nehemiah":"Neh","Esther":"Est","Job":"Jb","Psalms":"Ps",
            "Psalm":"Ps","Proverbs":"Prv","Ecclesiastes":"Eccl",
            "Isaiah":"Is","Jeremiah":"Jer","Ezekiel":"Ez","Daniel":"Dn",
            "Hosea":"Hos","Joel":"Jl","Amos":"Am","Micah":"Mi",
            "Habakkuk":"Hb","Zephaniah":"Zep","Zechariah":"Zec","Malachi":"Mal",
            "Matthew":"Mt","Mark":"Mk","Luke":"Lk","John":"Jn","Acts":"Acts",
            "Romans":"Rom","Corinthians":"Cor","Galatians":"Gal",
            "Ephesians":"Eph","Philippians":"Phil","Colossians":"Col",
            "Thessalonians":"Thes","Timothy":"Tm","Titus":"Ti","Hebrews":"Heb",
            "James":"Jas","Peter":"Pt","Revelation":"Rv","Jude":"Jude",
            "Lamentations":"Lam","Nahum":"Na","Song":"Song","Obadiah":"Ob",
            "Jonah":"Jon"
        ]
        return map[book] ?? String(book.prefix(3))
    }
}

// MARK: - accessoryInline

struct AccessoryInlineView: View {
    let entry: VerseEntry

    private var inlineText: String {
        let words = entry.verse.text.split(separator: " ").prefix(6).joined(separator: " ")
        return "\(entry.verse.reference) · \(words)…"
    }

    var body: some View {
        Text(inlineText)
            .lineLimit(1)
    }
}
