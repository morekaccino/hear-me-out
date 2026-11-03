# AGENTS.md

Operating guide for coding agents working on **Hear Me Out**. Read this before
changing code. Deeper references are linked at the bottom.

## What this project is

A local-only Flutter guitar musicianship trainer. The user works through a
240-lesson course covering notation, rhythm, chords, harmony, scales, ear
training, technique, and repertoire. A microphone detects the sounding pitch
and gives feedback. Every skill has its own FSRS-style review schedule, and
progress never leaves the device.

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

The visual language **follows current Duolingo**: bright white surfaces in light
mode, deep navy surfaces in dark mode, heavy
Nunito type, thick outlines, hard offset shadows, per-unit path colors, 3D
path nodes, heart /
gem / streak counters, chests, and a responsive side rail on wide screens. Keep
the mascot and all artwork original; do not copy the owl, proprietary
illustrations, font files, or trademarked assets.

- Bright white background, `Nunito`, heavy `w700`/`w800` text, thick outlines,
  rounded corners, and hard offset shadows with blur `0`.
- Use `AppColors` and the shared widgets (`DuoButton`, `OutlineDuoButton`,
  `SectionCard`, `AnswerOption`, `FeedbackPanel`, `Mascot`, `PageFrame`) before
  inventing new styles.
- Green = primary/success and Foundations; purple = First Position and free
  practice; blue = info/secondary and Accidentals; red = error/hearts; yellow =
  reward/progress.
- Primary buttons default to 56 px tall, uppercase, radius 16, with a visible
  bottom edge and a 3 px press movement; compact variants use 48–54 px. Answer
  options are 64 px tall.
- Content stays in a centered responsive column (600 px for path and lessons,
  720 px for hubs) and must fit a 390×844 viewport. Widths at or above 900 px
  use a 232–256 px side rail; narrower widths use five bottom tabs that take
  their own color when selected. At roughly 1200 px and wider the learn page
  adds a 320–372 px quest rail that shares the path's scroll.
- Feedback is immediate, specific, and encouraging. Prefer “Not quite” and a
  concrete string/fret hint over generic praise or blame.
- Confetti only on a passed result. Haptics: light for correct, medium for
  incorrect, respecting the setting.
- Sound follows the original Bright Pluck family: short plucked synth body,
  glass-bell sparkle, dry UI blips, soft low errors. Never play while the tuner
  or lesson mic is listening; respect the persisted Sound effects setting.
- No leaderboards, leagues, duels, ads, subscriptions, accounts, real-money
  purchases, or fake stats. The shop spends earned gems only.

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
4. **Practice never costs hearts.** Lessons share a five-heart pool; practice does
   not spend hearts and restores one on completion. Do not regress this.
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
| `flutter_app/lib/core/music/` | Note math, intervals, keys, scales, chords, progressions, rhythm, guitar transposition, curriculum model |
| `flutter_app/lib/core/learning/` | Skill scheduler, course specs, objectives, prompts, composer, progress model |
| `flutter_app/lib/content/` | Objectives, templates, verifiers, and session factories |
| `flutter_app/lib/core/audio/` | YIN detector, PCM capture, note matcher, local WAV synth |
| `flutter_app/lib/core/notation/` | Staff geometry and Bravura painter |
| `flutter_app/lib/core/storage/` | JSON progress store and backup validation |
| `flutter_app/lib/features/` | Onboarding, path, lesson, practice, quests, shop, profile |
| `flutter_app/lib/shared/` | Theme and reusable Duolingo-style widgets |
| `flutter_app/lib/state/` | Riverpod app controller and audio providers |
| `flutter_app/test/` | Unit and widget tests; fakes live in `test/support/` |

## Behavior worth protecting

- **Curriculum shape:** 8 sections, 40 units, 240 lessons. Every unit has a
  focus, a guidebook, six lessons, and a checkpoint. The six-lesson arc is
  Discover, Build, Connect, Apply, Integrate, Checkpoint.
- **Session size:** up to 16 exercises per normal lesson; checkpoints use 14–30
  items. A lesson whose material cannot fill the target is shortened (8
  minimum). New objectives get five exposures.
- **New-objective teaching:** each new objective gets a teach card, a guided
  attempt, an apply item, a transfer item, and a production item. Those
  exposures use different question shapes whenever possible.
- **Question variety:** notes, rhythm, chords, theory, ear training, fretboard,
  technique, sight-reading, repertoire, and improvisation all have scheduled
  objectives. The composer rotates templates per objective and never repeats
  the same template twice in a row.
- **Applied questions only:** every scored prompt asks the learner to read,
  play, build, transcribe, or apply a concept. Standalone “What is …?”
  definition questions are not allowed.
- **Engine boundaries:** `core/learning` is topic-agnostic. Objectives,
  prompts, and composers never import notes, and `lib/core` never imports
  `lib/content`. Adding a topic should touch `lib/content/` and at most one new
  prompt type, never the composer.
- **Pointer and touch:** every interactive control works with a finger and a
  mouse. Give it a pointer cursor (only when enabled) and a hover state, and
  size tap targets for thumbs. Lessons must not assume a phone; the layout
  switches at 900 px. Use `HoverRegion` for hover-only surfaces and
  `DuoTappable` for anything tapped; do not hand-roll a `GestureDetector`
  without a cursor.
- **Mistake resurfacing:** missed notes return once at the end of the lesson,
  capped at four retries.
- **Answer modes:** mixed starts each new note with naming and includes at
  least three play exercises when possible; name-only never starts the mic;
  play-only plays everything.
- **Hearts:** five shared hearts. A wrong lesson answer spends one; zero ends the
  lesson. Hearts refill one per four hours, a practice session restores one, and
  the shop can refill all five for 350 gems. Practice never spends hearts.
- **Gems and shop:** fresh profiles start with 500 gems. Gems come from chests
  and daily quests and buy heart refills, streak freezes, and double XP. No
  real-money purchases.
- **Chests:** one per unit, unlocked by the lesson before it, opened once for
  gems. Opening persists in `openedChests`.
- **Daily quests:** complete a lesson, answer ten notes, and build a five-answer
  combo. Claiming awards gems once per local day.
- **Streak freeze:** up to two equipped; one is consumed when a completed lesson
  arrives after a missed day and preserves the streak.
- **Double XP:** 15 minutes of doubled lesson/practice XP after purchase.
- **Jump ahead:** passing a 15-exercise test unlocks the sections before the
  target section without deleting note progress.
- **Curriculum migration:** bump `curriculumVersion` and map old lesson IDs;
  never silently drop completed lessons, XP, or note progress.
- **XP:** 10 normal lesson, 15 review, +5 perfect; replay 5, +3 perfect replay;
  practice 5; jump test 20. Double XP multiplies the award.
- **Streak:** first completed lesson of a local calendar day; practice does not
  advance it.
- **Mic matching:** require three stable frames, accept within the configured
  cents tolerance, flag ±12-semitone octave errors after six frames, and ignore
  the first 250 ms after a new play exercise.
- **Display spelling:** keep the target’s flat/sharp spelling in feedback; a
  B-flat exercise must not show A-sharp.
- **In-tune UI:** use `settings.toleranceCents`, not a hard-coded threshold.
- **Backup restore:** validate `schemaVersion` and reject arbitrary JSON.
- **Appearance:** System, Light, and Dark persist in `settings.themeMode`
  (`schemaVersion` 3). System follows the platform brightness; dark uses the
  Duo palette in `DuoPalette.dark`. Do not hardcode light-only neutral colors.
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

Last verified on 2026-11-02 with Flutter 3.47.9 / Dart 3.13.7:

- `flutter analyze` - no issues
- `flutter test` - 224 tests passing
- `flutter build web --release` - succeeds
- The course has 8 sections, 40 units, and 240 lessons. Every unit has six
  lessons (Discover, Build, Connect, Apply, Integrate, Checkpoint).
- Notes, rhythm, chords, theory, ear training, fretboard, technique,
  sight-reading, repertoire, and improvisation all use the same FSRS-style
  skill scheduler.
- Web app loads, onboarding completes, the path renders the Today card, chests,
  and counters, and lessons, quests, shop, practice, and profile are reachable
  on narrow and wide layouts; System, Light, and Dark appearance all render
  with the Duo palette
- 28 original Bright Pluck cues are bundled in `assets/audio/`; ear-training
  stimuli are synthesized locally as WAV bytes and the soundboard is available
  at `flutter_app/tool/soundboard.html`

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
- [`docs/SOUND.md`](docs/SOUND.md) — Bright Pluck family, assets, event map, settings
- [`LEARNING_ALGORITHM.md`](LEARNING_ALGORITHM.md) — scheduling and session rules
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — layers, data flow, invariants
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — setup, run, debug, common failures
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — contribution rules and workflow
