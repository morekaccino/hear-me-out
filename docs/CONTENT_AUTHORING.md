# Content authoring format (V1)

Status: T3.2. This document defines the hand-authoring format for V1
monophonic repertoire and etudes. It builds on the T2.1 `Piece`, `Phrase`,
`NoteEvent`, `Score`, and `score_parser.dart` models.

T3.2 ships the format, parser, and validator. T3.3/T3.4 author the ten launch
pieces, T3.6 authors the sixty etudes, and T6.3 owns legal review. The app does
not read authoring JSON at runtime yet.

## 1. Principles

- V1 is strictly monophonic: one sounding note at a time, no chords, no double
  stops, no overlapping durations.
- Written pitch and sounding pitch are both explicit. Guitar music is written
  one octave above sounding pitch.
- Every note names its string and fret. The app must never guess between an open
  string and a fretted position.
- The validator re-derives sounding pitch from the written note and from the
  string/fret position. It does not trust an author-supplied `soundingMidi`.
- The format is versioned. Unknown metadata fields are ignored for forward
  compatibility; a future `schemaVersion` is rejected, never guessed.

## 2. File shape

```json
{
  "schemaVersion": 1,
  "piece": { "...": "..." },
  "phrases": [ { "...": "..." } ],
  "authoring": { "...": "..." }
}
```

| Field | Type | Required | Meaning |
|---|---|---|---|
| `schemaVersion` | integer | yes | Authoring envelope version. Currently `1`. |
| `piece` | object | yes | Shared piece metadata; see 2.1. |
| `phrases` | array | yes | One or more phrases in performance order; see 2.2. |
| `authoring` | object | no | Provenance and review metadata; see 2.3. |

The musical fields are the canonical T2.1 score document. Authors who already
have a `scoreToJson` document only add the optional `authoring` object.

### 2.1 `piece`

| Field | Type | Required | V1 rule |
|---|---|---|---|
| `id` | string | yes | Lowercase kebab-case, stable forever. |
| `title` | string | yes | Human-readable title. |
| `composer` | string | yes | Composer or `Traditional` for public-domain melody. |
| `license` | string | yes | `public-domain` or `original`; `licensed` is rejected in V1. |
| `tuning` | object | yes | Standard tuning: `{"name": "Standard", "openStrings": [40, 45, 50, 55, 59, 64]}`. |
| `capo` | integer | no | `0`. Nonzero capos are rejected. |
| `timeSignature` | object | yes | `{"numerator": 4, "denominator": 4}`. |
| `key` | string | yes | Key plus mode, for example `"G major"` or `"A minor"`. |
| `sections` | array of strings | no | Optional rehearsal labels such as `["A", "B"]`. |
| `sourceUrl` | string | no | Optional provenance link for public-domain material. |

`openStrings` are sounding MIDI numbers from the lowest string to the highest:
E2 A2 D3 G3 B3 E4.

### 2.2 `phrases`

| Field | Type | Required | V1 rule |
|---|---|---|---|
| `id` | string | yes | `<piece-id>-p<n>`, 1-based, for example `original-study-in-g-p1`. |
| `title` | string | no | Short rehearsal label. |
| `bars` | integer | yes | 1–4 in V1. Includes a pickup bar when `pickupBeats > 0`. |
| `timeSignature` | object | yes | Usually the piece time signature. |
| `targetTempoBpm` | integer | yes | 50–90 in V1; outside is a warning. |
| `skills` | array of strings | no | Stable skill ids such as `note-reading.first-position`. |
| `difficulty` | integer | no | 1 (easiest) through 5 (hardest). Default `1`. |
| `startBar` | integer | no | Bar number in the piece where the phrase starts. Default `1`. |
| `pickupBeats` | number | no | Length of an incomplete first bar, in beats. Default `0`. |
| `events` | array | yes | Notes and rests in performance order. |

`pickupBeats` must be at least `0` and shorter than one bar. When it is
nonzero, the first bar is short and `bars` still counts it. For a four-bar 4/4
phrase with a one-beat pickup, the events must total `3 * 4 + 1 = 13` beats.

### 2.3 `authoring`

All fields are optional. Unknown fields are ignored.

| Field | Type | Meaning |
|---|---|---|
| `author` | string | Who wrote the arrangement. |
| `source` | string | Where the material came from. |
| `reviewedBy` | string | Musical reviewer, or `Pending musical review`. |
| `notes` | string | Short authoring notes. |
| `kind` | string | `piece` or `etude`. Etudes may use fewer than four phrases. |
| `tier` | string | Content tier, for example `foundation` or `returner`. |
| `stage` | integer | V1 stage 1–12, used by the summary output. |

`authoring` is descriptive provenance, not a legal opinion. See section 10.

## 3. Events

Every event has `startBeat`, `durationBeats`, and `kind`.

| Field | Type | Required | Meaning |
|---|---|---|---|
| `startBeat` | number | yes | Beat offset from the start of the phrase. |
| `durationBeats` | number | yes | Length in quarter-note beats; must be greater than zero. |
| `kind` | string | yes | `note` or `rest`. |
| `writtenNote` | string | note only | Written pitch, for example `G3`, `Bb4`, or `F#5`. |
| `soundingMidi` | integer | note only | MIDI number the microphone hears. |
| `string` | integer | note only | `1` = high E, `6` = low E. |
| `fret` | integer | note only | `0` = open string. |
| `tieToNext` | boolean | no | Sustain into the next event instead of plucking again. |
| `velocity` | number | no | `0.0`–`1.0`, default `1.0`. |

Rules:

- The domain model allows a note with both `string` and `fret`, or neither. V1
  authors must provide both. A note with neither is an
  `authoring.missingFingering` error; a note with only one is a
  `fingering.incomplete` error.
- A rest cannot have `writtenNote`, `soundingMidi`, `string`, `fret`, or
  `tieToNext`.
- Events must be listed in ascending `startBeat` order.
- Every bar must be completely covered by notes and rests. Gaps and overruns
  are bar errors.
- Quarter notes use `durationBeats: 1`, eighth notes use `0.5`. V1 launch
  content stays with quarter and eighth notes; the parser accepts any positive
  duration, but other values need a musical reason.

### 3.1 Written pitch versus sounding pitch

Guitar notation is written one octave above sounding pitch:

```text
soundingMidi = written MIDI - 12
```

| Written | Written MIDI | Sounds | Sounding MIDI | Example position |
|---|---|---|---|---|
| E3 | 52 | E2 | 40 | Low E open |
| G3 | 55 | G2 | 43 | Low E, fret 3 |
| C4 | 60 | C3 | 48 | A string, fret 3 |
| E4 | 64 | E3 | 52 | D string, fret 2 |
| G4 | 67 | G3 | 55 | G string open |
| C5 | 72 | C4 | 60 | B string, fret 1 |
| E5 | 76 | E4 | 64 | High E open |
| G5 | 79 | G4 | 67 | B string, fret 8 |
| E6 | 88 | E5 | 76 | High E, fret 12 |

The V1 written range is E3–E6. The sounding range is therefore E2–E5. Notes
outside that range are rejected.

### 3.2 Ties

A tie continues the same pitch into the next note:

- the tied note sets `"tieToNext": true`;
- the next event must start exactly at the tied note's end beat;
- the next event must be a note with the same written pitch and the same
  `soundingMidi`;
- when either side names a position, both sides must use the same `string` and
  `fret`;
- a rest cannot be tied, and the last event in a phrase cannot tie.

### 3.3 Rests

A rest fills time with silence. It has no pitch, position, or tie:

```json
{"startBeat": 2, "durationBeats": 1, "kind": "rest"}
```

Rests count toward bar coverage exactly like notes.

### 3.4 Pickup

A pickup is an incomplete first bar, not a rest. Set `pickupBeats` on the
phrase and start the first event at beat 0:

```json
"bars": 4,
"pickupBeats": 1.0,
"events": [
  {"startBeat": 0, "durationBeats": 1, "kind": "note", "writtenNote": "G3", "soundingMidi": 43, "string": 6, "fret": 3}
]
```

For 4/4, this phrase has one pickup beat plus three full bars, so the events
must span `(4 - 1) * 4 + 1 = 13` beats. The first bar ends at beat 1, bar 2
starts at beat 1, bar 3 at beat 5, and bar 4 at beat 9. `bars` counts the
pickup bar.

## 4. Worked example

The example is four bars in G major at 72 BPM. It is monophonic, uses one
position shift (D5 at B string fret 3 to G5 at B string fret 8), one tie (the
G5 in bar 4), and one rest (beat 3 of bar 4). It validates with zero errors and
zero warnings. The same document is stored at
`flutter_app/test/fixtures/content/valid_piece.json`.

```json
{
  "schemaVersion": 1,
  "piece": {
    "id": "original-study-in-g",
    "title": "Original Study in G",
    "composer": "Hear Me Out",
    "license": "original",
    "tuning": {"name": "Standard", "openStrings": [40, 45, 50, 55, 59, 64]},
    "capo": 0,
    "timeSignature": {"numerator": 4, "denominator": 4},
    "key": "G major",
    "sections": ["A"]
  },
  "phrases": [
    {
      "id": "original-study-in-g-p1",
      "title": "Rising line",
      "bars": 1,
      "timeSignature": {"numerator": 4, "denominator": 4},
      "targetTempoBpm": 72,
      "skills": ["note-reading.first-position", "rhythm.quarter-notes"],
      "difficulty": 1,
      "startBar": 1,
      "pickupBeats": 0.0,
      "events": [
        {"startBeat": 0, "durationBeats": 1, "kind": "note", "writtenNote": "G3", "soundingMidi": 43, "string": 6, "fret": 3},
        {"startBeat": 1, "durationBeats": 1, "kind": "note", "writtenNote": "A3", "soundingMidi": 45, "string": 5, "fret": 0},
        {"startBeat": 2, "durationBeats": 1, "kind": "note", "writtenNote": "B3", "soundingMidi": 47, "string": 5, "fret": 2},
        {"startBeat": 3, "durationBeats": 1, "kind": "note", "writtenNote": "C4", "soundingMidi": 48, "string": 5, "fret": 3}
      ]
    },
    {
      "id": "original-study-in-g-p2",
      "title": "Answering line",
      "bars": 1,
      "timeSignature": {"numerator": 4, "denominator": 4},
      "targetTempoBpm": 72,
      "skills": ["note-reading.first-position", "rhythm.quarter-notes"],
      "difficulty": 1,
      "startBar": 2,
      "pickupBeats": 0.0,
      "events": [
        {"startBeat": 0, "durationBeats": 1, "kind": "note", "writtenNote": "D4", "soundingMidi": 50, "string": 4, "fret": 0},
        {"startBeat": 1, "durationBeats": 1, "kind": "note", "writtenNote": "E4", "soundingMidi": 52, "string": 4, "fret": 2},
        {"startBeat": 2, "durationBeats": 1, "kind": "note", "writtenNote": "F4", "soundingMidi": 53, "string": 4, "fret": 3},
        {"startBeat": 3, "durationBeats": 1, "kind": "note", "writtenNote": "G4", "soundingMidi": 55, "string": 3, "fret": 0}
      ]
    },
    {
      "id": "original-study-in-g-p3",
      "title": "Upper register",
      "bars": 1,
      "timeSignature": {"numerator": 4, "denominator": 4},
      "targetTempoBpm": 72,
      "skills": ["note-reading.first-position", "rhythm.quarter-notes"],
      "difficulty": 2,
      "startBar": 3,
      "pickupBeats": 0.0,
      "events": [
        {"startBeat": 0, "durationBeats": 1, "kind": "note", "writtenNote": "A4", "soundingMidi": 57, "string": 3, "fret": 2},
        {"startBeat": 1, "durationBeats": 1, "kind": "note", "writtenNote": "B4", "soundingMidi": 59, "string": 2, "fret": 0},
        {"startBeat": 2, "durationBeats": 1, "kind": "note", "writtenNote": "C5", "soundingMidi": 60, "string": 2, "fret": 1},
        {"startBeat": 3, "durationBeats": 1, "kind": "note", "writtenNote": "D5", "soundingMidi": 62, "string": 2, "fret": 3}
      ]
    },
    {
      "id": "original-study-in-g-p4",
      "title": "Shift and tie",
      "bars": 1,
      "timeSignature": {"numerator": 4, "denominator": 4},
      "targetTempoBpm": 72,
      "skills": ["note-reading.first-position", "rhythm.quarter-notes"],
      "difficulty": 2,
      "startBar": 4,
      "pickupBeats": 0.0,
      "events": [
        {"startBeat": 0, "durationBeats": 1, "kind": "note", "writtenNote": "G5", "soundingMidi": 67, "string": 2, "fret": 8, "tieToNext": true},
        {"startBeat": 1, "durationBeats": 1, "kind": "note", "writtenNote": "G5", "soundingMidi": 67, "string": 2, "fret": 8},
        {"startBeat": 2, "durationBeats": 1, "kind": "rest"},
        {"startBeat": 3, "durationBeats": 1, "kind": "note", "writtenNote": "E5", "soundingMidi": 64, "string": 1, "fret": 0}
      ]
    }
  ],
  "authoring": {
    "author": "Hear Me Out content team",
    "source": "Original study written for the T3.2 fixture",
    "reviewedBy": "Pending musical review",
    "notes": "Four-bar monophonic study with one shift, one tie, and one rest.",
    "kind": "piece",
    "tier": "foundation",
    "stage": 3
  }
}
```

Why it passes:

- Each phrase is one complete 4/4 bar and totals four beats.
- Every `soundingMidi` is exactly 12 semitones below its written note.
- Every string/fret pair produces the declared sounding MIDI.
- The shift is D5 (B string, fret 3) to G5 (B string, fret 8): one shift in
  four bars, under the one-per-two-bars limit.
- The two G5 events are adjacent, have the same written pitch and position, and
  the first sets `tieToNext`.
- The rest at beat 2 fills the third beat of bar 4.
- Tempo 72 is inside 50–90, the highest fret is 8, and the written range is
  G3–G5 inside E3–E6.

## 5. Naming rules

- **Piece id:** lowercase ASCII kebab-case, no spaces, no version suffix. The
  file name matches: `original-study-in-g.json`.
- **Phrase id:** `<piece-id>-p<n>`, 1-based. Keep the order in the array and the
  `n` suffix aligned.
- **Skill id:** lowercase dotted namespace, for example
  `note-reading.first-position` or `rhythm.eighth-notes`. Skill ids are stable
  data, not display text.
- **Test fixtures:** may use a `fixture-` prefix or a descriptive id, but must
  still be unique.
- Do not rename a shipped piece id. A new arrangement is a new piece id so
  progress and references cannot silently move.
- Keep ids unique across all pieces and etudes.

## 6. V1 constraints

| Constraint | Value | Enforcement |
|---|---|---|
| Texture | One sounding note at a time | Error: `monophonic.chord`, `monophonic.overlap`, `event.overlap` |
| Overlap | No event may start before the previous event ends | Error |
| Phrase length | 1–4 bars | Error above four bars |
| Tempo | 50–90 BPM | Warning outside; error outside 30–200 |
| Range | Written E3–E6, sounding E2–E5 | Error |
| Maximum fret | 19 | Error above 19; warning above 12 |
| Position shifts | At most one per two bars | Warning |
| Fingering | Explicit string and fret on every note | Error when both are missing; error when they disagree with pitch |
| Tuning | Standard, low to high E2 A2 D3 G3 B3 E4 | Warning if non-standard |
| Capo | 0 | Error |
| License | `public-domain` or `original` | Error for `licensed` or unknown |
| Piece shape | Four phrases per piece | Warning in `--summary`; etudes may use fewer |
| Rhythm | Quarter and eighth notes | V1 editorial rule; parser accepts other positive durations |

Non-standard tuning is only a warning because the domain model can represent
it. V1 launch content must still use standard tuning. The app has no capo-aware
pitch semantics, so capo 0 is a hard error.

A position shift is counted between consecutive fretted notes when they are
five or more frets apart. Open strings do not move the left hand and do not
reset the count. This is authoring feedback, not a musical verdict; a human
reviewer decides whether a shift is musically justified.

## 7. Validator CLI

Run from `flutter_app/`:

```powershell
dart run tool/content/validate_piece.dart path/to/piece.json
dart run tool/content/validate_piece.dart path/to/piece.json --summary
dart run tool/content/validate_piece.dart path/to/piece.json --json
dart run tool/content/validate_piece.dart path/to/piece.json --strict
```

Options:

- `--summary` prints the piece title, id, composer, kind, tier, stage, phrase
  count, bars, tempo, written/sounding range, note count, and rest count.
- `--json` prints one object:
  `{"valid": bool, "errors": int, "warnings": int, "issues": [...]}`. With
  `--summary`, the object also has a `summary` field.
- `--strict` treats warnings as errors for the exit code.
- `--help` prints usage.

Exit codes:

| Code | Meaning |
|---|---|
| `0` | No errors. Warnings are allowed unless `--strict` is set. |
| `1` | Validation errors, a warning under `--strict`, or a score that cannot be parsed. |
| `2` | Usage error or unreadable file. |

Text output is one line per issue:

```text
error monophonic.chord at phrases[0].events[1]: Note events at beat 0 form a chord or double stop; V1 is monophonic.
FAIL path/to/piece.json: 1 error(s), 0 warning(s).
```

Example summary:

```text
Piece: Original Study in G
Id: original-study-in-g
Composer: Hear Me Out
Kind: piece
Tier: foundation
Stage: 3
Phrases: 4
Bars: 4
Tempo: 72 BPM
Range: written G3-G5, sounding G2-G4
Notes: 15
Rests: 1
```

The CLI reads the file with `dart:io`; the parser and validator use no Flutter
imports, so `dart run` works without a device.

## 8. Validation codes

T3.2 composes the T2.1 `MonophonicValidator`; those codes remain the source of
truth for musical model invariants.

| Code | Severity | Owner | Trigger |
|---|---|---|---|
| `monophonic.chord` | error | T2.1 | Two notes start at the same beat. |
| `monophonic.overlap` | error | T2.1 | A note starts before an earlier note ends. |
| `event.overlap` | error | T2.1 | A rest or mixed event overlaps another event. |
| `bar.durationMismatch` | error | T2.1 | A bar is not completely covered. |
| `phrase.barCountMismatch` | error | T2.1 | Events do not match `bars` and the pickup length. |
| `tie.mismatch` | error | T2.1 | A tie changes pitch, position, or destination. |
| `tie.notAdjacent` | error | T2.1 | A tied continuation does not start at the end beat. |
| `tie.dangling` | error | T2.1 | A tie has no following event. |
| `fingering.incomplete` | error | T2.1 | Only one of string/fret is present. |
| `fingering.invalidString` | error | T2.1 | String is outside 1–6. |
| `fingering.invalidFret` | error | T2.1 | Fret is outside 0–24. |
| `fingering.mismatch` | error | T2.1 | String/fret does not produce the declared sounding pitch. |
| `note.writtenSoundingMismatch` | error | T2.1 | `soundingMidi` is not written MIDI minus 12. |
| `note.missingWritten` / `note.missingSounding` | error | T2.1 | A note lacks pitch data. |
| `piece.invalidCapo` / `piece.unsupportedCapo` | error | T2.1 | Capo is invalid or nonzero. |
| `piece.licenseNotV1Compatible` | error | T2.1 | License is `licensed`. |
| `piece.unknownLicense` | error | T2.1 | License is not a known status. |
| `piece.nonStandardTuning` | warning | T2.1 | Tuning is not standard. |
| `authoring.phraseTooLong` | error | T3.2 | Phrase declares more than four bars. |
| `authoring.tempoOutsideV1` | warning | T3.2 | Tempo is outside 50–90 but still within 30–200. |
| `authoring.noteOutOfRange` | error | T3.2 | Written note is outside E3–E6. |
| `authoring.fretAboveV1Max` | error | T3.2 | Fret is above 19. |
| `authoring.highFret` | warning | T3.2 | Fret is 13–19. |
| `authoring.tooManyShifts` | warning | T3.2 | More position shifts than one per two bars. |
| `authoring.missingFingering` | error | T3.2 | A note has neither string nor fret. |
| `authoring.phraseCount` | warning | T3.2 | `--summary` sees a non-etude without four phrases. |
| `authoring.schemaVersion` | parse error | T3.2 | Missing or malformed `schemaVersion`. |
| `authoring.futureSchema` | parse error | T3.2 | `schemaVersion` is newer than this build. |
| `authoring.unsupportedSchema` | parse error | T3.2 | `schemaVersion` is older than this build. |
| `authoring.invalidKind` | parse error | T3.2 | `authoring.kind` is not `piece` or `etude`. |
| `authoring.invalidMeta` | parse error | T3.2 | `authoring` is not an object. |
| `authoring.invalidJson` | CLI error | T3.2 | The file is not valid JSON. |
| `authoring.invalidDocument` | CLI error | T3.2 | The JSON root is not an object. |
| `authoring.parseError` | CLI error | T3.2 | A domain parse error not covered above. |

Parse errors carry the path of the offending field, for example
`phrases[0].events[2].durationBeats` or `schemaVersion`.

## 9. Review checklist

Run the validator first, then review the music by hand.

**Notation**

- The written note matches the staff, key signature, and accidentals.
- Ties connect the same pitch and position.
- Rests complete every bar; a pickup matches `pickupBeats`.
- The written octave is correct for guitar (written one octave above sounding).

**Fingering**

- Every note has an explicit string and fret.
- No impossible stretch or string crossing inside a phrase.
- Frets stay at or below 12 for beginner content; never above 19.
- Position shifts are at most one per two bars and are marked by a musical
  reason, not a random jump.
- Open strings and fretted notes are unambiguous in context.

**Range and playability**

- Written range is inside E3–E6; sounding range is inside E2–E5.
- Tempo is 50–90 BPM and the phrase is playable at the slow tempo.
- The melody has a cadence and a reason to be practiced; it is not filler.
- Four phrases per piece, unless the item is an etude.

**Provenance and license**

- `license` is `public-domain` or `original`.
- The source is recorded in `authoring.source`.
- No copyrighted arrangement, edition, or transcription was copied.
- A human reference recording exists or is scheduled (T3.5 owns the 20 human
  takes).
- Legal review is tracked separately; this checklist is not legal advice.

**Evidence**

- Attach the validator command and its output to the content ticket.
- List the fixture or file path, the phrase ids, and any warnings that remain.
- Record the musical reviewer and the review date in `authoring.reviewedBy`.

## 10. Licensing and legal review

This format records provenance; it does not clear rights. **This document is
not legal advice.** Public-domain status depends on the work, the arrangement,
and the territory. T6.3 owns legal review, and no piece ships on the strength of
a `license` string alone. When in doubt, do not use the material.

## 11. Versioning and compatibility

- `schemaVersion` is `1`. A breaking change bumps it.
- A future or unknown `schemaVersion` is rejected with
  `authoring.futureSchema`; the parser does not guess.
- Unknown fields in `piece`, `phrases`, events, and `authoring` are ignored.
  They are not a stability promise; do not make runtime behavior depend on
  them.
- The authoring envelope currently shares version `1` with the canonical T2.1
  score document. A future split into separate domain and authoring versions
  must be a new authoring schema version, not an implicit change.
- Adding an optional metadata field is backward compatible. Removing or
  renaming a required field is not.

## 12. Fixtures and tests

Fixtures live in `flutter_app/test/fixtures/content/`:

| Fixture | Proves |
|---|---|
| `valid_piece.json` | Four bars, monophonic, one shift, one tie, one rest. |
| `invalid_chord.json` | `monophonic.chord` at `phrases[0].events[1]`. |
| `invalid_overlap.json` | `monophonic.overlap` at `phrases[0].events[1]`. |
| `invalid_bar.json` | `bar.durationMismatch` at `phrases[0].events`. |
| `invalid_tie.json` | `tie.mismatch` at `phrases[3].events[0].tieToNext`. |
| `invalid_fingering.json` | `fingering.mismatch` at `phrases[0].events[0]`. |
| `invalid_license.json` | `piece.licenseNotV1Compatible` at `piece.license`. |
| `future_schema.json` | `authoring.futureSchema` at `schemaVersion`. |

Run the tests:

```powershell
cd flutter_app
flutter test test/authoring_test.dart
```

CI validates `valid_piece.json` and asserts `invalid_chord.json` fails. The
validator is content tooling only; the app never imports `dart:io` or the CLI.
