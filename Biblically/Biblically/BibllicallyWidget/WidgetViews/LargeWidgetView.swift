import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: VerseEntry

    var body: some View {
        ZStack {
            entry.theme.backgroundColor

            VStack(alignment: .leading, spacing: 0) {
                Text(entry.verse.text)
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(entry.theme.primaryTextColor)
                    .lineSpacing(5)
                    .lineLimit(12)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 20)

                Text(entry.verse.reference)
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundStyle(entry.theme.secondaryTextColor)
                    .lineLimit(1)
            }
            .padding(11)
        }
    }
}

#Preview(as: .systemLarge) {
    BibllicallyHomeWidget()
} timeline: {
    VerseEntry(
        date: .now,
        verse: Verse(id: 7, book: "Isaiah", chapter: 40, verse: 31,
                     reference: "Isaiah 40:31",
                     text: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint."),
        theme: .midnightBlue
    )
}
