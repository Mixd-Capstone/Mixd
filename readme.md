# Mixd

A social music platform for creating and sharing custom mixtapes. Built with Flutter and Supabase.

## Tech Stack

- **Framework:** Flutter (Dart SDK ^3.10.8)
- **Backend:** [Supabase](https://supabase.com/) (PostgreSQL, Auth, Storage)
- **Auth:** Google Sign-In via Supabase OAuth
- **Audio:** just_audio
- **UI:** Material 3, Google Fonts (Outfit), dark theme

## Features

- **Feed** — TikTok-style vertical scroll of community mixes with like, comment, and share
- **Explore** — Search and browse by genre (Lo-Fi, Nightcore, Techno, Indie, Alternative, Hip Hop)
- **Create** — Upload tracks and build mixtapes (in progress)
- **Friends** — View friends list and shared mixes
- **Profile** — Google account info, stats (mixes, followers, following), sign out
- **Walkman Player** — Retro cassette tape audio player with animated reels and landscape mode

## Project Structure

```
├── lib/
│   ├── main.dart                  # App entry, Supabase init, auth routing
│   ├── auth_service.dart          # Google OAuth sign-in/sign-out
│   ├── login_screen.dart          # Login UI
│   ├── home_screen.dart           # Bottom nav with 5 tabs
│   └── walkman_player_screen.dart # Retro audio player
├── assets/
│   └── audio/
│       └── sample.mp3             # Placeholder audio (will be replaced with DB audio)
├── android/                       # Android platform config
├── ios/                           # iOS platform config + Podfile
├── web/                           # Web platform config
├── windows/                       # Windows platform config
└── pubspec.yaml                   # Dependencies and assets
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio or Xcode (for emulators)
- A connected device or emulator

### Run the App

```bash
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Build

```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# Web
flutter build web

# Windows
flutter build windows
```

## Environment Setup

This project uses a `.env` file for client config. It is **not** committed to git.

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```
2. Fill in the values (get them from a teammate)

The `.env.example` file shows which variables are needed:
- `SUPABASE_URL` — Supabase project URL
- `SUPABASE_ANON_KEY` — Supabase anonymous key
- `GOOGLE_WEB_CLIENT_ID` — Google OAuth web client ID
- `GOOGLE_IOS_CLIENT_ID` — Google OAuth iOS client ID
- `MIXD_API_KEY` — Mixd song download API key

## Branch Conventions

| Type | Format | Example |
|------|--------|---------|
| Feature | `feature/description` | `feature/create-mixtape` |
| Bug fix | `fix/description` | `fix/login-crash` |
| Docs | `docs/description` | `docs/readme` |
| Chore | `chore/description` | `chore/cleanup-assets` |

Always branch off `main`, open a PR, get it reviewed, then merge.

## Team

- [@Shreyan9](https://github.com/Shreyan9)
- [@atkinsonl477](https://github.com/atkinsonl477)
- [@camdenbalberg](https://github.com/camdenbalberg)
- [@DiegoLandaeta03](https://github.com/DiegoLandaeta03)
