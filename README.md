# Quran Chapter Player

A minimalist Flutter audio player for building a personal rotation of Quran chapters. Designed for one-tap playback — open it, pick your chapters, press play, done.

---

## Table of Contents

1. [What This App Does](#what-this-app-does)
2. [Prerequisites](#prerequisites)
3. [Running the App from Scratch](#running-the-app-from-scratch)
4. [Environment & Configuration](#environment--configuration)
5. [Project Architecture Guidance](#project-architecture-guidance)
6. [Key Dependencies](#key-dependencies)
7. [API Reference](#api-reference)
8. [Phased Development Roadmap](#phased-development-roadmap)
9. [Design Guidelines](#design-guidelines)
10. [Out of Scope (v1)](#out-of-scope-v1)
11. [Future: v2 Considerations](#future-v2-considerations)

---

## What This App Does

- Browse all 114 chapters (suras) of the Quran.
- Choose one reciter per playlist.
- Add and remove chapters via swipe gestures (with undo support).
- Play audio in the background with lock-screen / notification controls.
- Chapters that have been played once are cached offline automatically.
- No accounts, no login — all data lives on the device.

---

## Prerequisites

You need the following tools installed and working **before** creating the Flutter project.

### 1. Flutter SDK

Install Flutter from the official site: https://docs.flutter.dev/get-started/install

**Minimum version:** Flutter 3.19+ (Dart 3.3+)

After installing, verify everything is ready:

```bash
flutter doctor
```

All relevant checks (Android toolchain, Xcode if on macOS, Chrome for web) should pass without errors. Fix any issues `flutter doctor` reports before proceeding.

### 2. Platform-Specific Requirements

| Target | Additional tooling |
|---|---|
| **Android** | Android Studio (for SDK + emulator) or a physical device with USB debugging enabled |
| **iOS** | Xcode 15+, CocoaPods (`sudo gem install cocoapods`), a Mac, and an Apple Developer account for device testing |
| **Web** | Chrome (already checked by `flutter doctor`) |

> **Note for iOS on physical device:** You must have a paid or free Apple Developer account, and the bundle identifier in `pubspec.yaml` / Xcode must match one registered in your Apple Developer portal.

### 3. IDE

Either works:
- **VS Code** — install the [Flutter extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter).
- **Android Studio / IntelliJ** — install the Flutter and Dart plugins.

### 4. Git

For version-controlled, phased delivery as described in the [development roadmap](#phased-development-roadmap).

```bash
git --version   # should return a version; if not, install from https://git-scm.com
```

---

## Running the App from Scratch

### Step 1 — Create the Flutter project

```bash
# Navigate to the parent directory of where this README lives
cd "d:/Proyectos/Mobile apps"

# Create the project (adjust the org identifier as appropriate)
flutter create --org com.yourname --project-name quran_player quran_player

cd quran_player
```

> The `--org` flag sets the Android package name and iOS bundle ID prefix. Use a reverse-domain identifier you own or control (e.g. `com.yourname`). This cannot be easily changed after distribution.

### Step 2 — Add required dependencies

Open `pubspec.yaml` and add the packages listed in [Key Dependencies](#key-dependencies) under `dependencies`. Then:

```bash
flutter pub get
```

For iOS, after adding native-audio-related packages:

```bash
cd ios && pod install && cd ..
```

### Step 3 — Configure platform permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- Internet access for streaming -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Background audio -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

<!-- Offline caching: read/write to app-private storage requires no extra permission -->
```

Also register the foreground service and the background audio `<service>` element as required by the audio package you choose (e.g. `just_audio_background` or `audio_service`). Consult that package's README for the exact manifest snippet.

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

#### Web

No special permissions needed for streaming. Offline caching on web uses the browser cache / service worker (the audio package handles this or it can be skipped for web in v1).

### Step 4 — Run the app

```bash
# List available devices/emulators
flutter devices

# Run on a specific device
flutter run -d <device-id>

# Run on all connected devices simultaneously
flutter run -d all

# Run as a web app
flutter run -d chrome
```

For a release build (e.g. to test on a physical device without a debugger):

```bash
flutter run --release
```

### Step 5 — Verify the basics work

Before writing any feature code, confirm:

1. The default Flutter counter app launches without errors.
2. `flutter analyze` reports no issues.
3. `flutter test` passes (even with only the default stub test).

Then initialize git and make the first commit:

```bash
git init
git add .
git commit -m "chore: initial Flutter project scaffold"
```

---

## Environment & Configuration

This app has **no required API keys for v1.** The mp3quran.net API is public and key-free.

If you store any configuration (base URL, feature flags) in code, use a constants file (e.g. `lib/core/constants/api_constants.dart`) — not `.env` files or build-time secrets, since none are needed at this stage.

> **v2 note:** The Quran Foundation API requires registration and client credentials. Do not add any credential handling until that phase begins, and document the authentication approach (proxy server vs. secure local storage vs. other) before implementing it.

---

## Project Architecture Guidance

The builder chooses the architecture. The following principles must be satisfied regardless of which pattern is picked:

- **Separation of concerns** — UI, business logic, and data access are in clearly distinct layers and do not bleed into each other.
- **Testability** — core logic (playlist management, audio state, API parsing) should be independently testable without spinning up the UI.
- **No global mutable state** — state should flow through the app in a traceable, predictable way.
- **Sensible file organization** — group by feature, not by type (e.g. `lib/features/playlist/` rather than a flat `lib/widgets/` dumping ground).

Common patterns that fit Flutter well for a project of this size: `BLoC / Cubit`, `Riverpod`, or `Provider + Repository`. Pick one and apply it consistently.

---

## Key Dependencies

The following categories of packages are required. The specific package choice within each category is the builder's call — pick the best-maintained, most idiomatic option at the time of implementation.

| Category | What it must do | Example packages (not prescriptive) |
|---|---|---|
| **Audio playback** | Stream audio from URL, background playback, lock-screen/notification controls | `just_audio` + `audio_service`, or `just_audio_background` |
| **HTTP client** | Fetch JSON from the mp3quran.net API | `http`, `dio` |
| **JSON serialization** | Parse API responses cleanly, ideally with code generation | `json_serializable` + `build_runner`, or `freezed` |
| **Local persistence** | Store the playlist and user preferences between sessions | `shared_preferences` (simple KV), `hive`, or `isar` |
| **Offline audio cache** | Cache audio files that have already been played | Built into `just_audio` via a caching plugin, or `flutter_cache_manager` |
| **State management** | Manage UI and playback state | `flutter_bloc`, `riverpod`, or `provider` |

After choosing packages, pin their versions in `pubspec.yaml` (use `^` for patch-level flexibility, e.g. `just_audio: ^0.9.0`).

---

## API Reference

### v1 Data Source — mp3quran.net

Base URL: `https://www.mp3quran.net/api/v3`

Documentation: https://www.mp3quran.net/eng/api

No authentication is required. All endpoints return JSON.

**Endpoints used by this app:**

| Endpoint | Purpose |
|---|---|
| `GET /suwar?language=eng` | Fetch the list of all 114 chapters with name, number, and number of verses |
| `GET /reciters?language=eng` | Fetch the list of available reciters, including their server URL |

**Audio file URL structure:**

Each reciter object contains a `moshaf` array. Each moshaf has a `server` field (base URL) and a `surah_list` (comma-separated list of chapter numbers available for that reciter). The audio file for a given chapter is:

```
{server}/{surah_number_zero_padded_to_3_digits}.mp3

# Example: Chapter 1 (Al-Fatiha) by a reciter whose server is:
# https://server6.mp3quran.net/qtm/
# → https://server6.mp3quran.net/qtm/001.mp3
```

**Recommended approach:**

- Fetch reciters and chapters once on first launch, cache the response locally.
- Re-fetch on next launch if the cached data is older than a reasonable threshold (e.g. 7 days), or when the user explicitly refreshes.
- Do not make redundant API calls on every app open.

---

## Phased Development Roadmap

Build and commit one phase at a time. Each phase ends in a state where the app is fully functional up to that phase's scope — no half-built features committed.

### Phase 1 — Foundation & Visual Design

**Goal:** The app's look and feel is reviewable before any real data is wired in.

- Initialize the Flutter project.
- Implement light mode and dark mode themes using Flutter's `ThemeData` system (no hardcoded colors anywhere in the UI).
- Build core screens with placeholder/hardcoded data: chapter list, reciter selection, playlist view, player controls.
- Apply the [design guidelines](#design-guidelines) — typography, color palette, spacing, iconography.
- No network calls, no real audio, no persistence yet.

**Commit:** `feat(phase-1): foundation, theming, and placeholder UI`

---

### Phase 2 — Live Data

**Goal:** Real chapters and reciters appear in the UI.

- Implement the HTTP layer: fetch chapters and reciters from the mp3quran.net API.
- Parse and model the API responses.
- Wire the chapter list and reciter list screens to real data.
- Handle loading and error states gracefully in the UI.
- Cache the API responses locally so the app doesn't re-fetch on every launch.

**Commit:** `feat(phase-2): live data from mp3quran.net API`

---

### Phase 3 — Playlist Management

**Goal:** The user can build and manage their personal chapter rotation.

- Add chapters to the playlist by tapping (or another clear primary action).
- Remove chapters from the playlist using a **swipe-to-delete** gesture.
- Provide **undo** after a swipe deletion (e.g. a Snackbar with an "Undo" action).
- Support adding the entire Quran as the playlist with one action.
- Persist the playlist locally across app restarts.
- One reciter is associated with each playlist.

**Commit:** `feat(phase-3): playlist management with swipe and local persistence`

---

### Phase 4 — Playback

**Goal:** Real audio plays, including background and lock-screen control.

- Stream audio from the reciter server URLs constructed from the API data.
- Implement: play, pause, skip to next chapter, skip to previous chapter, seek within a chapter.
- Enable **background playback**: audio continues when the app is backgrounded or the screen locks.
- Show a **system media notification** (Android) and **lock-screen controls** (iOS) with play/pause/skip, using `audio_service` or equivalent.
- Bluetooth/car audio: this is automatically covered by correct background audio setup — no extra work required.
- Playback picks up from where the user is in their playlist.

**Commit:** `feat(phase-4): audio playback with background and notification controls`

---

### Phase 5 — Offline Support

**Goal:** Chapters that have already been played are available without a connection.

- After a chapter is successfully streamed, cache the audio file to local storage.
- On subsequent plays, use the cached file if available; fall back to streaming if not.
- Do not pre-download — only cache on actual play.
- The caching should be transparent to the user (no manual download step required).
- Optionally: show a subtle indicator on cached chapters.

**Commit:** `feat(phase-5): transparent offline caching of played chapters`

---

### Phase 6 — Polish & Release Readiness

**Goal:** The app is ready to be submitted to the App Store / Play Store.

- Proper error handling for network failures, bad API responses, and audio errors — no unhandled exceptions, no blank screens.
- Edge cases: empty playlist, no internet on first launch, reciter server unreachable for a specific chapter.
- App icon and splash screen (replace Flutter defaults).
- Test on a range of screen sizes (small phone, large phone, tablet).
- Run `flutter analyze` with zero issues.
- Review permissions — confirm only the minimum set is declared.
- Review and finalize `pubspec.yaml` metadata (name, description, version).
- Prepare release builds: `flutter build apk --release` / `flutter build ios --release` / `flutter build web --release`.

**Commit:** `feat(phase-6): polish, error handling, and release preparation`

---

### Phase 7 — v2 (Future, Separate Effort)

See [Future: v2 Considerations](#future-v2-considerations). Do not begin this phase until Phase 6 is committed and the authentication approach for the Quran Foundation API is decided.

---

## Design Guidelines

These are principles for the builder to interpret — concrete decisions (exact palette, fonts, icon set, spacing scale) are intentionally left to the builder.

- **Minimalist**: every screen, control, and visual element must earn its place. If it isn't necessary, leave it out.
- **Elegant, considered color palette**: avoid generic Material/Cupertino defaults. The palette should feel appropriate for the subject matter. Cohesion matters more than any specific hue.
- **Light mode and dark mode**: both are required, implemented properly via Flutter's `ThemeData` / `ColorScheme` system. No hardcoded `Color(0xff...)` values scattered through widget trees.
- **Contrast**: all text must meet [WCAG AA contrast](https://webaim.org/resources/contrastchecker/) (4.5:1 for normal text) in both modes.
- **Typography**: a small, consistent set of sizes and weights. Legibility over decoration. Use Google Fonts or a system font, not the default.
- **Overall feel**: open it → find what you want → press play → done.

---

## Out of Scope (v1)

The following will not be built in v1. Do not add them unless explicitly requested:

- User accounts, login, or cloud sync of any kind.
- Social or sharing features.
- Ads or in-app purchases.
- Full Quran text, translation, or tafsir display.
- Native Android Auto or Apple CarPlay integration (standard background audio already surfaces on car Bluetooth systems automatically).
- Any analytics or crash-reporting SDKs that send data to a third party.

---

## Future: v2 Considerations

v2 will integrate the [Quran Foundation API](https://api-docs.quran.foundation/) for richer data (translations, verse-level audio timestamps, etc.).

**Important:** This API requires app registration and client credentials, unlike the mp3quran.net API used in v1. Before any v2 implementation begins, the following must be decided and documented:

- How credentials are stored securely (not hardcoded in source).
- Whether a backend proxy is needed to keep credentials off the client entirely.
- Whether the credential flow differs between iOS, Android, and Web.

Do not implement, assume, or scaffold anything for v2 until this decision is made.

---

## Quick Reference — Common Commands

```bash
# Get dependencies
flutter pub get

# Run on a connected device
flutter run

# Run in web browser
flutter run -d chrome

# Static analysis
flutter analyze

# Run tests
flutter test

# Generate code (if using json_serializable / freezed / build_runner)
flutter pub run build_runner build --delete-conflicting-outputs

# Build release APK
flutter build apk --release

# Build release iOS (requires Mac + Xcode)
flutter build ios --release

# Build release web
flutter build web --release
```
