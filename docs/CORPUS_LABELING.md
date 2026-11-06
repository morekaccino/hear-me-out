# Corpus labeling guide

**Status:** labeling rules ready. No takes or labels exist yet. Do not claim
label accuracy, inter-labeler agreement, or onset error until real files have
been labeled, reviewed, and validated.

This guide defines the ground truth for the assessment corpus. It explains what
one label event is, how to measure it, how to decide expert pass/fail, how to
handle disagreements, and how to check labels against a MIDI or direct-input
reference.

Read [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md) first. The validator is the
executable definition of the schema; if this guide and the validator disagree,
fix both in the same change.

---

## 1. Inputs and outputs

For each take, the labeler receives:

- the WAV file, exactly as recorded (no trimming, normalization, or denoising);
- the phrase card with written notes, sounding pitches, string/fret, tempo, and
  rhythm;
- the manifest entry with `takeId`, player, device, condition, and guitar;
- the consent snapshot (`audioCapture`, `keepRawAudio`, `anonymizedMetrics`);
- any session notes from the session lead.

The labeler produces one JSON file beside the WAV, following
[`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md) §8. The reviewer reads the WAV and
the phrase card independently and either signs the label or records a
disagreement.

Do not edit the WAV. Do not move it. Do not rename it. A label change is a JSON
change with a revision note; it is not an audio edit.

---

## 2. Before labeling

1. Confirm the WAV opens at the sample rate in the label. If the file says
   44.1 kHz but the header is 48 kHz, stop and fix the metadata; do not label
   against the wrong rate.
2. Confirm `channels` matches the file (1 or 2). For stereo, measure onsets on
   the channel named in `notes`; if none is named, use the left channel and
   write `channel=left`.
3. Read the phrase card. Do not infer the target from what the player did.
4. Confirm the take is in the manifest and the consent flags. If the manifest
   entry is missing or `status` is `failed`/`excluded`, label it only if the
   reviewer asks; otherwise leave it out of the scored set.
5. Open the WAV in Audacity or an equivalent editor. Use the waveform for
   onsets and the spectrogram for pitch. Do not apply a noise gate or a
   high-pass filter before measuring.

---

## 3. Target events

The label's `target` array is the **intended phrase**, not a transcription of
what the player did. Pitch, string, and fret come from the phrase card. Onset
and duration are measured from the recording. If the player plays a wrong note,
the target stays wrong-free; the wrong performance goes in `expert` and `notes`.

Each event has exactly these fields:

| Field | Type | Rule |
|---|---|---|
| `index` | integer | 0, 1, 2, … in performance order. Must equal the array position. |
| `writtenNote` | string | Written pitch from the card: uppercase `A`–`G`, optional `#` or `b`, octave. Examples: `E4`, `F#4`, `Bb3`. |
| `soundingMidi` | integer | 0–127. Must equal the written note's MIDI **minus 12**, and must equal the open-string MIDI plus fret. |
| `string` | integer | 1–6. 1 = high E, 6 = low E. |
| `fret` | integer | 0–24. 0 = open string. |
| `onsetSample` | integer | First sample of the note, measured from the start of the WAV. |
| `onsetSeconds` | number | `onsetSample / sampleRate`, finite, ≥0. |
| `durationSeconds` | number | Finite and >0. `onsetSeconds + durationSeconds` must not pass the next event's onset. |
| `confidence` | number | 0.0–1.0. Below 0.6 means the note is indeterminate. |

### 3.1 Written versus sounding pitch

Guitar music is written one octave above sounding pitch:

```
soundingMidi = writtenMidi - 12
```

This is the most common labeling mistake. Examples:

| Written | Sounds | Sounding MIDI | Where it is played |
|---|---|---|---|
| E3 | E2 | 40 | String 6, fret 0 |
| E4 | E3 | 52 | String 4, fret 2 |
| E5 | E4 | 64 | String 1, fret 0 |
| Bb4 | Bb3 | 58 | String 3, fret 3 (not A#4) |
| C5 | C4 | 60 | String 2, fret 1 |

Do not write `writtenNote: "E4"` with `soundingMidi: 64`. Written E4 sounds E3
(MIDI 52). String 1 fret 0 is written E5 and sounds E4 (MIDI 64).

Keep the spelling from the phrase card. A B-flat phrase is `Bb`, not `A#`, even
though both produce MIDI 58. The validator checks MIDI, but the label should
preserve the musical spelling because feedback and notation use it.

### 3.2 String and fret

- Use the position the player actually used. If the card says string 3 fret 2
  but the player uses string 4 fret 7 for the same pitch, label string 4 fret 7
  and add `positionChanged` to `notes`.
- Open strings are fret 0. Do not write fret 0 for a fretted note.
- No capo and no alternate tuning in this corpus. If the recording uses a capo
  or drop-D, mark the take `failed`; do not invent a string/fret mapping that
  violates the formula.
- The validator checks `openStringMidi[string] + fret = soundingMidi`. The
  open-string values are: string 1 = 64, 2 = 59, 3 = 55, 4 = 50, 5 = 45, 6 = 40.

### 3.3 Onsets

`onsetSample` is the **absolute sample index from the first sample of the WAV**,
including the count-in. It is not relative to the first note, the first beat, or
the click.

Measurement procedure:

1. Set the Audacity selection format to samples. If only seconds are available,
   multiply by `sampleRate` and round.
2. Find the first sample where the note's fundamental is present and stable
   within ±50 cents for at least three cycles. This is the **pitch onset**.
3. Do not use the pick transient. A pluck can produce a broadband click 5–15 ms
   before the periodic part. Mark the first periodic cycle, not the click.
4. Do not mark the click/drone bleed as a note onset. If the stimulus is audible,
   identify it from the spectrogram and ignore it.
5. Set `onsetSample` to that integer sample. Set `onsetSeconds` to
   `onsetSample / sampleRate`; three decimal places is enough, but it must agree
   with the sample within 1.5 ms or one sample, whichever is larger.
6. For a note that is not attempted, use the **nominal grid onset** from the
   phrase card and set `confidence` to 0.0. Add `missedIndex=<n>` to `notes`.
7. For a false start, label the notes that were played with their measured
   onsets, give the remaining target events their nominal onsets and
   `confidence: 0.0`, and set `completeness` to `incomplete`.

### 3.4 Durations and monophony

The schema is monophonic: events must not overlap.

- Measure the end as the point where the note's RMS falls 20 dB below its
  sustain, or the next note's onset, whichever comes first.
- If an open string rings into the next note, cut the duration at the next
  onset. The label describes note events, not every ringing partial.
- A tie is one event with a duration that spans both written notes. Do not create
  a second event for the tied note.
- A slur is two or more events, one per pitch change. The onset of the second
  note is the pitch transition, not a new pick attack.
- A rest is a gap between events. Do not create an event for a rest, and do not
  stretch the previous event across it.
- `phraseNoteCount` counts target **events**, not written noteheads. A tied pair
  is one event; a rest is not an event. A four-note phrase with one rest has
  `phraseNoteCount: 4` and five rhythmic positions.
- A pickup is a normal event before the first full bar. Its onset can be earlier
  than the first beat of the phrase; that is expected.

The validator rejects an event whose onset is before the previous event's end.
If that happens, re-measure the end; do not shave the onset to hide a real
overlap.

### 3.5 Confidence

Confidence is confidence in the **label**, not confidence that the app will
detect the note.

| Value | Meaning |
|---|---|
| 1.0 | Clear pitch and clear onset; no ambiguity |
| 0.8 | Slight noise or a soft attack, but the note and onset are clear |
| 0.6 | Audible and identifiable, but the onset or pitch is uncertain |
| 0.4 | Not reliably identifiable; do not use as a determinate note |
| 0.0 | Not attempted, or no pitch evidence |

Any note below 0.6 is indeterminate. A take with any indeterminate target note
is `completeness: "incomplete"` and `outcome: "indeterminate"`. If more than 20%
of notes are below 0.6, the whole take is unusable; still keep the label and say
why in `notes`.

Do not raise confidence to make a take pass. A low-confidence note is useful
evidence about the recording, not a failure of the labeler.

### 3.6 Top-level fields

| Field | Rule |
|---|---|
| `schemaVersion` | Integer `1`. Unknown versions are rejected, not guessed. |
| `takeId` | Lowercase slug ending in a three-digit sequence; must match the WAV and manifest. |
| `playerId` | `p01`–`p99`; must match the manifest. |
| `device` | Lowercase device slug such as `pixel-6a`; must match the manifest. |
| `platform` | `android`, `ios`, or `web`. |
| `condition` | `quiet`, `room-noise`, `click`, or `drone`. |
| `guitar` | `nylon` or `steel`; the instrument actually used. |
| `sampleRate` | Integer 8000–192000. The corpus uses 44100 or 48000; record the actual rate. |
| `channels` | `1` or `2`; record the actual file. |
| `tempoBpm` | Integer 60–90 for this corpus. |
| `phraseNoteCount` | `4`, `8`, or `16`; must equal `target.length`. |
| `target` | Array of note events; at least one; no unknown fields. |
| `expert` | Object with `outcome`, `noteAccuracy`, `timingOk`, `completeness`, `labeler`, `reviewedBy`. |
| `consent` | Object with `audioCapture`, `keepRawAudio`, `anonymizedMetrics`. |
| `notes` | Optional string. Use the key=value tokens in [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md) §8.3. |

Unknown fields are errors. Do not add a field locally; propose a schema version
change if the corpus needs one.

---

## 4. Expert pass/fail

`expert.outcome` is a **practice-pass** decision, not note-perfect mastery. It
answers: "Would the app be honest if it let the learner continue after this
take?" Mastery still requires 100% of notes determinate and correct on separate
days; the label keeps `noteAccuracy` so that stricter analysis is possible.

### 4.1 Fields

| Field | Rule |
|---|---|
| `outcome` | `correct`, `incorrect`, or `indeterminate` |
| `noteAccuracy` | Correct determinate target notes ÷ total target notes, 0.0–1.0 |
| `timingOk` | `true` if the timing rule below passes |
| `completeness` | `complete` or `incomplete` |
| `labeler` | Primary labeler ID; non-empty |
| `reviewedBy` | Independent reviewer ID; non-empty and different from `labeler` |

### 4.2 Completeness

`complete` means all target notes were attempted, audible, and have confidence
≥0.6, and the player reached the final note. `incomplete` means any of these:

- a target note was skipped or not attempted;
- a target note is below 0.6 confidence;
- the player false-started or stopped early;
- the take is unreadable because of clipping, dropout, or noise;
- the tuning offset is strictly greater than 30 cents, so the pitch is not a
  fair test. At exactly +30 cents the take is at the boundary and may be
  `complete` if it is otherwise clear.

An incomplete take is always `indeterminate`, never `incorrect`. A missed note is
not a wrong note; it is missing evidence. The app should offer a retry, not fail
the learner.

A **wrong** note is attempted and audible, so it does not make the take
incomplete. It reduces `noteAccuracy`.

### 4.3 Note accuracy

Count a target note as correct only when the sounding pitch class and octave
match the target. A semitone error, an octave error, or a different note is
wrong. An extra note is not in the target, so it does not change
`noteAccuracy`; it forces `outcome: "incorrect"` under §4.5.

For a complete take every target note is determinate, so this equals the plan's
practice-pass fraction of determinate notes. For an incomplete take the value is
diagnostic only; the outcome is `indeterminate` regardless of the number.

Examples:

- 8 targets, 7 correct, 1 one-semitone error: `noteAccuracy = 7 / 8 = 0.875`.
- 8 targets, 7 correct, 1 missed: `noteAccuracy = 0.875`, but completeness is
  `incomplete`, so outcome is `indeterminate`, not `correct`.
- 4 targets, 3 correct, 1 wrong: `noteAccuracy = 0.75`, below 0.85, so
  `incorrect`.
- 16 targets, 15 correct, 1 wrong: `noteAccuracy = 0.9375`, which can still be
  `correct` if timing is OK and there is no extra note or octave error.
- One octave error: `incorrect`, regardless of the accuracy number.

### 4.4 Timing

Use the fixed click/beat grid. Do not warp the grid to fit the performance.

- The first beat after the count-in is `beatZero`. If `beatZeroSample` is in
  `notes`, use it; otherwise use the phrase card's first-beat time.
- The nominal onset of note `i` is `beatZero + gridOffset(i)`, where
  `gridOffset` comes from the phrase card.
- For a pickup, `gridOffset` is negative (for example, one beat before
  `beatZero`).
- Compute `error = measuredOnset - nominalOnset` for every determinate note.
- Tolerance is **`140 - tempoBpm` milliseconds**: 80 ms at 60 BPM, 68 ms at
  72 BPM, 50 ms at 90 BPM.
- `timingOk` is true when the **median absolute error is ≤ tolerance** and no
  more than one note is beyond **2× tolerance**.
- For phrases with at least two bars, if the per-bar mean error drifts by more
  than the tolerance from the first to the last bar, `timingOk` is false, even
  if the median is inside tolerance. This catches rushing or dragging late in a
  16-note phrase.
- A note that is deliberately late for musical phrasing is still late for this
  label. The corpus measures the assessment, not interpretation.

### 4.5 Outcome rule

Apply the rules in this order:

1. **Incomplete → indeterminate.** If `completeness` is `incomplete`, outcome is
   `indeterminate`, regardless of how many notes were correct.
2. **Extra note → incorrect.** If the player added any note that is not in the
   target, outcome is `incorrect`, even when every target note is correct.
3. **Octave error → incorrect.** An octave-off note is not a pass.
4. **Accuracy below 0.85 → incorrect.**
5. **Timing failure → incorrect.**
6. Otherwise **correct**.

The 0.85 threshold is the practice-pass rule from
[`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md) §4.3. It is not
the mastery rule. A `correct` take can contain one wrong note in eight or two
wrong notes in sixteen; record that in `noteAccuracy`, and do not describe the
take as note-perfect.

A take with an extra note can still have `completeness: "complete"` because all
target notes were attempted. The extra note is an error, not missing evidence.
Record it in `notes` as `extraNote=<written>@<onsetSeconds>`.

The validator enforces the schema, the confidence rule, and the
correct/incomplete invariants. It cannot verify an extra note or a timing
failure from free-text `notes`; the reviewer checks those rules by listening to
the take. If they must be machine-checked, add structured fields in schema v2
rather than parsing `notes`.

### 4.6 Indeterminate versus incorrect

Use **indeterminate** when the evidence cannot support a pass/fail decision:

- a target note is skipped, inaudible, or below 0.6 confidence;
- the player false-starts or stops early;
- clipping, dropout, or noise makes the pitch unreadable;
- click/drone bleed masks a note;
- the guitar is more than 30 cents out of tune;
- the wrong phrase or wrong tempo was played;
- the take is a failed recording (phone call, wrong device, corrupt file).

Use **incorrect** when the evidence is clear and the performance fails:

- a determinate wrong pitch or octave;
- an extra note;
- timing outside the tolerance;
- a restart that still produced a complete but wrong performance.

Do not mark a take incorrect because it is noisy. Noise is an evidence problem;
mark it indeterminate. Do not mark a take incorrect because the player is a
beginner; the corpus needs honest beginner data.

---

## 5. Inter-labeler review and adjudication

### 5.1 Sample

- The primary labeler labels 100% of accepted takes.
- The reviewer independently re-labels at least **20%** of accepted takes,
  randomly selected and stratified by device class, condition, phrase length,
  and outcome.
- Re-label **100% of indeterminate takes** and **100% of the MIDI/interface
  reference subset**. Add all `incorrect` takes if time allows.
- The reviewer must not see the primary label before finishing their own pass.
  Use a separate copy of the JSON or a blank form.

### 5.2 What counts as a disagreement

A disagreement exists when any of these differ:

- `expert.outcome`;
- `expert.completeness`;
- a target note's pitch (written or sounding);
- a target note's string or fret;
- an onset by more than **20 ms**;
- an extra or missed note in `notes`.

Differences in `confidence` alone are not a disagreement unless they cross the
0.6 boundary.

### 5.3 Adjudication

1. The reviewer records the disagreement with both labels and the timecode.
2. A third reviewer listens to the take without seeing either label.
3. If two of the three agree, use that result. If all three differ, use
   `indeterminate` and write `adjudication=unresolved` in `notes`.
4. The final JSON keeps the adjudicated values. The primary labeler's original
   values stay in git history (or `revisions/`), not in the final file.
5. Add `adjudicated=<date> <reason>` and the reviewer ID to `notes` or
   `expert.reviewedBy`.

No one reviews their own take. No one is the third reviewer for a take they
primary-labeled or reviewed.

### 5.4 Agreement statistics

After the corpus is labeled, compute and report:

- Cohen's kappa for pass/fail (`correct` vs not correct), target **≥0.70**;
- ICC(2,k) for `noteAccuracy`, target **≥0.75**;
- onset agreement (mean absolute difference and 95% limits) on the
  double-labeled subset.

Do not estimate or claim these values before the double-labeled files exist.
Record the command or script used to compute them in the T1.6 report.

---

## 6. Validating labels against a MIDI/interface reference

At least **10% of takes and no fewer than 24 takes** need a simultaneous
MIDI/interface reference. The reference is the truth for pitch and onset; the
phone recording is the device under test.

### 6.1 Rig

- Guitar → audio interface with a clean DI, recorded on a computer.
- If available, guitar → MIDI pickup or MIDI guitar, recorded as MIDI.
- Phone/tablet/laptop records the same performance through its microphone.
- Start both recordings before the count-in. Keep them running through the
  phrase.
- Make one sharp clap, or let the count-in click appear in both files, for
  alignment.
- Export the DI as WAV PCM16 at the same sample rate as the phone file. Do not
  apply amp simulation, EQ, compression, reverb, or noise reduction.

### 6.2 Label from the reference

1. Measure the performed pitch, onset, and duration from the DI/MIDI. Keep the
   target pitch, string, and fret from the phrase card.
2. Compare the phone label to the reference. The reference is the truth for the
   performance; do not lower its confidence because the phone missed a note.
3. If the phone missed a note that the DI proves was played, the label keeps the
   note as determinate. That is a false negative for the app, which is exactly
   what the corpus needs to measure.
4. If the DI is unusable for a note (dropout, clipping), use the phone audio and
   lower confidence.
5. If the phone and DI disagree on onset, use the DI onset and record the phone
   difference in `notes` as `phoneOnsetDeltaMs=<n>`.

### 6.3 Acceptance for the reference subset

- Onset difference between the label and the DI: **≤10 ms** mean absolute error,
  and no single disagreement above 20 ms without a written explanation.
- Pitch: exact MIDI note, including octave. No semitone or octave tolerance.
- String/fret: from the phrase card and the player's observed position; the DI
  cannot reveal fingering.
- Store the DI at `corpus/reference/<takeId>-di.wav` and add `reference=di` to
  `notes`.

If the subset does not meet these limits, fix the labels or the rig before
running T1.6. Do not report corpus validity from a reference set that disagrees
with the DI.

---

## 7. Worked examples

These examples are illustrative labels, not recorded takes. The onset values
assume 48 kHz and the count-in rule in the protocol.

### 7.1 Clean take

A 4-note first-position phrase at 60 BPM, played exactly on the grid. The
phrase mixes fretted and open strings.

| Index | Written | Sounding | String | Fret | Onset sample | Onset seconds | Duration | Confidence |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 0 | E4 | 52 | 4 | 2 | 204000 | 4.25 | 0.9 | 1.0 |
| 1 | F4 | 53 | 4 | 3 | 252000 | 5.25 | 0.9 | 1.0 |
| 2 | G4 | 55 | 3 | 0 | 300000 | 6.25 | 0.9 | 1.0 |
| 3 | E5 | 64 | 1 | 0 | 348000 | 7.25 | 1.0 | 1.0 |

```json
"expert": {
  "outcome": "correct",
  "noteAccuracy": 1.0,
  "timingOk": true,
  "completeness": "complete",
  "labeler": "expert-a",
  "reviewedBy": "expert-b"
}
```

Why: every target note is determinate and correct, no extra note, timing errors
are inside 80 ms, and the player reached the end.

### 7.2 One-semitone error

The same 4-note phrase, but index 2 is played as G-sharp instead of G. The target
stays G4.

- `noteAccuracy = 3 / 4 = 0.75`.
- `completeness = "complete"` (all notes attempted and audible).
- `timingOk = true`.
- `outcome = "incorrect"` because 0.75 is below 0.85.
- `notes = "wrongPitch[2]=G#4"`.

Do not change `writtenNote` or `soundingMidi` to G-sharp. The target is the
phrase on the card; the wrong performance is the evidence.

If the same error occurred in an 8-note phrase (7/8 correct, 0.875), the take
could be `correct` if timing is OK and there is no extra note or octave error.
That is the practice-pass rule, not a claim of mastery.

### 7.3 Missed note

An 8-note phrase; the player skips index 3 and continues to the end.

- Target stays 8 events.
- Index 3 gets the nominal grid onset and gap duration, `confidence: 0.0`.
- `noteAccuracy = 7 / 8 = 0.875` (diagnostic only).
- `completeness = "incomplete"` because a target note was not attempted.
- `outcome = "indeterminate"`, not `incorrect`.
- `notes = "missedIndex=3"`.

Why: an unattempted note is missing evidence. The app should offer a retry, not
fail the learner. Do not mark the missed note as a wrong pitch.

### 7.4 Extra note

An 8-note phrase with all 8 target notes correct, but the player adds an E5
between index 4 and index 5.

- `noteAccuracy = 1.0`.
- `completeness = "complete"`.
- `timingOk = true`.
- `outcome = "incorrect"` because of the extra note.
- `notes = "extraNote=E5@6.50s"`.

Why: extra notes count as errors in the product rule. The target array does not
gain an event for the extra note; it is evidence against the performance.

### 7.5 False start

The player starts the phrase, stops after two notes, and restarts. Keep the
first file.

- Label the two played notes with measured onsets.
- Give the remaining target notes nominal onsets, gap durations, and
  `confidence: 0.0`.
- `completeness = "incomplete"`.
- `outcome = "indeterminate"`.
- `notes = "falseStart; restarted at p01-pixel-6a-quiet-002"`.
- The restarted performance gets the next take ID, for example
  `p01-pixel-6a-quiet-002`.

Do not delete the false start. It is evidence that the endpoint behavior needs
to handle a restart.

### 7.6 Noisy take

A room-noise take where 3 of 8 notes are below 0.6 confidence and the rest are
clear.

- `completeness = "incomplete"` because any indeterminate target note makes the
  take incomplete.
- `outcome = "indeterminate"`.
- `noteAccuracy` is diagnostic; compute it over the target (for example, 5/8 =
  0.625) but do not use it to call the take incorrect.
- `notes = "noise=room-noise; lowConfidence[1,4,6]"`.

If all 8 notes are readable but the recording is noisy, keep
`completeness: "complete"` and apply the normal accuracy/timing rule. Noise is
not automatically a failure; only unreadable notes are.

If the take is clipped so badly that pitch is unreadable, mark it
`indeterminate` and `notes = "clipping"`. Do not try to reconstruct the pitch
from a distorted waveform.

### 7.7 Tuning-offset takes

The rule is **strictly greater than 30 cents**. At exactly +30 cents the take is
at the boundary and is labelled normally; above +30 cents it is indeterminate.

A deliberate +50-cent take. The player plays the right notes, but the guitar is
out of tune.

- `completeness = "incomplete"` (the take is not a fair pitch test).
- `outcome = "indeterminate"`.
- `notes = "tuningOffsetCents=+50"`.

The product should ask the learner to tune, not mark the note wrong. A
deliberate +30-cent take is labelled normally: keep `completeness: "complete"`
and apply the ordinary accuracy/timing rule, with `notes =
"tuningOffsetCents=+30"`. At +5 cents or better, also label normally.

---

## 8. Label checklist

Before saving a label:

- [ ] `takeId`, `playerId`, `device`, `platform`, `condition`, and `guitar`
      match the manifest and the folder. `guitar` must equal the player's
      registered guitar, or the player must be registered as `both`.
- [ ] `schemaVersion` is 1.
- [ ] `sampleRate` and `channels` match the WAV header.
- [ ] `tempoBpm` is 60–90 and matches the phrase card.
- [ ] `phraseNoteCount` is 4, 8, or 16 and equals `target.length`.
- [ ] Every `index` equals its array position, starting at 0.
- [ ] Every `writtenNote` uses the card's spelling.
- [ ] Every `soundingMidi = writtenMidi - 12`.
- [ ] Every `soundingMidi = openStringMidi[string] + fret`.
- [ ] Every `onsetSample` is a non-negative integer from the file start.
- [ ] Every `onsetSeconds` agrees with `onsetSample / sampleRate` within 1.5 ms.
- [ ] Every `durationSeconds` is >0.
- [ ] No event starts before the previous event ends.
- [ ] Every `confidence` is 0.0–1.0; below 0.6 is indeterminate.
- [ ] Any note below 0.6 confidence forces `completeness: "incomplete"` and
      `outcome: "indeterminate"`.
- [ ] `expert.outcome`, `noteAccuracy`, `timingOk`, and `completeness` follow
      §4.5.
- [ ] `expert.labeler` and `expert.reviewedBy` are different.
- [ ] `consent.audioCapture` is true for a take with audio.
- [ ] `consent.keepRawAudio` is not true when `audioCapture` is false.
- [ ] `notes` records every missed note, extra note, wrong pitch, false start,
      early stop, tuning offset, and reference.
- [ ] The validator exits 0.

Run:

```powershell
dart run tool/corpus/validate_labels.dart `
  corpus/p01/pixel-6a/quiet/p01-pixel-6a-quiet-001.json `
  --manifest corpus/manifest.json
```

If the validator reports an error, fix the label. If it reports a warning,
check whether the corpus is incomplete; do not silence the warning.

---

## 9. Common mistakes

| Mistake | Why it fails | Fix |
|---|---|---|
| Written E4 with sounding 64 | Guitar sounds an octave below written; E4 sounds 52 | Use written E5 / sounding 64 for string 1 fret 0 |
| Written E4 with string 1 fret 0 | String 1 fret 0 is written E5 | Read the phrase card's octave |
| `onsetSeconds` measured from the first note | Onsets are from the start of the WAV | Add the count-in offset |
| `onsetSample` not matching `onsetSeconds` | The two fields are redundant evidence | Compute seconds from the sample |
| Events overlap | The schema is monophonic | End the previous event at the next onset |
| Missing note marked as wrong | A skipped note is missing evidence | Use `incomplete` + `indeterminate` |
| Target changed to match a wrong note | The target is the intended phrase | Keep the card's pitch; record the error |
| Extra note ignored | Extra notes are errors | Add `extraNote=` and mark incorrect |
| Deleting a failed take | Failed takes are evidence | Keep the file; mark `failed` |
| Same labeler and reviewer | No independent check | Use a different reviewer |
| Flat changed to sharp | Spelling matters for notation/feedback | Keep the card's `Bb`/`Eb` spelling |
| Wrong sample rate | All sample/seconds math breaks | Read the WAV header before labeling |
| Raw audio committed to git | The corpus must stay local | Ignore `*.wav`; commit labels only |
| Labeling from the phone instead of the DI | The reference is the truth | Label from the DI, compare the phone |

---

## 10. What this guide does not do

It does not recruit players, record takes, or produce metrics. It does not claim
that the validator has been run on a real corpus. It defines the rules so that
when the corpus exists, the labels are usable as ground truth.

If a rule here is unclear, stop and ask the reviewer. A guess recorded as a
label is worse than a missing take.
