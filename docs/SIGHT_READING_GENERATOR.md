# Sight-reading generator and playability validator (T3.7 beta)

**Status:** Beta content tooling. Candidate-only. Not wired into the app
runtime, not shipped as assets, and not a claim of validated musical quality.
**Owner:** T3.7. **Depends on:** T3.2 authoring format and T3.6 reviewed etudes.
**Human review:** pending, owned by T3.8.

The 60 reviewed etudes in
[`SIGHT_READING_ETUDES.md`](SIGHT_READING_ETUDES.md) remain the stable core.
The generator produces **candidates**. A candidate becomes library content only
after a human pedagogue reviews it and records an approval. The generator never
writes to `flutter_app/assets/content/etudes/`.

Do not market the generator as unlimited. There is no validated claim about
generated musical quality, beginner playability, or coverage.

## 1. What ships in T3.7

| Surface | Path | State |
|---|---|---|
| Deterministic generator | `flutter_app/lib/content/sight_reading/etude_generator.dart` | Beta tooling |
| Level grammar | `flutter_app/lib/content/sight_reading/level_spec.dart` | Beta tooling |
| Seeded RNG | `flutter_app/lib/content/sight_reading/seeded_random.dart` | Stable for this beta |
| Approval gate | `flutter_app/lib/content/sight_reading/library.dart` | Pending-human default |
| Playability validator | `flutter_app/lib/core/music/playability.dart` | Pure Dart |
| Candidate CLI | `flutter_app/tool/content/generate_etude.dart` | Scratch output only |
| Tests | `flutter_app/test/sight_reading_generator_test.dart`, `playability_test.dart` | Machine checks |

Not in this ticket: sight-reading UI, runtime loading of candidates, generated
assets in the shipped library, reference recordings, and human review.

## 2. Level grammar

The grammar follows the T3.6 rubric in
[`SIGHT_READING_ETUDES.md`](SIGHT_READING_ETUDES.md) section 2. Every level
uses standard tuning, capo 0, and a tonal key from C major, G major, D major,
A minor, or E minor.

| Level | Stage / tier | Phrases | Bars | Tempo | Meter | Strings | Frets | Rhythm cells | Accidentals | Position plan | Shifts |
|---|---|---|---|---|---|---|---|---|---|---|---|
| L1 | 1 / foundation | 1 x 4 | 4 | 60 | 4/4 | 1-3 | 0-3 | half, quarter (both required) | 0 | first | 0 |
| L2 | 2 / foundation | 2 x 4 | 8 | 66 | 4/4 or 3/4 | 1-3 | 0-5 | quarter, eighth (both required) | 0 (allows 1) | first | 0 |
| L3 | 3 / foundation | 3 x 4 | 12 | 72 | 4/4 or 3/4 | 1-6 | 0-5 | quarter, eighth, dotted (dotted required) | exactly 1 | first | 0 |
| L4 | 5 / returner | 3 x 4 | 12 | 76 | 4/4 or 3/4 | 1-4 | 0-5 | quarter, eighth (both required) | 0 | first, second, first | 2 |
| L5 | 9 / returner | 2 x 2 | 4 | 70 | 4/4 or 3/4 | 1-6 | 0-5 | quarter, eighth, rest (all required) | 0 | first, second | 1 |

Grammar rules enforced by the generator:

- **Phrase bars:** each phrase is one to four bars, and the phrase plan sums to
  the level's total. Every bar is completely covered by notes and rests.
- **Frets and strings:** every note names a string and fret inside the level
  envelope. First-position phrases use frets 0-3 and include an open string;
  second-position phrases use frets 2-5 and include a fret 4-5 note.
- **Rhythm cells:** each event duration is one of the level cells. Required
  cells are guaranteed in the first bar. Eighth notes do not cross a bar line.
- **Meter:** 4/4 at level 1; 4/4 or 3/4 at levels 2-5, chosen by seed.
- **Range:** written pitch stays inside E3-E6 (sounding E2-E5).
- **Register:** each phrase picks a home tonic near a level register target and
  moves inside a seed-chosen window. The window never leaves the level's
  string/fret envelope.
- **Melody:** a motif from a small step/leap family, clamped to the level's
  maximum interval. Consecutive repeated notes are capped at two.
- **Cadence:** every phrase ends on the tonic, approached by a one- or
  two-semitone step. The last two notes of the etude are therefore a legal
  tonic cadence.
- **Accidentals:** level 3 adds exactly one chromatic note in its answer phrase:
  a chromatic neighbour to a stepwise pair in major, or a raised leading tone
  at the cadence in minor. Other levels stay in the key.
- **Texture:** strictly monophonic. No chords, double stops, overlaps, slurs,
  or ties.
- **Pitch:** written pitch is one octave above sounding pitch. The generator
  computes `soundingMidi` from the position and `writtenNote` from
  `soundingMidi + 12`.

The grammar is a content contract. Changing a value changes every candidate at
that level; treat a grammar edit as a content decision, not a refactor.

## 3. Deterministic seeds

`SeededRandom` is a Mulberry32 generator masked to 32 bits. It does not use
`dart:math` `Random(seed)`, whose sequence is not a stable cross-version
contract.

- Candidate id: `etude-candidate-l<level>-s<seed>`.
- The same level and seed always produce the same score and the same authoring
  JSON, byte for byte.
- Different seeds, or different levels with the same seed, produce different
  candidates.
- Negative seeds are rejected with `ArgumentError`.
- Levels outside 1-5 are rejected with `ArgumentError`; there is no silent
  default.

Approval records must pin the reviewed content. If a grammar value changes,
regenerating the same seed produces a different etude, so promotion to the
library is a file copy of the reviewed candidate (plus the reviewed ids and
metadata), not a "regenerate on load" step.

## 4. Playability validator

`PlayabilityValidator` runs on a parsed `Score` and returns typed
`PlayabilityIssue` values, not a boolean. Each issue carries:

- `code` and `message`;
- `severity` (`error`, or `warning` for an unknown key name);
- `phraseIndex` and stable `phraseId`;
- 1-based `bar` inside the phrase;
- `eventIndex` in `Phrase.events`.

`validateCandidateScore(score)` composes `Score.validate()` and the playability
validator. A candidate is valid only when both lists have no errors. The
generator tests also run `AuthoringValidator`, so a candidate must pass the
T3.2 authoring checks too.

| Code | Rule |
|---|---|
| `playability.writtenRange` | Written pitch inside E3-E6 (override allowed by limits). |
| `playability.stringRange` | String inside the level envelope. |
| `playability.fretRange` | Fret inside the level envelope. |
| `playability.rhythmCell` | Every event duration is an allowed level cell. |
| `playability.stretch` | Fretted notes in one phrase fit one hand position (`maxStretch`, default 4 frets). |
| `playability.stringCrossing` | Consecutive notes skip at most `maxStringSkip` strings. |
| `playability.repeatedNote` | No more than `maxConsecutiveRepeatedNotes` identical pitches in a row. The default is 4 so the reviewed T3.6 set passes; generated candidates use 2. |
| `playability.noOpenString` | The level requires at least one open string. |
| `playability.tooManyShifts` | Position shifts stay inside the level budget. A shift is a first/second phrase change or a fretted leap wider than `maxStretch`. |
| `playability.shiftTooFar` | A single fretted shift is wider than `maxShiftDistance` (default 7 frets). |
| `playability.cadence` | The final event is a note on the tonic. |
| `playability.cadenceApproach` | The final approach is a step or half-step (at most 2 semitones). |
| `playability.unknownKey` | Warning only: the key name has no parseable tonic, so the cadence check is skipped. |

First/second position uses the T3.6 classification: first position has a fret
0-1 and no fret 4-5; second position has a fret 4-5 and no fret 0-1. A phrase
with both, or neither, is neutral and does not count as a shift.

The 60 reviewed T3.6 etudes pass the default playability limits with zero
issues. One reviewed L4 etude repeats a note four times; that is recorded as a
T3.8 musical-review flag in [`SIGHT_READING_ETUDES.md`](SIGHT_READING_ETUDES.md)
section 5.1, not hidden by a test exception. The generator's own candidates cap
repeats at two.

## 5. CLI

From `flutter_app/`:

```powershell
dart run tool/content/generate_etude.dart --level 3 --seed 42
dart run tool/content/generate_etude.dart --level 5 --seed 2024 --out build/generated_etudes
```

Options:

- `--level <1-5>` (required).
- `--seed <non-negative integer>` (required).
- `--out <dir>` (default `build/generated_etudes`).
- `--help`.

The output file is `<out>/etude-candidate-l<level>-s<seed>.json` in the T3.2
authoring envelope, with `authoring.kind: etude` and
`authoring.reviewedBy: Pending human pedagogue review`.

The CLI validates the candidate with `Score.validate()`, `AuthoringValidator`,
and the level playability limits before writing. A failed candidate is not
written.

Exit codes:

| Code | Meaning |
|---|---|
| `0` | Candidate written and valid. |
| `1` | Candidate failed validation or generation; nothing was written. |
| `2` | Usage error, invalid level/seed, or file-system error. |

The CLI refuses any `--out` path under `assets/`. It prints the candidate id,
level, seed, key, meter, phrase count, bars, tempo, `pending-human` status, and
the written path.

## 6. Candidate and approval workflow

1. **Generate** a candidate to a scratch folder such as
   `build/generated_etudes/`. Do not generate into
   `assets/content/etudes/`.
2. **Machine-validate** it. The CLI does this automatically; the test matrix in
   `sight_reading_generator_test.dart` covers levels 1-5 and a spread of seeds.
3. **Human review.** A pedagogue reads the candidate, plays it, and checks
   musical payoff, notation, fingering, the cadence, and whether the level
   feels right. This is the T3.8 review surface.
4. **Record the decision.** `GeneratedEtudeLibrary.register` always creates a
   `pending-human` record. `approve` requires a reviewer and a date, re-runs
   both validators, and refuses an invalid candidate. `reject` records a
   rejection without changing the score. `approved` and `approvedEtudes`
   expose only approved records; `pendingHuman` is a review queue, not a
   library view.
5. **Promote by hand.** To enter the shipped library, a human copies the
   approved file into `assets/content/etudes/level_<n>/`, gives it a stable
   `etude-l<n>-<nn>` id and phrase ids, updates
   [`SIGHT_READING_ETUDES.md`](SIGHT_READING_ETUDES.md), and records the
   reviewer and date. The generator and CLI never do this.

An approval record has the candidate id, level, seed, status, reviewer, review
date, and optional notes. Re-registering the same deterministic candidate
returns the existing record, so a later generation cannot silently downgrade an
approval.

## 7. Pedagogue sample plan (pending)

The pedagogue review is a human step and is **not complete**. This section
records the planned stratified sample; it is not a claim that the sample
happened.

Proposed sample: 30 candidates, six per level, fixed by `(level, seed)`:

| Level | Seeds | Strata covered |
|---|---|---|
| L1 | 1, 2, 3, 4, 5, 6 | all five keys, 4/4, open strings |
| L2 | 1, 2, 3, 4, 5, 6 | all five keys, both meters |
| L3 | 1, 2, 3, 4, 5, 6 | all five keys, both meters, low and high register, dotted rhythms, accidental |
| L4 | 1, 2, 3, 4, 5, 6 | all five keys, both meters, first/second/first positions |
| L5 | 1, 2, 3, 4, 5, 6 | all five keys, both meters, first/second positions, rests |

Reviewer, date, and findings are blank until a human completes the review. The
sample is intentionally small: T3.7 is a beta, and the 60 reviewed etudes
remain the launch set. T3.8 owns human musical, notation, fingering, and
playtest review for the reviewed set and may extend this sample plan.

## 8. What is not claimed

- No human musical review, notation review, fingering review, or playtest of
  any generated candidate.
- No beginner playtest and no microphone/device test.
- No reference recording.
- No legal review. `license: original` is provenance, not a legal conclusion;
  T6.3 owns legal review.
- No runtime loader and no sight-reading UI. T3.8 and T5.3 own the content QA
  and progress surfaces.
- No validated musical or pedagogical accuracy. The generator is a grammar
  exercise plus a playability screen, not a substitute for a teacher.
- Do not market the generator as unlimited. The 60 reviewed etudes are the
  stable core.

## 9. Verification commands

From `flutter_app/`:

```powershell
flutter analyze
flutter test test/playability_test.dart
flutter test test/sight_reading_generator_test.dart
flutter test
flutter build web --release
```

The tests cover deterministic generation, a level/seed validation matrix,
level-limit enforcement, invalid grammar rejection, the 60-etude playability
pass and content hashes, the approval gate, the CLI's scratch-only output,
and the no-unlimited-claim check.

## 10. Related documents

- [`SIGHT_READING_ETUDES.md`](SIGHT_READING_ETUDES.md) - the 60 reviewed
  etudes, rubric, and T3.8 review flags.
- [`CONTENT_AUTHORING.md`](CONTENT_AUTHORING.md) - the T3.2 envelope and
  validator codes the generator composes with.
- [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md) section 6.3 -
  the generator beta and playability scope.
- `flutter_app/test/sight_reading_generator_test.dart` and
  `flutter_app/test/playability_test.dart` - the machine contract.
