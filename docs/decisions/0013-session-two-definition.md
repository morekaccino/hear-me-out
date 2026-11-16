# Decision 0013 — Session-2 uses the KC-03 definition; the retention helper is diagnostic

**Date:** 2026-11-16
**Status:** Accepted
**Owner:** AI delivery manager
**Supersedes:** Nothing
**Related:** T5.6, T5.7, T9.1, T9.2, KC-03, `docs/KILL_CRITERIA_DASHBOARD.md`, `docs/BETA_METRICS.md`, `docs/REMINDER_EXPERIMENT.md`

## Context

Two different session-2 rules were in circulation while the T5.7 beta kit was
written:

1. **KC-03, the gate.** Session 1 is the first `session_start`; session 2 is the
   next `session_start` within 48 hours of session 1's `session_start`, and it
   must follow session 1's `session_complete` by at least 60 minutes. Dropouts
   stay in the denominator. The dashboard records the 60-minute sitting boundary
   as a proposed operational definition that T9.2 must confirm or replace before
   the first measurement.
2. **`returnMetricsFromLog`.** The helper added for the T5.6 reminder report
   anchors session 1 on the first `session_complete` and session 2 on the next
   `session_complete`, with a 48-hour window and no sitting boundary.

The second rule counts two lessons in one sitting as a return. That is exactly
what KC-03 excludes. A beta report could therefore pass the ≥35% session-2 bar
on a looser definition than the gate uses, which is a false pass at the level of
the project's primary retention decision.

## Decision

1. **KC-03 is the only definition of session-2 for a gate or a beta report.**
   Anchor on `session_start`; require the next `session_start` to be within 48
   hours of session 1's `session_start` and at least 60 minutes after session 1's
   `session_complete`; keep dropouts in the denominator.
2. **`returnMetricsFromLog` stays diagnostic only.** It is the helper behind the
   T5.6 reminder-copy comparison, where both arms use the same rule, so its
   looser definition cannot bias the arm difference. It must never be quoted as
   KC-03 or as T5.7's headline session-2 number. Any tool that reports a gate
   metric computes KC-03 itself from exported `session_start` and
   `session_complete` events.
3. **The T5.7 beta kit states the KC-03 formula verbatim** and labels the helper
   as diagnostic. The kit may not leave two unlabeled definitions in
   circulation.
4. **A follow-up ticket aligns or renames the helper** so a future agent cannot
   mistake it for the gate metric. Until then, the docstrings and the beta docs
   carry the warning.

## Consequences

Positive: the beta and the kill-criteria dashboard report the same number, so
the gate cannot pass on a technicality. The reminder experiment keeps its
same-rule comparison without a rewrite.

Negative: the analyst computes the headline session-2 metric by hand or with a
future helper, not with the T5.6 report. That is one more manual step in a
20-user beta, and it is the price of not shipping two definitions.

## Evidence

- `docs/KILL_CRITERIA_DASHBOARD.md` KC-03 and section 4.2 define the anchor, the
  60-minute boundary, and the denominator.
- `flutter_app/lib/core/retention/return_metrics.dart` implements the looser
  `session_complete` rule for the reminder comparison.
- The T5.7 review (PR #61) found the two docs disagreed and that the beta doc
  omitted the conflict from its source-conflict list.
