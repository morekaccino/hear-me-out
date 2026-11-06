# Learning Algorithm

> **Status:** This document describes the current 240-lesson implementation. The
> approved transformation plan lives in Plane (`D0.1 — START HERE`) and
> [`docs/TRANSFORMATION_PLAN_FINAL.md`](docs/TRANSFORMATION_PLAN_FINAL.md); it is
> not implemented yet. Do not assume planned behavior is shipped.

Hear Me Out is now a **240-lesson, 48-week guitar musicianship course**. The
learning engine has two layers:

1. a **session planner** that mixes new material, due review, and production
   work into a short lesson;
2. a **skill scheduler** that gives every objective its own memory state and
   decides when it should return.

The old note-only Leitner boxes are still visible as note chips, but they are no
longer the source of truth. Every note, chord, interval, scale, rhythm, theory
fact, ear skill, technique, and repertoire piece is scheduled.

## 1. Course shape

| Item | Value |
|---|---|
| Sections | 8 |
| Units | 40 |
| Lessons | 240 |
| Lessons per unit | 6 |
| Pace | 5 sessions/week × 48 weeks |
| Session length | 12–18 minutes |

Each unit follows the same arc:

1. **Discover** — teach cards and guided attempts.
2. **Build** — apply the new idea slowly.
3. **Connect** — interleave it with earlier material.
4. **Apply** — production: play, tap, build, or notate.
5. **Integrate** — mixed review in a new context.
6. **Checkpoint** — 14–30 mixed items with an 80–85% mastery gate.

The generated course lives in
[`flutter_app/lib/core/learning/course/`](../flutter_app/lib/core/learning/course/).
Forty `UnitSpec`s expand into 240 lessons through `LessonFactory`. A unit is the
authoring unit; a lesson is generated.

## 2. Skill cards

The scheduler stores one `SkillProgress` per objective:

```text
objectiveId, family, stabilityDays, difficulty, dueAt, lastSeenAt,
reps, lapses, correct, incorrect, correctDays,
productionCorrect, transferCorrect, averageResponseMs,
level, fragile, masteredAt, recentTemplateIds, cents samples
```

Stable objective IDs are namespaced:

- `note:E4`
- `interval:m3:melodic`
- `chord:G:maj`
- `keysig:G`
- `ear:interval:m3:melodic`
- `rhythm:eighths`
- `fret:C4:5`
- `scale:C:maj:3`
- `progression:I-IV-V-I:C`

A note is no longer a special scheduling case. It is one family among many.

## 3. Scheduler

The scheduler is an FSRS-6-style model in
[`core/learning/skill.dart`](../flutter_app/lib/core/learning/skill.dart):

- **Retrievability:** `R(t,S) = (1 + factor × t/S)^-w20`, where
  `factor = 0.9^(-1/w20) - 1`; by construction `R(S,S) = 0.9`.
- **Stability** is the interval at which recall is about 90%.
- **Difficulty** is clamped to 1–10 and updates with mean reversion.
- **Ratings:** Again, Hard, Good, Easy.
- **Initial stability and difficulty** come from the first rating.
- **Success** increases stability using difficulty, current stability, and
  retrievability.
- **Failure** sharply reduces stability and increases difficulty.
- **Same-day reviews** use the FSRS same-day formula.
- **Caps:** performance skills are capped at 30 days of stability; declarative
  facts at 180 days. Mastered performance skills still return for maintenance.

The default weights are pinned in `FsrsScheduler.defaultWeights`. The scheduler
is pure Dart and deterministic in tests.

### Rating inference

The learner does not rate a card. The app infers the rating:

| Rating | Condition |
|---|---|
| Again | Wrong, revealed, or answered after 2.5× the target time |
| Hard | Correct after 1.3× target time, or with a hint |
| Good | Correct within target, no hint |
| Easy | Correct under 0.6× target, no hint, production/transfer surface |

Target times are per family: note naming is faster than playing a phrase.

### Indeterminate attempts

Every scored attempt is `correct`, `incorrect`, or `indeterminate`
(`AttemptOutcome` in
[`core/learning/attempt_outcome.dart`](../flutter_app/lib/core/learning/attempt_outcome.dart)).
An indeterminate attempt means the app could not tell what happened: a
low-confidence note, a missed note, a false start, an early stop, or silence. It
is a retry, not a failure.

- It changes no FSRS state, XP, streak, daily counter, combo, or quest.
- It does not queue a mistake retry.
- It shows a calm retry message and leaves the learner on the same prompt.
- If any note is indeterminate, the whole phrase take is incomplete and
  indeterminate, even when another note was confidently wrong.
- A phrase attempt records phrase-level evidence only. Per-note skills record
  only from determinate note evidence, so one take never counts twice.

## 4. Mastery

A skill is mastered only when **all** of these are true:

- stability ≥ 21 days,
- at least 4 spaced reps,
- correct on at least 3 different calendar days,
- at least one production success,
- at least one transfer success (new key, position, or context),
- the unit checkpoint is passed at 80–85%.

One good session cannot master a skill. A mastered skill is not retired; it
returns for maintenance.

## 5. Repair chain

Wrong answers immediately enter a repair path:

1. Explain the correct answer.
2. Require a corrective retry.
3. Reinsert the objective 2–4 slots later in the session.
4. Create a next-day repair card with three different question surfaces.
5. Schedule a 3-day recheck.
6. Two lapses marks the skill **fragile**.
7. Four lapses marks it a **leech** and recommends a prerequisite micro-lesson.

Smart review prioritises due, fragile, and weak skills. The daily review queue
is capped at about 30 items so a backlog never becomes an avalanche.

## 6. Session planner

A normal lesson contains:

- **Warm-up (about 25%)** — due review, interleaved.
- **Core (about 55%)** — new objective: teach → guided → apply → transfer →
  produce.
- **Cool-down (about 20%)** — older material plus one ear or rhythm item.

Checkpoints are 50% review and 50% assessment. They contain no teach cards and
at least two production items.

Rules enforced by the planner and validator:

- at least 30% review in a normal lesson,
- at least 50% review in a checkpoint,
- at least 30% production in a normal lesson,
- at least 50% production in a checkpoint,
- no objective more than twice in a session,
- no template twice in a row for one objective,
- no family above 40% of the session when alternatives exist,
- new objectives get five exposures while they are still fragile.

## 7. Anti-flying-through rules

- Every scored prompt must ask the learner to read, play, build, transcribe, or
  apply a concept. Standalone “What is …?” definition questions are not allowed.
- Distractors are plausible: nearby staff steps, same interval quality, same
  chord family, one accidental away.
- Four options is standard; three only on the guided attempt.
- After a skill reaches box 2, recognition questions switch to free recall:
  note pad, staff placement, build/order, play, tap.
- Every normal lesson has at least 30% production.
- Slow-but-correct answers are rated Hard and return sooner.
- Above 90% accuracy for two sessions raises item difficulty; below 70% lowers
  it.
- A failed checkpoint generates a repair session from missed objectives.
- Lessons pass at 80%; checkpoints at 85%.

## 8. Practice

Practice is always available. It never spends or restores a life because there
are no hearts; a wrong answer only lowers accuracy and queues the repair. The
only habit signals are the weekly minutes goal and the optional streak.

Modes:

- **Smart review** — due + fragile + weak skills across every family.
- **Due review** — skills whose due date has passed.
- **Weak skills** — skills below 75% accuracy or flagged fragile.
- **Free practice** — every skill the learner has met.
- **Tuner** — standard tuning, live pitch and cents.

If the learner has no skills yet, practice falls back to the first note lesson.

## 9. Persistence

`ProgressState` schema 8 stores:

- `skills` — the full skill map;
- `notes` — legacy note boxes kept for the note chips;
- completed lessons and checkpoints;
- legacy completed lesson IDs;
- XP, streak, musical quest counters, settings, recent sessions;
- `practiceSecondsByDay` — real guitar time per local day;
- `lastPracticeDay` — the last day with effective practice.

Version 3 documents migrate note boxes into skill cards: box 0 → 0.5 days, 1 → 1
day, 2 → 3 days, 3 → 7 days, 4 → 21 days, 5 → 45 days. Version 7 removes the
heart pool, heart refill timer, streak freezes, and the XP daily goal. It maps
`lastCompletedDay` to `lastPracticeDay`, adds `weeklyGoalMinutes` (default 30)
and `streakEnabled` (default false), and starts `practiceSecondsByDay` empty
because old saves contain no measured guitar time. Version 8 removes gems,
chests, the XP boost, claimed quests, and the old quest day, and adds honest
musical quest counters at zero. XP, streak, notes, skills, phrase evidence, and
lesson history are preserved. Old lesson IDs map through `legacyLessonIdMap`.
Future schema versions are rejected, not guessed.

The optional streak advances on any local day with 3+ minutes of guitar time or
one determinate recorded take. A missed day reads as zero with neutral copy; no
resource is spent and no freeze exists. The weekly goal sums real measured
session seconds in a rolling seven-day window; XP is not the habit goal.
Completion and return are read locally from `recentSessions` and
`practiceSecondsByDay` for before/after comparison.

## 10. Why this is better than a fixed box ladder

A fixed six-box ladder makes every note return on the same schedule regardless
of how hard it was, how long it has been, or whether the learner can produce it.
FSRS tracks stability, difficulty, and retrievability separately, so difficult
skills return sooner and easy ones wait. The repair chain and production/transfer
requirements stop a learner from “passing” by tapping a lucky multiple-choice
answer.

The 240-lesson course is long enough to be a year, but the scheduler is what
makes it a course rather than a playlist.
