import SwiftUI
import WidgetKit

struct ContentView: View {

    @StateObject private var repo = VerseRepository.shared

    @State private var showSettings    = false
    @State private var selectedInterval: Int    = SharedDataManager.loadInterval()
    @State private var selectedTheme:   AppTheme = SharedDataManager.loadTheme()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("Biblically")
                        .font(.custom("Georgia-Bold", size: 30))
                        .foregroundStyle(.black)

                    Text("Built by Rehan Dominic.")
                        .font(.custom("Georgia-Italic", size: 13))
                        .foregroundStyle(Color(white: 0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                Spacer()

                // ── Verse ─────────────────────────────────────────────────
                if let verse = repo.currentVerse {
                    VStack(spacing: 22) {
                        Text(verse.text)
                            .font(.custom("Georgia", size: 21))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                            .lineSpacing(7)

                        Text(verse.reference)
                            .font(.custom("Georgia-Italic", size: 15))
                            .foregroundStyle(Color(white: 0.42))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 36)
                }

                Spacer()
            }

            // ── Floating settings button ───────────────────────────────────
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(Color(white: 0.25))
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 3)
                    )
            }
            .padding(.trailing, 28)
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(
                selectedInterval: $selectedInterval,
                selectedTheme:    $selectedTheme
            )
        }
        .onChange(of: selectedInterval) { _, newValue in
            SharedDataManager.saveInterval(newValue)
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: selectedTheme) { _, newValue in
            SharedDataManager.saveTheme(newValue)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

// MARK: - Settings Sheet

struct SettingsSheet: View {

    @Binding var selectedInterval: Int
    @Binding var selectedTheme:    AppTheme

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var repo = VerseRepository.shared
    @State private var showRefreshConfirmation = false

    private let intervalOptions = [1, 2, 4, 8, 12, 24]

    var body: some View {
        NavigationStack {
            List {
                widgetSettingsSection
                appearanceSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(selectedTheme.backgroundColor.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedTheme.accentColor)
                }
            }
        }
        .tint(selectedTheme.accentColor)
    }

    // MARK: - Sections

    private var widgetSettingsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Refresh Interval")
                    .font(.subheadline)
                    .foregroundStyle(selectedTheme.secondaryTextColor)
                Picker("Interval", selection: $selectedInterval) {
                    ForEach(intervalOptions, id: \.self) { hours in
                        Text(hours == 1 ? "1h" : "\(hours)h").tag(hours)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }
            .listRowBackground(Color.clear)

            Button {
                repo.refreshCurrentVerse()
                showRefreshConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showRefreshConfirmation = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showRefreshConfirmation
                          ? "checkmark.circle.fill"
                          : "arrow.clockwise.circle.fill")
                    Text(showRefreshConfirmation ? "Refreshed!" : "Refresh Widgets Now")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(showRefreshConfirmation ? .green : .white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(showRefreshConfirmation
                              ? Color.green.opacity(0.15)
                              : selectedTheme.accentColor)
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

            if let verse = repo.currentVerse {
                VersePreviewCard(verse: verse, theme: selectedTheme)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
        } header: {
            Text("Widget Settings")
                .foregroundStyle(selectedTheme.secondaryTextColor)
        }
    }

    private var appearanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.subheadline)
                    .foregroundStyle(selectedTheme.secondaryTextColor)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            ThemeSwatch(theme: theme, isSelected: selectedTheme == theme)
                                .onTapGesture { selectedTheme = theme }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.clear)

            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.subheadline)
                    .foregroundStyle(selectedTheme.secondaryTextColor)
                if let verse = repo.currentVerse {
                    MiniMediumPreview(verse: verse, theme: selectedTheme)
                }
            }
            .listRowBackground(Color.clear)
        } header: {
            Text("Appearance")
                .foregroundStyle(selectedTheme.secondaryTextColor)
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(selectedTheme.primaryTextColor)
                Spacer()
                Text(appVersion)
                    .foregroundStyle(selectedTheme.secondaryTextColor)
            }
            .listRowBackground(Color.clear)

            Text("Scripture from the NIV translation.\n© Biblica, Inc. Used by permission.")
                .font(.footnote)
                .foregroundStyle(selectedTheme.secondaryTextColor)
                .listRowBackground(Color.clear)

            Text("Widgets refresh automatically based on your chosen interval.")
                .font(.footnote)
                .foregroundStyle(selectedTheme.secondaryTextColor)
                .listRowBackground(Color.clear)
        } header: {
            Text("About")
                .foregroundStyle(selectedTheme.secondaryTextColor)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Verse Preview Card

struct VersePreviewCard: View {
    let verse: Verse
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currently Showing")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(theme.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(verse.text)
                .font(.custom("Georgia", size: 15))
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(4)

            Divider()
                .overlay(theme.accentColor.opacity(0.3))

            Text(verse.reference)
                .font(.custom("Georgia-Italic", size: 13))
                .foregroundStyle(theme.secondaryTextColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.backgroundColor)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.accentColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Theme Swatch

struct ThemeSwatch: View {
    let theme: AppTheme
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.backgroundColor)
                    .frame(width: 52, height: 52)
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.primaryTextColor.opacity(0.7))
                        .frame(width: 28, height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.secondaryTextColor.opacity(0.5))
                        .frame(width: 20, height: 3)
                }

                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.accentColor, lineWidth: 2.5)
                        .frame(width: 52, height: 52)
                }
            }

            Text(theme.displayName)
                .font(.caption2)
                .foregroundStyle(isSelected ? theme.accentColor : .secondary)
                .lineLimit(1)
                .frame(width: 60)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Mini Medium Widget Preview

struct MiniMediumPreview: View {
    let verse: Verse
    let theme: AppTheme

    var body: some View {
        ContainerRelativeShape()
            .fill(theme.backgroundColor)
            .frame(height: 100)
            .overlay(
                VStack(alignment: .leading, spacing: 6) {
                    Text(verse.text)
                        .font(.custom("Georgia", size: 11))
                        .foregroundStyle(theme.primaryTextColor)
                        .lineLimit(4)
                    Spacer(minLength: 0)
                    Text(verse.reference)
                        .font(.custom("Georgia-Italic", size: 9))
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .padding(10)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}
