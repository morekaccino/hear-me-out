# Hear Me Out

Guitar note-reading trainer built with Flutter.

## Quick start

```bash
flutter pub get
flutter run
```

Requires Flutter 3.47+ / Dart 3.13+.

## Checks

```bash
flutter analyze
flutter test
flutter build web --release
```

## Project docs

- [`../AGENTS.md`](../AGENTS.md) — rules and verification steps for coding agents
- [`../docs/DESIGN.md`](../docs/DESIGN.md) — mission and Duolingo-style design language
- [`../docs/SOUND.md`](../docs/SOUND.md) — Bright Pluck sound family and event map
- [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) — layers, data flow, invariants
- [`../docs/DEVELOPMENT.md`](../docs/DEVELOPMENT.md) — setup, debug, manual checks
- [`../LEARNING_ALGORITHM.md`](../LEARNING_ALGORITHM.md) — scheduling and session rules

## Project layout

- `lib/core/music/` — note math, guitar transposition, curriculum
- `lib/core/learning/` — scheduler, session builder, progress state
- `lib/core/audio/` — YIN pitch detection, PCM capture, note matcher
- `lib/core/notation/` — staff geometry and painter
- `lib/core/storage/` — local progress store
- `lib/features/` — onboarding, path, lesson, practice, quests, shop, profile
- `lib/shared/` — theme, reusable widgets
- `lib/state/` — Riverpod controller, economy actions, pitch source factory

## Microphone

- Android: `RECORD_AUDIO` is declared in `AndroidManifest.xml`.
- iOS: `NSMicrophoneUsageDescription` is declared in `Info.plist`.
- Web: use `localhost` or HTTPS.

If the microphone is unavailable, lessons fall back to naming notes.

## Data and privacy

Progress is saved with `shared_preferences` on the device. There is no Firebase,
no Firestore, no auth, no analytics, and no cloud sync. The microphone is active
only during a lesson, practice, tuner, or recording session, and audio is
analyzed on the device. When you record a take, it is stored only on the device.
Android backup rules exclude the recording directory from Auto Backup and device
transfer. On iOS the app asks iOS to exclude it from iCloud backup and reports
when it could not confirm that exclusion; the take may then be included in
device backup. Nothing is uploaded.

## Launcher icon

The icon is generated from `assets/icon/app_icon.png`:

```bash
dart run flutter_launcher_icons
```

## Fonts

- `assets/fonts/Nunito-Variable.ttf` — SIL Open Font License
- `assets/fonts/Bravura.otf` — SIL Open Font License

License texts are kept next to the font files.
