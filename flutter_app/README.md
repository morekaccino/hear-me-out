# Hear Me Out

Guitar note-reading trainer built with Flutter.

## Quick start

```bash
flutter pub get
flutter run
```

Requires Flutter 3.47+ / Dart 3.10+.

## Checks

```bash
flutter analyze
flutter test
flutter build web --release
```

## Project layout

- `lib/core/music/` — note math, guitar transposition, curriculum
- `lib/core/learning/` — scheduler, session builder, progress state
- `lib/core/audio/` — YIN pitch detection, PCM capture, note matcher
- `lib/core/notation/` — staff geometry and painter
- `lib/core/storage/` — local progress store
- `lib/features/` — onboarding, path, lesson, practice, profile
- `lib/shared/` — theme, reusable widgets
- `lib/state/` — Riverpod controller and pitch source factory

## Microphone

- Android: `RECORD_AUDIO` is declared in `AndroidManifest.xml`.
- iOS: `NSMicrophoneUsageDescription` is declared in `Info.plist`.
- Web: use `localhost` or HTTPS.

If the microphone is unavailable, lessons fall back to naming notes.

## Data and privacy

Progress is saved with `shared_preferences` on the device. There is no Firebase,
no Firestore, no auth, and no analytics. Audio is analyzed in memory and never
recorded or uploaded.

## Launcher icon

The icon is generated from `assets/icon/app_icon.png`:

```bash
dart run flutter_launcher_icons
```

## Fonts

- `assets/fonts/Nunito-Variable.ttf` — SIL Open Font License
- `assets/fonts/Bravura.otf` — SIL Open Font License

License texts are kept next to the font files.
