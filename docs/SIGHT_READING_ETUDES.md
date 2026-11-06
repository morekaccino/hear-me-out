# Sight-reading etudes (T3.6)

**Status:** Authored and machine-validated. No human musical review, notation
review, fingering review, or playtest has happened yet. That review is T3.8.
**Owner:** T3.6. **Format:** T3.2 authoring document, see
[`CONTENT_AUTHORING.md`](CONTENT_AUTHORING.md). **Generator:** T3.7 beta, see
[`SIGHT_READING_GENERATOR.md`](SIGHT_READING_GENERATOR.md); it produces
candidates only and does not change this reviewed set. **First-read UI:**
T3.8/T5.3. **Reference recordings:** T3.4/T3.5 and the content calendar.

This document is the index and rubric for the 60 launch sight-reading etudes.
It records what the files contain and what has actually been checked. It does
not claim a human playtest or a human musical review.

## 1. What ships

- 60 strictly monophonic etudes: 12 at each of levels 1-5.
- Stable ids `etude-l1-01` through `etude-l5-12`, one JSON file per id.
- Files live in `flutter_app/assets/content/etudes/level_<n>/`.
- `flutter_app/pubspec.yaml` packages the five `assets/content/etudes/level_<n>/`
  directories so a future runtime loader can read the files. This ticket does
  not add a loader.
- Every file uses the T3.2 envelope: `schemaVersion: 1`, `piece`, `phrases`,
  and `authoring`. `authoring.kind` is `etude`.

The etudes are original compositions (`composer: "Hear Me Out"`,
`license: "original"`). No external melody is quoted. Legal review remains
T6.3; the license string is provenance, not a legal conclusion.

## 2. Level rubric

The rubric is the contract for the set. The tests in
`flutter_app/test/sight_reading_etudes_test.dart` assert the machine-checkable
columns below. Guide-finger fingering and musical payoff are T3.8 review, not
machine claims.

| Level | Stage | Tier | Strings and frets | Rhythm | Bars | Tempo | Meter | Accidentals | Position work | Cadence |
|---|---|---|---|---|---|---|---|---|---|---|
| L1 | 1 | foundation | strings 1-3, frets 0-3 | quarter and half notes | 4 | 60 BPM | 4/4 | none | open strings and first position | one clear tonic cadence |
| L2 | 2 | foundation | strings 1-3, frets 0-5 | quarter and eighth notes | 8 | 66 BPM | 4/4 or 3/4 | at most one | first position | clear phrase ending |
| L3 | 3 | foundation | strings 1-6, frets 0-5 | quarter, eighth, and dotted rhythms | 12 | 72 BPM | 4/4 or 3/4 | one or two | first position across the strings | repeated rhythmic motif and a tonic cadence |
| L4 | 5 | returner | strings 1-4, frets 0-5 | quarter and eighth notes | 12 | 76 BPM | 4/4 or 3/4 | tonal; none in this set | first position, a second-position answer, then first position; two phrase-level position changes (guide-finger detail T3.8) | tonic cadence |
| L5 | 9 | returner | strings 1-6, frets 0-5 in this set | mixed quarter, eighth, and rest cells | 4 | 70 BPM | 4/4 or 3/4 | tonal; none in this set | one compact second-position passage | musical tonic cadence |

Every note names an explicit string and fret. Written pitch stays inside
E3-E6, sounding pitch inside E2-E5, and `soundingMidi = written MIDI - 12`.
Every phrase is at most four bars and every bar is fully covered by notes and
rests. The L2/L3 first-position columns are asserted through the string/fret
envelope (frets 0-5) and an open-string note; the app has no formal
hand-position model.

### 2.1 Scope note: phrase length and stage outcomes

The ticket's shorthand "2-4 bars each" is enforced at the phrase level: every
phrase is 1-4 bars. Etude totals follow the published stage outcomes instead
of forcing every file into four bars:

- L1: 4 bars (stage 1: a 4-bar study at 60 BPM).
- L2: 8 bars (stage 2: an 8-bar folk melody).
- L3: 12 bars (stage 3: a 12-bar piece).
- L4: 12 bars (stage 5: a 12-bar study with two position changes).
- L5: 4 bars at 70 BPM (stage 9: read a 4-bar etude at sight at 70 BPM).

This deviation is intentional and was requested in review. T9.2 remains the
manager's decision log; this section is the content-side record. L5's compact
second-position passage is also intentional per the ticket's L5 rubric. It is
not a change to the stage map, and T3.8 must judge whether it reads cleanly at
sight.

### 2.2 How shifts are counted

A phrase is classified as first position when it uses at least one fret 0-1
and no fret 4-5, and as second position when it uses at least one fret 4-5
and no fret 0-1. A level 4 etude must have at least two phrase-to-phrase
transitions between those two classes. Every L4 etude follows the same plan:

1. first-position theme;
2. second-position answer;
3. first-position return and cadence.

The position change is therefore explicit in the string and fret fields. The
files cannot encode which finger guides the shift; that is a T3.8 fingering
review question, not a machine claim. The T3.2 validator's separate warning
counts a five-fret leap between consecutive fretted notes; all 60 files have
zero such warnings.

### 2.3 Accidentals

Accidentals are counted as distinct written pitch classes outside the key
signature:

- L1: none.
- L2: at most one.
- L3: one or two. Major-key etudes use a chromatic lower neighbour to the
  dominant; minor-key etudes add the raised leading tone at the final
  cadence. The exact interval is visible in the `writtenNote` fields.
- L4 and L5: tonal; this set uses no accidentals in either level.

## 3. Musical design

The set is not 60 unrelated note strings. It uses a small motif family and
varies it:

- **Motif shapes:** arch, neighbour, cascade, wave, turn, pedal, sequence,
  question, scale run, leap-return, thirds, and cadence walk.
- **Phrase plan:** statement, answer (often inverted or sequenced), and a
  return with a cadence. L3 repeats its rhythm across phrases 1 and 3 so the
  rhythmic motif is audible and testable.
- **Keys:** C major, G major, D major, A minor, and E minor rotate across the
  set. Level 1-2 keep to strings 1-3; level 3 adds the lower strings; level 4
  introduces the second-position answer; level 5 compresses the same skills
  into a shorter first-read test.
- **Cadences:** every etude ends on the tonic. The final two notes are always
  a step or half-step, and the approach to the cadence is kept inside a
  perfect fourth or smaller so the ending is not a random leap.
- **Difficulty:** the tempo rises 60, 66, 72, 76 BPM and then L5 returns to
  70 BPM for the stage-9 at-sight outcome. Bar counts are 4, 8, 12, 12, 4.
  L5 is shorter than L4 on purpose: it is a fresh 4-bar reading check at the
  stage-9 tempo, not a longer technique study.

## 4. Index

`Stage` is the V1 stage, `Bars` is the sum of the phrase bars, and `BPM` is the
phrase target tempo.

| Id | Level | Stage | Key | Bars | Meter | BPM |
|---|---|---|---|---|---|---|
| `etude-l1-01` | L1 | 1 | G major | 4 | 4/4 | 60 |
| `etude-l1-02` | L1 | 1 | C major | 4 | 4/4 | 60 |
| `etude-l1-03` | L1 | 1 | D major | 4 | 4/4 | 60 |
| `etude-l1-04` | L1 | 1 | A minor | 4 | 4/4 | 60 |
| `etude-l1-05` | L1 | 1 | E minor | 4 | 4/4 | 60 |
| `etude-l1-06` | L1 | 1 | G major | 4 | 4/4 | 60 |
| `etude-l1-07` | L1 | 1 | C major | 4 | 4/4 | 60 |
| `etude-l1-08` | L1 | 1 | D major | 4 | 4/4 | 60 |
| `etude-l1-09` | L1 | 1 | A minor | 4 | 4/4 | 60 |
| `etude-l1-10` | L1 | 1 | E minor | 4 | 4/4 | 60 |
| `etude-l1-11` | L1 | 1 | G major | 4 | 4/4 | 60 |
| `etude-l1-12` | L1 | 1 | C major | 4 | 4/4 | 60 |
| `etude-l2-01` | L2 | 2 | C major | 8 | 4/4 | 66 |
| `etude-l2-02` | L2 | 2 | G major | 8 | 4/4 | 66 |
| `etude-l2-03` | L2 | 2 | D major | 8 | 4/4 | 66 |
| `etude-l2-04` | L2 | 2 | A minor | 8 | 4/4 | 66 |
| `etude-l2-05` | L2 | 2 | E minor | 8 | 4/4 | 66 |
| `etude-l2-06` | L2 | 2 | C major | 8 | 3/4 | 66 |
| `etude-l2-07` | L2 | 2 | G major | 8 | 3/4 | 66 |
| `etude-l2-08` | L2 | 2 | D major | 8 | 3/4 | 66 |
| `etude-l2-09` | L2 | 2 | A minor | 8 | 3/4 | 66 |
| `etude-l2-10` | L2 | 2 | E minor | 8 | 3/4 | 66 |
| `etude-l2-11` | L2 | 2 | C major | 8 | 4/4 | 66 |
| `etude-l2-12` | L2 | 2 | G major | 8 | 4/4 | 66 |
| `etude-l3-01` | L3 | 3 | C major | 12 | 4/4 | 72 |
| `etude-l3-02` | L3 | 3 | G major | 12 | 4/4 | 72 |
| `etude-l3-03` | L3 | 3 | D major | 12 | 4/4 | 72 |
| `etude-l3-04` | L3 | 3 | A minor | 12 | 4/4 | 72 |
| `etude-l3-05` | L3 | 3 | E minor | 12 | 4/4 | 72 |
| `etude-l3-06` | L3 | 3 | C major | 12 | 4/4 | 72 |
| `etude-l3-07` | L3 | 3 | G major | 12 | 4/4 | 72 |
| `etude-l3-08` | L3 | 3 | D major | 12 | 4/4 | 72 |
| `etude-l3-09` | L3 | 3 | A minor | 12 | 4/4 | 72 |
| `etude-l3-10` | L3 | 3 | E minor | 12 | 3/4 | 72 |
| `etude-l3-11` | L3 | 3 | C major | 12 | 3/4 | 72 |
| `etude-l3-12` | L3 | 3 | A minor | 12 | 3/4 | 72 |
| `etude-l4-01` | L4 | 5 | C major | 12 | 4/4 | 76 |
| `etude-l4-02` | L4 | 5 | G major | 12 | 4/4 | 76 |
| `etude-l4-03` | L4 | 5 | D major | 12 | 4/4 | 76 |
| `etude-l4-04` | L4 | 5 | A minor | 12 | 4/4 | 76 |
| `etude-l4-05` | L4 | 5 | E minor | 12 | 4/4 | 76 |
| `etude-l4-06` | L4 | 5 | C major | 12 | 3/4 | 76 |
| `etude-l4-07` | L4 | 5 | G major | 12 | 3/4 | 76 |
| `etude-l4-08` | L4 | 5 | D major | 12 | 3/4 | 76 |
| `etude-l4-09` | L4 | 5 | A minor | 12 | 3/4 | 76 |
| `etude-l4-10` | L4 | 5 | E minor | 12 | 4/4 | 76 |
| `etude-l4-11` | L4 | 5 | C major | 12 | 4/4 | 76 |
| `etude-l4-12` | L4 | 5 | G major | 12 | 4/4 | 76 |
| `etude-l5-01` | L5 | 9 | C major | 4 | 4/4 | 70 |
| `etude-l5-02` | L5 | 9 | G major | 4 | 4/4 | 70 |
| `etude-l5-03` | L5 | 9 | D major | 4 | 4/4 | 70 |
| `etude-l5-04` | L5 | 9 | A minor | 4 | 4/4 | 70 |
| `etude-l5-05` | L5 | 9 | E minor | 4 | 4/4 | 70 |
| `etude-l5-06` | L5 | 9 | C major | 4 | 3/4 | 70 |
| `etude-l5-07` | L5 | 9 | G major | 4 | 3/4 | 70 |
| `etude-l5-08` | L5 | 9 | D major | 4 | 3/4 | 70 |
| `etude-l5-09` | L5 | 9 | A minor | 4 | 3/4 | 70 |
| `etude-l5-10` | L5 | 9 | E minor | 4 | 4/4 | 70 |
| `etude-l5-11` | L5 | 9 | C major | 4 | 4/4 | 70 |
| `etude-l5-12` | L5 | 9 | G major | 4 | 4/4 | 70 |

## 5. Review status

What has actually happened:

- Every file parses through the T3.2 `parseAuthoringDocument`.
- Every file passes `AuthoringValidator` with zero errors and zero warnings.
- Every file passes `Score.validate()`, the monophonic, bar, tie, range, and
  fingering checks.
- Every file passes the validator CLI in `--strict` mode.
- The 60-file rubric checks in
  `flutter_app/test/sight_reading_etudes_test.dart` pass: counts, ids, stage,
  tier, tempo, bars, ranges, accidentals, repeated rhythm, first/second
  position classification, phrase skills against the notes, rests, cadence,
  and honest `reviewedBy`.
- Phrase-level `skills` are checked against the notes: a first-position phrase
  cannot claim second position or a shift; a second-position phrase must use
  frets 2-5 and include a fret 4-5 note; rhythm tags require the matching
  duration or rest; an accidental tag requires an out-of-key note; a
  phrase-ending tag requires a step or half-step.
- L3's phrases 1 and 3 are asserted to share the same rhythmic signature.
- L5 is 4 bars at 70 BPM, and its second phrase is an exclusively
  second-position passage.
- A machine review of the melodic intervals keeps every approach to a cadence
  inside a perfect fourth and every etude ends on its tonic.

What has **not** happened:

- No human musical review of the melodies.
- No human notation or fingering review. The files encode phrase-level
  position changes, not which finger guides a shift; that is T3.8's fingering
  review.
- No human playtest, no beginner playtest, and no microphone/device test of
  these files.
- No reference recordings. T3.4/T3.5 and the content calendar own them.
- No legal review. T6.3 owns it.
- No runtime loader and no first-read scoring UI. T3.7 owns the generator;
  the first-read/feedback flow is a separate product surface.

`authoring.reviewedBy` is therefore the exact string:

```text
Machine validation and rubric review; human playtest pending T3.8
```

No file names a human reviewer. Do not upgrade this string until T3.8 records
a real reviewer, date, and playtest evidence.

### 5.1 T3.8 musical-review flags

The following files are tonal, stepwise, and cadential, but they are
deliberately repetitive two- or three-note exercises. T3.8 should reject or
revise them if they do not read as music:

- `etude-l1-06`
- `etude-l1-12`
- `etude-l2-02`
- `etude-l2-06`
- `etude-l3-06`
- `etude-l4-02`
- `etude-l4-06`

Their `authoring.notes` also carry a T3.8 flag. This is not a
machine-validation failure; it is musical-payoff evidence that T3.8 owns.

## 6. Validation commands

From `flutter_app/`:

```powershell
Get-ChildItem assets/content/etudes -Recurse -Filter *.json | ForEach-Object {
  & 'C:\Users\morekaccino\flutter\bin\dart.bat' run tool/content/validate_piece.dart $_.FullName --strict
  if ($LASTEXITCODE -ne 0) { throw "validation failed: $($_.FullName)" }
}
flutter test test/sight_reading_etudes_test.dart
flutter analyze
flutter test
flutter build web --release
```

The 60 files pass the strict validator with `0 error(s), 0 warning(s)` each.
The dedicated test covers the same files through the parser, both validators,
the rubric, phrase-skill/note agreement, the L5 4-bar/70 BPM contract, and the
CLI. Current result: 60/60 strict PASS, 12 focused tests, 801 full tests,
`flutter analyze` clean, and the release web build contains all 60 JSON files.

## 7. Related documents

- [`CONTENT_AUTHORING.md`](CONTENT_AUTHORING.md) - envelope, fields, validation
  codes, and review checklist.
- [`SIGHT_READING_GENERATOR.md`](SIGHT_READING_GENERATOR.md) - the T3.7 beta
  generator, playability validator, approval gate, and pending pedagogue
  sample plan. Generated material is a candidate, not part of this set.
- [`LAUNCH_PIECES.md`](LAUNCH_PIECES.md) - the 10 launch pieces and the
  stage map these etudes support.
- [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md) sections 6.1,
  6.3, and 6.5 - stage outcomes, the 60-etude launch target, and the content
  calendar.
- `flutter_app/test/sight_reading_etudes_test.dart` - the machine contract for
  this index.
