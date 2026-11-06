# Decision 0007 - Remove hearts and replace them with an optional weekly habit goal

**Date:** 2026-11-06
**Status:** Accepted
**Superseded in part by:** [0008](0008-no-gems-shop.md) for the gem/chest/shop economy and quests
**Owner:** T2.10
**Related:** T2.10, T5.4, T5.5, T9.2

## Context

The five-heart pool punished the mistakes beginners need to make. A wrong
answer spent a shared resource, zero hearts failed the lesson early, the path
blocked new lessons until a refill or practice session, and the shop sold the
way back in. That is a loss loop, not a learning signal. T2.10 removes it.

The replacement habit signal must be non-lossy, local, and honest. It must not
fake minutes, must preserve old saves, and must leave the full
economy/quests/shop migration to T5.5.

## Decision

### No hearts or lives

- Remove the heart pool, four-hour regeneration timer, 350-gem refill, heart
  loss on a wrong answer, and the out-of-lives early failure.
- `LessonRun` has no `lives`, `livesPerLesson`, or `outOfLives`. A lesson always
  reaches its result. Accuracy still decides the pass/fail feedback, but a
  failed lesson does not block practice or remove a resource and can be retried
  immediately.
- Practice is always available. It never spends or restores a life.
- The mistake-retry queue stays. It is pedagogical repair, not punishment.
- No heart UI remains in the path, lesson, practice, profile, result, or shop.
  The shop no longer sells a heart refill or a streak freeze.

### Optional, non-lossy streak

- `AppSettings.streakEnabled` defaults to **false**.
- A local day counts as effective practice when the learner accumulates at least
  three minutes of measured guitar time or completes one determinate recorded
  phrase take. Short sessions add up within the day.
- The streak advances on any effective-practice day, not only on a completed
  lesson. It is hidden and does not advance while the setting is off.
- A missed day reads as zero with neutral copy. Nothing is spent, no warning
  fires, and there is no “you lost your streak” message or red state.
- Streak freezes are removed. A quiet reset is the whole rule, so a second
  protective system is unnecessary.
- A determinate phrase take marks the day without inventing guitar minutes.

### Weekly goal in minutes

- `AppSettings.weeklyGoalMinutes` defaults to **30** and is the primary habit
  goal. XP stays an internal reward number and is not the habit goal.
- Progress is the sum of `practiceSecondsByDay` over a rolling seven-day window
  ending today. Sessions record measured wall time, capped at 60 minutes per
  session so an app left in the background cannot inflate it. A fresh profile
  reads 0.
- The path, the wide quest rail, practice, and profile show the weekly goal
  with neutral copy. There is no XP daily goal.
- The path/profile copy never frames a shortfall as failure.

### Local measurement

- `sessionCompletionRate` is the passed share of the real `recentSessions` list.
- `returnRate` is the share of the trailing 14 days with measured guitar time.
- Both are pure local values from stored data. Nothing is sent anywhere. They
  give the manager a before/after read for T2.10 without adding network. T5.4's
  opt-in local retention log is the fuller funnel described in
  `docs/RETENTION_INSTRUMENTATION.md`; T2.10 does not depend on it and does not
  turn it on.

### Storage migration

- Schema v6 → v7 removes `hearts`, `nextHeartAt`, `streakFreezes`, and the
  nested XP `dailyGoalXp`.
- The old `lastCompletedDay` is copied to `lastPracticeDay`.
- `weeklyGoalMinutes` (30) and `streakEnabled` (false) are added.
- `practiceSecondsByDay` starts empty. Old saves have no measured guitar time,
  so the weekly goal honestly starts at 0.
- Notes, skills, `phraseProgress` including content versions, completed
  lessons, checkpoints, XP, gems, chests, quests, settings, and recent sessions
  are preserved. Backups remain versioned and validated; future versions are
  rejected, not guessed.

### Scope boundary

T5.5 still owns the full economy, quest catalog, and shop migration. T2.10 keeps
gems, chests, daily quests, and the double-XP purchase. It removes only the
heart-refill and streak-freeze items. The existing daily quests do not mention
hearts or punish wrong answers, so they are unchanged.

## Consequences

Positive: a beginner can make mistakes without losing access to the lesson,
practice, or a paid resource. The weekly minutes goal measures time on the
instrument rather than tapping speed. The optional streak is quiet and cannot
gate learning. Old saves keep every unrelated field.

Negative: the shop temporarily has one item (double XP), and the old streak
freeze counter is discarded. T5.5 will rebuild the economy and quests around
musical actions. Weekly minutes are wall-clock session time, not a per-note
guitar-time sensor, so background time is capped rather than perfectly
classified.
