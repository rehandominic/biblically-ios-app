import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: VerseEntry

    var body: some View {
        ZStack {
            entry.theme.backgroundColor

            VStack(alignment: .leading, spacing: 0) {
                Text(entry.verse.text)
                    .font(.custom("Georgia", size: 14))
                    .foregroundStyle(entry.theme.primaryTextColor)
                    .lineLimit(5)
                    .minimumScaleFactor(0.8)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)

                // Decorative rule
                Rectangle()
                    .fill(entry.theme.accentColor.opacity(0.35))
                    .frame(height: 0.75)
                    .padding(.bottom, 6)

                HStack(alignment: .center) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(entry.theme.accentColor.opacity(0.7))

                    Text(entry.verse.reference)
                        .font(.custom("Georgia", size: 12))
                        .italic()
                        .foregroundStyle(entry.theme.secondaryTextColor)

                    Spacer()
                }
            }
            .padding(16)
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
