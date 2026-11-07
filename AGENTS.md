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

## Issue tracking and source of truth

All product direction, work breakdown, research, decisions, risks, and delivery
status live in Plane:

- **Project:** Hear Me Out — Guitar Practice OS
  <https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780>
- **START HERE:** `D0.1` —
  <https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/3bc42073-d36c-48df-b7bc-27ad89338ac7>
- **Operating manual:** [`docs/PLANE.md`](docs/PLANE.md)
- **AI handoff protocol:**
  [`docs/AI_HANDOFF_PROTOCOL.md`](docs/AI_HANDOFF_PROTOCOL.md)
- **Approved plan:** [`docs/TRANSFORMATION_PLAN_FINAL.md`](docs/TRANSFORMATION_PLAN_FINAL.md)

A project-scoped MCP server named `plane` is configured for OpenCode
(`opencode.json`), Claude Code / Codex / generic MCP (`.mcp.json`), VS Code
(`.vscode/mcp.json`), Cursor (`.cursor/mcp.json`), and Gemini CLI
(`.gemini/settings.json`). Each runs
`uvx --from ./tools/plane_mcp_ce plane-mcp-server-ce-fixed stdio` with the
self-hosted host, workspace slug, and API
key in its `env` block. This is a private single-user repository, so the key is
committed on purpose. Verify with `opencode mcp list`; it must show
`plane connected`.

**Before changing code:**

1. Read `docs/PLANE.md` and `docs/AI_HANDOFF_PROTOCOL.md`.
2. Open `D0.1 — START HERE`; read `D0.2`–`D0.5`.
3. Open the ticket for your task and read its acceptance criteria.
4. Check `blocked_by`; do not start blocked work. Move the ticket to
   **In Progress**.

**After changing code:**

1. Run `flutter analyze`, `flutter test`, and `flutter build web --release`.
2. Comment on the ticket with files, commands, results, and device/mic evidence.
3. Move to **Done** only when every acceptance criterion is met.
4. Update the decision log (`T9.2`) or risk register (`T9.1`) if the change
   changes a decision or risk. When an experiment changes an assumption, update
   [`docs/ASSUMPTION_TRACKER.md`](docs/ASSUMPTION_TRACKER.md) with the evidence
   link and the confidence change.
5. In the weekly review, update risks, decisions, cycle status, and the START
   HERE status using [`docs/WEEKLY_REVIEW.md`](docs/WEEKLY_REVIEW.md). The
   review is not skipped during a busy build week.
6. Before a phase-gate review, use the evidence checklist in
   [`docs/PHASE_GATES.md`](docs/PHASE_GATES.md). A merge, a green suite, or an
   agent summary is not gate evidence.

The current code is still the **240-lesson notation course**. The approved
transformation is planned but not implemented. Do not describe planned features
as shipped. If Plane and local docs disagree, Plane wins; update both and record
the reason in `T9.2`.

- Plane is development tooling only. Never add Plane, network, or cloud code to
  the app itself.
- If a tool call fails with 401, replace `PLANE_API_KEY` in the MCP config files
  with a fresh workspace-scoped token from Plane profile settings. Do not paste
  the key into tickets, chat, logs, or screenshots.

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
path nodes, an optional streak counter, and a responsive side rail
on wide screens. Keep the mascot and all artwork original; do not copy the owl,
proprietary
illustrations, font files, or trademarked assets.

- Bright white background, `Nunito`, heavy `w700`/`w800` text, thick outlines,
  rounded corners, and hard offset shadows with blur `0`.
- Use `AppColors` and the shared widgets (`DuoButton`, `OutlineDuoButton`,
  `SectionCard`, `AnswerOption`, `FeedbackPanel`, `Mascot`, `PageFrame`) before
  inventing new styles.
- Green = primary/success and Foundations; purple = First Position and free
  practice; blue = info/secondary and Accidentals; red = error; yellow =
  reward/progress.
- Primary buttons default to 56 px tall, uppercase, radius 16, with a visible
  bottom edge and a 3 px press movement; compact variants use 48–54 px. Answer
  options are 64 px tall.
- Content stays in a centered responsive column (600 px for path and lessons,
  720 px for hubs) and must fit a 390×844 viewport. Widths at or above 900 px
  use a 232–256 px side rail; narrower widths use four bottom tabs that take
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
  purchases, gems, chests, shops, XP boosts, or fake stats. Quests describe
  musical actions and award nothing.

Full palette, typography, component dimensions, motion, screen intent, copy
tone, accessibility notes, and non-goals are in
[`docs/DESIGN.md`](docs/DESIGN.md). Read it before changing UI.

## Hard rules

1. **No network, cloud, accounts, remote analytics, or third-party trackers in
   the app.** The only usage log is local, opt-in, bounded, and eraseable; it is
   documented in [`docs/RETENTION_INSTRUMENTATION.md`](docs/RETENTION_INSTRUMENTATION.md).
   Progress lives in `shared_preferences`. Recordings live in the local media
   store, are never uploaded, and are excluded from cloud backup only when the
   platform confirms it; the UI must say when that confirmation is missing. The
   microphone is active only during a lesson, practice, tuner, or recording
   session. Plane is development tooling only and is never imported by the app.
   The Phase 2 teacher channel is gated by
   [`docs/COPPA_GUARDIAN_CONSENT_PLAN.md`](docs/COPPA_GUARDIAN_CONSENT_PLAN.md).
   Do not add teacher, student-roster, minor, account, upload, or public-recital
   paths until its gates are cleared; the teacher channel is not in the base
   case. Legal clearance for it is human-owned; an agent must not claim it.
2. **Keep `lib/core/` free of widgets.** Music math, scheduling, pitch
   detection, and staff geometry must stay pure Dart and testable.
3. **Written pitch is not sounding pitch.** Guitar notation is written one
   octave above sounding pitch. Use `Guitar.soundingMidiForWritten`.
4. **There are no hearts and no currency.** Lessons and practice never spend or
   restore a life. A wrong answer only lowers accuracy and queues the
   pedagogical repair. The habit signal is a weekly minutes goal; the streak is
   optional and resets quietly. Do not reintroduce a loss-based gate. V1 has no
   gems, chests, shop, XP boosts, or paid streak freezes; quests describe
   musical actions and award nothing.
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
10. **Plane is the source of truth for product work.** Before coding, read
    `docs/PLANE.md`, `D0.1 — START HERE`, and the ticket's acceptance criteria.
    Update the ticket with evidence and status. Do not implement unplanned
    surfaces or reopen settled decisions without a new decision record.

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
| `flutter_app/lib/core/notifications/` | Pure reminder copy, schedule seam, and weekly recap (no widgets) |
| `flutter_app/lib/core/storage/` | JSON progress store and backup validation |
| `flutter_app/lib/features/` | Onboarding, path, lesson, practice, recordings, quests, profile |
| `flutter_app/lib/shared/` | Theme and reusable Duolingo-style widgets |
| `flutter_app/lib/state/` | Riverpod app controller and audio providers |
| `flutter_app/test/` | Unit and widget tests; fakes live in `test/support/` |
| `docs/PLANE.md` | Plane project manual, MCP access, read order, update protocol |
| `docs/TRANSFORMATION_PLAN_FINAL.md` | Approved v3.1 transformation plan |
| `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` | Client-specific entry points to `AGENTS.md` and Plane |
| `tools/plane_bootstrap.py` | Idempotent Plane bootstrap: docs, tickets, links, comments |
| `tools/plane_relations.py` | Creates the `blocked_by` dependency graph |
| `tools/plane_assign*.py` | Assigns tickets to modules and cycles |
| `.mcp.json`, `opencode.json`, `.vscode/mcp.json`, `.cursor/mcp.json`, `.gemini/settings.json` | Plane MCP client configuration |

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
- **No hearts:** there is no heart pool, regeneration timer, refill, or
  out-of-lives failure. A lesson always reaches its result; wrong answers lower
  accuracy and queue the repair, never a life.
- **Weekly goal:** `settings.weeklyGoalMinutes` defaults to 30 and is the primary
  habit signal. Progress is summed from real measured session seconds in the
  rolling seven-day window. XP remains an internal progress number and is not
  the habit goal. A fresh profile reads 0.
- **Practice reminder:** `settings.reminderEnabled` defaults to false,
  `settings.reminderHour`/`reminderMinute` default to 19:00. The reminder is a
  local notification only; there is no push service, account, or network call.
  Quiet hours are 21:00–07:59, so the settings UI only accepts 08:00–20:59. A
  denied permission keeps the switch off and shows a typed message. The
  scheduler lives behind a conditional import so web resolves to a no-op and
  never imports the platform plugin. Progress schema 9 adds these settings with
  defaults; a v8 save migrates without inventing a preference. Enabling the
  reminder records the local `reminder_opt_in` retention event. The Quests
  screen shows a weekly recap of real minutes, phrases, recordings, and one
  before/after pair; no lesson-completion percentage is used.
- **Gems and shop:** none. V1 has no gems, chests, shop, XP boosts, or paid
  streak freezes. Do not add a closed currency economy back; the V1 economy was
  removed by T5.5.
- **Musical quests:** play 3 determinate phrases (daily), record a take
  (weekly), and learn 4 bars (weekly). No claim step and no reward. Quests reset
  at local midnight or on the local Monday as appropriate.
- **Quest counters:** `quests.phrasesPracticed` increments once per determinate
  phrase attempt; `quests.recordingsMade` is incremented only by a real saved
  recording through `recordRecordingMade`, which the recordings screen calls
  once per saved take; `quests.barsLearned` counts the bars of each phrase with
  at least one correct determinate take this week, once per phrase. Prompt taps
  never count. Nothing else may mark the recording quest complete.
- **Jump ahead:** passing a 15-exercise test unlocks the sections before the
  target section without deleting note progress.
- **Curriculum migration:** bump `curriculumVersion` and map old lesson IDs;
  never silently drop completed lessons, XP, or note progress.
- **Phrase content versions:** phrase progress stays keyed by the stable phrase
  id. `Phrase.contentVersion` marks musical edits and
  `PhraseProgress.contentVersion` records the version the evidence was earned
  against. A content edit preserves every counter and marks the evidence for a
  re-test; it never resets or relabels old evidence. The phrase UI that will
  surface the re-test stays behind the T1.7 switch. A determinate phrase
  attempt records its raw evidence and its own repertoire skill, never
  per-note skills. `phrase:` skill ids resolve through the content registry,
  and unknown ids are skipped rather than crashing practice.
- **XP:** 10 normal lesson, 15 review, +5 perfect; replay 5, +3 perfect replay;
  practice 5; jump test 20. XP is an internal progress number, not a currency
  and not the habit goal; there is no multiplier or purchase.
- **Streak:** opt-in (`settings.streakEnabled`, default false). Any local day
  with 3+ minutes of guitar time or one determinate recorded take advances it.
  A missed day reads as zero with neutral copy; there is no freeze, spending,
  or “you lost your streak” message.
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
- **Recording pipeline:** one live take at a time, never a second
  `AudioRecorder`. The recordings controller is auto-disposed with the route and
  stops/discards a live take on exit; the microphone must never stay on behind
  Practice. A save already in flight belongs to `stop()`: `cancel()` must return
  early while `_finishing`, and a disposed controller must not read its Ref. A
  take saved after the route closes keeps its piece/phrase ids and retention;
  the retention/quest hooks are skipped on that narrow path. 60 s per take, 20
  takes, 200 MB, first and last take per piece. The screen's optional
  launch-piece selector is the production path that supplies a `pieceId` for
  retention. WAV storage goes through `RecordingEncoder` (V1 is WAV, not AAC;
  see decision 0009). The manifest is the versioned
  `hear_me_out_recordings_v1` document, never `ProgressState`. Commit the new
  manifest before deleting retention victims; a failed manifest write must leave
  every older take intact. Permission, quota, and storage failures are typed and
  shown, not thrown into the UI. Reconcile removes unreferenced blobs and
  missing index entries but adopts media when the index is missing, unreadable,
  or partially malformed. Export copies bytes without deleting or changing the
  take. The screen shows the conditional backup copy; T4.2 made no A/B or
  before/after claim. T4.3 adds an in-memory loudness-matched A/B comparison:
  both takes are normalized to the same RMS before playback, the stored WAV is
  never rewritten, and a missing tempo is shown honestly rather than invented.

## Testing notes

- Pure logic belongs in `test/*_test.dart`; microphone/UI flows use
  `test/microphone_flow_test.dart`.
- `test/support/fakes.dart` provides `FakePitchSourceFactory` with
  `permission`, `startResult`, and `startGate` controls. Use `startGate` to test
  start/dispose races. It also provides `FakeReminderScheduler`, which records
  each daily schedule, cancel, and before/after request and returns controllable
  permission and typed results.
- Override `lessonGraceProvider` with `Duration.zero` in widget tests that emit
  frames immediately.
- If a widget is below the fold, call `tester.ensureVisible(finder)` before
  tapping it.
- The web app renders to canvas; browser accessibility snapshots require
  enabling Flutter semantics first if you inspect it manually.

## Current verified state

Last verified on 2026-11-06 with Flutter 3.47.9 / Dart 3.13.7:

- `flutter analyze` - no issues
- `flutter test` - 1038 tests passing
- `flutter build web --release` - succeeds
- `opencode mcp list` - `plane connected` (Plane project has 99 work items, 10
  modules, 10 cycles, 48 labels; `D0.1` is the START HERE ticket)
- The course has 8 sections, 40 units, and 240 lessons. Every unit has six
  lessons (Discover, Build, Connect, Apply, Integrate, Checkpoint).
- Notes, rhythm, chords, theory, ear training, fretboard, technique,
  sight-reading, repertoire, and improvisation all use the same FSRS-style
  skill scheduler.
- Web app loads, onboarding completes, the path renders the Today card and the
  optional streak counter, and lessons, quests, practice, and profile are
  reachable on narrow and wide layouts; System, Light, and Dark appearance all
  render with the Duo palette
- 27 original Bright Pluck cues are bundled in `assets/audio/`; ear-training
  stimuli are synthesized locally as WAV bytes and the soundboard is available
  at `flutter_app/tool/soundboard.html`
- The T2.5 phrase prompt, verifier, recorder, scored-take gate, and player
  screen exist, but `phraseLoopEnabled` is false and the screen has no
  main-navigation entry. No microphone-accuracy claim is validated.
- The T2.8 placement check is skippable and reachable from onboarding, a Path
  card, and the Profile starting-point card. Its versioned store is separate
  from progress; stages 6-8 map to 5 or 9 with a Phase 2 label, and the
  three-piece starter set comes from the real launch list.
- The T4.2 recordings screen is reachable from Practice. It records bounded
  PCM16 WAV takes locally (60 s/take, 20 takes, 200 MB, first and last take per
  piece), reconciles orphans against `hear_me_out_recordings_v1`, and supports
  local play, delete, clear-all, and export. T4.3 adds an A/B comparison reached
  when one piece has two takes. Both sides are normalized in memory to −20 dBFS
  RMS (peak-normalized below −60 dBFS, capped gain and ±0.98 sample ceiling)
  before playback; the stored take is never changed. V1 is WAV, not AAC
  (decision 0009), and recording quality is not validated on every device.
- T2.9 adds an opt-in local practice reminder with fixed quiet hours, a weekly
  recap card in Quests, and a before/after notification hook. Progress schema
  9 stores the reminder settings. The notification plugin is mobile-only
  behind a conditional import; web shows the setting as unavailable. Opt-in
  and session-2 lift are instrumented locally and remain pending a real beta.

Re-run the checks after any change. The test count will grow; treat the
analyze/test/build commands as the source of truth.

## Definition of done

- Behavior is covered by a test, including the regression that motivated it.
- `flutter analyze` and `flutter test` pass.
- `flutter build web --release` still succeeds for user-facing changes.
- Audio changes are checked against the device checklist in `README.md`.
- Docs are updated when a rule, setting, storage format, or workflow changes.
- The Plane ticket is updated with evidence and moved to Done only when its
  acceptance criteria are met.
- The CI workflow at `.github/workflows/flutter.yml` must be tracked by git for
  CI to run.

## Documentation map

- [`README.md`](README.md) — product overview, features, project link, device checklist
- [`docs/PLANE.md`](docs/PLANE.md) — Plane project manual, MCP access, read order, update protocol
- [`docs/ASSUMPTION_TRACKER.md`](docs/ASSUMPTION_TRACKER.md) — beliefs the plan depends on, weakest-first tests, and the experiment log
- [`docs/TRANSFORMATION_PLAN_FINAL.md`](docs/TRANSFORMATION_PLAN_FINAL.md) — approved v3.1 plan
- [`docs/DESIGN.md`](docs/DESIGN.md) — mission, Duolingo-style language, copy, gamification
- [`docs/SOUND.md`](docs/SOUND.md) — Bright Pluck family, assets, event map, settings
- [`LEARNING_ALGORITHM.md`](LEARNING_ALGORITHM.md) — scheduling and session rules
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — layers, data flow, invariants
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — setup, run, debug, common failures
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — contribution rules, Plane workflow, pull requests
