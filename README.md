<div align="center">

# Hear Me Out

### Read music. Play guitar.

A year-long guitar musicianship trainer with a Duolingo-style course path, real
microphone pitch feedback, ear training, and spaced review across every skill.
Everything stays on your device.

</div>

---

## Project management

The approved transformation plan and the full work breakdown live in Plane:

- **Project:** [Hear Me Out — Guitar Practice OS](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780)
- **Start here:** [D0.1 — START HERE](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/3bc42073-d36c-48df-b7bc-27ad89338ac7)
- **Operating manual:** [`docs/PLANE.md`](docs/PLANE.md)
- **Local canonical plan:** [`docs/TRANSFORMATION_PLAN_FINAL.md`](docs/TRANSFORMATION_PLAN_FINAL.md)

The app in this repository is still the 240-lesson notation course. The approved
plan changes it into a 5-minute, song-first practice system; those changes are
planned in Plane and are not implemented yet. Do not describe planned features as
shipped.

## Mission

**Help a beginner become a confident guitarist and musician through short,
forgiving daily practice: reading, rhythm, chords, harmony, ear training, and
repertoire.**

Hear Me Out is built for people practicing alone on a phone, with or without a
microphone. A session should fit into a few spare minutes, every answer should
teach something, and progress should mean real recall rather than a lucky
streak. The app stays private, guitar-correct, and free of social pressure.

## What it is

Hear Me Out teaches you to read standard notation on guitar. Each lesson shows a
note on a treble staff and asks you to either **name it** or **play it**. The
microphone listens to your guitar, detects the pitch, and tells you whether you
hit the note, missed it, or played the right note in the wrong octave.

- **240 lessons across 40 units in 8 sections** — a year-long guitar course:
  foundations, reading fluency, rhythm and groove, chords and harmony, fretboard
  and scales, ear training and theory, intermediate repertoire, and mastery.
  Every unit has six lessons: Discover, Build, Connect, Apply, Integrate, and a
  checkpoint.
- **One schedule for every skill** — notes, rhythm, chords, theory, ear training,
  fretboard, technique, and repertoire each have their own FSRS-style memory
  state. Due and fragile skills return in Smart review, not just notes.
- **Play or name** — every note can be answered by tapping its name or by
  playing it. If the mic is unavailable, the app falls back to naming.
- **Guitar-correct notation** — written pitch is one octave above sounding
  pitch. The staff, the microphone target, and the string/fret hints all respect
  that.
- **Real spaced repetition** — a skill is mastered only after spaced correct
  answers across at least three days, with production and transfer evidence.
  Wrong answers trigger a repair chain, not a single end-of-lesson retry.
- **Duolingo-style path** — section and unit banners, a winding lesson map,
  guidebooks, streak / gem / heart counters, chests, jump-ahead tests, daily
  quests, and a five-heart pool. No fake leaderboards or leagues.
- **A voice of its own** — original marimba/bell/woodblock cues for correct,
  wrong, combo, lesson, practice, streak, goal, and level-up moments, with a
  persisted sound-effects setting.
- **Working tuner** — standard E–A–D–G–B–E tuning with live pitch and cents.
- **Local-only progress** — `shared_preferences` on the device. No accounts, no
  remote analytics or third-party trackers, no network calls, no cloud database.
  The only usage log is local, opt-in, bounded, and eraseable.
- **Backup by clipboard** — export your progress as JSON and restore it later.

## Screens

- **Learn** — a Today card, an eight-section course map, winding unit paths,
  guidebooks, checkpoints, jump-ahead tests, and streak / gem / heart / XP
  progress.
- **Lesson** — staff, fretboard, chord, rhythm, and ear-training questions with
  real feedback and a mastery gate.
- **Practice** — a standard-tuning guitar tuner plus Smart review across every
  skill family, due review, weak skills, and free practice. Practice never
  spends hearts and restores one.
- **Quests** — three local daily quests that pay gems.
- **Shop** — heart refills, streak freezes, and double XP, bought with earned
  gems only.
- **Profile** — real stats, per-note box progress, settings including a
  System/Light/Dark appearance, backup/restore, and reset.

The app is phone-first. At 900 px and wider it uses a left side rail and a
wider centered content column; below that it uses five bottom tabs. At roughly
1200 px and wider the learn page adds a quest rail that scrolls with the path.

## Run it

Requirements: Flutter 3.47 or newer with Dart 3.13+.

```bash
cd flutter_app
flutter pub get
flutter run
```

For a browser build:

```bash
flutter build web --release
```

Microphone access:

- **Android:** `RECORD_AUDIO` permission is declared in the manifest.
- **iOS:** `NSMicrophoneUsageDescription` is declared in `Info.plist`.
- **Web:** microphone access requires `localhost` or HTTPS.

The app works without a microphone, but the play exercises become naming
exercises.

## Test it

```bash
cd flutter_app
flutter analyze
flutter test
```

The suite covers:

- MIDI/frequency/cents conversions and note parsing
- intervals, key signatures, scales, chords, progressions, and guitar transposition
- staff geometry and ledger lines for every curriculum note
- the FSRS-style skill scheduler, mastery, fragility, and repair ratios
- session composition for all 240 lessons, including review quotas, five
  exposures, checkpoints, and mistake retries
- curriculum migration from the old 40-lesson layout and schema 1–3 to schema 4
- local WAV synthesis for notes, intervals, chords, and progressions
- YIN pitch detection on synthetic guitar tones, harmonics, decay, silence, and
  noise
- PCM16 decoding, 44.1/48 kHz resampling, mono/stereo downmix, and chunk
  boundaries
- note matching, cents tolerance, octave errors, and re-arming
- JSON persistence, corrupt-storage fallbacks, and a simulated app restart
- onboarding, path, lesson, quests, shop, practice, profile, and responsive-shell
  widget flows
- hearts, gems, chests, daily quests, streak freezes, double XP, and jump-ahead
  tests

### Device checklist

Synthetic audio tests cannot prove real microphone accuracy. Before shipping,
run the app on a physical phone with a guitar and check:

1. The tuner identifies all six open strings and shows small cents error.
2. A correct lesson note advances; a wrong note is rejected; an octave error is
   called out specifically.
3. Playing the same note twice in a row works after a short mute.
4. Ambient noise does not trigger an answer.
5. Denying microphone permission falls back to note names without crashing.
6. **Pending — needs physical-device evidence.** On a 48 kHz-only device and on
   a device that negotiates stereo, the tuner and lessons still read the correct
   pitch (not ~8.8% high). Synthetic tests cover the decode/resample path, but
   this checklist item is not yet verified on hardware.
7. Killing and reopening the app restores XP, streak, skills, and note boxes.
8. **Pending — needs physical-device evidence.** After T4.2 adds recording,
   record a take, run an Android Auto Backup, an Android device-transfer target,
   and an iCloud backup, and confirm the `media/` directory is absent from each.
   Source tests prove the rules and resource-value call exist; only a device
   backup proves the OS honored them.

Build an APK or app bundle with `flutter build apk` or `flutter build appbundle`
on a machine with the Android SDK, or use `flutter run` with a connected device.

## How it works

```
flutter_app/lib/
├── core/
│   ├── music/        note math, guitar transposition, curriculum
│   ├── learning/     scheduler, session builder, progress model
│   ├── audio/        YIN detector, PCM capture, note matcher
│   ├── notation/     staff geometry + Bravura painter
│   └── storage/      shared_preferences progress store
├── features/         onboarding, path, lesson, practice, profile
├── shared/           Duolingo-style theme and widgets
└── state/            Riverpod app controller and audio provider
```

The learning engine is pure Dart and independent of widgets. The pitch detector
is also pure Dart and tested without a microphone. That keeps the hard parts
verifiable.

See [LEARNING_ALGORITHM.md](LEARNING_ALGORITHM.md) for the scheduling and
session rules.

## Docs

- [AGENTS.md](AGENTS.md) — operating guide for coding agents
- [docs/PLANE.md](docs/PLANE.md) — Plane project manual, MCP access, read order, update protocol
- [docs/TRANSFORMATION_PLAN_FINAL.md](docs/TRANSFORMATION_PLAN_FINAL.md) — approved v3.1 transformation plan
- [docs/CONTENT_CALENDAR.md](docs/CONTENT_CALENDAR.md) — 24-month content supply, cost model, break-even, and the subscription-to-piece-pack gate (T3.9)
- [docs/DESIGN.md](docs/DESIGN.md) — mission, Duolingo-style design language, copy, gamification
- [docs/SOUND.md](docs/SOUND.md) — Bright Pluck sound family and event map
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — layers, data flow, invariants
- [docs/decisions/0002-backup-exclusion-no-opt-in.md](docs/decisions/0002-backup-exclusion-no-opt-in.md) — no V1 backup opt-in and the T4.2 gate
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) — setup, debug, manual checks
- [CONTRIBUTING.md](CONTRIBUTING.md) — contribution workflow

## Privacy

- The microphone is active only during a lesson, practice, tuner, or recording
  session. Audio is analyzed on the device for feedback and is never uploaded.
- Progress is stored in `shared_preferences` on the device.
- Recording follows a local-only model (the recording UI arrives in T4.2). When
  you record a take, the audio is stored only on the device. Android Auto Backup
  and device transfer exclude the recording directory through manifest rules.
  On iOS the app asks iOS to exclude the directory from iCloud backup; the
  profile card says when iOS could not confirm that, so a take may then be
  included in device backup. The app never claims exclusion without that
  confirmation.
- T4.2 adds the recording, delete, and export controls. When it lands, a take
  will leave the device only through an explicit export you start, and deleting
  a take will remove it from the device.
- There is no Firebase, no Firestore, no auth, no remote analytics or
  third-party trackers, no account, no cloud sync, and no network persistence
  layer. The only usage log is local, opt-in, bounded, and eraseable; see
  [`docs/RETENTION_INSTRUMENTATION.md`](docs/RETENTION_INSTRUMENTATION.md).
- The shop is a closed gem economy. It takes no money and has no subscriptions
  or ads.
- The only way progress leaves the app is if you copy a backup JSON to your
  clipboard.

## Limitations

- Guitar only in this version. The note model is ready for other instruments,
  but the curriculum and string hints are guitar-specific.
- No accounts or cross-device sync by design.
- No social leagues, friend duels, ads, or subscriptions.
- Web microphone support depends on the browser's PCM stream support.

## Credits

- Pitch detection: YIN (de Cheveigné & Kawahara, 2002), implemented in Dart.
- Notation font: [Bravura](https://github.com/steinbergmedia/bravura), SIL Open
  Font License.
- UI font: [Nunito](https://github.com/googlefonts/nunito), SIL Open Font
  License.
- Built with Flutter, Riverpod, the `record` plugin, and
  `shared_preferences`.

## License

MIT. See [LICENSE](LICENSE).
