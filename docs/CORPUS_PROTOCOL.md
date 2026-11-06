# Corpus protocol — assessment spike

**Status:** protocol ready for use. No corpus has been recorded. Do not report a
player count, take count, onset error, label agreement, or any other metric until
the files exist and the validator passes.

**Owner:** T1.2. **Execution:** T1.6. **Recruitment:** T1.1.

This is the operating protocol for the assessment corpus described in
[`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md) §4.5. It defines
who does what, which devices and rooms are used, how a take is recorded, how it
is named, and how ground truth is stored. It is not evidence that the spike has
passed.

Related documents:

- [`CORPUS_CONSENT.md`](CORPUS_CONSENT.md) — participant consent and deletion.
- [`CORPUS_LABELING.md`](CORPUS_LABELING.md) — how to create and review labels.
- [`../tool/corpus/README.md`](../tool/corpus/README.md) — validator commands.
- [`../test/fixtures/corpus/valid_labels.json`](../test/fixtures/corpus/valid_labels.json)
  — a valid 8-note label.

---

## 0. Session lead quick start

Print this page and keep it next to the recorder.

1. **Before the session.** Confirm the participant signed the consent sheet and
   chose whether raw audio may be kept. Assign the next player ID (`p01`–`p10`).
   Do not put the player's name in any file name or label.
2. **Set up the room and device** using §4. Record a 10-second room tone before
   the first take.
3. **Tune** to A4 = 440 Hz. Check all six open strings with a clip-on tuner.
   Record the offset in cents.
4. **Record the core take set** in §5: ten takes per player per assigned
   device/condition cell. Each cell needs two players' core sets, or 20 accepted
   takes. Log every take in `manifest.json` as it is recorded.
5. **Copy the files** to the encrypted corpus drive. Do not leave the only copy
   on the phone or laptop.
6. **Label** every take with the labeling guide. Run the validator on every
   label.
7. **Second-label** at least 20% of takes and adjudicate every disagreement.
8. **Close the session.** Update the manifest, back up, and record the retention
   date. Raw audio is deleted 30 days after analysis sign-off unless the
   participant opted in to keeping it.

If a step cannot be completed, write the reason in the take's `notes` and mark
the take `failed` in the manifest. Do not silently skip a take.

---

## 1. Roles and responsibilities

| Role | Owns | Must not |
|---|---|---|
| **Recruiter** (T1.1) | Recruiting 6–10 eligible players, scheduling, assigning player IDs, sending the consent sheet at least 24 hours before the session, keeping the player-key file separate from the corpus | Label or review takes from their own session |
| **Session lead** | Consent check, room and device setup, tuning, recording, file naming, manifest entries, backup, validator run | Change a label after the reviewer signs it without recording the revision |
| **Labeler** | Turning each WAV into a label JSON, marking confidence, writing the expert outcome and notes | Label a take they played; edit or trim the audio |
| **Reviewer / data custodian** | Second-labeling at least 20%, adjudicating disagreements, holding the encrypted drive and access log, running deletion, signing the retention log | Review the same take they primary-labeled |

Rules:

- A take has one primary labeler and one reviewer. The two names must differ in
  the label (`expert.labeler`, `expert.reviewedBy`).
- The player ID key is stored outside `corpus/`. The corpus contains no names,
  email addresses, phone numbers, or account IDs.
- One person may hold more than one role across different sessions, but never
  both label and review the same take.
- If the session lead is also the player for a take, another person must run the
  recorder and log the take.

---

## 2. Participants and mix

### 2.1 Eligibility

A participant is eligible when all of these are true:

- 18 years or older and able to give informed consent.
- Can hold a guitar safely and play a four-note phrase at 60 BPM.
- Can tune with help or with a tuner.
- Has no active hand, wrist, or shoulder injury that playing would aggravate.

Do not exclude a player for skill, instrument price, guitar type, spoken
language, or reading fluency. The corpus needs near-beginners, not polished
performers.

### 2.2 Required mix

Recruit **6 to 10 players** with this minimum mix:

| Requirement | Minimum | Where it is recorded |
|---|---|---|
| Returners | 3 | `players[].segment = "returner"` |
| Near-beginners | 3 | `players[].segment = "near-beginner"` |
| Guitar types | 2 (nylon and steel) | `players[].guitar` and each label's `guitar` |
| Distinct playing levels | 3 | `players[].playingLevel` (1–5) |

Definitions:

- **Returner:** played guitar for at least one year in the past, stopped for at
  least six months, and is playing again. May read notation or tab slowly.
- **Near-beginner:** less than 12 months of total playing, can play open strings
  and simple first-position notes, may not read notation fluently.
- **Playing level (self-rated):** 1 = first month, 2 = can play simple open
  chords, 3 = can play a short piece slowly, 4 = can play barre chords and
  shift, 5 = can sight-read simple pieces. Record the participant's own number;
  do not correct it.

If a player owns both a nylon- and a steel-string guitar, set
`players[].guitar = "both"`, and use the actual guitar on each take's `guitar`
field. A player may record on more than one guitar; this is useful, but do not
count one player twice in the mix.

### 2.3 Player IDs and key file

- Assign `p01` through `p10` in recruitment order.
- Write the name-to-ID mapping only in `corpus-keys/player-key.csv`, stored
  outside the corpus folder on the encrypted drive. The custodian is the only
  person who opens it.
- Never reuse a player ID, even if a player withdraws.
- If a player withdraws, delete their corpus folder and manifest entries. Keep
  only the deletion log in §10.

---

## 3. Devices and conditions

### 3.1 Device classes

Use four device classes. The exact model is recorded in `device`; the class is
recorded in the manifest.

| Class | `deviceClass` | Example device | `platform` |
|---|---|---|---|
| Mid-range Android phone | `mid-range-android` | Pixel 6a, Galaxy A54, or a 2–3 year old phone | `android` |
| iPhone | `iphone` | iPhone 12, 13, or newer | `ios` |
| Tablet | `tablet` | iPad 9th generation or newer; Galaxy Tab A | `ios` or `android` |
| Laptop / web | `laptop-web` | Windows, macOS, or Chromebook running the web build | `web` |

Record the actual model as a lowercase slug, for example `pixel-6a`,
`iphone-13`, `ipad-9`, `thinkpad-x1`. Do not label a device `android`; that is a
platform, not a device.

### 3.2 Conditions

There are three condition buckets. The last bucket contains two stimuli, so the
label's `condition` is one of four values.

| Bucket | Label value | Setup | Target |
|---|---|---|---|
| Quiet | `quiet` | Closed door, no HVAC, no fan, no notifications, ≤35 dBA | Clean reference |
| Room noise | `room-noise` | 45–55 dBA of non-guitar noise: room-noise playlist, chair, traffic through a window, or a television at low volume | Realistic home noise |
| Click / drone | `click` or `drone` | Click at the take tempo, or a sustained tonic drone, through the device speaker at 65–70 dBA at the player's ear | Bleed and sustained-noise robustness |

Use a noise generator or a recording for room noise. Do not record bystanders'
speech without their consent. Do not use music that contains guitar.

For the click/drone bucket, split the 20 takes per cell as evenly as possible
between `click` and `drone`. The manifest summary groups both values under
`click-drone`; the label keeps the exact value.

### 3.3 Matrix and take count

Each of the 4 device classes is crossed with each of the 3 condition buckets.
That is 12 cells. Each cell needs **at least 20 accepted takes**, for at least
**240 accepted takes** total.

| Device class | Quiet | Room noise | Click / drone |
|---|---:|---:|---:|
| `mid-range-android` | 20 | 20 | 20 |
| `iphone` | 20 | 20 | 20 |
| `tablet` | 20 | 20 | 20 |
| `laptop-web` | 20 | 20 | 20 |

Plan the session allocation before recruiting:

- 8 players × 3 cells × 10 takes = 240.
- 6 players × 4 cells × 10 takes = 240.
- 10 players: 4 players cover 3 cells and 6 players cover 2 cells = 24 cells;
  24 × 10 = 240.

Each cell should contain takes from at least two players so a single player's
instrument or room does not define the cell. Every player should use at least
two device classes when practical. Record the assignment in the manifest; do
not rely on memory.

### 3.4 Playback routes and the bleed study

The main matrix uses the device's built-in microphone and the device speaker
for click/drone. This is deliberate: the corpus must show what happens when the
click or drone leaks into the recording.

Add a bleed subset of at least 24 takes total: at least 2 phrase instances per
cell, each recorded under all three routes (8 phrase instances × 3 routes = 24).
The three routes are:

1. **Speaker** — click/drone from the device speaker. This is the main condition.
2. **Wired headphones** — click/drone in wired headphones; the microphone still
   records the guitar.
3. **Bluetooth headphones** — click/drone over Bluetooth.

Use the same phrase and tempo for the three takes. Note the route in `notes`,
for example `monitor=wired-headphones`. Bluetooth takes are for the bleed study
only; do not use them for timing labels because Bluetooth adds latency that the
label cannot recover.

For quiet and room-noise takes, the player may use wired headphones for a click
if needed. Record `monitor=wired-headphones` in `notes`; otherwise record
`monitor=none`.

---

## 4. Room setup, gain staging, and capture

### 4.1 Room

- Use the quietest room available. Close windows and doors. Turn off fans,
  air-conditioning, washing machines, and desk lamps with noisy transformers.
- Put the phone in airplane mode and turn off notifications. Do not take calls
  during a session.
- Use a soft furnishing behind the player if the room is bright or echoey. Do
  not move furniture between takes in the same cell.
- Keep the player, chair, microphone position, and guitar the same for every
  take in a cell. Mark the microphone position with tape.
- Keep other people out of the room. If someone must be present, they must sign
  the consent sheet or stay silent and out of microphone range.

### 4.2 Microphone placement

- Phone or tablet: 30 cm from the 12th fret, about 45° off the soundhole axis,
  slightly above the guitar. Do not point the microphone into the soundhole.
- Laptop or web: use the built-in microphone at 50 cm, or a USB microphone at
  30 cm. Record which one was used in `notes` (`mic=built-in` or `mic=usb`).
- Keep the same placement for every take on that device.

### 4.3 Gain staging

- Set gain manually. Disable automatic gain control, noise suppression, and echo
  cancellation when the recorder allows it.
- Aim for peaks between **−12 dBFS and −6 dBFS**. Never clip.
- Record a five-second loud strum and check the meter before the first take. If
  it clips, lower the gain and repeat the check.
- Do not normalize, compress, denoise, or trim the archived WAV. All processing
  happens after the raw file is stored.
- If the recorder has no meter, record a test take, inspect the waveform, and
  adjust. Delete the test take only if it contains no usable phrase and the
  participant agrees; otherwise mark it `failed`.

### 4.4 Sample rate, channels, and file format

- Store **WAV, PCM16**, mono by default. Stereo is allowed only for the one
  required stereo case.
- Capture at the device's native rate. Record the actual value in
  `sampleRate`: 44100 and 48000 are expected; 16000 is acceptable only if the
  device cannot do better, and must be noted.
- Record the actual channel count in `channels` (1 or 2).
- Include one **48 kHz-only Android case** and one **stereo case** in the
  corpus. These are explicit spike requirements, not optional extras.
- Do not resample before archiving. If a resampled copy is needed, keep the
  original and write `resampled-from=<rate>` in `notes`.
- Budget about 6 MB per 60-second mono WAV. 240 takes of 10 seconds are roughly
  25 MB; longer piece takes dominate. Keep at least 5 GB free on the recorder
  and the corpus drive.

### 4.5 Tuning

- Tune to **A4 = 440 Hz** with a clip-on tuner or a trusted tuner app.
- Check open strings 6 to 1: E2, A2, D3, G3, B3, E4 (sounding).
- A baseline take must be within **±5 cents** on every string. Record the worst
  offset in `notes`, for example `tuningOffsetCents=+3`.
- Record deliberate tuning-offset takes at **+30 cents** and **+50 cents** on
  one device per player. Retune to baseline after them. These takes are labelled
  `indeterminate`, not `incorrect`; the product should ask the player to tune,
  not fail them.
- If a string goes out during a session, retune and note it. If the take is
  already recorded and the drift is audible, mark it `failed` and record again.

### 4.6 Count-in and clock

- Record a full 4/4 bar of count-in before the phrase: four clicks at the take
  tempo. The first click is at **0.25 s** after the start of the file, so the
  first phrase beat is at 4.25 s at 60 BPM. If the recorder starts at a different
  offset, keep the offset consistent and record the actual first-beat sample in
  `notes` as `beatZeroSample=<n>`.
- Do not edit out the count-in. It is the timing reference and evidence that the
  tempo was correct.
- For a pickup, keep the full count-in and start the pickup one beat before the
  first full bar. Note `pickup=true` and the pickup beat in `notes`.
- Keep recording for two seconds after the last note. This captures release and
  room tone and makes offset labeling possible.

### 4.7 Room tone

At the start of each device/condition session, record **10 seconds of room
tone** with the guitar silent. Store it as
`corpus/<player>/<device>/<condition>/roomtone-<device>-<condition>.wav`. It is
not a label take and does not go in `manifest.json` as a scored take. Use it to
check noise floor and clipping.

---

## 5. Take script

### 5.1 Core ten takes per player per cell

Each player records these ten takes in every assigned device/condition cell.
Two players' core sets make the 20-take minimum for a cell. Rotate the order
between players so fatigue does not always hit the 16-note phrases. The session
lead may change the order but not the set.

| # | ID | Phrase | Tempo | What it covers |
|---|---|---|---|---|
| 1 | `P4-A` | 4 notes, open strings 6→3, one note per beat | 60 | Open strings, low register |
| 2 | `P4-B` | 4 notes, frets 1-2-3-4 on string 3 | 60 | Fretted notes, no open strings |
| 3 | `P8-A` | 8 notes, E-minor first position (the fixture phrase) | 60 | Mixed open/fretted, 8-note phrase |
| 4 | `P8-B` | 8 notes, one note per string, 6→1 | 72 | String crossing, full range |
| 5 | `P8-C` | 8 notes from a public-domain piece | 72 | Actual repertoire |
| 6 | `P16-A` | 16 notes, E-minor scale fragment from low E to high E | 90 | 16-note phrase, high and low strings |
| 7 | `P16-B` | 16 notes from a public-domain piece | 90 | 16-note repertoire phrase |
| 8 | `P4-R` | 4 notes with a rest: note-rest-note-note | 60 | Rests |
| 9 | `P8-S` | 8 notes with a slur, a tie, and a position shift | 72 | Articulation and shift |
| 10 | `E-01` | Endpoint take: rotate early stop, extra note, missed note, false start | 60–90 | Endpoint behavior |

This gives three 4-note takes, four 8-note takes, two 16-note takes, and one
endpoint take per player per cell. Across the cell's 20 takes, include both
guitar types when the assigned players own them; at minimum the corpus as a
whole must include nylon and steel. If a cell's two players both have the same
guitar type, schedule a third player or swap a device assignment.

### 5.2 Phrase cards

Every phrase gets a card before the session. A card contains:

- phrase ID and title;
- written notes and sounding MIDI;
- string and fret for every note;
- rhythm, meter, and tempo;
- count-in length and first-beat position;
- whether it contains a pickup, rest, slur, tie, or shift;
- source for a piece phrase (public-domain title, composer, bar numbers).

The session lead must be able to hand the card to the player without explaining
music theory. If a player cannot read the card, the session lead may demonstrate
the phrase once, then the player plays it. Do not coach during the scored take.

#### P8-A card (fixture phrase)

This is the same phrase as
[`../test/fixtures/corpus/valid_labels.json`](../test/fixtures/corpus/valid_labels.json).
It is an E-minor first-position phrase in 4/4 at 60 BPM, eight eighth notes.

| Index | Written | Sounding | String | Fret | Nominal onset |
|---:|---|---|---:|---:|---:|
| 0 | E4 | E3 (MIDI 52) | 4 | 2 | 4.25 s |
| 1 | F4 | F3 (MIDI 53) | 4 | 3 | 4.75 s |
| 2 | G4 | G3 (MIDI 55) | 3 | 0 | 5.25 s |
| 3 | A4 | A3 (MIDI 57) | 3 | 2 | 5.75 s |
| 4 | B4 | B3 (MIDI 59) | 2 | 0 | 6.25 s |
| 5 | C5 | C4 (MIDI 60) | 2 | 1 | 6.75 s |
| 6 | D5 | D4 (MIDI 62) | 2 | 3 | 7.25 s |
| 7 | E5 | E4 (MIDI 64) | 1 | 0 | 7.75 s |

The nominal onsets assume the first count-in click at 0.25 s. The label records
the **measured** onsets, not these nominal values, when the player is early or
late.

### 5.3 Tempo and rhythm

- 4-note phrases: one note per beat at **60 BPM** (quarter notes).
- 8-note phrases: eighth notes at **60 or 72 BPM**, or quarter notes where the
  card says so. Record the actual `tempoBpm`.
- 16-note phrases: sixteenth notes at **90 BPM**, or eighth notes at 60 BPM
  where the card says so. A 16-note phrase at 90 BPM is demanding; the session
  lead may lower it to 72 or 60 if the player cannot complete it, but then
  record the lower tempo. Do not change tempo mid-take.
- Keep the same tempo for every take in a phrase set. The corpus needs 60, 72,
  and 90 BPM represented; it does not need every tempo for every player.
- Use a click for all scored takes except the quiet/room-noise takes where the
  player prefers no click. If there is no click, timing is labelled against the
  hidden grid from the count-in and the phrase card; note `stimulus=none`.

### 5.4 Open and fretted notes, strings, and guitar types

The corpus must include:

- open strings 6, 5, 4, 3, 2, and 1;
- fretted notes at frets 1–4, with at least one take reaching fret 5 or higher;
- sounding range from E2 (low E) to E4 (high E), and at least one phrase that
  crosses all six strings;
- nylon and steel guitars;
- at least one slur, one tie, one rest, and one position shift;
- actual piece phrases, not only scales.

Record the actual string and fret used on the take. If the player uses a
different position than the card, label the position they actually used if it
produces the target pitch. Do not change the target pitch to match a mistake.

### 5.5 Count-in, pickup, early stop, extra note, missed note, false start

| Event | What the player does | What the session lead does | Label |
|---|---|---|---|
| **Count-in** | Waits through four clicks | Keeps the count-in in the file | Onsets measured from file start; `beatZeroSample` in `notes` |
| **Pickup** | Starts before the first full bar | Keeps the full count-in | `pickup=true`; pickup onset may be one beat before beat 1 |
| **Early stop** | Stops before the last note | Keeps recording for two seconds; does not prompt | `completeness=incomplete`; `outcome=indeterminate`; note `earlyStop` |
| **Extra note** | Adds a note that is not in the target | Lets the player finish; does not stop the take | Target unchanged; `outcome=incorrect`; note `extraNote=<note>@<time>` |
| **Missed note** | Skips a target note | Does not point it out during the take | Target unchanged; missing event gets the nominal onset, gap duration, `confidence=0.0`; `completeness=incomplete`; `outcome=indeterminate`; note `missedIndex=<n>` |
| **False start** | Starts, stops within the first two notes, and restarts | Keeps the file; starts a new take with the next sequence number | `completeness=incomplete`; `outcome=indeterminate`; note `falseStart`; never delete the take |

A missed note that the player **attempts with the wrong pitch** is not a missed
note. Keep the target note, record the measured onset, and mark the take
`incorrect` if the performance fails the practice-pass rule.

### 5.6 Failed takes

A take is failed when the recording is not usable as evidence:

- clipping or a dropped microphone;
- wrong phrase, wrong tempo, or wrong condition;
- a phone call, notification, or conversation in the room;
- the player stops to ask a question or restarts;
- consent was not given for that take;
- the file is corrupt or the sample rate/channel count is wrong.

Keep the failed file and label unless the consent or retention rules require
deletion. In the manifest set `status = "failed"`. In the label set
`expert.outcome = "indeterminate"`, `expert.completeness = "incomplete"`, and
write the reason in `notes`. A failed take is evidence of a recording problem;
it is not a performance failure, and it must not be counted as an incorrect
take.

### 5.7 Relabeling instead of deleting

- Never delete or overwrite a take because the performance was poor, the label
  was wrong, or the player was unhappy with it.
- A retake gets a new sequence number. The old take stays.
- To correct a label, edit the JSON, keep the previous version in git history
  (or copy it to `revisions/<takeId>.<timestamp>.json` if the corpus is not in
  git), and add `notes=revised <date> <reason>`.
- If the audio is deleted under the retention rule, keep the label and add
  `notes=audioDeleted=<YYYY-MM-DD>`.
- If the player withdraws consent, delete the audio and label under §10; that is
  the only reason to remove a take from the corpus.

---

## 6. File naming and folder layout

```
corpus/
  manifest.json
  p01/
    pixel-6a/
      quiet/
        p01-pixel-6a-quiet-001.wav
        p01-pixel-6a-quiet-001.json
        roomtone-pixel-6a-quiet.wav
      room-noise/
        p01-pixel-6a-room-noise-001.wav
        p01-pixel-6a-room-noise-001.json
    iphone-13/
      quiet/
        p01-iphone-13-quiet-001.wav
        p01-iphone-13-quiet-001.json
  p02/
    ...
  reference/
    p01-pixel-6a-quiet-001-di.wav
```

Rules:

- `playerId`: `p01` through `p10`.
- `device`: lowercase slug of the actual model (`pixel-6a`, `iphone-13`,
  `ipad-9`, `thinkpad-x1`).
- `condition`: `quiet`, `room-noise`, `click`, or `drone`.
- Sequence: three digits, starting at `001`, unique within
  player/device/condition. A retake gets the next number, never `-r2`.
- `takeId` is exactly `<playerId>-<device>-<condition>-<NNN>`. The label's
  `takeId`, the WAV file name, and the JSON file name must match.
- The label JSON sits next to its WAV. The manifest path is relative to the
  corpus root and uses forward slashes, for example
  `p01/pixel-6a/quiet/p01-pixel-6a-quiet-001.json`.
- Do not put dates, names, moods, or guitar brands in file names. Put those in
  `notes` or the manifest.
- `corpus-keys/player-key.csv` is outside `corpus/` and is never copied into it.
- Audio is not committed to git. If the corpus directory is a git repository,
  ignore `*.wav` and commit only labels and the manifest.

---

## 7. Manifest schema

`corpus/manifest.json` is the collection index. It tells the validator which
takes exist and which cell each one belongs to. It is not a substitute for the
labels.

```json
{
  "schemaVersion": 1,
  "corpusId": "spike-2026-11",
  "players": [
    {
      "playerId": "p01",
      "segment": "returner",
      "guitar": "nylon",
      "playingLevel": 3
    }
  ],
  "devices": [
    {
      "device": "pixel-6a",
      "platform": "android",
      "deviceClass": "mid-range-android"
    }
  ],
  "takes": [
    {
      "takeId": "p01-pixel-6a-quiet-001",
      "playerId": "p01",
      "device": "pixel-6a",
      "platform": "android",
      "condition": "quiet",
      "labelFile": "p01/pixel-6a/quiet/p01-pixel-6a-quiet-001.json",
      "audioFile": "p01/pixel-6a/quiet/p01-pixel-6a-quiet-001.wav",
      "status": "accepted"
    }
  ],
  "notes": "Optional free text for the corpus as a whole."
}
```

| Field | Type | Rules |
|---|---|---|
| `schemaVersion` | integer | `1` |
| `corpusId` | string | Lowercase slug, for example `spike-2026-11` |
| `players` | array | 6–10 entries for a complete corpus; each entry has the fields below |
| `players[].playerId` | string | `p01`–`p10`, unique |
| `players[].segment` | string | `returner` or `near-beginner` |
| `players[].guitar` | string | `nylon`, `steel`, or `both` |
| `players[].playingLevel` | integer | 1–5, self-rated |
| `devices` | array | Each entry has `device`, `platform`, `deviceClass` |
| `devices[].device` | string | Lowercase slug of the actual model, unique |
| `devices[].platform` | string | `android`, `ios`, or `web` |
| `devices[].deviceClass` | string | `mid-range-android`, `iphone`, `tablet`, or `laptop-web` |
| `takes` | array | Each entry has the fields below |
| `takes[].takeId` | string | Same pattern as the label; unique |
| `takes[].playerId` | string | Must exist in `players` |
| `takes[].device` | string | Must exist in `devices` |
| `takes[].platform` | string | Must match the device's platform |
| `takes[].condition` | string | `quiet`, `room-noise`, `click`, or `drone` |
| `takes[].labelFile` | string | Relative path ending in `.json`; no `..`, no absolute path |
| `takes[].audioFile` | string | Relative path ending in `.wav`; no `..`, no absolute path |
| `takes[].status` | string | `accepted`, `failed`, or `excluded` |
| `takes[].notes` | string | Optional; reason for a failed or excluded take |
| `notes` | string | Optional free text for the corpus |

The validator treats a missing cell, fewer than 6 players, fewer than 3
returners, fewer than 3 near-beginners, fewer than 3 playing levels, or fewer
than 2 guitar types as **warnings**, because a manifest may be a work in
progress. It treats unknown references, duplicate IDs, bad paths, bad enums, and
unknown fields as **errors**.

If a label and a manifest are passed together, the label's `takeId` must appear
in the manifest, and `playerId`, `device`, `platform`, and `condition` must
agree. See [`../tool/corpus/README.md`](../tool/corpus/README.md).

---

## 8. Label schema

Every take has one JSON label beside its WAV. The full field-by-field rules and
worked examples are in [`CORPUS_LABELING.md`](CORPUS_LABELING.md). This is the
exact v1 shape:

```json
{
  "schemaVersion": 1,
  "takeId": "p01-pixel-6a-quiet-001",
  "playerId": "p01",
  "device": "pixel-6a",
  "platform": "android",
  "condition": "quiet",
  "guitar": "nylon",
  "sampleRate": 48000,
  "channels": 1,
  "tempoBpm": 60,
  "phraseNoteCount": 4,
  "target": [
    {
      "index": 0,
      "writtenNote": "E4",
      "soundingMidi": 52,
      "string": 4,
      "fret": 2,
      "onsetSample": 204000,
      "onsetSeconds": 4.25,
      "durationSeconds": 0.9,
      "confidence": 1.0
    },
    {
      "index": 1,
      "writtenNote": "F4",
      "soundingMidi": 53,
      "string": 4,
      "fret": 3,
      "onsetSample": 252000,
      "onsetSeconds": 5.25,
      "durationSeconds": 0.9,
      "confidence": 1.0
    },
    {
      "index": 2,
      "writtenNote": "G4",
      "soundingMidi": 55,
      "string": 3,
      "fret": 0,
      "onsetSample": 300000,
      "onsetSeconds": 6.25,
      "durationSeconds": 0.9,
      "confidence": 1.0
    },
    {
      "index": 3,
      "writtenNote": "E5",
      "soundingMidi": 64,
      "string": 1,
      "fret": 0,
      "onsetSample": 348000,
      "onsetSeconds": 7.25,
      "durationSeconds": 1.0,
      "confidence": 1.0
    }
  ],
  "expert": {
    "outcome": "correct",
    "noteAccuracy": 1.0,
    "timingOk": true,
    "completeness": "complete",
    "labeler": "expert-a",
    "reviewedBy": "expert-b"
  },
  "consent": {
    "audioCapture": true,
    "keepRawAudio": false,
    "anonymizedMetrics": true
  },
  "notes": "4-note example at 60 BPM; tuningOffsetCents=+2; monitor=none"
}
```

Unknown fields are errors. Schema v1 has no extension fields; propose a
`schemaVersion: 2` instead of adding a field locally.

The most common schema error is written-versus-sounding pitch. Guitar notation
is written one octave above sounding pitch. `writtenNote` is what is printed on
the staff; `soundingMidi` is what the microphone hears. For example, written E4
sounds E3 = MIDI 52 on string 4 fret 2. String 1 fret 0 is written **E5** and
sounds E4 = MIDI 64. A label that says written E4 / MIDI 64 / string 1 fret 0 is
wrong in two ways.

### 8.1 Open-string reference

| String | Sounding note | Sounding MIDI | Written note |
|---:|---|---:|---|
| 6 (low E) | E2 | 40 | E3 |
| 5 (A) | A2 | 45 | A3 |
| 4 (D) | D3 | 50 | D4 |
| 3 (G) | G3 | 55 | G4 |
| 2 (B) | B3 | 59 | B4 |
| 1 (high E) | E4 | 64 | E5 |

`fret` adds semitones to both the sounding and written pitch. The validator
checks both `soundingMidi = writtenMidi − 12` and
`soundingMidi = openStringMidi[string] + fret`.

### 8.2 Required consent fields

Each label has a snapshot of the consent choices at capture time:

- `audioCapture` — must be true for any take with audio.
- `keepRawAudio` — true only if the participant opted in to keeping raw audio
  after analysis. It cannot be true when `audioCapture` is false.
- `anonymizedMetrics` — true if the participant allows anonymized metrics in
  reports. If false, the take is excluded from aggregate reporting.

A label with `audioCapture: false` produces a warning: the take must not contain
audio. Do not use it as evidence.

### 8.3 Notes conventions

`notes` is free text, but use these `key=value` tokens so the corpus can be
searched:

| Token | Example | Meaning |
|---|---|---|
| `tuningOffsetCents=` | `tuningOffsetCents=+30` | Worst open-string offset at take start |
| `monitor=` | `monitor=wired-headphones` | Click/drone route |
| `stimulus=` | `stimulus=speaker-click` | Click, drone, or none |
| `mic=` | `mic=built-in` | Built-in, USB, or interface microphone |
| `beatZeroSample=` | `beatZeroSample=204000` | First phrase beat in samples |
| `reference=` | `reference=di` | MIDI/interface reference used |
| `pickup=` | `pickup=true` | Phrase starts with a pickup |
| `falseStart` | `falseStart` | Player restarted |
| `earlyStop` | `earlyStop` | Player stopped before the end |
| `missedIndex=` | `missedIndex=3` | Target note not attempted |
| `extraNote=` | `extraNote=E5@6.50s` | Note outside the target |
| `wrongPitch=` | `wrongPitch[2]=G#4` | Target note played at the wrong pitch |
| `audioDeleted=` | `audioDeleted=2026-12-01` | Raw audio removed under retention |
| `revised` | `revised 2026-11-20 corrected onset` | Label revision |
| `piece=` | `piece=Ode to Joy, bars 1-2` | Public-domain piece phrase |

---

## 9. Validation workflow

Every label must pass the validator before it is accepted:

```powershell
dart run tool/corpus/validate_labels.dart `
  corpus/p01/pixel-6a/quiet/p01-pixel-6a-quiet-001.json `
  --manifest corpus/manifest.json
```

Use `--json` for a machine-readable report. The tool exits 0 when the label and
manifest are valid, 1 on validation errors, and 2 on usage or I/O errors. It
prints every error with a JSON path, for example
`$.target[0].soundingMidi: ...`.

To validate every label in a completed corpus, run the command once per label
and fail the session if any run exits non-zero. A simple PowerShell loop:

```powershell
$labels = Get-ChildItem corpus -Recurse -Filter *.json |
  Where-Object { $_.Name -ne 'manifest.json' }
foreach ($label in $labels) {
  dart run tool/corpus/validate_labels.dart $label.FullName --manifest corpus/manifest.json
  if ($LASTEXITCODE -ne 0) { throw "Invalid label: $($label.FullName)" }
}
```

Do not treat validator warnings as failures. Warnings mean the corpus is not yet
complete: too few players, a missing cell, a take marked failed, or a label that
does not follow the recommended prefix. Fix the missing data, not the warning.

---

## 10. Retention and deletion path

### 10.1 Retention clock

The clock starts at capture. **Analysis sign-off** means the T1.6 report has
been accepted and the label set is frozen. Record the sign-off date in the
manifest notes or the retention log.

| Data | Default retention | If `keepRawAudio` is true |
|---|---|---|
| Take WAVs and room tones | Delete **30 days after analysis sign-off**, and in any case no later than **180 days after capture** | Keep until the participant withdraws or **12 months after capture**, whichever comes first |
| DI/MIDI reference WAVs | Same as take WAVs | Same as take WAVs |
| Label JSON and manifest | Keep until the spike decision plus 12 months; no names | Same |
| Consent forms and player-key file | Keep until all participant data is deleted plus 12 months for audit; stored separately under lock | Same |
| Aggregate metrics and reports | Keep; must not contain names, raw audio, or a reversible player key | Same |

The default is deletion. `keepRawAudio: true` is an explicit opt-in; it does not
override a later withdrawal.

### 10.2 Deletion request path

The consent sheet names the **corpus custodian** and a contact channel. The
recruiter fills both in before the first session.

1. The participant contacts the custodian by the channel on the consent sheet.
   A verbal request is accepted; the custodian writes it down and reads it back.
2. The custodian logs the request the same day: player ID, date, scope, and
   whether raw audio, labels, and derived data are included.
3. The custodian verifies the player ID against `corpus-keys/player-key.csv`.
   Do not ask for more identity than the key file already holds.
4. The custodian acknowledges the request within **2 business days**.
5. The custodian deletes the player's folder (WAVs, labels, revisions), removes
   the player and takes from `manifest.json`, deletes the player's DI/reference
   files, and removes the player's row from the key file. If a backup exists,
   delete it or schedule its deletion within **30 days**.
6. The custodian confirms completion in writing within **14 days** of the
   request. If a backup cannot be purged immediately, say so and give the date.
7. Keep a deletion log with player ID, request date, completion date, and scope.
   The log contains no audio and no name.

Aggregate metrics that were already published without identifiers may not be
reversible. Say that in the confirmation. Do not promise deletion of a number
that has already been aggregated.

### 10.3 Deletion errors

- If a copy of raw audio is found in chat, email, a cloud drive, or a personal
  phone, delete it, record the incident in the retention log, and tell the
  custodian. The corpus is local-only; a cloud copy is a breach of the protocol.
- If a label references a deleted WAV, keep the label with
  `notes=audioDeleted=<date>` unless the participant withdrew consent. A
  withdrawal deletes the label too.

---

## 11. MIDI/interface reference subset

At least **10% of takes and no fewer than 24 takes** must have a simultaneous
MIDI or direct-input reference. Include 4-, 8-, and 16-note phrases and at least
two takes per cell.

Procedure:

1. Connect the guitar to an audio interface with a clean DI, and to a MIDI
   pickup or MIDI guitar if one is available. Record the DI/MIDI on the
   computer.
2. Start the DI and the phone recording together. Clap sharply once, or let the
   count-in click appear in both recordings.
3. Record the phrase on the phone as usual. The DI is the reference; the phone
   is the device under test.
4. Export the DI as WAV PCM16 at the same sample rate as the phone recording.
   Do not apply amp simulation, EQ, compression, or noise reduction.
5. Label the take from the DI where possible. If the DI is not usable for a
   note (dropout, clipping), use the phone audio and lower the confidence.
6. Compare the phone label to the DI: onsets must agree within **10 ms**, and
   pitch must be exact. If they disagree, fix the phone label; if the phone
   audio is unreadable, mark the note indeterminate.
7. Store the DI at `corpus/reference/<takeId>-di.wav` and add `reference=di` to
   the label notes. The reference file follows the same retention clock.

The full labeling procedure, including the comparison table and adjudication
rules, is in [`CORPUS_LABELING.md`](CORPUS_LABELING.md) §8.

---

## 12. Data-quality gates before T1.6 analysis

Do not start the analysis until all of these are true:

- [ ] 6–10 players, with at least 3 returners, 3 near-beginners, 2 guitar types,
      and 3 distinct playing levels.
- [ ] All 4 device classes and all 3 condition buckets represented.
- [ ] At least 20 accepted takes in every device/condition cell, at least 240
      accepted takes total.
- [ ] At least 24 takes in the MIDI/interface reference subset, including 4-, 8-,
      and 16-note phrases.
- [ ] Every label passes `validate_labels.dart` with no errors.
- [ ] At least 20% of takes second-labeled; every disagreement adjudicated; the
      agreement statistic recorded (do not claim a value before it is computed).
- [ ] Every take has a consent record; no take has `audioCapture: false`.
- [ ] At least one 48 kHz-only Android case and one stereo case.
- [ ] Tuning-offset takes at 0, +30, and +50 cents exist for at least one device
      per player.
- [ ] No raw audio in git, email, chat, or cloud storage.
- [ ] Retention dates and deletion path recorded.

If a gate is open, the corpus is incomplete. Do not fill the gap with synthetic
data, and do not report a metric computed from a partial cell.

---

## 13. Session checklist

### Before the session

- [ ] Consent sheet signed; `audioCapture`, `keepRawAudio`, and
      `anonymizedMetrics` choices recorded.
- [ ] Player ID assigned and added to the key file.
- [ ] Device charged; airplane mode on; notifications off; storage free.
- [ ] Recorder set to WAV PCM16, correct sample rate and channels; AGC/noise
      suppression/echo cancellation off.
- [ ] Room quiet; microphone position marked; gain checked at −12 to −6 dBFS.
- [ ] Guitar tuned to A4 = 440; open-string offsets written down.
- [ ] Phrase cards, tuner, timer, manifest, and validator available.
- [ ] At least two copies of the data plan: phone and encrypted drive.

### During the session

- [ ] Record 10 seconds of room tone.
- [ ] For each take: say the take ID, play the count-in, play the phrase, wait
      two seconds, stop.
- [ ] Log the take in the manifest immediately.
- [ ] Change one variable at a time: device, condition, guitar, or phrase.
- [ ] Do not coach during a scored take. Demonstrate once before it if needed.
- [ ] Mark failed takes as failed; keep the files.
- [ ] Take a short break every 20 minutes. Fatigue is a confound.

### After the session

- [ ] Copy the files to the encrypted corpus drive; verify the file count.
- [ ] Label every take or schedule the labeling session.
- [ ] Run the validator on every label.
- [ ] Update the manifest and the retention log.
- [ ] Back up; do not leave the only copy on the recording device.
- [ ] Tell the participant how to request deletion and when raw audio will be
      deleted.

---

## 14. What T1.2 delivers, and what it does not

T1.2 delivers this protocol, the consent sheet, the labeling guide, the
validator, and its tests. It does **not** deliver players, audio, labels, a
validated metric, or a go/no-go decision. Those are T1.1 and T1.6.

If the protocol and the validator disagree, the validator and its tests decide.
Update the protocol and the validator together in the same change.
