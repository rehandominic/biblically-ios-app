# Biblically — Xcode Setup Guide

All source files are written. Follow these steps to wire them into Xcode.

---

## 1. Create the Xcode Project

1. Open Xcode → **File › New › Project**
2. Choose **iOS › App**
3. Set:
   - **Product Name**: `Biblically`
   - **Bundle Identifier**: `com.yourname.biblically`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployment**: iOS 16.0 (needed for lock screen widgets)
4. Save the project **inside** this folder so the generated `.xcodeproj` sits alongside `Biblically/` and `BibllicallyWidget/`.

---

## 2. Add Source Files to the Main App Target

Drag the following into the Xcode navigator under the **Biblically** group, making sure **"Add to target: Biblically"** is checked:

```
Biblically/BibllicallyApp.swift
Biblically/ContentView.swift
Biblically/Models/Verse.swift
Biblically/Models/AppTheme.swift
Biblically/Data/VerseRepository.swift
Biblically/Data/verses_niv.json
Biblically/Shared/SharedDataManager.swift
```

---

## 3. Add the Widget Extension Target

1. **File › New › Target**
2. Choose **Widget Extension**
3. Set:
   - **Product Name**: `BibllicallyWidget`
   - **Bundle Identifier**: `com.yourname.biblically.widget`
   - **Include Configuration Intent**: **No** (leave unchecked)
4. Xcode will create a default widget file — **delete it** (or replace it with the files below).

---

## 4. Add Source Files to the Widget Target

Drag these into the **BibllicallyWidget** group, checking **"Add to target: BibllicallyWidget"**:

```
BibllicallyWidget/BibllicallyWidgetBundle.swift
BibllicallyWidget/HomeWidgets.swift
BibllicallyWidget/LockScreenWidget.swift
BibllicallyWidget/WidgetTimelineProvider.swift
BibllicallyWidget/WidgetViews/SmallWidgetView.swift
BibllicallyWidget/WidgetViews/MediumWidgetView.swift
BibllicallyWidget/WidgetViews/LargeWidgetView.swift
```

### Shared files — add to BOTH targets

Select each of these files in the Xcode navigator, open the **File Inspector** (right panel), and under **Target Membership** check **both** Biblically and BibllicallyWidget:

```
Biblically/Models/Verse.swift
Biblically/Models/AppTheme.swift
Biblically/Shared/SharedDataManager.swift
Biblically/Data/verses_niv.json
```

> **Why?** The widget extension is a separate process. It needs its own copies of the model types and shared data manager, and must be able to read the JSON bundle directly (for offline timelines).

---

## 5. Configure App Groups

App Groups let the main app and the widget extension share the same `UserDefaults`.

### Main App target
1. Select the **Biblically** target → **Signing & Capabilities**
2. Click **+ Capability** → add **App Groups**
3. Add group: `group.com.yourname.biblically`

### Widget Extension target
1. Select the **BibllicallyWidget** target → **Signing & Capabilities**
2. Click **+ Capability** → add **App Groups**
3. Add the **same** group: `group.com.yourname.biblically`

> Both targets must be in the same App Group or `SharedDataManager` will not work.

---

## 6. Add the Network Permission (for online verse fetching)

In `Biblically/Info.plist` add:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>bible-api.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

The app already uses HTTPS so this is optional — but some App Store reviewers expect an explicit entry.

---

## 7. Set Deployment Target

Set **iOS Deployment Target to 16.0** on both targets (lock screen widgets require iOS 16).

- Select each target → **Build Settings** → search `IPHONEOS_DEPLOYMENT_TARGET` → set `16.0`

---

## 8. Build and Test

1. Build with **⌘B** — resolve any "file not found" errors by verifying target membership (step 4).
2. Run on a **real device** (widgets don't appear in the simulator widget picker reliably).
3. Long-press the home screen → tap **+** → search **Biblically** → verify all four widget sizes appear.
4. Go to the lock screen → long-press → **Customize** → verify the three lock screen accessory types appear.
5. Enable **Airplane Mode**, reboot, confirm widgets still show a verse (offline test).
6. Open the app, change the interval, tap **Refresh Widgets Now** — widget should update within seconds.

---

## Project Structure Reference

```
biblically-app/
├── Biblically/
│   ├── BibllicallyApp.swift          ← App entry point
│   ├── ContentView.swift             ← Settings UI
│   ├── Models/
│   │   ├── Verse.swift               ← Shared with widget ✓
│   │   └── AppTheme.swift            ← Shared with widget ✓
│   ├── Data/
│   │   ├── verses_niv.json           ← Shared with widget ✓
│   │   └── VerseRepository.swift     ← Main-app only
│   └── Shared/
│       └── SharedDataManager.swift   ← Shared with widget ✓
│
├── BibllicallyWidget/
│   ├── BibllicallyWidgetBundle.swift
│   ├── HomeWidgets.swift
│   ├── LockScreenWidget.swift
│   ├── WidgetTimelineProvider.swift
│   └── WidgetViews/
│       ├── SmallWidgetView.swift
│       ├── MediumWidgetView.swift
│       └── LargeWidgetView.swift
│
└── SETUP.md                          ← This file
```

---

## Acceptance Checklist

- [ ] All 4 home screen widget sizes appear in the widget picker
- [ ] All 3 lock screen accessory types appear in the lock screen customiser
- [ ] Widgets display a verse in Airplane Mode on first install
- [ ] Changing the interval and tapping "Refresh Now" visibly updates the widget
- [ ] Changing the theme in settings updates all widgets within one reload cycle
- [ ] App compiles with zero errors and zero warnings on Xcode 15+ / iOS 16+ SDK

---

## Notes on NIV Copyright

The bundled verses in `verses_niv.json` are from the New International Version.
The NIV text is copyright © Biblica, Inc. For App Store distribution you should
obtain a license from Biblica (biblica.com) or switch to a public-domain
translation (e.g. KJV, ASV, WEB). The online fetch via `bible-api.com` uses
the NIVUK edition under that service's terms of use.
