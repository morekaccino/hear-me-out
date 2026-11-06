# Decision 0006 — Local, opt-in retention instrumentation

**Date:** 2026-11-06
**Status:** Accepted
**Owner:** Engineering
**Supersedes:** Nothing
**Related:** T5.4, T9.2, AGENTS.md hard rule 1, plan sections 12.4 and 12.5

## Context

The repository rule said the app has "no analytics". T5.4 needs to measure the
onboarding and practice funnel without adding a network path, an account, a
third-party SDK, or remote persistence. Treating every event log as forbidden
would make the ticket impossible, while quietly shipping one would break the
privacy promise and the repository's own source of truth.

## Decision

1. Replace the absolute "no analytics" wording with **no remote analytics or
   third-party trackers**. The only usage log is local, opt-in, bounded, and
   eraseable.
2. The log stores only a fixed event name, a UTC timestamp, and a locally
   generated pseudonymous install id. It stores no audio, note name, piece
   title, free text, account, device fingerprint, or advertising id.
3. Logging is off by default. Consent is available on the first onboarding
   screen and in **Profile → Privacy**. No document is written before consent.
4. The log lives under `hear_me_out_retention_v1`, separate from
   `ProgressState`, with `schemaVersion: 1`, a 500-event bound, and an explicit
   `installAt` so trimming cannot move D1/D7/D30.
5. The user can copy the log as JSON or erase it from Profile. Erase deletes
   every event but keeps the install id, install day, and opt-in choice. Turning
   the switch off stops new events.
6. The app never uploads the log. Export is a user clipboard action; aggregation
   and sharing happen outside the app and are the user's or researcher's
   decision.
7. Opt-in data is biased and is **not** an unbiased baseline. The pilot uses a
   hand-recruited beta cohort; opt-in funnel numbers are diagnostic only.
8. `firstPhrase` and `firstRecording` are reserved APIs for T2.5 and T4.2. No
   lesson may fake them.

## Consequences

Positive: the team can debug the onboarding and session funnel on-device
without a network dependency, an SDK, or a progress-schema change. The consent
surface is visible before onboarding, so the onboarding steps are reachable for
a real new install. The decision record and updated rule remove the contradiction
between the feature and `AGENTS.md`.

Negative: the log is still observation of the learner, so consent copy and the
bias caveat must stay prominent. The 500-event bound is a rolling window, not a
complete history. Onboarding numbers are only meaningful for users who opt in at
the first screen.

## Follow-up

T9.2 should record this change in the Plane decision log. The manager owns the
Plane update; the implementation PR carries the code, docs, and this record.
