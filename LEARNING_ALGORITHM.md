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

The course has **3 sections, 6 units, and 25 lessons**. Units alternate between
staff reading, string groups, a mixed first-position unit, and accidentals.

| Section | Unit | Focus | Lessons |
|---|---|---|---|
| Foundations | 1. The Staff | Read the staff | E/F, G/A, B/C, D/E, staff review |
| Foundations | 2. High Strings | B/high E strings; add F5 | B/C again, D/E again, high F, high-string review |
| Foundations | 3. Below the Staff | C4/D4, recall E–A | C/D below, E/F again, G/A again, below-staff review |
| First Position | 4. Low Strings | Low E/A strings | A/B, low E/F, G below, low-string review |
| First Position | 5. First Position | Mix all six strings | lower half, upper half, full position, checkpoint |
| Accidentals | 6. Accidentals | Sharps and flats | F♯, C♯, B♭, accidental review |

Each normal lesson introduces at most two notes. A new note gets **4 exposures**
while it is still in box 0–1. Every unit ends with a 15-exercise checkpoint with
no new notes. Review material deliberately reappears across units.

## 3. Session planner

`buildLessonExercises` creates exactly **12 exercises** for a normal lesson and
**15** for a checkpoint:

1. Put four copies of each new note into the pool.
2. Fill the remaining slots with a **review quota** from prior notes: due first,
   weak second, then recently seen notes. A normal lesson has at least four
   review slots when prior material exists.
3. Arrange the pool so the most frequent note comes first and the same note is
   not reused within the last two positions when an alternative exists.
4. Mark the first four occurrences of each new note as new exposures 0–3.
5. Assign answer modes:
   - No mic or Name mode: every exercise is naming.
   - Play mode: every exercise is playing.
   - Mixed: the first exposure of a new note is naming; later exercises split
     between naming and playing, with at least three play exercises when
     possible.
6. Build four plausible answer choices for naming exercises. Natural-note
   questions never show accidentals; accidental questions may show the natural
   neighbor.

If a note is answered incorrectly, it is added to a **mistake queue**. The base
lesson is completed first, then the missed notes return in a short “Mistake
review” phase at the end. Each distinct missed note is retried once, capped at
four retries per session.

Practice sessions use the same planner without new notes and also use 12
exercises. They draw from due notes, weak notes, or every learned note.

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

## 5. Gamification

- **Lives:** three per lesson. A wrong answer costs one. At zero the lesson ends
  and can be retried. Practice never costs lives.
- **XP:** 10 for a lesson, 15 for a review lesson, +5 for a perfect lesson.
  Replaying a completed lesson gives 5 XP (plus 3 for a perfect replay).
  Practice gives 5 XP.
- **Streak:** increments on the first completed lesson of a calendar day.
  Completing two lessons in one day does not double it. Missing a day resets it
  to 1 on the next completed lesson.
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
lessons, best lesson accuracy, XP, streak, daily XP, settings, and the last 30
sessions. Corrupt or missing data falls back to a fresh profile instead of
crashing. Backup exports the same document to the clipboard; restore validates
it before replacing local progress.

No network or cloud service is involved.

## 8. Why this is better than “3 in a row”

A short-term streak measures working memory, not retention. Requiring spaced
correct answers across days, with wrong answers demoting two boxes, produces
durable recall. The session planner also prevents the two common failure modes:
introducing five new notes at once, and showing the same note twice in a row.
