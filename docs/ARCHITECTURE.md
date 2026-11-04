# Architecture

> **Status:** This document describes the current 240-lesson implementation. The
> approved transformation plan lives in Plane (`D0.1 — START HERE`) and
> [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md); it is not
> implemented yet. Do not assume planned behavior is shipped.

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
│   ├── learning/    Objectives, prompts, templates, composer, LessonRun
│   ├── audio/       YIN detector, PCM capture, note matcher
│   ├── notation/    StaffGeometry and StaffPainter
│   └── storage/     shared_preferences JSON store, export/import
├── content/         lesson material: objectives, templates, session factories
├── features/        onboarding, path, lesson, practice, quests, shop, profile
├── shared/          theme, reusable widgets, sound service
└── state/           Riverpod AppController, pitch-source, sound providers
```

Dependency direction:

```
features -> state -> content -> core/learning -> core/music
features -> core/audio, core/notation
core/* does not import content, features, or shared widgets
```

The `core`/`content` split is the load-bearing one. `core/learning` knows about
families, roles, and capabilities, never about notes, staffs, or chords.
`content` holds everything teachable and depends on `core`, not the other way
around. A test in `test/composer_test.dart` enforces that `lib/core` never
imports `lib/content`.

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

`curriculum.dart` exposes the generated 8-section / 40-unit / 240-lesson course,
the unit focus metadata, the note catalog used for answer choices, and the legacy
lesson-ID map used by progress migration. The course is authored as 40
`UnitSpec`s in `core/learning/course/` and expanded by `LessonFactory` into six
lessons per unit. Lessons name non-note objectives by id (`teaches` / `reviews`),
which resolve through `lib/content/objectives.dart`.

## Progress and scheduling

`ProgressState` is the persisted domain aggregate:

- per-skill `SkillProgress`: stability, difficulty, due time, reps, lapses,
  correct/incorrect, correct-day set, production/transfer evidence, response
  time, level, fragile flag, cent samples
- per-note `NoteProgress`: legacy boxes kept for the note chips
- completed lessons, checkpoints, and best accuracy
- XP, streak, daily XP
- gems, hearts, next heart time, streak freezes, XP boost
- opened chests, daily quest counters, claimed quests
- settings
- `curriculumVersion` plus a migration path from the old 40-lesson IDs
- last 30 session summaries

`SkillProgress.recordAnswer` is the scheduler. It applies the FSRS-6 model in
`core/learning/skill.dart`: stability, difficulty, and retrievability. Performance
skills are capped at 30 days of stability; declarative facts at 180 days.
Mastery requires at least 21 days of stability, four spaced reps, three correct
days, one production success, one transfer success, and a passed checkpoint.

A wrong answer is not just a box change: it queues a same-session repair, a
next-day repair card, and a 3-day recheck. Two lapses marks the skill fragile;
four marks it a leech.

Streak and daily XP are calendar-day based; `dayKey` uses local time. Hearts
regenerate lazily in `refreshHearts`, one every four hours, and daily quest
counters reset in `refreshDaily`. Streak freezes are consumed only when the
next completed lesson finds a gap. All values are local and validated on load.

## Session planning

A session is a `SessionShape` filled by a `SessionComposer` and checked by a
`SessionValidator`.

- `SessionShape.standard(total: n, newObjectives: k)` reserves four slots per
  new objective and gives the rest to review. The factory lowers `n` when the
  available objectives are too few to fill it, with a floor of 8.
- `SessionComposer.compose` builds one entry per slot, interleaves them so the
  same objective is never reused within two positions, then picks an answer
  surface per slot from the `ContentPack`.
- `SessionValidator` asserts slot count, teach-before-question, one teach card
  per objective, unscored teach cards, and objective spacing.

Roles come from `SessionShape.roleForOccurrence`: occurrence 0 is a `teach`
card, 1 is `guided`, and the rest are `apply`. Review slots use `review`.

Answer surfaces are `AnswerMode.name`, `AnswerMode.play`, or null for the
unscored teach card. Mode policy:

- no mic or name mode: all scored slots name
- play mode: all scored slots play
- mixed: guided is name, later slots alternate, and at least three play
  exercises are guaranteed when the microphone is available

`buildLessonExercises` and `buildPracticeExercises` live in
`content/session_factory.dart`. They do the note-specific selection (which notes
are new, which are due or weak) and hand objective refs to the composer.
`buildPracticeExercises` draws from due notes, weak notes, or all learned notes,
and falls back to the first lesson so practice never opens empty.

`LessonRun` holds the mutable session state: index, hearts snapshot, correct/
wrong, combo, result feedback, and `isPractice`. A wrong answer spends a shared
heart and queues the objective for a short end-of-lesson retry; distinct
objectives are capped at four. Practice sessions never spend hearts and never
end on `outOfLives`; only lessons do. `isJumpTest` runs a 15-slot section test
and unlocks earlier sections on a pass.

### Prompt and template types

`core/learning/prompt.dart` holds the sealed prompt union:

| Prompt | Answer | Families |
|---|---|---|
| `NotePrompt` | choice or pitch | note reading |
| `StaffTapPrompt` | staff position | note reading |
| `FretTapPrompt` | string and fret | note reading, fretboard |
| `ChoicePrompt` | option id | theory, harmony, ear, technique, sight-reading, repertoire, improvisation |
| `OrderPrompt` | ordered token labels | theory, harmony |
| `RhythmPrompt` | timed taps | rhythm |

`ChoicePrompt.reveal` turns it into an unscored teach card. `ChoicePrompt.chord`
renders a fretboard diagram above the options. `ChoicePrompt.audio` carries a
`SoundSpec` for ear-training questions; the UI renders a replay button and the
synth in `core/audio/synth.dart` generates the WAV bytes locally.

`core/learning/verifier.dart` owns one verifier per answer type. Taps on the
staff compare diatonic indices, fret taps accept any valid position for the
written note, and rhythm taps are graded against the pattern onsets with a
0.28-beat tolerance.

`features/exercises/prompt_view.dart` renders every non-note prompt. The lesson
screen keeps the note-reading UI and delegates the rest.

`features/lesson/lesson_layout.dart` owns the lesson layout. The lesson is a
single centred column (max 640 px) at every width, following Duolingo's web
lesson. The question scrolls at the top; the answers (or the teach card's
`GOT IT`) sit in a bottom dock with a top border. Only the dock is wrapped in
`SafeArea`, so the iPhone home indicator never covers a control and the page is
not inset twice. The top bar uses the same 640 px column: close on the left
edge, hearts on the right edge, progress bar edge to edge, caption centred.
`shared/widgets/hover_region.dart` adds a pointer cursor and hover state to any
surface. `shared/theme/motion.dart` is the single source of durations and
curves, and `shared/navigation/duo_route.dart` opens a lesson with a fade plus a
97% scale. The lesson uses `PageTransitionSwitcher` (shared-axis horizontal)
from the `animations` package for question changes.

### Adding a topic

The engine is designed so a new topic is additive:

1. Add objective ids and builders in `lib/content/<topic>/objectives.dart`.
2. If the answer surface is new, add a `Prompt` subclass in
   `lib/core/learning/prompt.dart` and an `Answer`/`Verifier` pair in
   `lib/core/learning/verifier.dart`.
3. Add `ExerciseTemplate`s in `lib/content/<topic>/templates.dart`, declaring
   family, roles, answer mode, and required `Capability`.
4. Register the templates in `lib/content/packs.dart`.
5. Render the prompt. `LessonScreen` reads prompts through `LessonRun.current`
   and already routes answers through `PromptVerifier`.
6. If the topic selects its own material, add a factory beside
   `buildLessonExercises` in `content/session_factory.dart`.

No change to `SessionComposer`, `SessionShape`, or `SessionValidator` is needed
for steps 1–4. If a new topic forces a change there, fix the abstraction before
adding the second template.

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

### Ear-training audio

Ear-training questions carry a `SoundSpec` (notes, intervals, chords,
progressions, or melodies). `core/audio/synth.dart` renders it to a small PCM16
WAV with a plucked-string timbre. `shared/audio/audio_engine.dart` plays the
bytes; widget tests override the engine. Audio is stopped before any microphone
exercise starts.

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

## Path performance

The path is the heaviest screen, and it runs on mobile Safari through CanvasKit,
where every frame is painted to a canvas. Keep it cheap:

- No blurred shadows or `MaskFilter` on the path. Use hard offset shadows
  (`blurRadius: 0`). A blurred shadow per node is re-rasterised on every scroll
  frame.
- No per-node entrance animations. Nodes build as they enter the cache extent,
  so an opacity animation started mid-scroll is jank.
- No opacity animations on large surfaces. Fading a page, a column, or a panel
  forces `saveLayer` per frame. Use a translate with a `RepaintBoundary`
  (`SettleIn`) instead. The lesson route, question change, and bottom dock are
  all transform-only.
- Each unit path, lesson node, chest, and pinned unit banner sits inside a
  `RepaintBoundary`. Scrolling then translates cached layers instead of
  repainting every gradient.
- `CustomPaint` glyphs and chests set `isComplex: true` so they can be cached.
- The scroll view prefetches 800 px (`ScrollCacheExtent.pixels(800)`) so the
  next unit is built before it slides into view.

If scrolling still stutters, profile with Safari Web Inspector before adding
more layers. A Flutter canvas will not match native DOM scrolling; the goal is
to keep the painter cheap, not to chase a frame budget the renderer cannot hit.

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
`schemaVersion` in `[1, currentSchemaVersion]`. `currentSchemaVersion` is 4.
Version 1 documents load with default economy values (500 gems, five hearts,
no chests or quests); version 2 adds the System appearance; version 3 documents
migrate note boxes into skill cards. Future versions are rejected rather than
partially parsed.

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
| `test/session_factory_test.dart` | All lessons, teach cards, choices, modes, ordering, pacing |
| `test/composer_test.dart` | Family-agnostic composer, determinism, core/content layering |
| `test/topics_test.dart` | Template rotation, theory/chord/rhythm prompts, verifiers |
| `test/prompt_view_test.dart` | Staff tap, fret tap, chord diagram, rhythm view at 390 px |
| `test/placement_flow_test.dart` | A placed note grades, shows feedback, and advances |
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
