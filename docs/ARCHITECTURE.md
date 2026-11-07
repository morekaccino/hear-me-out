# Architecture

> **Status:** This document describes the current build: the 240-lesson
> notation course plus gated Phase 1 engineering (score model, phrase player,
> and Today session). The approved transformation plan lives in Plane (`D0.1 —
> START HERE`) and [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md);
> it is not shipped yet. Do not assume planned behavior is live.

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
│   ├── music/       Note, guitar transposition, score models, curriculum
│   ├── media/       MediaStore interface, file and IndexedDB stores, factory
│   ├── learning/    Objectives, prompts, templates, composer, LessonRun, PracticeSession
│   ├── audio/       YIN detector, PCM capture, note matcher
│   ├── notation/    StaffGeometry and StaffPainter
│   ├── retention/   Pure-Dart retention events, bounded log, funnel helpers
│   └── storage/     shared_preferences JSON store, export/import
├── content/         lesson material: objectives, templates, session factories
├── features/        onboarding, path, today, reading_lab, lesson, practice, quests, profile
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

## Score and media models (Phase 1)

The score model is present but not yet wired into the lesson UI, progress
storage, or phrase scoring. It is the domain contract for T2.2–T2.5, T3.2, and
T4.1. The phrase UI remains unreachable from main navigation until T1.7 passes
(decision 0001).

- `core/music/note_event.dart` — `NoteEvent` stores one timed note or rest.
  Notes carry both `writtenNote` and `soundingMidi`; the validator re-derives
  the sounding value with `Guitar.soundingMidiForWritten`. A note may carry an
  optional string/fret; rests may not carry pitch, position, or a tie.
- `core/music/phrase.dart` — `Phrase` holds bars, time signature, events,
  target tempo, skills, difficulty, start bar, an explicit `pickupBeats`
  value, and a `contentVersion` revision. V1 caps a phrase at 64 bars.
  `totalBeats` comes from the events; `expectedTotalBeats` comes from the bars
  and pickup. The validator compares them instead of rounding.
- `core/music/piece.dart` — `Piece`, `Tuning`, `TimeSignature`, and
  `LicenseStatus`. V1 is standard tuning (E2 A2 D3 G3 B3 E4), capo 0, and
  public-domain or original material. Nonzero capo is rejected with
  `piece.unsupportedCapo` until capo-aware pitch semantics exist; a
  non-standard tuning is a warning for future content.
- `core/music/score.dart` — `Score` is a piece plus phrases in performance
  order. `Score.validate()` returns every `ScoreIssue` from
  `MonophonicValidator`. V1 rules: one sounding note at a time, no chords or
  double stops, valid written/sounding pairs, position-consistent fingerings,
  bars that match the time signature (including an explicit pickup), adjacent
  ties with the same written/sounding pitch and position, unique phrase ids,
  bounded ranges, and no NaN/Inf.
- `core/music/score_parser.dart` — canonical JSON with `schemaVersion: 1`.
  `parseScore` is structural: it throws `FormatException` with a field path
  such as `phrases[0].events[2].soundingMidi`, ignores unknown fields for
  forward compatibility, and rejects future versions. `scoreToJson` emits the
  canonical document. Callers must call `Score.validate()` for musical rules.
- `core/media/media_store.dart` — `MediaStore`, `MediaRef`, and
  `MemoryMediaStore`. Recordings live in media storage, never in
  `ProgressState`. The interface is pure Dart; the persistent stores and the
  platform factory are described under [Media storage](#media-storage).

- `lib/content/pieces/launch_pieces.dart` — the locked 10-piece V1 launch list
  (5 Foundation, 5 Returner), their stage outcomes, and the legal questions.
  Metadata only; T3.3/T3.4 add the notes. See
  [`LAUNCH_PIECES.md`](LAUNCH_PIECES.md).

Tests live in `test/note_event_test.dart`, `test/phrase_test.dart`,
`test/score_test.dart`, `test/score_parser_test.dart`,
`test/launch_pieces_test.dart`, and `test/media_store_test.dart`; fixtures are
in `test/fixtures/score/`.

## Phrase player (T2.5)

The phrase player is built but gated. `features/phrase/phrase_loop_flag.dart`
holds the single compile-time switch, `phraseLoopEnabled = false`.
`phrasePlayerFor` returns null while it is false, and `HomeShell`, `PathScreen`,
and `PracticeScreen` have no phrase entry. Decision 0001 is binding: the screen
does not ship in navigation, and neither the screen nor this document claims
that microphone phrase scoring is validated. The screen shows a preview/no-claim
footer so a test build cannot be mistaken for released behavior.

- `core/audio/phrase_prompt.dart` converts a `Phrase` into the fixed click grid
  for `PhraseScorer`: sounding MIDI through `Guitar.soundingMidiForWritten`,
  onset seconds from the target BPM and count-in, duration seconds, and
  zero-based piece bars from `startBar`. Ties fold into one attack with a summed
  duration because a tied continuation has no new pluck. Rests and pickup beats
  keep the grid but do not become targets. `PhraseBackingSpec` is a small value
  object; `core` stores no audio bytes. `previewSpec` is a synthesized
  `SoundSpec` for the play button. The prompt never reads a clock.
- `core/audio/phrase_verifier.dart` calls `PhraseScorer.score` with the
  prompt's target notes, BPM, bar length, intonation tolerance, and count-in.
  It returns the tri-state outcome plus note accuracy, timing, completeness,
  worst bar, confidence, practice/performance flags, and exactly one correction.
  Bar detail is withheld when the mean note confidence is below 0.70. A missing
  or low-confidence note is an indeterminate retry, never "wrong". Incomplete
  takes report `updatesProgress == false`.
- `core/audio/phrase_recorder.dart` wraps the existing `PcmCapture` seam. It
  requests 48 kHz mono PCM16 with a 44.1 kHz startup fallback (stopping the
  failed capture first), follows the effective format callback, resamples to
  22.05 kHz with `Pcm16StreamDecoder`, flushes on stop, ignores late bytes, and
  disposes the capture once. It never starts a second capture while running.
  `phraseRecorderFactoryProvider` in `state/providers.dart` is the injection
  point; widgets never import `record`.
- `core/audio/scored_take_gate.dart` is the scored-take gate. A take may update
  phrase progress only when wired headphones are confirmed or a loopback
  `CalibrationReport` has both `timingUsable` and `offsetVerified`. Otherwise
  the screen records practice feedback, labels the take "Practice only", and
  never calls `recordPhraseResult`. The screen captures the gate state when the
  take stops, so a later headphones toggle cannot rewrite the saved/practice
  label.
- `features/phrase/phrase_player_screen.dart` is a responsive `PageFrame`
  surface at 390x844 and 1200 px. It shows the phrase title, level, tempo, bars,
  a note strip with bar/beat labels, a synth preview, a visual count-in,
  record/stop, status, the gate card, and one `FeedbackPanel` correction. It
  scores with `AppSettings.toleranceCents`, not a hard-coded 30-cent threshold.
  It has no hearts, XP, streak, quests, or other game chrome. Retry clears
  the result and re-arms the take. It also supports `recordProgress: false`
  with an `onTakeCompleted` callback, so Today owns the single recording and
  receives the real take correction, and `practiceOnly` for an unscored Acquire
  take.

The prompt is intentionally not part of the sealed `Prompt` hierarchy. The
lesson composer and lesson screen keep their existing behavior.
`phrasePlayerForPhraseId` resolves a stable phrase id through T2.11's
`PhraseObjectiveRegistry` in `content/pieces/phrase_objectives.dart`; there is
no second registry. The player passes `pieceId` and `Phrase.contentVersion`
into `recordPhraseResult`, so T2.11's versioned repertoire evidence is preserved.

Tests live in `test/phrase_prompt_test.dart`, `test/phrase_verifier_test.dart`,
`test/phrase_recorder_test.dart`, `test/scored_take_gate_test.dart`,
`test/phrase_loop_flag_test.dart`, and `test/phrase_player_screen_test.dart`.
The prompt and verifier tests load real arrangements through `parseScore`:
`ode-to-joy.json` for the fixed grid, `londonderry-air.json` for rests and a
two-beat pickup, and `amazing-grace.json` for a tie.

## Today session (T2.6)

Today is built but gated. `features/today/today_gate.dart` re-exports decision
0001's compile-time `phraseLoopEnabled` value as `todayEnabled`, so `HomeShell`
can choose the home surface without importing the phrase module. While the gate
is false, main navigation keeps `PathScreen` and has no Today destination; the
switch has no production "on" path. Tests construct `TodayScreen` directly or
use `HomeShell.withTodayForTesting()`, a `@visibleForTesting` constructor.

- `features/today/today_controller.dart` owns one T2.4 `PracticeSession`. It
  builds the target through `content/practice_session_factory.dart`, exposes
  5/10/20-minute selection, the maintenance-day extension, and clock methods
  (`start`, `tick`, `pause`, `resume`, `advance`, `finishEarly`,
  `resyncClock`, `restart`). Every timestamp comes from `todayClockProvider`;
  the controller never reads the wall clock itself. Returning to the tab
  re-bases the clock, so time spent elsewhere is not charged as guitar time. A
  completed session calls
  `AppController.recordTodayPractice`, which increments the existing daily
  practice counter and records measured guitar time through T2.10's
  `recordPracticeEffort`. That owns the weekly minutes goal and the optional
  habit streak; Today shows no XP, streak, quest, currency, or punishment.
  `instrumentElapsed` is the real guitar-in-hand time and is what the screen
  displays; the 5-minute plan has 3:30 of it.
- `todayPerformanceDayProvider` defaults to false, so an Apply take is practice
  only unless a caller explicitly marks a performance day.
  `todayScoredTakeGateProvider` wraps the T2.5 `ScoredTakeGate`. A phrase result
  is handed to `AppController.recordPhraseResult` only on a performance day,
  when it is complete and determinate, and when the gate is open; indeterminate,
  incomplete, non-performance-day, or gate-closed takes record nothing. The
  surface never promotes a take as a validated accuracy claim.
- `features/today/today_screen.dart` renders a responsive `PageFrame` column
  (720 px max) that fits 390x844 and 1200 px. The plan is a visible sequence:
  setup, technique, model, acquire, apply, reflect, then the maintenance block
  at the end when present. Each block states what to do, why, and its budget.
  The current block carries the start/continue control. The header shows guitar
  time and the stop point, and pause/stop/early-end controls make the end calm
  and explicit. There are no hearts, XP, streak, quests, currency, or fake
  metrics.
- `features/today/today_content.dart` resolves the one target for display. A
  note target gets a staff read-along card; a phrase target resolves through
  T2.11's `PhraseObjectiveRegistry`, never a second registry. The model block
  plays the phrase's synthesized `SoundSpec` or a synthesized note and labels it
  `SYNTH PREVIEW`; it says human reference recordings are not available yet.
  The technique block links to the existing T2.7 `TechniqueScreen` and shows
  only the existing 60-second drill data.
- The Apply block records only on a performance day and only through the T2.5
  gate. It opens the phrase player with `recordProgress: false` and an
  `onTakeCompleted` callback, so the take is recorded exactly once through
  `TodayController.savePhraseResult` and the reflect card receives the real
  `PhraseResult` and correction. Acquire opens the player in practice-only
  mode, which never saves progress. When the gate is closed or the phrase
  player is still gated, the block says the take is unscored practice. The
  reflect block asks for the 1-3 self-rating first, then shows one real metric
  (the last take's note accuracy or measured guitar time), one correction, and
  one next step. A correction that comes only from the self-rating is labelled
  `ONE CORRECTION · FROM YOUR RATING`, not presented as take evidence.

Session state is in memory; the durable facts are the measured seconds in
`ProgressState.practiceSecondsByDay` (through `recordPracticeEffort`) and phrase
evidence. There is no second goal system and no new storage shape. Tests live in
`test/today_session_test.dart` and `test/today_screen_test.dart`.

## Reading Lab (T2.12)

The original 240-lesson course stays in place as the optional Reading Lab. It is
a bridge for current learners, not the core Today loop.

- `features/reading_lab/reading_lab_entry.dart` holds `ReadingLabCard` (the
  Profile entry) and `ReadingLabEntry` (the compact Today entry). Both show the
  real `completedLessons.length` out of 240. The copy says "Structured reading
  practice, optional". The body adds the 5-minute Today complement only when
  decision 0001's gate is open; with the gate closed it says optional,
  self-paced practice instead of promising an unreachable loop.
- `features/reading_lab/reading_lab_screen.dart` pushes `readingLabRoute()` and
  hosts the existing `PathScreen` under a Reading Lab header. No lesson,
  curriculum, or progress object is copied. The path launches the same
  `LessonRun` and writes the same `ProgressState`. The header uses
  `pathContentColumnFor` from `path_screen.dart` so its title aligns with the
  path card, and the path runs with `showReadingLabLabel: false` so the screen
  does not repeat the label.
- Both the Today strip and the Acquire block's fallback `OPEN READING LAB`
  control open `readingLabRoute()`. The fallback is no longer wired to the
  Practice tab, so identical labels never open different destinations. Opening
  the lab pauses a running Today clock, and Back returns to the same surface.
- `HomeShell` keeps four tabs. When the gate is off, the first tab is `Learn`
  and is the path; its top card is labelled `READING LAB` so the course is not
  mistaken for the Today loop or for removed content. When the gate is on, the
  first tab is `Today`, and the Today body carries the compact Reading Lab entry
  below the session plan. Profile always shows the full card.
- There is no hearts, gems, XP, streak, or purchase gate on the Reading Lab.
  The curriculum's own content progression is unchanged: completed lessons
  reopen, only the current lesson is playable, and the section jump test
  unlocks earlier sections. That lock is content order, not an economy.
- `curriculum.dart`, lesson ids, storage, and migrations are untouched.

Tests live in `test/reading_lab_test.dart`. They pin the 240 lesson ids and the
40 unit ids; open the lab from Profile, the Today entry, and the in-plan Acquire
control; assert that completed lessons, XP, skill boxes, and weekly minutes
survive; browse a later unit without completing earlier lessons; assert the
absence of heart/gem/XP/streak gating; cover the header back control and the
running-session pause; check that the header aligns with the path at 1200 px;
and render at 390x844 and 1200x900 without overflow.

## Placement check (T2.8)

The placement check is a skippable, three-screen diagnostic for returners. It
never replaces the first lesson or phrase: onboarding still lands on the normal
path, and the Path keeps its **Continue** button above the optional placement
card. The placement entry sits below the Today/Reading Lab card; it never
replaces the Reading Lab entry.

- `features/placement/` owns the flow. Screen 1 is a three-item reading check
  built from existing `StaffTapPrompt` and `ChoicePrompt` data and rendered by
  `PromptView`. Screen 2 is one written note played into the existing
  `PitchSource`/`NoteMatcher` path. Screen 3 is a three-item technique
  self-check. Every screen has a skip action, and the header keeps **Skip for
  now** visible. The result is editable before it is saved.
- `core/learning/placement.dart` owns `PlacementRecord`,
  `inferPlacementStage`, `resolvePlacementStage`, `phase2StageFor`, the 35-day
  re-test interval, and the 14-day dismissal snooze. The inference starts from
  the onboarding `readingLevel` (note names 1, slow reader 2, comfortable 5),
  then nudges from the reading score, one played note, and the self-checks. It
  is clamped to stages 1-10 and only ever saved at a V1 stage.
- `content/pieces/placement_starters.dart` picks exactly three real launch
  pieces: the placed stage first, then the same tier by distance, then the
  other tier. It calls `launchPiecesByStage` / `piecesForStage` rather than
  keeping a second stage table. A Phase 2 suggestion is mapped to the nearest
  V1 stage (a tie goes lower); stages 6-8 land on 5 or 9 and the result copy
  labels the skipped stage **Phase 2**.
- `core/storage/placement_store.dart` stores one versioned document under
  `hear_me_out_placement_v1` (`schemaVersion` 1). Corrupt or future data is
  ignored. The store is deliberately separate from
  `hear_me_out_progress_v1`: saving placement never writes `ProgressState`, so
  completed lessons, note boxes, XP, minutes, streak, and phrase evidence
  survive.
- `state/placement_controller.dart` loads and saves the record and owns the
  re-test dismissal. The next re-test is 35 days (five weeks) after the save;
  dismissing the neutral prompt snoozes it for 14 days. Nothing is forced.
- Entry points are the onboarding piece screen link, a Path card when no
  placement exists or a re-test is due, and the Profile **Starting point**
  card. The Profile card is the manual override.
- `phraseLoopEnabled` is not read by the flow. With the gate off, placement
  uses the existing single-note/read-along checks and never mounts the phrase
  player or records a phrase take.

## Media storage

Media is a separate storage domain from progress. `ProgressState` holds no
media bytes or refs, backups never contain recordings, and clearing progress
does not delete media. `MediaStore` is the only contract the recording flow
uses: `put`, `get`, `delete`, `list`, `usageBytes`, and `clear`.

`MediaRef` carries the manifest for a take: id, mime type, byte length, creation
time, and optional piece id, phrase id, duration, analysis score, and analysis
version. The file index and IndexedDB records persist those optional fields when
present; older records without them load as nulls. `put` validates the manifest
on every store (non-blank piece/phrase ids, non-negative duration and analysis
version, finite score) and throws `ArgumentError` naming the field, so a value
accepted by `put` is always readable back.

Platform selection lives behind a conditional export in
`core/media/media_store_factory.dart`:

- `media_store_factory_io.dart` builds `FileMediaStore`. The app resolves the
  application support directory with `path_provider` and passes `<dir>/media`;
  `core/` never imports the plugin. Bytes live in `objects/<id>.bin`, metadata
  in `index.json`. Writes use a temporary file and rename, so a failed write
  leaves the previous recording intact. Invalid ids, orphans, and index entries
  whose file disappeared are handled explicitly.
- `media_store_factory_web.dart` builds `WebMediaStore`, which uses IndexedDB
  through `package:web` and `dart:js_interop`. Each record holds metadata plus
  the bytes in one object store. A missing or blocked IndexedDB raises a clear
  error; there is no silent memory fallback for real recordings.

`mediaStoreProvider` in `state/providers.dart` chooses the platform store and
is overridable in tests with `MemoryMediaStore`. It does not start a recorder.
The VM test runner cannot exercise IndexedDB, so
`test/web_media_store_test.dart` is browser-only and runs with
`dart test -p chrome test/web_media_store_test.dart` (also part of CI).

Backup exclusion is platform-enforced and surfaced to the UI:

- **Android:** `android/app/src/main/res/xml/backup_rules.xml` (Auto Backup on
  Android 11 and lower) and `data_extraction_rules.xml` (cloud backup and
  device transfer on Android 12 and higher) exclude `domain="file"` with
  `path="media/"`. `AndroidManifest.xml` wires them with
  `android:fullBackupContent` and `android:dataExtractionRules`.
  `path_provider` resolves `getApplicationSupportDirectory()` to `filesDir` on
  Android, and `mediaStoreProvider` appends `mediaDirectoryName` (`media`), so
  the rules cover `filesDir/media`. The shared constant and both rule files are
  checked structurally by `test/platform_backup_config_test.dart`; the
  provider and channel wiring are checked by `test/backup_exclusion_test.dart`.
- **iOS:** `mediaStoreProvider` calls `MediaBackupExclusion` before creating the
  store. `PlatformMediaBackupExclusion` invokes the
  `hear_me_out/media_backup_exclusion` channel; `ios/Runner/AppDelegate.swift`
  creates the directory if needed, sets `NSURLIsExcludedFromBackupKey`, reads
  the resource value back, and returns true only when it is set. A failure is
  logged and the store is still created, but nothing may claim the directory is
  excluded. A real iOS device check of the resource value remains human-owned;
  the automated test only reads the source files.
- **Web:** IndexedDB has no app-managed OS backup exclusion; storage is
  controlled by the browser.

`mediaBackupStatusProvider` exposes the `BackupExclusionResult` to the UI. The
profile privacy card uses `mediaPrivacyNote` in
`features/profile/privacy_note.dart`: it claims exclusion only when the result
is confirmed (an iOS resource value or Android manifest rules). A failed,
unsupported, or still-loading result says the app could not confirm the
exclusion and the take may be included in device backup. T4.2's recording flow
must read the same provider before presenting a take as private; decision
[`0002`](decisions/0002-backup-exclusion-no-opt-in.md) records the no-opt-in V1
choice and that gate.

Quota enforcement, delete/export UI, retention, and recording itself are
described in [Recording pipeline](#recording-pipeline-t42).

## Recording pipeline (T4.2)

Recording is a local-only second consumer of `MediaStore`. The recorder is the
same `PcmCapture`/`PhraseRecorder` seam used by phrase scoring; there is no
second `AudioRecorder` and no simultaneous record and stream.

- `core/media/recording_service.dart` owns one live take at a time. `start`
  returns a typed failure for a denied microphone, a busy recorder, a full
  quota, or a capture error. `stop` decodes once, truncates at 60 seconds,
  encodes through `RecordingEncoder`, writes the bytes, and updates the
  manifest. A 60-second timer stops the take automatically and marks it
  `capped`; samples beyond the limit are truncated even if the timer did not
  fire. The service takes a `MediaStore`, `RecordingIndexStore`,
  `RecordingExporter`, clock, recorder factory, and timer factory, so unit
  tests never touch a real microphone or wait 60 real seconds.
- `core/media/recording_encoder.dart` is the format seam. The only shipped
  implementation is `WavRecordingEncoder` (PCM16 WAV). It is **not** AAC.
  Decision [`0009`](decisions/0009-v1-recording-format.md) records why V1 stores
  bounded WAV and what a later cross-platform encoder must prove. T4.2 makes no
  recording-quality or codec claim.
- Quota and retention: 60 seconds per take, 20 takes globally, and a 200 MB
  global byte cap. The first and last take per piece are protected
  (`pieceTakeLimit` is 2). A new take for a piece deletes only middle takes;
  it never deletes the first take or the take just saved. The new manifest is
  committed **before** any retention victim is deleted, so a failed manifest
  write removes only the new blob and leaves every older take intact. A full
  global quota is a typed `RecordingFailureKind.quota` failure with a UI
  message and a delete action; the service never overwrites user data. A store
  failure leaves existing takes readable and indexes nothing new.
- `core/media/recording_index.dart` is a versioned document stored under
  `hear_me_out_recordings_v1` by `SharedPreferencesRecordingIndexStore`. It is
  separate from `ProgressState` and is not part of the progress backup.
  `reconcile` removes index entries whose blob is missing and deletes blobs the
  index does not reference. If the index is missing, unreadable, or partially
  malformed, the service adopts the existing blobs instead of deleting them.
  An unreadable document is copied to `hear_me_out_recordings_unreadable`
  before a recovered index can replace it. The recordings screen reconciles
  when it opens and has a manual **Check storage** action.
- `core/media/recording_exporter.dart` copies bytes without changing the stored
  take. IO writes under the app support `exports/` directory; web uses
  `package:web` to download the WAV. There is no share or cloud package.
- `core/audio/loudness.dart` measures RMS/peak and returns a new WAV with a
  capped gain and a shared peak limiter. `CompareTakesScreen` reads both takes,
  normalizes them in memory, and only then calls `TakePlayer`. Stored bytes are
  unchanged; a malformed take is a typed error, never a raw fallback. The screen
  shows the real date, take length, and target tempo only when the phrase
  registry resolves one.
- `state/recording_controller.dart` is auto-disposed with the recordings route.
  Its dispose stops and discards a live take, so the microphone never remains
  open behind Practice. A save already in flight is owned by `stop()`: `cancel`
  returns early while finishing, and a disposed controller does not read its
  Ref. A take saved after the route closes keeps its piece/phrase ids and
  retention; the retention/quest hooks are skipped on that narrow path. The
  controller exposes capture, list, delete, export, clear-all, and reconcile
  state. It records `first_recording` through `RetentionController` only after a
  take is saved, and calls the weekly `recordRecordingMade` quest counter once
  per saved take. `features/recordings/` renders the record/stop controls, an
  optional launch-piece selector, the take list with local play/export/delete,
  usage and cap, an empty state, and `MediaPrivacyCard`. The piece selector is
  the production path that makes first/last retention reachable.
  `PracticeScreen` opens the screen after stopping the tuner. The screen has no
  hearts, gems, XP, or streak, and it does not implement the T4.4 before/after
  card. The T4.3 comparison is a separate screen reached from the take list.
- Backup exclusion remains decision [`0002`](decisions/0002-backup-exclusion-no-opt-in.md):
  the screen shows the conditional `MediaPrivacyCard` copy and never claims
  exclusion when the platform did not confirm it.

Tests: `test/recording_service_test.dart` covers permission denial, the
60-second auto-stop and truncation, busy/no-second-capture, global and byte
quotas, disk failure with existing takes, a failed manifest write that keeps the
previous last take, delete/clear, export without mutation, first/last retention,
both reconciliation directions, and adoption of a partially malformed index.
`test/recording_index_store_test.dart`, `test/recording_exporter_test.dart`, and
`test/recordings_screen_test.dart` cover the versioned index, IO exports, the
390x844 / 1200 px screen with conditional privacy copy, route-exit microphone
shutdown, pop-while-saving with a gated store, and the piece-scoped retention
path.

## Take comparison (T4.3)

`core/audio/loudness.dart` is pure Dart. It parses PCM16 WAV bytes, measures RMS
and peak, applies a gain toward −20 dBFS RMS (or −1 dBFS peak below −60 dBFS
RMS), caps the gain at +18 dB and attenuation at −24 dB, applies a shared peak
limiter at ±0.98, and returns new bytes. A silent take is returned unchanged;
malformed bytes throw `LoudnessNormalizationException`; the stored blob is never
rewritten. `features/recordings/compare_takes_screen.dart` picks the oldest and
newest take for a piece (preferring a shared phrase), shows date, length, and
the registry's target tempo when available, and normalizes both sides in memory
before `TakePlayer.playWav`. Delete and export use the existing
`RecordingController` paths.

Tests: `test/loudness_test.dart`, `test/compare_pair_test.dart`, and
`test/compare_takes_screen_test.dart`.

## Before/after card (T4.4)

`core/media/before_after.dart` is pure Dart. It reuses the comparison pair
selection, groups takes by piece/phrase, and returns the first/latest take, the
take count, and the local-day span. A group with fewer than two takes returns
null; a free take (no piece id) is not a card. `features/before_after/before_after_card.dart`
renders piece, phrase, dates, and one metric (days apart) with a privacy line;
it never shows a score, grade, or public rank. `before_after_screen.dart` wraps
the card in a `RepaintBoundary`, renders PNG bytes, and writes them through the
existing `RecordingExporter` seam with `image/png` only after the explicit
export tap. The audio is not included. `recordingExporterProvider` is shared by
the recording service and the card so tests and production use one seam.

Tests: `test/before_after_test.dart` (pure) and
`test/before_after_screen_test.dart` (widget).

## First session (T5.2)

`features/first_session/first_session_screen.dart` owns a five-step, practice-only
flow pushed after onboarding: intro, hear, play, correction, 10-second record,
done. The phrase is the first four written notes of Ode to Joy (E5 E5 F5 G5,
string 1, first position). The play step uses `PhrasePlayerScreen` with
`practiceOnly: true` and `recordProgress: false`; the player exposes
`onVerification` so the flow can show the single correction without saving FSRS,
mastery, XP, or quest evidence. The recording step uses the existing
`RecordingController` (one live take, typed failures, 10-second timer, skip
path). The flow records the existing local funnel events (`first_note`,
`first_phrase`, `session_start`, `session_complete`, `daily_active`) and real
elapsed guitar time. It is not the scored phrase loop; decision 0001 still gates
that path.

## Local reminders and weekly recap (T2.9)

`core/notifications/reminder_copy.dart` is pure Dart: fixed quiet hours
(21:00–07:59), an allowed-time predicate, time formatting, and a real-task body
built from due notes and the weekly goal. `reminder_scheduler.dart` is the
platform seam; `reminder_scheduler_factory.dart` conditionally exports the IO
implementation (flutter_local_notifications + timezone) or a web no-op. The IO
implementation initializes the local timezone explicitly and refuses to schedule
if it cannot resolve one; it uses an inexact daily schedule, not exact-alarm
permission. `reminderSchedulerProvider` owns the instance.

`core/notifications/weekly_recap.dart` builds real minutes, phrases, recordings,
and one before/after pair from `ProgressState` and the recording index. The
Quests screen renders it; `recordingRecapTakesProvider` reads the index without
starting the recorder. `RecordingController` asks the scheduler for the
“before/after ready” alert only after a saved take makes a piece’s second take,
and only when reminders are enabled. The reminder settings are part of
`AppSettings`; progress schema 9 migrates a v8 document with reminders off.

## Retention instrumentation

The retention log is a separate, opt-in storage domain. `core/retention/` is
pure Dart: `RetentionEventName`, `RetentionEvent`, and a bounded `RetentionLog`
with `record`, `funnel`, `activeDays`, D1/D7/D30 helpers, and `exportJson`.
`core/storage/retention_store.dart` owns the `hear_me_out_retention_v1` key and
the schema. `state/retention_controller.dart` gates every write on opt-in and
wires the hooks in `AppController`, onboarding, and app resume.

The log has no audio, note names, piece titles, free text, account, device
fingerprint, or network path. It is not part of `ProgressState` or the progress
backup. The stored document pins `installAt` separately from the bounded event
list so trimming cannot move D1/D7/D30. Consent is offered on the first
onboarding screen and in Profile; both are off by default. See
[`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md) for the exact
event list, fields, export format, erase behavior, and the bias caveat, and
decision [`0006`](decisions/0006-local-retention-instrumentation.md) for the
change from the old "no analytics" rule.

## Progress and scheduling

`ProgressState` is the persisted domain aggregate:

- per-skill `SkillProgress`: stability, difficulty, due time, reps, lapses,
  correct/incorrect, correct-day set, production/transfer evidence, response
  time, level, fragile flag, cent samples
- per-phrase `PhraseProgress`: raw phrase-attempt evidence — memory state,
  correct and performance days, best tempo, best accuracy, and the phrase
  `contentVersion` the evidence was practiced against. It also stores optional
  performance-mastery evidence: `masteryDays` (local `yyyy-MM-dd` keys earned
  only by a correct, full-accuracy, at-target take), `firstMasteryDay`, and
  `lastMasteryAt`. Those three keys are written only when present and default
  empty on load, so no schema bump is needed. There is no storage-level mastery
  flag; T5.3 decides performance mastery from the mastery evidence.
- per-note `NoteProgress`: legacy boxes kept for the note chips
- completed lessons, checkpoints, and best accuracy
- XP, daily XP, optional streak, and `lastPracticeDay`
- `practiceSecondsByDay` (real measured guitar time)
- `quests`: daily phrase count, weekly recording count, and the learned-bars
  map for the current local week
- settings, including the opt-in reminder switch and its local time
- `curriculumVersion` plus a migration path from the old 40-lesson IDs
- last 30 session summaries

`SkillProgress.recordAnswer` is the scheduler. It applies the FSRS-6 model in
`core/learning/skill.dart`: stability, difficulty, and retrievability. Performance
skills are capped at 30 days of stability; declarative facts at 180 days.
Mastery requires at least 21 days of stability, four spaced reps, three correct
days, one production success, one transfer success, and a passed checkpoint.

`AttemptOutcome` is declared once in `core/learning/attempt_outcome.dart`.
`SkillProgress.recordAnswer`, `ProgressState.recordSkillAnswer`, and
`ProgressState.recordAnswer` return without changing anything for
`indeterminate`: no FSRS state, XP, streak, daily counter, combo, quest, or
mistake queue. A phrase take with any indeterminate note is incomplete and
records nothing, even if another note was confidently wrong. A determinate
phrase attempt records `PhraseProgress` and the phrase's own `repertoire` skill
through `ProgressState.recordPhraseAttempt`; per-note skills record only from
determinate note evidence, so one take cannot count twice. The phrase skill uses
the canonical `phrase:<pieceId>:<phraseId>` id when the caller knows the piece
and the legacy `phrase:<phraseId>` id otherwise. It schedules practice; it makes
no phrase-mastery claim, which remains T2.5 work.

Phrase evidence is keyed by the stable `Phrase.id`. `Phrase.contentVersion`
records the arrangement revision, and `PhraseProgress.contentVersion` records
the revision the evidence was earned against. A content edit replaces the
registered record but keeps the id and every stored counter. The intended
phrase UI compares the versions and asks for a re-test instead of treating old
evidence as proof of the unseen arrangement. No UI consumes `needsRetest` yet;
the phrase UI stays behind the T1.7 switch, and progress is never reset
silently.

`PhraseProgress.isPerformanceMastered(currentContentVersion)` is the only
can-play rule. It requires evidence from the current content version, at least
three separate local mastery days, and a first-to-last span of at least seven
calendar days. A mastery day enters `masteryDays` only from a correct take with
note accuracy `1.0`, a known played tempo, a known phrase target tempo, and
`tempoBpm >= targetTempoBpm`. Failed, slow, low-accuracy, indeterminate, and
target-less takes never contribute. `performanceDays`, `bestTempoBpm`, and
`bestAccuracy` remain raw high-water evidence and are never relabelled.

## Mastery map (T5.3)

`core/learning/mastery_map.dart` is a pure-Dart view model. It reads
`ProgressState`, a `PhraseContentCatalog` (implemented by the one
`PhraseObjectiveRegistry`, so `core` still does not import `content`), saved
`RecordingTake`s, and a supplied clock. It produces four honest sections:

- **can play** — phrases where `isPerformanceMastered` is true, with piece and
  phrase titles and target tempo from the registry, the latest mastery date,
  and the latest saved take for that phrase when one exists.
- **shaky** — due or fragile atomic note, rhythm, and interval skills, capped
  at five, with human-readable objective ids.
- **reading** — the count of mastered note and rhythm skills plus a few
  mastered entries; never a lesson-completion percentage.
- **next** — due atomic skills plus the first unmastered phrase in registry
  stage order. A phrase that is already can-play is never recommended again.

`features/mastery/mastery_map_screen.dart` renders those sections in a
responsive `PageFrame` at 390x844 and 1200 px. `features/mastery/
mastery_entry_card.dart` is the Profile entry above the settings. The screen
reads the shared `phraseRegistryProvider` and the existing recording controller,
uses `takePlayerProvider` and `readTake` for explicit playback (no autoplay),
and shows the exact empty state when no phrase has earned mastery. There are no
hearts, gems, XP, leaderboards, social comparison, or fake progress. The screen
is available while decision 0001 keeps the phrase loop gated; its can-play
section stays honestly empty until real phrase evidence exists.

A wrong answer is not just a box change: it queues a same-session repair, a
next-day repair card, and a 3-day recheck. Two lapses marks the skill fragile;
four marks it a leech.

Daily XP and the optional streak are calendar-day based; `dayKey` uses local
time. Musical quest counters reset in `refreshQuests`: the daily phrase count at
local midnight and the weekly recording and learned-bars counters on the local
Monday. There is no heart pool, regeneration timer, refill, streak freeze, gem,
chest, shop, or XP boost. The weekly goal sums
`practiceSecondsByDay` over a rolling seven-day window; only measured session
time is recorded, so a fresh profile reads zero. The optional streak advances
when a day has 3+ minutes of guitar time or one determinate recorded take. A
missed day renders as zero with neutral copy; the stored counters are not
punished and no resource is spent. All values are local and validated on load.
`sessionCompletionRate` and `returnRate` derive from `recentSessions` and real
practice days for local before/after comparison; nothing is sent anywhere.

`recordPhraseAttempt` advances `quests.phrasesPracticed` once per determinate
take. When the caller supplies the phrase's bar count, a correct take records
those bars for the phrase in the current week; a repeated take never adds them
twice, and a prompt tap never counts. `recordRecordingMade` is the only
producer of `quests.recordingsMade`. The recording flow (T4.2) has not shipped,
so the counter and its quest stay honestly at zero with a "coming with
recordings" note.

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

### Phrase objectives

`core/learning/phrase_objective.dart` defines the runtime contract
`PhraseObjectiveResolver`. `content/pieces/phrase_objectives.dart` implements it
with a mutable `PhraseObjectiveRegistry`. The app does not read authoring JSON
at startup, so the registry starts empty; a content loader registers parsed
`Score`s with `registerScore`. The session factory accepts an optional resolver
for tests and otherwise uses `phraseObjectiveResolver`.

A registered phrase gets the stable id `phrase:<pieceId>:<phraseId>` and the
`repertoire` family. Its objective data carries the piece id, phrase id,
current content version, practiced content version, re-test flag, stage,
difficulty, title, and the multiple-choice recognition surface the current
repertoire template renders. `_refsForSkills` resolves `phrase:` skill ids
through the registry, keeps the stored skill id (including legacy
`phrase:<phraseId>` ids) so scheduling never moves, and skips unknown ids. A
newer practiced version than the build contains also resolves to null rather
than substituting older notes. Note ids and static catalog ids take the
unchanged path. The phrase performance UI remains unreachable until T1.7
passes; this is practice-pool infrastructure.

`LessonRun` holds the mutable session state: index, correct/wrong, combo,
result feedback, and `isPractice`. It has no lives or failure resource. A wrong
answer queues the objective for a short end-of-lesson retry; distinct objectives
are capped at four. A lesson always reaches its result, where accuracy decides
the existing pass/fail feedback. `isJumpTest` runs a 15-slot section test and
unlocks earlier sections on a pass.

`PracticeSession` in `core/learning/practice_session.dart` is the separate
Today-loop aggregate. It owns one `ObjectiveRef` target, a computed 5/10/20
minute block plan, the maintenance-day extension, and clock-driven elapsed and
instrument time. Callers supply every timestamp through `start`, `pause`,
`resume`, `tick`, and `advance`; the aggregate never reads the wall clock and
never scores. The block roles are setup, technique, model, acquire, apply,
maintenance, and reflect. A five-minute session totals five minutes with three
and a half minutes of guitar time; a maintenance day extends it to six minutes
and adds a previously learned phrase last only when the builder found a learned
target. The ten- and twenty-minute plans always total their selected length: a
maintenance block is added when a learned target exists, and otherwise its time
goes to the application block. `advance()` deliberately does not invent time;
callers must tick first, or pass `now` to `advance`, for the time since the last
tick to count toward elapsed and instrument time. `LessonRun` remains the
Reading Lab and single-note lesson engine. `content/practice_session_factory.dart`
chooses the target from due, weak, and fragile skills and picks a learned
maintenance target; the core aggregate does not import content.

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
edge, the mode label on the right edge, progress bar edge to edge, caption
centred.
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
road between nodes. The path widget lays out the elliptical nodes and the active
START slot.

## Audio pipeline

```
record plugin -> PCM16 stream (requests 48 kHz mono, falls back to 44.1 kHz)
  -> setOnConfigChanged stores the effective sample rate and channel count
  -> Pcm16StreamDecoder: little-endian decode (keeps odd trailing byte)
  -> average all channels to mono
  -> linear resample to a fixed 22.05 kHz analysis rate
  -> 2048-sample analysis window, 1024-sample hop (~93 ms / ~46 ms)
  -> YIN detector
  -> PitchFrame (sampleIndex / sampleTime)
  -> NoteMatcher
```

`PitchFrame.timestamp` is for display and debugging only. Alignment, onset
detection, and phrase scoring use `sampleIndex` (monotonic analysis-sample
index) and `sampleTime` (`sampleIndex / analysisSampleRate`). Never use
wall-clock time for audio alignment.

`Pcm16StreamDecoder` is pure Dart and streaming. It keeps partial samples,
partial channel frames, and resampler history across chunks, so any chunking
of the same bytes produces the same output. If the platform reports a
different format after the stream starts, `RecordPitchSource` restarts the
decoder with the effective format and drops samples decoded before the
correction; the published sample clock never moves backwards.

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
- Before pushing a route that can play sound (a lesson or the technique
  self-check), Practice stops and disposes the tuner first.

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
- Each unit path, lesson node, and pinned unit banner sits inside a
  `RepaintBoundary`. Scrolling then translates cached layers instead of
  repainting every gradient.
- `CustomPaint` glyphs set `isComplex: true` so they can be cached.
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

- `OnboardingScreen` — welcome, explanation, optional mic check.
- `PathScreen` — lesson map, weekly goal, optional streak counter,
  jump-ahead tests, lesson launch.
- `TodayScreen` — gated 5/10/20-minute plan, one target, instrument timer,
  block sequence, reflection. Not reachable from main navigation while
  `phraseLoopEnabled` is false.
- `LessonScreen` — staff, name/play answers, feedback, result.
- `PracticeScreen` — tuner, due/weak/free practice, weekly goal, stats.
- `TechniqueScreen` — per-stage self-check, 60-second drill, demo script.
- `QuestsScreen` — a weekly recap card (real minutes, phrases, recordings, and
  one before/after), then the daily phrase, weekly recording, and weekly bars
  quests with real counters and no claim step.
- `ProfileScreen` — stats, weekly goal, optional streak, per-note boxes,
  settings, the opt-in local practice reminder, backup/restore, reset.

`TechniqueScreen` reads `lib/content/technique/technique_content.dart`. The
checklists are pure data: they do not touch the scheduler, storage, or mic, and
the drill/checklist state lives only in the screen's `State`.

`PageFrame` keeps content in a responsive centered column (600 px default,
720 px hubs). `HomeShell` owns five destinations and switches between a 256 px
side rail at 900 px and wider, and a five-item bottom bar below that. The learn
page places a 372 px quest rail beside the path at 1000 px and wider.

## Persistence

`SharedPreferencesProgressStore` stores one JSON document under
`hear_me_out_progress_v1`.

`ProgressState.toJson` / `fromJson` handle the full document. `importProgress`
and store loading go through `_decodeProgress`, which runs the pure migration
pipeline in `core/storage/progress_migrations.dart`. `currentSchemaVersion` is 9.

### Schema v9 migration pipeline

`migrateProgress` takes a decoded map and returns a `MigrationSuccess` with a
new map or a `MigrationFailure` with a reason. It has no IO, clock, or random
input, and it never mutates its argument. The steps are explicit:

| Step | Adds |
|---|---|
| v1 → v2 | historical default economy: 500 gems, five hearts, no chests or quests (removed again by v7/v8) |
| v2 → v3 | System appearance and the remaining `AppSettings` defaults |
| v3 → v4 | skill cards rebuilt from legacy note boxes when no skills exist |
| v4 → v5 | `contentVersion` (default 1), an empty `phraseProgress` map, re-applied `AppSettings` defaults, and a defensive skill rebuild when `skills` is empty |
| v5 → v6 | per-phrase `contentVersion` (default 1) for existing evidence; every phrase id and counter is preserved |
| v6 → v7 | remove `hearts`, `nextHeartAt`, `streakFreezes`, and the XP `dailyGoalXp`; map `lastCompletedDay` to `lastPracticeDay`; add `weeklyGoalMinutes` (default 30), `streakEnabled` (default false), and an empty `practiceSecondsByDay` |
| v7 → v8 | remove `gems`, `xpBoostUntil`, `openedChests`, `claimedQuests`, and `questDay`; add `quests` with empty day/week, zero counters, and an empty learned-bars map |
| v8 → v9 | add `reminderEnabled` (default false), `reminderHour` (default 19), and `reminderMinute` (default 0); the validator checks the bool and the 0–23 / 0–59 clock ranges |

A v9 document is returned as an equivalent new map, not migrated again. A v8
document gains the reminder defaults and keeps every other field. The
migration never invents practice minutes or quest progress: old saves have no
measured guitar time or phrase/recording/bars evidence, so the weekly goal and
the quest counters start at zero until the learner acts.
Unknown top-level fields are copied through and re-emitted by
`ProgressState.toJson`, so a newer build can add fields without an older build
deleting them. A known field always wins over an unknown field with the same
name. Unknown fields nested inside typed objects (`settings`, `notes`, `skills`,
one `phraseProgress` entry) are not preserved; only top-level keys are.

Future versions are rejected, not guessed. Missing or non-integer versions,
versions below 1, and malformed fields that a step or the current-shape
validator cannot interpret also fail. There is no partial save: `load` returns
null, `importProgress` returns null, and `ProgressState.fromJson` throws a
`FormatException` that the storage boundary catches. Before returning null for
an unreadable document, `SharedPreferencesProgressStore` copies the raw JSON to
`hear_me_out_progress_unreadable`. A later fresh-profile save therefore cannot
destroy a document written by a newer build; the recovery copy survives `save`
and `clear`. `PhraseProgress` stores raw attempt evidence only and does not
award mastery.

Backups are copied as pretty JSON via the clipboard. Restore validates first,
then replaces the state and saves it. Corrupt/missing storage falls back to a
fresh profile; an unreadable document is quarantined first.

## Test map

| File | Covers |
|---|---|
| `test/note_test.dart` | Parsing, MIDI, spelling, transposition |
| `test/guitar_test.dart` | Written/sounding transposition, fingerings |
| `test/note_event_test.dart` | NoteEvent timing, pitch pairs, JSON, field paths |
| `test/phrase_test.dart` | Phrase pickup math, notes/rests, JSON |
| `test/score_test.dart` | Score validator rules, error codes, capo/bar bounds, ties |
| `test/score_parser_test.dart` | Canonical score JSON, schema version, field paths, roundtrip |
| `test/media_store_test.dart` | MediaStore put/get/delete/list/usage/clear, purity |
| `test/file_media_store_test.dart` | File store atomic replace, ids, orphans, pruning, manifest, clock injection |
| `test/media_store_factory_test.dart` | Platform factory, required directory, provider override |
| `test/web_media_store_test.dart` | IndexedDB roundtrip, manifest, list/usage, delete/clear, malformed rows, closed state (Chrome) |
| `test/recording_service_test.dart` | Permission denial, 60 s auto-stop/truncation, busy guard, quotas, storage failure, delete/clear/export, first/last retention, orphan reconciliation |
| `test/recording_index_store_test.dart` | Versioned take manifest, future-version rejection, malformed entries, clear |
| `test/recording_exporter_test.dart` | IO export bytes/name and path traversal rejection |
| `test/recordings_screen_test.dart` | 390x844 and 1200 px, empty state, record/stop, play/export/delete, quota action, clear-all confirmation, auto-stop, conditional privacy copy |
| `test/staff_geometry_test.dart` | Staff positions, ledger lines |
| `test/scheduler_test.dart` | Boxes, intervals, mastery, XP, streak |
| `test/attempt_outcome_test.dart` | Tri-state no-ops, determinate scheduling, phrase evidence, retry feedback |
| `test/session_factory_test.dart` | All lessons, teach cards, choices, modes, ordering, pacing |
| `test/composer_test.dart` | Family-agnostic composer, determinism, core/content layering |
| `test/topics_test.dart` | Template rotation, theory/chord/rhythm prompts, verifiers |
| `test/prompt_view_test.dart` | Staff tap, fret tap, chord diagram, rhythm view at 390 px |
| `test/placement_flow_test.dart` | A placed note grades, shows feedback, and advances |
| `test/placement_diagnostic_test.dart` | Three skippable screens, stage inference and 6-8 mapping, starter set, manual override, re-test dismissal, progress survival, no phrase loop, 390/1200 layout |
| `test/yin_test.dart` | Synthetic guitar tones, harmonics, noise, silence |
| `test/note_matcher_test.dart` | Stable frames, tolerance, octave errors, grace |
| `test/progress_store_test.dart` | JSON round trips, storage, controller, practice |
| `test/progress_migration_test.dart` | v1–v8 fixtures, version rejection, phrase evidence and content versions, v7→v8 economy removal, quarantine/rollback |
| `test/phrase_objective_test.dart` | Runtime phrase resolver, due phrase practice, unknown ids, edited content and re-test |
| `test/phrase_progress_test.dart` | Mastery-day rule (correct, full accuracy, at target), three days over seven, stale versions, JSON round-trip |
| `test/mastery_map_test.dart` | Can-play selection, piece/phrase/tempo/date/recording mapping, shaky/reading/next, no duplicate recommendation, empty state |
| `test/mastery_map_screen_test.dart` | Profile entry, earned badge only, honest empty states, take playback, 390x844 and 1200 px, no lesson percentage |
| `test/widget_test.dart` | Onboarding, sectioned path, lesson, mic exercise, sound trigger |
| `test/path_layout_test.dart` | Path bounds, spacing, arc direction, and center anchors |
| `test/microphone_flow_test.dart` | Mic lifecycle, name-only practice, retry reset |
| `test/quests_test.dart` | Musical quest definitions and counters, honest recording quest, resets, jump tests, no currency |
| `test/reminder_copy_test.dart` | Due-note / weekly-goal / plain copy branches, no guilt words, quiet hours, time format |
| `test/weekly_recap_test.dart` | Real minutes, phrases, recordings, visible before/after selection, empty state |
| `test/reminder_scheduler_test.dart` | Fake schedule request, cancel, denied-permission no-op, typed failure, web no-op |
| `test/recording_reminder_test.dart` | First take silent, second take fires, reminders-off silent, one-piece scope |
| `test/reminder_profile_test.dart` | Toggle persist/schedule, denial path, quiet-hour rejection, 390/1200 px |
| `test/weekly_recap_widget_test.dart` | Recap real numbers, empty state link, 390/1200 px |
| `test/habit_test.dart` | Weekly minutes goal, optional streak, no-heart/no-shop UI, musical quests, measured session time, local completion/return |
| `test/retention_test.dart` | Event names, bound, funnel, D1/D7/D30, export fields, pure-domain imports |
| `test/retention_store_test.dart` | Opt-out default, round trip, corrupt/future data, bound, erase |
| `test/retention_controller_test.dart` | Opt-in gating, first-event dedupe, `reminder_opt_in` dedupe, AppController session hooks |
| `test/retention_profile_test.dart` | Default-off switch, toggle, copy, erase, 390 px and 1200 px layouts |
| `test/technique_test.dart` | Eight-stage coverage, 3/3 item counts, 60-second drills, demo scripts, pain warning |
| `test/technique_screen_test.dart` | Practice entry, tuner teardown, session-only state, drill timer, 390 px/wide layout |
| `test/phrase_prompt_test.dart` | Real corpus prompt conversion, onsets, bars, rests, pickup, ties, preview |
| `test/phrase_verifier_test.dart` | Clean/wrong/missing/extra/timing takes, one correction, confidence gate, no progress on indeterminate |
| `test/phrase_recorder_test.dart` | PCM collection, resampling, effective format, flush/stop, double start, dispose |
| `test/scored_take_gate_test.dart` | Headphones, verified clock, calibration gate, practice-only default |
| `test/phrase_loop_flag_test.dart` | Flag is off, gated entry returns null, no main-navigation entry |
| `test/phrase_player_screen_test.dart` | 390x844 and 1200 px, play/count-in/record/stop/correction/retry, gate, calm copy |
| `test/today_session_test.dart` | 5/10/20 plans, 3:30 guitar time, maintenance, supplied clock, no drift, early end, synth preview, phrase gate |
| `test/today_screen_test.dart` | Gated Today surface, block sequence and copy, instrument timer, reflection, 390x844/1200 px, HomeShell switch |

`test/support/fakes.dart` contains an in-memory store, controllable
`FakePitchSource` / `FakePitchSourceFactory`, and `FakeSoundService`. Use
`startGate` for async start/dispose races and override `soundServiceProvider`
in widget tests so platform audio is never touched.
