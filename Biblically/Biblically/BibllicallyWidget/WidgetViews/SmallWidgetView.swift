import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: VerseEntry

    var body: some View {
        ZStack {
            entry.theme.backgroundColor

            VStack(alignment: .leading, spacing: 0) {
                Text(entry.verse.text)
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(entry.theme.primaryTextColor)
                    .lineSpacing(2)
                    .lineLimit(6)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 6)

                Text(entry.verse.reference)
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundStyle(entry.theme.secondaryTextColor)
                    .lineLimit(1)
            }
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
