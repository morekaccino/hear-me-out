# Reminder-copy experiment (T5.6)

**Status: prepared, not measured; awaiting the T5.7 beta.**
**Owner:** Manager for the beta run; engineering for this protocol and the
analysis helper.
**Source of truth:** Plane. This document is the pre-registered protocol; the
ticket stays **In Review** until the beta produces a real artifact.

## Hypothesis

A reminder that names the next real musical task keeps more beginners on the
second session than a generic reminder.

- **Specific task (control):** the copy that ships today, built from real
  progress only.
- **Generic (treatment):** `Time to practice!`

The experiment asks whether the specific task improves **session-2 within 48
hours** versus the generic body, and secondarily whether it improves **D7
activity**. It is a directional beta pilot, not a powered experiment.

## Variants and exact copy

Both variants share the same notification title, `Time to practice`, the same
chosen reminder time, and the same fixed quiet hours. The body is the only
difference, so the test has one variable.

| Variant | Body | Source |
|---|---|---|
| `specificTask` | `Today: 5 min — <phrase>, 1 bar.` / `Today: 5 min — <phrase>, <n> bars.` when a real phrase target resolves; else `Today: 5 min — 1 note is due.` / `Today: 5 min — <n> notes are due.`; else `Today: 5 min to reach your weekly goal.`; else `Today: 5 min of guitar.` | `reminderTaskBody` in `flutter_app/lib/core/notifications/reminder_copy.dart`, fed from `ProgressState` |
| `generic` | `Time to practice!` | `genericReminderBody` in `flutter_app/lib/core/notifications/reminder_experiment.dart` |

The specific copy never invents a task, a count, or a deadline. The phrase
title and bar count are used only when the caller resolves a real phrase; the
due-note count and the weekly-goal remainder come from `ProgressState`.

**The current Profile reminder path does not resolve a phrase target.** It
calls the copy function without phrase inputs, so during the beta the specific
arm will use the real due-note count, the real weekly-goal remainder, or
`Today: 5 min of guitar.` The phrase/bar branch is the first branch of the same
function and becomes reachable only when a caller supplies a real phrase; it is
not what this beta measures.

Neither body contains a streak, a lost day, "don't lose", "you missed", a fake
deadline, or urgency. `test/reminder_experiment_test.dart` scans every generated
body for those phrases.

## Assignment

Assignment is local, deterministic, and stable for the life of the install:

1. Take the local `installId` from the retention log, trim it, and lowercase it.
2. A well-formed id is at least 8 hex characters. The real id is 32 lowercase
   hex characters from `Random.secure()`. An empty or malformed id gets the
   specific-task copy, which is the current behavior.
3. SHA-256 the UTF-8 bytes of the id.
4. Read the first 8 hex characters of the digest as an unsigned integer.
   - odd → `generic`
   - even → `specificTask`

The rule lives in `reminderVariantForInstall` in
`flutter_app/lib/core/notifications/reminder_experiment.dart`. It uses no
`Random`, no clock, and no platform value, so re-scheduling the reminder after a
time change keeps the same variant. Changing the hash, the digest prefix length,
or the parity rule reassigns every install; do not change it during the beta.

### Who is assigned

Only an install whose **local retention log is opted in** is assigned a
variant. Without opt-in, the reminder keeps the specific-task copy. This keeps
the experiment inside the population whose returns can actually be measured and
avoids changing copy for people who declined instrumentation.

A user who enables the reminder before opting into the log, then opts in later,
can change arms when the reminder is next scheduled. The beta should ask the
cohort to opt in before enabling the reminder; otherwise that user is not
cleanly exposed. This is an opt-in experiment, not an unbiased baseline.

There is no user-facing A/B switch, banner, or experiment copy. The learner
never sees the word "experiment".

## Metrics

### Primary

**Session-2 within 48 hours.**

- Session 1 is the first `session_complete` at or after `installAt` (or the
  first `session_complete` in the log when `installAt` is missing).
- Session 2 is the next `session_complete` strictly after session 1.
- The return counts only when session 2 is at most 48 **elapsed** hours after
  session 1. This is not two calendar days: two sessions at 09:00 and 21:00 the
  next day count (36 h); a session 49 hours later does not, even on an adjacent
  local date.
- Timestamps are UTC in the log. The helper compares instants, not local days.

### Secondary

- **D7 activity:** any `session_complete` or `daily_active` event on the local
  calendar day seven days after the install day, 00:00 through 23:59 local,
  inclusive of the end. A mere `app_open` does not count. `ReturnMetrics`
  reports `day7WindowComplete` so an unfinished day is not read as a miss.
  D7 is a **local-day** metric, but the log stores UTC timestamps only and
  `localDayKey` uses the analysis machine's timezone. Run the analysis in the
  participant's local timezone; a different timezone can move an event between
  day 6, day 7, and day 8. If the timezone is unknown, state that limitation
  rather than guessing.
- **Reminder opt-in rate:** installs with a `reminder_opt_in` event divided by
  opted-in installs with at least one event. This is a proxy, not a perfect
  exposure flag. The event is written only after a successful schedule while
  the log is opted in, so a denied permission, a scheduler failure, or a
  reminder enabled before consent leaves no event. The write is also fired
  without awaiting it, so an app kill before the queued write lands leaves an
  exposed user without the event. Treat `reminder_opt_in` as a lower bound on
  exposure, and use the facilitator's exposure answer for the primary
  denominator.
- **Notification permission grant rate:** the local log has **no** permission
  event, so this is not derivable from the export. The beta facilitator records
  it once per participant during the cohort check-in. Do not infer it from
  `reminder_opt_in`: a denied permission and a granted permission with a
  scheduler failure both leave no opt-in event.

## Measurement source and analysis sequence

The app never uploads anything. The analyst reads the user-copied JSON from
**Profile → Privacy → Copy usage log** and analyzes it offline. The document has
`schemaVersion`, `installId`, `installAt`, and `events`; every event has only
`name`, `at` (UTC), and `installId`.

For each exported log:

1. Verify `schemaVersion: 1`. Reject an unknown version; do not guess.
2. Compute the variant with `reminderVariantForInstall(installId)` or the
   identical documented hash. Do not ask the user which copy they saw.
3. Classify exposure from the facilitator's per-participant answer,
   corroborated by the log:
   - Never enabled the reminder → not exposed.
   - Enabled the reminder before opting into the log → exposed but excluded
     from the primary comparison. The log alone cannot identify this; only the
     facilitator's answer can.
   - Enabled the reminder while opted in → exposed, whether or not
     `reminder_opt_in` is present. The event can be missing because the write is
     fired unawaited and an app kill can lose it.
4. Find session 1 and session 2 with the rules above. Compute
   `returnedWithin48h`.
5. Compute D7 from `installAt` and the local day keys. Only count a user in the
   D7 denominator when `day7WindowComplete` is true.
6. Aggregate **per arm**, never pooled:
   - session-2 rate = returned users / exposed users with session 1;
   - D7 rate = active users / exposed users whose D7 window is complete;
   - reminder opt-in rate = installs with `reminder_opt_in` / opted-in installs
     with any event.
7. Report raw numerators and denominators with every percentage, plus 95%
   Wilson intervals. A percentage without a denominator is not a result.

`returnMetricsFromLog(log, now: ...)` in
`flutter_app/lib/core/retention/return_metrics.dart` implements steps 4–5 and
is covered by `test/return_metrics_test.dart`. It ignores foreign install ids,
future timestamps, and out-of-order events, and it never throws.

## Sample size

The T5.7 beta is 20–40 hand-recruited users, so each arm has roughly 10–20
people. At that size:

- about 20 users per arm can distinguish only a gap of roughly 40 percentage
  points at 80% power (two-sided α = 0.05), for example 35% → 75%;
- about 10 users per arm can distinguish only a gap of roughly 55–60 points.

A 10–15 point difference will look like noise. Report the result as
**directional**, with intervals and denominators. Do not describe the experiment
as powered, do not compute a p-value as if the sample were adequate, and do not
generalize beyond the hand-recruited cohort.

## Decision rule (pre-registered)

Keep the **specific-task** copy unless the generic variant is clearly better on
session-2 within 48 hours. The generic copy is adopted only if **all** of these
hold:

1. At least 8 exposed users per arm have a session 1.
2. The generic arm's session-2 rate is at least **15 percentage points** higher
   than the specific arm's.
3. The 95% Wilson intervals for the two rates do not overlap.

If any condition fails, or the sample is smaller than 8 per arm, the result is
inconclusive and the specific-task copy stays. D7 and the secondary metrics are
reported but do not by themselves change the copy. This threshold is fixed
before data collection and must not be moved after seeing the result.

## Guardrails

- Quiet hours stay fixed at 21:00–07:59; only 08:00–20:59 can be scheduled on
  every path. The experiment changes body copy only and cannot bypass
  `isAllowedReminderTime`.
- No guilt, streak loss, "don't lose", "you missed", fake deadline, or urgency
  in either arm.
- The reminder is a local notification only. There is no push service, no
  account, no network call, no analytics SDK, and no third-party tracker.
- The retention log stays off by default, local, bounded at 500 events, and
  eraseable. Only the user copies it.
- No `ProgressState` or storage-schema change. No new persisted key. No
  user-facing experiment switch.
- The variant is assigned from the install id alone; it does not depend on the
  clock, the chosen reminder time, or the platform.

## Status and what the beta must collect

**Prepared, not measured.** The code, assignment, copy, metrics helper, tests,
and this protocol are in place. No user has received either arm, and no result
exists.

The T5.7 beta must collect:

1. a hand-recruited cohort with a known denominator and recruitment method;
2. one copied local log per opted-in participant, with `installAt` present;
3. each participant's reminder exposure and permission-grant answer, recorded
   by the facilitator;
4. enough elapsed time for session-2 (48 hours after session 1) and D7 (the end
   of install day + 7) to complete before the analysis is read.

Until that artifact exists, T5.6 stays **In Review**, not Done. A merged pull
request, a green test suite, and this document are not evidence.
