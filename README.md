<div align="center">

# Hear Me Out

### Read music. Play guitar.

A guitar note-reading trainer with a Duolingo-style lesson path, real microphone
pitch feedback, and spaced review. Everything stays on your device.

</div>

---

## What it is

Hear Me Out teaches you to read standard notation on guitar. Each lesson shows a
note on a treble staff and asks you to either **name it** or **play it**. The
microphone listens to your guitar, detects the pitch, and tells you whether you
hit the note, missed it, or played the right note in the wrong octave.

- **17 lessons across 4 units** — staff basics, first position, low strings, and
  accidentals.
- **Play or name** — every note can be answered by tapping its name or by
  playing it. If the mic is unavailable, the app falls back to naming.
- **Guitar-correct notation** — written pitch is one octave above sounding
  pitch. The staff, the microphone target, and the string/fret hints all respect
  that.
- **Real spaced repetition** — notes move through six boxes with due dates. A
  note is mastered only after five correct answers across at least two days,
  not after three lucky taps in one session.
- **Duolingo-style path** — streak, XP, daily goal, three lives per lesson, and
  a winding lesson map. No fake leaderboards.
- **Working tuner** — standard E–A–D–G–B–E tuning with live pitch and cents.
- **Local-only progress** — `shared_preferences` on the device. No accounts, no
  analytics, no network calls, no cloud database.
- **Backup by clipboard** — export your progress as JSON and restore it later.

## Screens

- **Path** — a winding lesson map with completed, current, and locked nodes,
  plus streak, XP, and daily-goal progress.
- **Lesson** — a treble-staff card, four note-name choices or a live mic meter,
  feedback with the correct string and fret, and three lives.
- **Practice** — a standard-tuning guitar tuner plus due-review, weak-note, and
  free-practice drills.
- **Profile** — real stats, per-note box progress, settings, backup/restore, and
  reset.

The app is designed for a phone. On tablets and desktop web it stays in a
centered 520 px column.

## Run it

Requirements: Flutter 3.47 or newer with Dart 3.10+.

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
- guitar written-vs-sounding transposition and first-position fingerings
- staff geometry and ledger lines for every curriculum note
- the spaced-repetition scheduler, streaks, and mastery rules
- session composition for all 17 lessons
- YIN pitch detection on synthetic guitar tones, harmonics, decay, silence, and
  noise
- note matching, cents tolerance, octave errors, and re-arming
- JSON persistence, corrupt-storage fallbacks, and a simulated app restart
- onboarding, path, and lesson widget flows

### Device checklist

Synthetic audio tests cannot prove real microphone accuracy. Before shipping,
run the app on a physical phone with a guitar and check:

1. The tuner identifies all six open strings and shows small cents error.
2. A correct lesson note advances; a wrong note is rejected; an octave error is
   called out specifically.
3. Playing the same note twice in a row works after a short mute.
4. Ambient noise does not trigger an answer.
5. Denying microphone permission falls back to note names without crashing.
6. Killing and reopening the app restores XP, streak, and note boxes.

This environment has Flutter and Chrome, but no Android SDK, so an APK was not
built here. Use `flutter run` with a connected device or install Android Studio
to produce one.

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

## Privacy

- Audio is analyzed in memory and discarded. Nothing is recorded or uploaded.
- Progress is stored in `shared_preferences` on the device.
- There is no Firebase, no Firestore, no auth, no analytics, and no network
  persistence layer.
- The only way data leaves the app is if you copy a backup JSON to your
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
