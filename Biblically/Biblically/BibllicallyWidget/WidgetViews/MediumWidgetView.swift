import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: VerseEntry

    var body: some View {
        ZStack {
            entry.theme.backgroundColor

            VStack(alignment: .leading, spacing: 0) {
                Text(entry.verse.text)
                    .font(.custom("Georgia", size: 19))
                    .foregroundStyle(entry.theme.primaryTextColor)
                    .lineSpacing(3)
                    .lineLimit(6)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)

                Text(entry.verse.reference)
                    .font(.custom("Georgia-Italic", size: 15))
                    .foregroundStyle(entry.theme.secondaryTextColor)
                    .lineLimit(1)
            }
            .padding(11)
        }
    }
}

#Preview(as: .systemMedium) {
    BibllicallyHomeWidget()
} timeline: {
    VerseEntry(
        date: .now,
        verse: Verse(id: 1, book: "John", chapter: 3, verse: 16,
                     reference: "John 3:16",
                     text: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."),
        theme: .sepia
    )
}
