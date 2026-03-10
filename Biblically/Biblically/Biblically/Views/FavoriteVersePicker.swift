import SwiftUI

/// Sheet that lets the user pick any verse from the full Bible and add it to their Favorites.
/// Uses the same Book → Chapter → Verse → Preview flow as VersePicker.
struct FavoriteVersePicker: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var repo: VerseRepository
    let theme: AppTheme

    @State private var selectedBookIndex: Int = 0
    @State private var selectedChapter:   Int = 1
    @State private var selectedVerse:     Int = 1

    @State private var previewedVerse: Verse? = nil
    @State private var isFetching:     Bool   = false
    @State private var fetchError:     Bool   = false

    private var bookNames: [String] { BibleIndex.allBookNames }

    var body: some View {
        NavigationStack {
            List {
                pickersSection
                if isFetching { fetchingRow }
                if fetchError  { errorRow }
                if let verse = previewedVerse { previewSection(verse) }
            }
            .scrollContentBackground(.hidden)
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Add to Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(theme.accentColor)
                }
            }
            .tint(theme.accentColor)
        }
        .onChange(of: selectedBookIndex) { _, _ in resetChapterAndVerse() }
        .onChange(of: selectedChapter)   { _, _ in clampVerse() }
    }

    // MARK: - Sections

    private var pickersSection: some View {
        Section {
            Picker("Book", selection: $selectedBookIndex) {
                ForEach(bookNames.indices, id: \.self) { i in
                    Text(bookNames[i]).tag(i)
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(theme.primaryTextColor)

            Picker("Chapter", selection: $selectedChapter) {
                ForEach(1...BibleIndex.chapterCount(for: selectedBookIndex), id: \.self) { ch in
                    Text("\(ch)").tag(ch)
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(theme.primaryTextColor)

            Picker("Verse", selection: $selectedVerse) {
                ForEach(1...BibleIndex.verseCount(for: selectedBookIndex, chapter: selectedChapter), id: \.self) { v in
                    Text("\(v)").tag(v)
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(theme.primaryTextColor)

            Button {
                fetchPreview()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "eye.circle.fill")
                    Text("Preview Verse")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.accentColor)
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .disabled(isFetching)
        } header: {
            Text("Select Reference")
                .foregroundStyle(theme.secondaryTextColor)
        }
        .listRowBackground(Color.clear)
    }

    private var fetchingRow: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(theme.accentColor)
            Text("Fetching verse…")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
            Spacer()
        }
        .listRowBackground(Color.clear)
        .padding(.vertical, 8)
    }

    private var errorRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("Verse unavailable offline. Try another or check your connection.")
                .font(.subheadline)
        }
        .foregroundStyle(.orange)
        .listRowBackground(Color.clear)
    }

    private func previewSection(_ verse: Verse) -> some View {
        let alreadyFavorited = repo.isFavorite(verse)
        return Section {
            FavoriteVerseCard(verse: verse, theme: theme)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            Button {
                repo.addFavorite(verse)
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: alreadyFavorited ? "heart.fill" : "heart.circle.fill")
                    Text(alreadyFavorited ? "Already in Favorites" : "Add to Favorites")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(alreadyFavorited ? Color.gray : theme.accentColor)
                )
            }
            .disabled(alreadyFavorited)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("Preview")
                .foregroundStyle(theme.secondaryTextColor)
        }
    }

    // MARK: - Actions

    private func fetchPreview() {
        isFetching     = true
        fetchError     = false
        previewedVerse = nil

        let bookName  = bookNames[selectedBookIndex]
        let reference = "\(bookName) \(selectedChapter):\(selectedVerse)"

        Task {
            if let verse = await repo.fetchVerseOnlineFor(reference: reference) {
                previewedVerse = verse
            } else {
                fetchError = true
            }
            isFetching = false
        }
    }

    private func resetChapterAndVerse() {
        selectedChapter = 1
        selectedVerse   = 1
        previewedVerse  = nil
        fetchError      = false
    }

    private func clampVerse() {
        let maxVerse = BibleIndex.verseCount(for: selectedBookIndex, chapter: selectedChapter)
        if selectedVerse > maxVerse { selectedVerse = maxVerse }
        previewedVerse = nil
        fetchError     = false
    }
}
