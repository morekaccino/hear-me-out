# Development

Setup, commands, and troubleshooting for working on Hear Me Out.

## Requirements

- Flutter 3.47 or newer
- Dart 3.13 or newer (included with Flutter)
- Chrome for web development
- Android Studio / Xcode only if you want native device builds

The project pins dependency constraints in `flutter_app/pubspec.lock`. Do not
lower the SDK constraint without checking every direct dependency.

## First run

```powershell
cd flutter_app
flutter pub get
flutter run -d chrome
```

If Flutter is not on `PATH` on this Windows machine, the verified SDK is:

```powershell
& 'C:\Users\morekaccino\flutter\bin\flutter.bat' pub get
& 'C:\Users\morekaccino\flutter\bin\flutter.bat' run -d chrome
```

Use `flutter devices` to see available targets. The repo contains Android, iOS,
and web runners; there is no desktop runner.

## Checks

Run all four before considering a change done:

```powershell
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

Useful focused commands:

```powershell
flutter test test/session_factory_test.dart
flutter test test/microphone_flow_test.dart
flutter analyze lib/features/lesson/lesson_screen.dart
```

## Run the release web build locally

```powershell
cd flutter_app
flutter build web --release
python -m http.server 8080 --directory build/web
```

Open <http://127.0.0.1:8080/>. Re-run `flutter build web --release` after code
changes; the Python server serves the existing `build/web` directory and does
not rebuild automatically.

For live development, `flutter run -d chrome` gives hot reload and is usually
preferable.

## Microphone permissions

- **Web:** the page must be served from `localhost` or HTTPS. Chrome asks for
  microphone permission on first use. If denied, the app intentionally falls
  back to note names.
- **Android:** `RECORD_AUDIO` is declared in
  `flutter_app/android/app/src/main/AndroidManifest.xml`.
- **iOS:** `NSMicrophoneUsageDescription` is declared in
  `flutter_app/ios/Runner/Info.plist`.

The `record` package’s `hasPermission()` requests permission by default. A false
result means the app should fall back gracefully; it is not an error state that
should block the lesson.

If the tuner shows `LIVE` but never updates, check the browser site permissions
and whether another application is holding the microphone.

## Sound assets

The original Bright Pluck family lives in `flutter_app/assets/audio/` and is
generated deterministically by `tool/generate_sounds.py`:

```powershell
cd flutter_app
python tool/generate_sounds.py
```

Audition every cue with the development soundboard:

```powershell
python -m http.server 8081 --directory build/web
```

Then open `/soundboard.html` on that server. Rebuild the web app first so the
audio assets are present in `build/web`.

Do not play feedback sounds while the tuner or lesson microphone is actively
listening. Never add a continuous tuner beep: the mic will hear it. Sound effects
are controlled by `AppSettings.soundEffects` and are separate from haptics.

## Test conventions

- Pure algorithms and state belong in `test/*_test.dart`.
- Widget flows belong in `test/widget_test.dart` or
  `test/microphone_flow_test.dart`.
- Use `MemoryProgressStore` for controller tests.
- Use `FakePitchSourceFactory` for microphone tests:
  - `permission` controls `ensurePermission()`.
  - `startResult` controls `start()` while permission can still be true.
  - `startGate` (a `Completer<bool>`) lets you test a start that is still
    pending when the user navigates or disposes the screen.
- Override `lessonGraceProvider` with `Duration.zero` when emitting frames
  immediately in a widget test.
- Call `tester.ensureVisible(finder)` if a target row is below the test
  viewport.
- For web accessibility inspection, enable Flutter semantics first; the app is
  canvas-rendered and otherwise exposes only the “Enable accessibility” control.

## Common failures

### `flutter` is not recognized

Use the full path above or add Flutter to `PATH`:

```powershell
$env:PATH = "C:\Users\morekaccino\flutter\bin;$env:PATH"
```

### `pub get` rejects the SDK

The app requires Dart 3.13+ / Flutter 3.47+. Check:

```powershell
flutter --version
```

Do not “fix” this by lowering `pubspec.yaml`; `record` and
`shared_preferences` already require newer SDKs. Upgrade Flutter instead.

### Tests fail on a tap because the widget is off-screen

The test viewport is often 390×844. Scroll first:

```dart
await tester.ensureVisible(find.text('Free practice'));
await tester.pumpAndSettle();
await tester.tap(find.text('Free practice'));
```

### Web build shows old behavior

Rebuild `build/web` and hard-refresh the browser. The local Python server does
not watch files.

### Microphone never starts on web

Use `localhost` or HTTPS, grant the site microphone permission, and confirm no
other app/tab is capturing the device. The app should still let you use note
names.

### Android APK not built here

There is no Android SDK in this environment. Build on a machine with Android
Studio:

```powershell
flutter build apk
# or
flutter build appbundle
```

## Manual device checklist

Synthetic audio tests cannot prove real microphone accuracy. Before shipping,
test on a physical phone with a guitar:

1. Tuner identifies all six open strings with small cents error.
2. Correct lesson note advances.
3. Wrong note is rejected.
4. Octave error is called out specifically.
5. Same note twice in a row works after a short mute.
6. Ambient noise does not trigger an answer.
7. Denying microphone permission falls back to note names without crashing.
8. Killing and reopening restores XP, streak, and note boxes.
9. Practice with three mistakes does not end.
10. Leaving and retrying a lesson resets the note-name fallback.

See `README.md` for the full product checklist.

## CI

The workflow is `.github/workflows/flutter.yml`:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web --release`

The file must be tracked by git for GitHub Actions to run it. If you change the
minimum Flutter version, update the workflow and `AGENTS.md` together.

## Project documentation

- [`../AGENTS.md`](../AGENTS.md) — agent operating guide
- [`../README.md`](../README.md) — product overview
- [`DESIGN.md`](DESIGN.md) — mission, design language, copy, gamification
- [`../LEARNING_ALGORITHM.md`](../LEARNING_ALGORITHM.md) — learning rules
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — code map and data flow
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — contribution rules
