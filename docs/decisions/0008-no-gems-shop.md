# Decision 0008 - Remove the gem/chest/shop economy and use musical quests

**Date:** 2026-11-06
**Status:** Accepted
**Owner:** T5.5
**Related:** T5.5, T2.10, T2.5, T4.2, T9.2

## Context

T2.10 removed the heart pool and the loss loop, but left gems, chests, a
double-XP purchase, gem-claim daily quests, and a Shop tab. That half-state
contradicted the approved V1 scope: the plan says no gems, chests, or shop in
V1, and quests should describe musical actions ("play 3 phrases", "record a
take", "learn 4 bars"), not answer counts. Keeping a currency would keep the
product focused on earning and spending instead of reading and playing.

The recording flow (T4.2) has not shipped. A quest for a missing action must
stay honest at zero rather than fake a completion.

## Decision

### No currency economy

- Remove gems, chests, opened chests, the double-XP purchase, and the Shop tab
  and screen. `HomeShell` has four destinations: Learn (or Today when the
  phrase gate is open), Practice, Quests, and Profile.
- Remove the gem and chest nodes from the path and the chest slot from the pure
  path geometry. The path shows lessons, the current START bubble, and the
  optional streak counter only.
- Remove the gem counter from the path, practice, quests, and profile. Profile
  keeps Level/XP because XP is an internal progress number, not a currency.
- No replacement loss-aversion mechanic: there is no life, energy, ticket,
  timer, or purchasable protection. Practice is always available.

### Musical quests

The quest catalogue is local-only and has no reward and no claim step. Finishing
the real action completes the quest.

| Quest | Period | Target | Counter |
|---|---|---|---|
| Play 3 phrases | Daily | 3 | `quests.phrasesPracticed` |
| Record a take | Weekly | 1 | `quests.recordingsMade` |
| Learn 4 bars | Weekly | 4 | `quests.barsLearned` |

Counters reset at local midnight (daily) or on the local Monday (weekly).

- A determinate phrase attempt increments `phrasesPracticed` once. An
  indeterminate take is a retry and increments nothing.
- A correct determinate take records the phrase's bar count in the current
  week's `learnedBarsByPhrase` map. `barsLearned` is the sum of that map. A
  repeated take of the same phrase never adds the same bars twice, and a prompt
  tap never counts because only a scored phrase attempt reaches the counter.
- `recordRecordingMade` is the only producer of `recordingsMade`. T4.2 owns the
  recording flow and has not shipped, so the quest is visible with real zero
  progress and a "coming with recordings" note. Nothing marks it complete until
  a real saved take calls the API.

### Storage

- Schema v7 → v8 removes `gems`, `xpBoostUntil`, `openedChests`,
  `claimedQuests`, and `questDay`.
- It adds `quests`: `day`, `week`, `phrasesPracticed`, `recordingsMade`, and
  `learnedBarsByPhrase`. Every counter starts at zero; a v7 save has no
  phrase-practice, recording, or bars evidence, so inventing progress would be
  fake.
- Notes, skills, `phraseProgress` (including content versions), completed
  lessons, checkpoints, XP, streak, settings, `contentVersion`, completion
  accuracy, recent sessions, and practice seconds are preserved.
- v1–v7 documents still migrate through the full pipeline. Future versions are
  rejected, not guessed. Backups remain versioned and validated.

## Consequences

Positive: the product no longer sells access to learning, and the remaining
habit signals are a weekly minutes goal and an optional non-lossy streak. The
quests point at playing, recording, and learning repertoire rather than tapping
answers. Old saves keep every unrelated field.

Negative: the recording quest cannot complete until T4.2 ships. The quest
counters add storage shape, so the schema moves to v8 and older builds reject
the document rather than silently dropping the counters. Removing chests
changes path spacing, so the path geometry and its tests were updated.
