import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: VerseEntry

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            entry.theme.backgroundColor

            // Watermark book name (faint large text behind the verse)
            Text(entry.verse.book.uppercased())
                .font(.system(size: 72, weight: .black, design: .serif))
                .foregroundStyle(entry.theme.primaryTextColor.opacity(0.04))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .offset(y: 10)

            // Verse content
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                Text(entry.verse.text)
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(entry.theme.primaryTextColor)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 20)

                // Divider
                Rectangle()
                    .fill(entry.theme.accentColor.opacity(0.35))
                    .frame(height: 0.75)
                    .padding(.bottom, 10)

                HStack {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(entry.theme.accentColor.opacity(0.7))

                    Text(entry.verse.reference)
                        .font(.custom("Georgia", size: 14))
                        .italic()
                        .foregroundStyle(entry.theme.secondaryTextColor)

                    Spacer()
                }

                Spacer(minLength: 0)
            }
            .padding(20)
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
