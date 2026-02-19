import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: VerseEntry

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            entry.theme.backgroundColor

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Spacer(minLength: 0)

                Text(entry.verse.text)
                    .font(.custom("Georgia", size: 13))
                    .foregroundStyle(entry.theme.primaryTextColor)
                    .lineLimit(5)
                    .minimumScaleFactor(0.8)
                    .lineSpacing(2)

                Spacer(minLength: 4)

                Text(entry.verse.reference)
                    .font(.custom("Georgia", size: 11))
                    .italic()
                    .foregroundStyle(entry.theme.secondaryTextColor)
                    .lineLimit(1)
            }
            .padding(14)

            // Corner icon
            Image(systemName: "book.closed.fill")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(entry.theme.accentColor.opacity(0.6))
                .padding(10)
        }
    }
}

#Preview(as: .systemSmall) {
    BibllicallyHomeWidget()
} timeline: {
    VerseEntry(
        date: .now,
        verse: Verse(id: 1, book: "John", chapter: 3, verse: 16,
                     reference: "John 3:16",
                     text: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."),
        theme: .light
    )
}
