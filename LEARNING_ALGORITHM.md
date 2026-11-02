# Learning Algorithm

Hear Me Out uses two layers: a **session planner** that builds a focused
12-exercise lesson (15 for checkpoints) and a **spaced-repetition scheduler**
that decides when each note should come back.

## 1. Written pitch vs sounding pitch

Guitar music is written one octave above sounding pitch.

- Written C4 (the staff) sounds C3 (MIDI 48).
- Written E3 (low E string) sounds E2 (MIDI 40).
- Open strings: written E3 A3 D4 G4 B4 E5.

The staff shows the written note. The microphone compares against
`soundingMidi = writtenMidi - 12`. The string/fret hint uses the same mapping.
This is why a guitarist can read a written C4 and be told to use the A string,
fret 3.

## 2. Curriculum

The course has **5 sections, 10 units, and 40 lessons**. Units cover staff
reading, string groups, first position, accidentals, meters and keys, capo,
open chords, and rhythm.

| Section | Unit | Focus | Lessons |
|---|---|---|---|
| Foundations | 1. The Staff | Read the staff | E/F, G/A, B/C, D/E, staff review |
| Foundations | 2. High Strings | B/high E strings; add F5 | B/C again, D/E again, high F, high-string review |
| Foundations | 3. Below the Staff | C4/D4, recall E–A | C/D below, E/F again, G/A again, below-staff review |
| First Position | 4. Low Strings | Low E/A strings | A/B, low E/F, G below, low-string review |
| First Position | 5. First Position | Mix all six strings | lower half, upper half, full position, checkpoint |
| Accidentals | 6. Accidentals | Sharps and flats | F♯, C♯, B♭, accidental review |
| Harmony | 7. Counting and Keys | Meters and key signatures | beats and bars, G/F, D and 6/8, checkpoint |
| Harmony | 8. Capo | Move shapes into new keys | capo two and three, checkpoint |
| Harmony | 9. Open Chords | Read chord diagrams | G/C, D/Em, Am/E, checkpoint |
| Rhythm | 10. Pulse | Hold a beat and tap what you read | quarters/halves, long and short, rests and waltz, strum feel, checkpoint |

Each normal lesson introduces at most two objectives. A note gets **4 exposures**
while it is still in box 0–1; topic objectives get **3**. Those exposures always
use different question shapes. Every unit ends with a 15-slot checkpoint with no
new objectives. Review material deliberately reappears across units.

## 3. Session planner

A session is built in three pure steps: a **shape**, a **composer**, and a
**validator**.

`SessionShape` decides how many slots a session has (up to 12 normal, 15
checkpoint), how many objectives are new, and how many slots are left for
review. The session factory caps the length at `distinct objectives x
exposures`, with an 8-slot floor, so a two-note lesson does not ask the same
note six times.

`SessionComposer` fills the slots from a ranked pool of objectives:

1. Each new objective gets four exposures: a **teach card**, a **guided
   attempt**, and two independent applications.
2. Remaining slots are a review quota from prior objectives: due first, weak
   second, then recently seen. A normal lesson has at least four review slots
   when prior material exists.
3. Objectives are interleaved so the same one is not reused within the last two
   positions when an alternative exists.
4. Each objective's exposures rotate through different question shapes. A note
   might be taught, then named, then placed on the staff, then played. The
   composer never asks the same shape twice in a row for one objective.
5. An answer surface is chosen per slot:
   - No mic or Name mode: every scored slot is naming.
   - Play mode: every scored slot is playing.
   - Mixed: the teach card is ungraded, the guided attempt is naming, and later
     slots alternate with at least three play exercises when possible.

Teach cards show the note on the staff with its name and fretboard position and
are never scored, so meeting a new note cannot cost a heart. Guided attempts
offer three options, including one deliberately distant choice, so the first
attempt is a choice between ideas rather than between neighbouring staff steps.

`SessionValidator` asserts the pacing rules on every generated session: slot
count, teach-before-question, one teach card per objective, and objective
spacing. Add a rule there before adding a new question style.

If a note is answered incorrectly, it is added to a **mistake queue**. The base
lesson is completed first, then the missed notes return in a short “Mistake
review” phase at the end. Each distinct note is retried once, capped at four
retries per session.

Practice sessions use the same planner without new objectives and also use 12
slots. They draw from due notes, weak notes, or every learned note.

## 4. Spaced repetition

Each note has a box 0–5 and a due timestamp.

| Box | After a correct answer |
|---|---|
| 0 | due immediately |
| 1 | 10 minutes |
| 2 | 1 day |
| 3 | 3 days |
| 4 | 7 days |
| 5 | 21 days |

**Correct answer:** box + 1 (maximum 5), due = now + interval for the new box,
rolling accuracy updated.

**Wrong answer:** box − 2 (minimum 0), due = now + 1 minute, streak reset.

**Mastery:** box ≥ 4 **and** at least five correct answers **and** correct on at
least two different calendar days. Three correct taps in one session cannot
master a note.

**Due queue:** notes whose due timestamp is in the past, oldest first. Weak
notes are those with at least two attempts and accuracy below 75%. Lesson
review slots use due notes first, then weak notes, then recently seen notes.

## 5. Gamification and the gem economy

- **Hearts:** five shared hearts. A wrong lesson answer costs one. At zero the
  lesson ends. Hearts regenerate one every four hours, a completed practice
  session restores one, and 350 gems refills all five. Practice never costs
  hearts.
- **XP:** 10 for a lesson, 15 for a review lesson, +5 for a perfect lesson.
  Replaying a completed lesson gives 5 XP (plus 3 for a perfect replay).
  Practice gives 5 XP. A jump test gives 20 XP. Double XP multiplies the award
  for 15 minutes.
- **Streak:** increments on the first completed lesson of a calendar day.
  Completing two lessons in one day does not double it. Missing a day resets it
  to 1 on the next completed lesson unless a streak freeze is equipped; one
  freeze is consumed and the streak continues.
- **Gems:** new profiles start with 500. Chests and claimed daily quests award
  more. The shop spends them on heart refills (350), streak freezes (200, max
  two), and double XP (100).
- **Chests:** one per unit, placed after the unit's second lesson. It unlocks
  when that lesson is complete and pays its gems once.
- **Daily quests:** complete one lesson (10 gems), answer ten notes correctly
  (10), and reach a five-answer combo (15). Claim each once per local day.
- **Jump ahead:** a 15-exercise test of earlier material unlocks the sections
  before the target section. Passing keeps all existing note progress.
- **Daily goal:** 10, 20, or 30 XP. XP is tracked per local calendar day.

## 6. Pitch detection and matching

**Capture:** mono PCM16 at 44.1 kHz. Frames of 4096 samples are decimated by two
to ~22.05 kHz and analyzed every 2048 samples (about 46 ms).

**YIN:**
1. Remove DC and gate on RMS.
2. Difference function over lags 70–1000 Hz.
3. Cumulative mean normalized difference.
4. First dip below 0.15, refined by parabolic interpolation.
5. Frequency = sample rate / lag; clarity = 1 − normalized difference.

**Matching:**
- Reject frames with clarity < 0.5.
- Require three stable frames of the same MIDI note.
- Accept the target when |cents| ≤ 30 (configurable: 20/30/40).
- Flag an octave error when the detected MIDI is target ± 12 for six frames.
- Flag a wrong note when another pitch is stable for six frames.
- Ignore the first 250 ms of a new exercise so the tail of the previous note
  cannot trigger a false answer.
- Show cents sharp/flat and allow retuning. A note that is close but out of tune
  is not accepted.

The tuner uses the same detector but compares against the selected open string
instead of a lesson target.

## 7. Persistence

A versioned `ProgressState` JSON document is stored under
`hear_me_out_progress_v1` in `shared_preferences`.

It contains notes, boxes, due dates, accuracy, correct-day sets, completed
lessons, best lesson accuracy, XP, streak, daily XP, gems, hearts, chests,
daily quests, streak freezes, XP boosts, settings, and the last 30 sessions.
The schema version is 3; version 1 documents load with default economy values
and version 2 adds the System appearance default. Corrupt or missing data falls
back to a fresh profile instead of crashing. Backup exports the same document
to the clipboard; restore validates it before replacing local progress.

No network or cloud service is involved.

## 8. Why this is better than “3 in a row”

A short-term streak measures working memory, not retention. Requiring spaced
correct answers across days, with wrong answers demoting two boxes, produces
durable recall. The session planner also prevents the two common failure modes:
introducing five new notes at once, and showing the same note twice in a row.
