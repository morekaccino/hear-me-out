# Decision 0013 — Session-2 uses the KC-03 definition in every path

**Date:** 2026-11-16
**Status:** Accepted; aligned by T5.9 on 2026-11-16
**Owner:** AI delivery manager
**Supersedes:** Nothing
**Related:** T5.6, T5.7, T5.9, T9.1, T9.2, KC-03, `docs/KILL_CRITERIA_DASHBOARD.md`, `docs/BETA_METRICS.md`, `docs/REMINDER_EXPERIMENT.md`

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
   anchored session 1 on the first `session_complete` and session 2 on the next
   `session_complete`, with a 48-hour window and no sitting boundary.

The second rule counts two lessons in one sitting as a return. That is exactly
what KC-03 excludes. A beta report could therefore pass the ≥35% session-2 bar
on a looser definition than the gate uses, which is a false pass at the level of
the project's primary retention decision.

T5.9 removed the difference. `returnMetricsFromLog` and the T5.6 reminder report
now implement the KC-03 rule, so no looser definition remains in the code.

## Decision

1. **KC-03 is the only definition of session-2 for a gate, a beta report, or the
   helper.** Anchor on `session_start`; require the next `session_start` to be
   within 48 hours of session 1's `session_start` and at least 60 minutes after
   session 1's `session_complete`; keep dropouts in the denominator. An install
   whose first `session_start` has no `session_complete` is a session-1 user who
   did not return, not an excluded install.
2. **`returnMetricsFromLog` implements the KC-03 rule.** It backs the T5.6
   reminder-copy comparison, where both arms use the same rule, and it may be
   quoted as the KC-03 calculation for a local log. It keeps the `now`
   data-freeze filter and never throws.
3. **The T5.7 beta kit states the KC-03 formula verbatim** and names the helper
   as the same rule. The kit may not leave two unlabeled definitions in
   circulation.
4. **No loose mode.** A caller that needs a different rule must add an explicit
   named parameter with a doc warning and a new decision record; it may not
   reuse this helper silently. The original "align or rename" follow-up is
   closed by T5.9.

## Consequences

Positive: the beta, the kill-criteria dashboard, and the reminder report compute
the same number, so the gate cannot pass on a technicality and the helper cannot
be mistaken for a looser metric. The reminder experiment keeps its same-rule
comparison without a second definition.

Negative: the T5.6 report's per-arm rates change under the stricter rule and are
not comparable with any rate computed before T5.9. An earlier analysis must be
recomputed from the exports. That is the price of one definition.

## Evidence

- `docs/KILL_CRITERIA_DASHBOARD.md` KC-03 and section 4.2 define the anchor, the
  60-minute boundary, and the denominator.
- `flutter_app/lib/core/retention/return_metrics.dart` implements the KC-03 rule.
  `flutter_app/test/return_metrics_test.dart` covers the sitting boundary, the
  48-hour anchor to session 1's start, the incomplete first session in the
  denominator, and the `now` filter.
- `flutter_app/tool/beta/reminder_experiment_report.dart` and
  `flutter_app/test/reminder_experiment_report_test.dart` use the same helper;
  the report no longer carries a second session-2 rule.
- The T5.7 review (PR #61) found the two docs disagreed and that the beta doc
  omitted the conflict from its source-conflict list.
