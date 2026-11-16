# Reference takes (T3.5)

**Status:** the manifest contract, strict parser, validator, CLI, and recording
protocol are in place. The 20 human reference takes are **outstanding**. The
shipped manifest is empty and no audio file is in the repository.

The app does not play these takes yet. Decision 0010 keeps the phrase player out
of main navigation with `phraseLoopEnabled = false`, so this ticket does not add
a "Hear the model" button or an A/B surface. A later ticket wires playback when
the takes exist.

**This document is a product and operations document, not legal advice.** T6.3
owns legal review. The corpus custodian owns consent and the key file.

## 1. What a reference take is

A reference take is a human performance of one arrangement phrase at one tempo.
It is the model for "this is what the phrase sounds like on a guitar", not a
score and not a learner take. The app's synthesized preview is not a substitute:
a synth does not model guitar tone, articulation, or phrasing.

The recordings are human-owned. Do not commit a placeholder, a synthesized WAV,
a MIDI render, a commercial recording, or an excerpt from a copyrighted
performance. A take enters the repository only after the performer has signed
the release described in section 8.

## 2. The launch set and the 20-take count

The ticket and the plan count **20 piece takes**: the ten launch pieces at
target and slow tempo. A piece take is one recording session for one piece at
one tempo.

The manifest is phrase-level because the phrase player models one phrase at a
time. In a session, record each phrase as its own file with its own count-in.
The V1 pieces have four phrases each, so a complete launch set is:

- **20 piece takes** (10 pieces × 2 tempo variants);
- **80 phrase files** (4 phrases × 2 variants × 10 pieces).

Do not concatenate four phrases into one WAV and do not reuse one file for two
entries. The validator does not require the set to be complete: it validates
whatever is present, and an empty manifest is valid. Completeness is a launch
gate, not a parser rule.

## 3. Room, guitar, and microphone

- Use an acoustic or classical guitar in good setup. No amplifier, pickup,
  effects, backing track, or accompaniment. The V1 arrangements are monophonic.
- Use one player and one guitar for the launch set when possible. If that is not
  possible, record the real `guitar` and `microphone` values; do not pretend the
  set came from one instrument.
- Record in a quiet room with soft furnishings. Turn off fans, HVAC, phones, and
  notifications. Keep other people and pets out of the room.
- Place one microphone 20–30 cm from the 12th fret, angled slightly toward the
  body and away from the soundhole to reduce boom and pick noise.
- Keep the same microphone and placement for both tempo variants of a piece so
  an A/B comparison changes tempo, not tone.
- Tune before recording. Do not capture the tuner, a tuning phrase, or a test
  strum in the take.
- No talking, singing, counting aloud, tapping, chair noise, or page turns. The
  count-in is a click, not a voice.

Do not record through the app's learner recording flow. That flow is capped at
60 seconds and writes to the local media store, not to app assets. Use a 48 kHz
capable recorder or audio interface and copy only the approved final files into
the repository.

## 4. Count-in and take discipline

- Give **four clicks at the take tempo**, then about half a second of silence,
  then start the phrase. Leave about one second after the last note.
- The count-in and tail are part of the file, and `durationMs` is the full file
  duration, including both.
- The click must be audible in the file but quieter than the guitar. A spoken
  count is not allowed.
- A pickup phrase still gets the count-in before the pickup. Do not pad the
  pickup with a silent bar.
- Record one continuous pass. If you make a mistake, stop and restart the whole
  phrase. No punch-ins, comping, cutting, or pasting.
- Do not reuse a file for two pieces, phrases, or variants.

## 5. Tempo

The target take uses the phrase's declared target tempo exactly. The slow take
uses **60–75% of that target**, rounded to an integer inside the band. The
validator uses the same rule.

| Piece | Target BPM | Slow envelope (BPM) |
|---|---:|---:|
| `greensleeves` | 60 | 36–45 |
| `ode-to-joy` | 72 | 44–54 |
| `amazing-grace` | 66 | 40–49 |
| `down-by-the-riverside` | 76 | 46–57 |
| `original-study-1` | 60 | 36–45 |
| `scarborough-fair` | 58 | 35–43 |
| `londonderry-air` | 54 | 33–40 |
| `bach-minuet-in-g` | 72 | 44–54 |
| `spanish-romance` | 72 | 44–54 |
| `original-study-2` | 66 | 40–49 |

All four phrases of a piece currently declare the piece target. If a phrase
declares a different target, the phrase's value wins; the CLI reads the parsed
arrangement, not a hand-maintained tempo table.

Do not record the slow take at half speed, and do not round a take that sits
just outside the band. Re-record it at a tempo inside the envelope.

## 6. Audio format and file naming

- **Format:** 48 kHz, mono, PCM WAV. Use 24-bit for the master and the shipped
  file; 16-bit is accepted if the whole set uses it. No MP3, M4A, FLAC, or
  compressed delivery.
- **Loudness:** about −20 dBFS RMS over the take, within ±1 dB, with a true peak
  at or below −1 dBFS. If the raw take is quiet, apply one gain change. Do not
  compress, limit, EQ, add reverb, or run noise reduction. Re-record a clipped
  take instead of repairing it.
- **Naming:** `audio/<phrase-id>-<variant>.wav`, lowercase, no spaces. Phrase ids
  already carry the piece id. Examples:

  ```text
  assets/content/reference_takes/
    manifest.json
    audio/
      amazing-grace-p1-target.wav
      amazing-grace-p1-slow.wav
      ode-to-joy-p1-target.wav
      ode-to-joy-p1-slow.wav
  ```

- The `file` value in the manifest is the path relative to
  `assets/content/reference_takes/`, for example
  `audio/ode-to-joy-p1-target.wav`.
- `pubspec.yaml` currently declares `assets/content/reference_takes/`, which
  covers `manifest.json`. When the first audio file arrives, add
  `- assets/content/reference_takes/audio/`. Flutter asset directory entries
  are not recursive, so do not assume the parent entry covers a subdirectory.
- The performance must be of our arrangement. Do not use a commercial
  recording, a YouTube rip, a sample library, or a copyrighted edition's audio.

## 7. Manifest contract

The document lives at
`flutter_app/assets/content/reference_takes/manifest.json` and ships empty:

```json
{
  "schemaVersion": 1,
  "takes": []
}
```

One entry looks like this. The example is illustrative; it is not a committed
take.

```json
{
  "schemaVersion": 1,
  "takes": [
    {
      "pieceId": "ode-to-joy",
      "phraseId": "ode-to-joy-p1",
      "variant": "target",
      "bpm": 72,
      "file": "audio/ode-to-joy-p1-target.wav",
      "durationMs": 8450,
      "guitar": "steel-string acoustic, 6-string",
      "microphone": "small-diaphragm condenser, 30 cm, 12th fret",
      "recordedOn": "2026-11-16",
      "consentId": "rt-0007"
    }
  ]
}
```

| Field | Type | Rule |
|---|---|---|
| `schemaVersion` | integer | Currently `1`. A future version is rejected, never guessed. |
| `takes` | array | Required. May be empty. Each item is an object. |
| `pieceId` | string | One of the ten launch piece ids. |
| `phraseId` | string | A phrase that belongs to `pieceId`. Phrase ids are globally unique. |
| `variant` | string | Exactly `target` or `slow`. Any other value is rejected. |
| `bpm` | integer | `target`: exactly the phrase's declared target. `slow`: 60–75% of it, inside the integer envelope. |
| `file` | string | Non-empty and unique. A path relative to `assets/content/reference_takes/`. |
| `durationMs` | integer | Greater than zero. The full file duration, including count-in and tail. |
| `guitar` | string | Non-empty. Instrument type, model, and strings as recorded. |
| `microphone` | string | Non-empty. Microphone model and placement as recorded. |
| `recordedOn` | string | Date only, `yyyy-MM-dd`. A timestamp or an impossible date is rejected. |
| `consentId` | string | Non-empty, opaque id that links to the signed release held outside the repository. Never a name, email, address, or free text. |

Unknown fields are ignored for forward compatibility. Unknown enum values,
wrong types, a malformed date, a missing required field, and a future
`schemaVersion` are rejected with a field path such as
`takes[0].variant`. A blank `guitar`, `microphone`, or `consentId` is a
validation error, not a missing-field parse error.

## 8. Consent, storage, and deletion

[`CORPUS_CONSENT.md`](CORPUS_CONSENT.md) is the base template. It is written for
an analysis corpus, not for shipping audio in a product. Read it before the
first session and apply the stricter of the two rules when they differ.

- **Adults only.** Do not record a minor, even with a guardian's signature.
- **Base consent.** The performer reads the corpus sheet, gets a copy, chooses
  the optional raw-audio and metrics options, and receives a player ID such as
  `p01`. The name-to-ID key is stored separately by the custodian, outside the
  corpus folder and outside this repository.
- **Distribution release.** Shipping a take in the app is publication, and the
  corpus sheet does not grant it. Get a separate written release that names the
  app, the files, the territories where the app ships, and the term. Do not
  commit a take whose release does not cover app distribution. This is
  human-owned; T6.3 reviews the legal question.
- **Manifest identity.** `consentId` is the opaque link to that release. It is
  never a name. Do not put a name, email, phone number, address, account id, or
  free-text note in the manifest. The manifest is shipped in the app.
- **Storage.** Keep session masters, the consent forms, and the key file on the
  encrypted drive described in `CORPUS_CONSENT.md` §4. The repository holds only
  the approved final WAVs and the manifest. No cloud drive, chat, email, or
  public share. The app has no upload path.
- **Retention.** `CORPUS_CONSENT.md` §5 governs the corpus copies: raw audio is
  deleted 30 days after analysis sign-off and no later than 180 days after
  recording, unless the performer opted into keeping it for up to 12 months.
  The distribution release states the separate term for the app copy.
- **Deletion.** To remove a take, delete its entry from the manifest, delete the
  WAV, run the validator, and rebuild. Removing the file from the working tree
  does not remove it from Git history; a full withdrawal needs the maintainer to
  rewrite history or rotate the asset. Do not promise that a normal delete
  removes copies already cloned or installed.
- **Withdrawal.** Follow `CORPUS_CONSENT.md` §7: acknowledge within 2 business
  days, delete the audio, labels, reference files, manifest entries, and
  backups, remove the key-file row, and confirm in writing within 14 days
  (backups within 30 days).

## 9. Validation

Run from `flutter_app/`:

```powershell
dart run tool/content/validate_reference_takes.dart assets/content/reference_takes/manifest.json
dart run tool/content/validate_reference_takes.dart assets/content/reference_takes/manifest.json --json
```

The CLI builds the catalog from the ten parsed arrangements under
`assets/content/pieces/`, not from a second hand-maintained phrase list. A
missing arrangement or a piece-id mismatch is a tool error (exit 2).

Exit codes match `tool/content/validate_piece.dart`:

| Code | Meaning |
|---|---|
| `0` | No errors. |
| `1` | Validation errors, or a manifest that cannot be parsed. |
| `2` | Usage error, unreadable manifest, or unreadable piece registry. |

`--json` prints one object:

```json
{
  "valid": false,
  "errors": 1,
  "warnings": 0,
  "issues": [
    {
      "severity": "error",
      "code": "referenceTake.bpmOutsideTempoEnvelope",
      "path": "takes[0].bpm",
      "message": "Slow take is 43 BPM; the 60-75% envelope for 72 BPM is 44-54 BPM."
    }
  ]
}
```

Parse codes: `referenceTake.schemaVersion`, `referenceTake.futureSchema`,
`referenceTake.unsupportedSchema`, `referenceTake.invalidTakes`,
`referenceTake.invalidTake`, `referenceTake.missingField`,
`referenceTake.invalidType`, `referenceTake.invalidVariant`,
`referenceTake.invalidDate`, `referenceTake.invalidJson`, and
`referenceTake.invalidDocument`.

Validation codes: `referenceTake.missingKey`, `referenceTake.duplicateKey`,
`referenceTake.unknownPiece`, `referenceTake.unknownPhrase`,
`referenceTake.bpmOutsideTempoEnvelope`,
`referenceTake.durationNotPositive`, `referenceTake.emptyFile`,
`referenceTake.duplicateFile`, and `referenceTake.emptyMetadata`.

## 10. Per-take checklist

- [ ] The performer is 18 or older, the base consent is signed, and the
      distribution release covers the app.
- [ ] `consentId` is recorded; no name or contact detail is in the manifest.
- [ ] The phrase and target tempo come from the parsed arrangement.
- [ ] The slow take is inside the table's 60–75% envelope.
- [ ] Four-click count-in, no talk, and one continuous pass.
- [ ] 48 kHz mono PCM WAV, around −20 dBFS RMS, peak at or below −1 dBFS.
- [ ] The filename is `audio/<phrase-id>-<variant>.wav`.
- [ ] The manifest entry has every field and a unique `(pieceId, phraseId,
      variant)` and `file`.
- [ ] The validator exits 0.
- [ ] A human listening check finds no clipping, talking, count-in cut-off,
      wrong phrase, or wrong tempo.
- [ ] The take is our arrangement, not a copyrighted recording.

## 11. Status and next

Shipped in this ticket:

- `core/content/reference_take.dart`: the model, the versioned manifest, and
  strict parsing.
- `core/content/reference_take_validator.dart`: the semantic rules and the
  catalog interface that keeps `lib/core` free of `lib/content`.
- `tool/content/validate_reference_takes.dart`: the CLI and the real-registry
  catalog.
- `assets/content/reference_takes/manifest.json`: an empty, valid manifest.
- `test/reference_take_test.dart`: parser round-trip, every rejection rule, the
  empty manifest, and the CLI exit codes.
- This protocol.

Still outstanding:

- The 20 piece takes and their 80 phrase files.
- Signed distribution releases and T6.3's legal review.
- A playback surface. The phrase player is still gated; no "Hear the model"
  button, A/B control, or navigation entry is added here.

Do not describe the human takes as shipped, and do not label the synthesized
preview as a reference recording.
