# AGENTS.md

Operating guide for coding agents working on **Hear Me Out**. Read this before
changing code. Deeper references are linked at the bottom.

## What this project is

A local-only Flutter guitar note-reading trainer. The user sees a written note
on a treble staff and either names it or plays it. A microphone detects the
sounding pitch and gives feedback. Progress uses a six-box spaced-repetition
schedule and never leaves the device.

- Product code: [`flutter_app/`](flutter_app/)
- Mission and design language: [`docs/DESIGN.md`](docs/DESIGN.md)
- Sound family and event map: [`docs/SOUND.md`](docs/SOUND.md)
- Learning rules: [`LEARNING_ALGORITHM.md`](LEARNING_ALGORITHM.md)
- Architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Setup, debugging, manual checks: [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md)
- Contribution rules: [`CONTRIBUTING.md`](CONTRIBUTING.md)

## Mission

**Help a beginner read standard notation on guitar through short, forgiving
practice with honest pitch feedback.** The tagline is “Read music. Play guitar.”

The app is for beginner/early-intermediate guitarists practicing alone on a
phone. It should be usable in a few spare minutes, with or without a microphone.
Progress must be real: mastery means spaced correct answers, not lucky taps.
Privacy, musical accuracy, and a calm daily habit matter more than social
features or monetization.

## Design language

The visual language is **Duolingo-inspired, not a Duolingo clone**. Original
mascot and art only; do not copy the owl, proprietary illustrations, or exact
screen layouts.

- Bright white background, `Nunito`, heavy `w700`/`w800` text, thick outlines,
  rounded corners, and hard offset shadows with blur `0`.
- Use `AppColors` and the shared widgets (`DuoButton`, `OutlineDuoButton`,
  `SectionCard`, `AnswerOption`, `FeedbackPanel`, `Mascot`, `PageFrame`) before
  inventing new styles.
- Green = primary/success and Foundations; purple = First Position and free
  practice; blue = info/secondary and Accidentals; red = error/lives; yellow =
  reward/progress.
- Primary buttons default to 56 px tall, uppercase, radius 16, with a visible
  bottom edge and a 3 px press movement; compact variants use 48–54 px. Answer
  options are 64 px tall.
- Content stays in a centered 520 px column and must fit a 390×844 viewport.
- Feedback is immediate, specific, and encouraging. Prefer “Not quite” and a
  concrete string/fret hint over generic praise or blame.
- Confetti only on a passed result. Haptics: light for correct, medium for
  incorrect, respecting the setting.
- Sound follows the original Warm Mallet family: marimba body, glass-bell
  rewards, muted woodblock UI, soft low errors. Never play while the tuner or
  lesson mic is listening; respect the persisted Sound effects setting.
- No leaderboards, leagues, duels, ads, subscriptions, accounts, or fake stats.

Full palette, typography, component dimensions, motion, screen intent, copy
tone, accessibility notes, and non-goals are in
[`docs/DESIGN.md`](docs/DESIGN.md). Read it before changing UI.

## Hard rules

1. **No network, cloud, accounts, analytics, or remote persistence.** Progress
   lives in `shared_preferences`; audio is analyzed in memory and discarded.
2. **Keep `lib/core/` free of widgets.** Music math, scheduling, pitch
   detection, and staff geometry must stay pure Dart and testable.
3. **Written pitch is not sounding pitch.** Guitar notation is written one
   octave above sounding pitch. Use `Guitar.soundingMidiForWritten`.
4. **Practice never costs lives.** Lessons have three lives; practice does not.
   Do not regress this.
5. **Mastery needs space.** A note is mastered only at box >= 4, with at least
   five correct answers across at least two calendar days.
6. **Do not fake stats or progress.** Every number must come from
   `ProgressState` or a real session.
7. **Add regression tests for every behavior change.** UI-only flows need a
   widget test when they affect the lesson experience.
8. **Do not silently change storage shape.** The backup format is versioned and
   validated; future schema versions are rejected, not guessed.
9. **Follow the design language.** Reuse theme tokens and shared components; do
   not add one-off colors, fonts, or button styles without updating
   `docs/DESIGN.md`.

## Environment

- Flutter `>=3.47.0`, Dart `>=3.13.0`.
- On this Windows machine Flutter may not be on `PATH`. The verified local SDK
  is:

  ```powershell
  C:\Users\morekaccino\flutter\bin\flutter.bat
  ```

  If that path is missing, install Flutter 3.47.x or newer and verify
  `flutter --version`.

## Commands

Run from `flutter_app/`:

```powershell
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

Run one test file:

```powershell
flutter test test/microphone_flow_test.dart
```

If `flutter` is not on `PATH`:

```powershell
& 'C:\Users\morekaccino\flutter\bin\flutter.bat' analyze
& 'C:\Users\morekaccino\flutter\bin\flutter.bat' test
```

Launch locally:

```powershell
flutter run -d chrome
```

Or build and serve the release web app:

```powershell
flutter build web --release
python -m http.server 8080 --directory build/web
```

Then open <http://127.0.0.1:8080/>.

## Repo map

| Path | Purpose |
|---|---|
| `flutter_app/lib/core/music/` | Note math, guitar transposition, curriculum |
| `flutter_app/lib/core/learning/` | Scheduler, progress model, session planner |
| `flutter_app/lib/core/audio/` | YIN detector, PCM capture, note matcher |
| `flutter_app/lib/core/notation/` | Staff geometry and Bravura painter |
| `flutter_app/lib/core/storage/` | JSON progress store and backup validation |
| `flutter_app/lib/features/` | Onboarding, path, lesson, practice, profile |
| `flutter_app/lib/shared/` | Theme and reusable Duolingo-style widgets |
| `flutter_app/lib/state/` | Riverpod app controller and audio providers |
| `flutter_app/test/` | Unit and widget tests; fakes live in `test/support/` |

## Behavior worth protecting

- **Curriculum shape:** 3 sections, 6 units, 25 lessons. Every unit has a
  focus, a guidebook, and a 15-exercise checkpoint.
- **Session size:** 12 exercises per normal lesson, 15 per checkpoint.
- **New-note teaching:** each new note gets four exposures while its box is
  below 2. A normal lesson also reserves review slots from prior notes.
- **Mistake resurfacing:** missed notes return once at the end of the lesson,
  capped at four retries.
- **Answer modes:** mixed starts each new note with naming and includes at
  least three play exercises when possible; name-only never starts the mic;
  play-only plays everything.
- **Lives:** three per lesson; zero ends the lesson. Practice has no life cost.
- **Curriculum migration:** bump `curriculumVersion` and map old lesson IDs;
  never silently drop completed lessons, XP, or note progress.
- **XP:** 10 normal lesson, 15 review, +5 perfect; replay 5, +3 perfect replay;
  practice 5.
- **Streak:** first completed lesson of a local calendar day; practice does not
  advance it.
- **Mic matching:** require three stable frames, accept within the configured
  cents tolerance, flag ±12-semitone octave errors after six frames, and ignore
  the first 250 ms after a new play exercise.
- **Display spelling:** keep the target’s flat/sharp spelling in feedback; a
  B-flat exercise must not show A-sharp.
- **In-tune UI:** use `settings.toleranceCents`, not a hard-coded threshold.
- **Backup restore:** validate `schemaVersion` and reject arbitrary JSON.
- **Mic lifecycle:** every screen that owns a source uses a generation token
  and disposes stale starts. Do not remove those guards.

## Testing notes

- Pure logic belongs in `test/*_test.dart`; microphone/UI flows use
  `test/microphone_flow_test.dart`.
- `test/support/fakes.dart` provides `FakePitchSourceFactory` with
  `permission`, `startResult`, and `startGate` controls. Use `startGate` to test
  start/dispose races.
- Override `lessonGraceProvider` with `Duration.zero` in widget tests that emit
  frames immediately.
- If a widget is below the fold, call `tester.ensureVisible(finder)` before
  tapping it.
- The web app renders to canvas; browser accessibility snapshots require
  enabling Flutter semantics first if you inspect it manually.

## Current verified state

Last verified on 2026-10-31 with Flutter 3.47.9 / Dart 3.13.7:

- `flutter analyze` — no issues
- `flutter test` — 121 tests passing
- `flutter build web --release` — succeeds
- Web app loads, onboarding completes, the sectioned path renders, and a
  lesson answer produces feedback
- 28 original Warm Mallet cues are bundled in `assets/audio/`; all decode
  successfully in Chrome and the soundboard is available at
  `flutter_app/tool/soundboard.html`

Re-run the checks after any change. The test count will grow; treat the
analyze/test/build commands as the source of truth.

## Definition of done

- Behavior is covered by a test, including the regression that motivated it.
- `flutter analyze` and `flutter test` pass.
- `flutter build web --release` still succeeds for user-facing changes.
- Audio changes are checked against the device checklist in `README.md`.
- Docs are updated when a rule, setting, storage format, or workflow changes.
- The CI workflow at `.github/workflows/flutter.yml` must be tracked by git for
  CI to run.

## Documentation map

- [`README.md`](README.md) — product overview, features, device checklist
- [`docs/DESIGN.md`](docs/DESIGN.md) — mission, Duolingo-style language, copy, gamification
- [`docs/SOUND.md`](docs/SOUND.md) — Warm Mallet family, assets, event map, settings
- [`LEARNING_ALGORITHM.md`](LEARNING_ALGORITHM.md) — scheduling and session rules
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — layers, data flow, invariants
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — setup, run, debug, common failures
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — contribution rules and workflow
