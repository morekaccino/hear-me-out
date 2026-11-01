# Architecture

Hear Me Out is a Flutter app with pure-Dart domain layers and thin UI
adapters. The main rule is that the hard parts — pitch detection, scheduling,
session composition, and staff geometry — do not depend on widgets.

For user-facing behavior rules, see [`../LEARNING_ALGORITHM.md`](../LEARNING_ALGORITHM.md)
and [`../AGENTS.md`](../AGENTS.md). For mission, visual language, copy, and
gamification, see [`DESIGN.md`](DESIGN.md).

## Layers

```
flutter_app/lib/
├── core/
│   ├── music/       Note, Accidental, guitar transposition, curriculum
│   ├── learning/    ProgressState, scheduler, session builder, LessonRun
│   ├── audio/       YIN detector, PCM capture, note matcher
│   ├── notation/    StaffGeometry and StaffPainter
│   └── storage/     shared_preferences JSON store, export/import
├── features/        onboarding, path, lesson, practice, quests, shop, profile
├── shared/          theme, reusable widgets, sound service
└── state/           Riverpod AppController, pitch-source, sound providers
```

Dependency direction:

```
features -> state -> core/learning -> core/music
features -> core/audio, core/notation
core/* does not import features or shared widgets
```

`core/learning` imports `core/music`; it does not import Flutter widgets.
`core/audio/note_matcher.dart` depends on `core/music/guitar.dart` and
`note.dart`. `core/audio/pitch_source.dart` is the only audio file that depends
on the `record` plugin. `core/notation` is the one visual core area and uses
Flutter painting APIs.

## Music model

`Note` stores a letter, octave, and `Accidental` (`natural`, `sharp`, `flat`).
Important properties:

- `midi` — MIDI number with C4 = 60.
- `diatonicIndex` — staff position independent of accidentals.
- `id` — stable storage/curriculum key such as `F#4` or `Bb4`.
- `display` — UI spelling with ♯/♭ symbols.

Equality is by spelling (`C#4 != Db4`), even though `samePitchAs` compares MIDI.
Do not replace stored note IDs with normalized pitch classes without migrating
progress and answer choices.

`Guitar` owns the guitar-specific rules:

- `soundingMidiForWritten(written) == written.midi - 12`.
- Open strings are sounding E2 A2 D3 G3 B3 E4, written E3 A3 D4 G4 B4 E5.
- `bestPosition` prefers the lowest fret, then the lowest-pitched (highest-numbered)
  string.

`curriculum.dart` holds the 3 sections / 6 units / 25 lessons, the unit focus
and guidebook metadata, the note catalog used for answer choices, and the
legacy lesson-ID map used by progress migration.

## Progress and scheduling

`ProgressState` is the persisted domain aggregate:

- per-note `NoteProgress`: box, due time, correct/incorrect counts, streak,
  correct-day set, cent samples
- completed lessons and best accuracy
- XP, streak, daily XP
- gems, hearts, next heart time, streak freezes, XP boost
- opened chests, daily quest counters, claimed quests
- settings
- `curriculumVersion` plus a migration path from the old 4-unit lesson IDs
- last 30 session summaries

`NoteProgress.recordAnswer` is the scheduler:

| Result | Box | Next due |
|---|---|---|
| correct | +1 (max 5) | interval for the new box |
| wrong | -2 (min 0) | 1 minute |

Intervals are `0, 10 min, 1 day, 3 days, 7 days, 21 days`. Mastery requires
box >= 4, at least five correct answers, and correct days on at least two
different calendar dates.

Streak and daily XP are calendar-day based; `dayKey` uses local time. Hearts
regenerate lazily in `refreshHearts`, one every four hours, and daily quest
counters reset in `refreshDaily`. Streak freezes are consumed only when the
next completed lesson finds a gap. All values are local and validated on load.

## Session planning

`buildLessonExercises` returns exactly 12 exercises for a normal lesson and 15
for a checkpoint:

1. Select up to two new notes whose box is below 2.
2. Add four copies of each new note.
3. Fill the rest from a review quota: due notes, weak notes, then recently seen
   notes.
4. Order by frequency/priority while keeping the same note out of the last two
   positions when another choice exists.
5. Assign `isNew` and `newExposure` based on occurrence order.
6. Assign modes:
   - no mic or name mode: all naming
   - play mode: all playing
   - mixed: first exposure of a new note is naming; later exercises alternate
     and guarantee at least three play exercises when possible.

`buildPracticeExercises` reuses the same planner without teaching new notes.
It draws from due notes, weak notes, or all learned notes. If the profile is
empty it falls back to the first lesson notes so a practice screen never opens
empty.

`LessonRun` holds the mutable session state: index, hearts snapshot, correct/
wrong, combo, result feedback, and `isPractice`. A wrong answer spends a shared
heart and queues the note for a short end-of-lesson retry; distinct notes are
capped at four. Practice sessions never spend hearts and never end on
`outOfLives`; only lessons do. `isJumpTest` runs a 15-exercise section test and
unlocks earlier sections on a pass.

`features/path/path_layout.dart` is pure geometry. It builds one continuous
low-amplitude sine across the course, where each unit continues the phase the
previous unit ended on, so the path never restarts at center. There is no drawn
road between nodes. The path widget lays out the elliptical nodes, chests, and
the active START slot.

## Audio pipeline

```
record plugin -> PCM16 mono 44.1 kHz -> stream chunks
  -> little-endian sample decode (keeps odd trailing byte)
  -> 2:1 decimate to ~22.05 kHz
  -> 4096-sample window, 2048-sample hop (~46 ms)
  -> YIN detector
  -> PitchFrame
  -> NoteMatcher
```

YIN (`core/audio/yin.dart`):

1. Remove DC and gate on RMS.
2. Difference function over lags for 70–1000 Hz.
3. Cumulative mean normalized difference.
4. First dip below 0.15, refined by parabolic interpolation.
5. Frequency = sample rate / lag; clarity = 1 − normalized difference.

`NoteMatcher`:

- Rejects clarity below 0.5.
- Requires three stable frames of the same rounded MIDI note.
- Accepts the target when cents are within `toleranceCents`.
- Reports an octave error when the detected MIDI is target ± 12 for six frames.
- Reports a wrong note when another pitch is stable for six frames.
- Ignores the first 250 ms of a new exercise (`lessonGraceProvider`).
- Uses the written target’s sounding MIDI, not the written MIDI.

The tuner uses the same pitch source and compares frequency against the selected
open string. It does not use `NoteMatcher`.

### Sound feedback

`shared/audio/sound_service.dart` owns the original Bright Pluck family. Core
cues are preloaded; rare reward cues are created lazily. `SoundService.enabled`
mirrors `AppSettings.soundEffects`. UI and result screens call the service; the
domain layer does not know about audio. Sound is never played while the tuner or
lesson mic is actively listening, except the answer cue after the answer is
committed. See [`SOUND.md`](SOUND.md).

### Microphone ownership

Each screen that owns a `PitchSource` keeps a monotonically increasing
generation token:

- `_ensureMic` / `_toggleTuner` increments the token at start.
- `_stopMic` / `_stopTuner` increments it and disposes the current source.
- After `await start()`, a stale token means dispose the new source.
- Subscription callbacks ignore stale generations.
- Onboarding disables its test button while a source is listening.

Do not remove these guards. They prevent duplicate recorders when users tap
repeatedly, skip onboarding, leave practice, retry a lesson, or start practice
while the tuner is starting.

## UI and state

`AppController` is an `AsyncNotifier<AppData>`:

```
AppData
├── ProgressState progress
├── LessonRun? run
└── LessonResult? result
```

It loads progress from `ProgressStore`, saves after answers/completions/settings,
and exposes lesson/practice lifecycle methods. Screens read it through Riverpod.

Screens:

- `OnboardingScreen` — welcome, explanation, optional mic check, daily goal.
- `PathScreen` — lesson map, counters, chests, jump-ahead tests, lesson launch.
- `LessonScreen` — staff, name/play answers, hearts, feedback, result.
- `PracticeScreen` — tuner, due/weak/free practice, heart recovery, stats.
- `QuestsScreen` — three daily quests and gem claims.
- `ShopScreen` — heart refill, streak freezes, double XP.
- `ProfileScreen` — stats, per-note boxes, settings, backup/restore, reset.

`PageFrame` keeps content in a responsive centered column (600 px default,
720 px hubs). `HomeShell` owns five destinations and switches between a 256 px
side rail at 900 px and wider, and a five-item bottom bar below that. The learn
page places a 372 px quest rail beside the path at 1000 px and wider.

## Persistence

`SharedPreferencesProgressStore` stores one JSON document under
`hear_me_out_progress_v1`.

`ProgressState.toJson` / `fromJson` handle the full document. `importProgress`
and store loading go through `_decodeProgress`, which requires a numeric
`schemaVersion` in `[1, currentSchemaVersion]`. `currentSchemaVersion` is 3.
Version 1 documents load with default economy values (500 gems, five hearts,
no chests or quests); version 2 documents load with the System appearance.
Arbitrary JSON such as `{"hello":"world"}` is rejected.
Future versions are rejected rather than being partially parsed.

Backups are copied as pretty JSON via the clipboard. Restore validates first,
then replaces the state and saves it. Corrupt/missing storage falls back to a
fresh profile.

## Test map

| File | Covers |
|---|---|
| `test/note_test.dart` | Parsing, MIDI, spelling, transposition |
| `test/guitar_test.dart` | Written/sounding transposition, fingerings |
| `test/staff_geometry_test.dart` | Staff positions, ledger lines |
| `test/scheduler_test.dart` | Boxes, intervals, mastery, XP, streak |
| `test/session_builder_test.dart` | All lessons, choices, modes, ordering |
| `test/yin_test.dart` | Synthetic guitar tones, harmonics, noise, silence |
| `test/note_matcher_test.dart` | Stable frames, tolerance, octave errors, grace |
| `test/progress_store_test.dart` | JSON round trips, storage, controller, practice |
| `test/widget_test.dart` | Onboarding, sectioned path, lesson, mic exercise, sound trigger |
| `test/path_layout_test.dart` | Path bounds, spacing, arc direction, and center anchors |
| `test/microphone_flow_test.dart` | Mic lifecycle, name-only practice, retry reset |
| `test/economy_test.dart` | Hearts, gems, chests, quests, boosts, jump tests |

`test/support/fakes.dart` contains an in-memory store, controllable
`FakePitchSource` / `FakePitchSourceFactory`, and `FakeSoundService`. Use
`startGate` for async start/dispose races and override `soundServiceProvider`
in widget tests so platform audio is never touched.
