# Decision 0004 - T3.3 beginner playtest moves to T3.8

**Date:** 2026-11-06
**Status:** Accepted
**Owner:** AI delivery manager
**Related:** T3.3, T3.8, T9.2

## Context

T3.3's ticket asks for a playtest with three beginners. That is a human
content-QA activity: it needs real beginners, a facilitator, and a session
record. An autonomous agent can write and validate arrangements, but it cannot
honestly produce playtest evidence.

T3.8 (content QA) already owns playthrough, notation, fingering, license, and
musical-payoff review, and a 3-beginner/returner playtest fits there.

## Decision

T3.3 is marked Done for the arrangement/validator scope only. The 3-beginner
playtest moves to T3.8 and must be recorded there before T3.8 closes. T3.3's
ticket comment and this record carry the handoff. No agent may claim the
playtest happened.

## Consequences

Positive: the arrangements and their machine validation can ship without
pretending a human study happened.

Negative: T3.3's original acceptance criterion is split; T3.8 must not close
without the playtest evidence. If T3.8 is descoped, the playtest needs a new
owner.
