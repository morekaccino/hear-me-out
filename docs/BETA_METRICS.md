# Beta metrics (T5.7)

**Status:** Definitions only. The beta has not run, no export exists, and no
value on this page is measured.
**Ticket:** T5.7.
**Source of truth:** Plane for the ticket and thresholds; this page fixes the
field rules the analyst uses so the same export produces the same number twice.
**Related:** [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md),
[`REMINDER_EXPERIMENT.md`](REMINDER_EXPERIMENT.md),
[`KILL_CRITERIA_DASHBOARD.md`](KILL_CRITERIA_DASHBOARD.md),
[`PHASE_GATES.md`](PHASE_GATES.md),
[`BETA_RUNBOOK.md`](BETA_RUNBOOK.md),
[`decisions/0013-session-two-definition.md`](decisions/0013-session-two-definition.md).

This page is not a decision record. It defines how to read the local log for
this beta; it does not change a product threshold or a gate.

## 1. The only input

Every quantitative beta metric comes from one document: the JSON that
**Profile > Privacy > Copy usage log** puts on the clipboard. The app does not
upload it. The facilitator receives the file from the participant and analyzes
it offline.

The document has exactly these fields:

| Field | Type | Use |
|---|---|---|
| `schemaVersion` | integer | Must be `1`. Reject any other value; do not guess a shape. |
| `installId` | string | Pseudonymous install identity. One install, not necessarily one person. |
| `installAt` | ISO-8601 UTC string, optional | Pinned install day. It is outside the event list, so trimming does not move D1/D7/D30. |
| `events[].name` | string | One of the stable wire names in [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md#events). |
| `events[].at` | ISO-8601 UTC string | Event time. Convert to the participant's local timezone before making a day key. |
| `events[].installId` | string | Must match the document id. Ignore an event with a foreign id and flag it. |

There is no `exportedAt`, app version, device, OS, timezone, account, email,
note name, piece title, score, duration, or free text. If a field is not in the
list, the export cannot supply it.

### Validation before any calculation

1. Parse the JSON. If it does not parse, return the file to the facilitator;
   do not repair it by hand.
2. Require `schemaVersion: 1`. Reject a future or unknown version as a whole.
3. Require `installId`. A document without it cannot be attributed.
4. Prefer `installAt`. If it is missing, use the first `app_open` as the install
   time and flag the fallback. If there is no `app_open`, use the first event
   and flag it. If there are no events and no `installAt`, exclude the file from
   day metrics.
5. Ignore events with a foreign `installId`, an unknown name, an unparseable
   `at`, or an `at` after the data-freeze time. Record how many were ignored.
6. Sort by `at` only for display and for the session-2 rule. Do not reorder the
   stored file.

### Install identity and the unit of analysis

The unit for D1/D7/D30 is an **install**, not a person. The log has no account
and no cross-device id.

- One participant can have two installs (web and Android) or a new install
  after clearing site data or reinstalling. Record the primary install at week
  0 in the runbook sheet. Use the primary install for the participant-level
  report and count the second install separately if it exists.
- Two exports with the same `installId` are the same install. Use the latest
  export the participant sent. Do not merge an older export back in after an
  erase; the erase is the participant's choice.
- A new browser profile, incognito session, cleared site data, or APK
  reinstall creates a new `installId`. It is a new install, not a return.
- The cohort denominator is the number of **people** the facilitator enrolled,
  and the quantitative denominator is the number of **primary installs** with
  a valid export. Report both; they can differ.
- `installAt` is the first consent or `app_open`, not necessarily the first time
  the app was opened. A participant who used the app before opting in starts the
  measured window at opt-in. Record the opt-in date; do not backdate it to the
  store or sideload install date.
- A late opt-in can miss `onboarding_start` and `onboarding_complete`. Mark the
  install as late opt-in and report it separately from the activation
  denominator. Do not infer the missing onboarding events from the interview.

### Timezone and day keys

The log stores UTC only. The export does not store the offset that was in
effect when an event happened.

- Record the participant's local timezone at week 0. Analyze that participant's
  file in that timezone. Do not analyze a Berlin participant in the analyst's
  timezone.
- Use a timezone-aware conversion (an IANA zone such as `Europe/Berlin`), not a
  fixed UTC offset, so a daylight-saving change is handled. A fixed offset is
  acceptable only when the participant did not cross a DST change during the
  window, and the report must say so.
- A day key is `yyyy-MM-dd` in the participant's local timezone. Convert each
  `at` to that zone, then take the date.
- The install day is the local date of `installAt`, or the documented fallback.
- If the timezone is unknown, mark the day metrics `INSUFFICIENT DATA` for that
  install. Do not guess a zone, and do not use the analyst's zone as a
  substitute.
- A daylight-saving day is still one calendar day. Do not use a 24-hour window.
- If the participant travels or changes the device timezone, record the change
  and the date. An event near midnight can move between day N and day N+1. State
  the ambiguity; do not silently pick the cleaner date.

### Erased, empty, and trimmed logs

- An exported document with `installAt` and an empty `events` array is not a
  zero-activity install. It is most likely an erased log. Mark it `erased or
  empty` and exclude it from the retention denominators. Do not treat it as a
  churned user.
- The log keeps at most 500 events and drops the oldest. `installAt` survives.
  If the first event is later than `installAt` by a wide margin, flag possible
  trimming. D1/D7/D30 can still be read from the surviving events; session 1
  and session 2 may be unavailable.
- A participant can turn logging off without erasing. Events recorded while it
  was on remain. The gap after opt-out is not evidence of inactivity. Report
  `logging off` and exclude the affected window from a retention claim if the
  gap covers it.

## 2. Metric definitions

All denominators use primary installs with a valid export and a complete
window. A window is complete only when the data freeze is after 23:59:59 on the
last local day in that window.

### Activation

**Definition:** an install with `onboarding_complete` and a `session_complete`
on the install local day (day 0).

- Numerator: installs meeting both conditions.
- Denominator: primary installs with a complete day-0 window.
- `onboarding_complete` is the first event with that name. `session_complete` is
  any event with that name on the install day; the first one is enough.
- Why day 0: activation means the new user finished a real session on the day
  they installed. A first session on day 1 or later is a return, not
  activation.
- The log cannot tell the guided first session from a lesson, practice, or jump
  test. `session_complete` is the common event. Do not claim the guided first
  session specifically completed unless the facilitator saw it. T5.8 lets the
  Path reopen the guided flow until it is completed, but the event still cannot
  distinguish it, so activation is not a first-session completion rate; a normal
  lesson can satisfy the same rule.
- Report the funnel components beside activation: `onboarding_start`,
  `onboarding_complete`, `first_note`, `first_phrase`, and `first_recording`,
  each with its own denominator.

**Event meanings.**

- `first_note` is the first determinate scored note-prompt answer (naming,
  placing, or hearing), correct or incorrect. It is not pitch-verified and it is
  not accuracy evidence.
- `first_phrase` is the first completed practice-only first-session phrase
  verification. It is not a scored phrase and it is not accuracy evidence.

**Known call-site mismatch.** The current first-session flow also calls
`recordFirstNote()` after a completed practice-only phrase verification. That
call is an implementation defect against the `first_note` meaning above. Until
it is removed, a `first_note` event does not prove a scored note prompt; do not
infer pitch verification, correctness, or accuracy from it. Remove the call in a
follow-up; do not create a second definition for it.

### D1, D7, and D30

**Definition:** the install is retained on day N when at least one event exists
on the local calendar day N after the install day. N is 1, 7, or 30.

- Numerator: installs with at least one event on that local day.
- Denominator: primary installs with an install day and a complete day-N
  window.
- Any event counts, including `app_open`. This is the app's
  `RetentionLog.retainedOnDay(N)` rule and the rule in
  [`KILL_CRITERIA_DASHBOARD.md`](KILL_CRITERIA_DASHBOARD.md) for KC-06 and
  KC-09.
- D1 is the day after the install day, not the first 24 hours. D7 is local day
  7, not seven 24-hour periods. D30 is local day 30.
- If the participant installed at 23:50, day 0 still ends at local midnight.
  The first 10 minutes are day 0, not a reason to start the clock at install
  time.
- At a week-4 exit, D7 is usually complete and D30 is not. D30 stays
  `INSUFFICIENT DATA` until the day-30 window closes. Ask for a final export on
  day 30 or later; do not infer D30 from D7.

**Difference from the reminder experiment.** The reminder experiment's D7 is
stricter: it counts only `session_complete` or `daily_active`, not a mere
`app_open`. That rule lives in
[`REMINDER_EXPERIMENT.md`](REMINDER_EXPERIMENT.md) and is computed by its own
report tool. Do not substitute the stricter D7 for the beta D7 without labeling
the difference, and do not pool the two.

### Session-2 within 48 hours (KC-03)

**KC-03 definition, verbatim from the dashboard:**

> Share of new users with a second session whose `session_start` is within 48 h
> of session 1's `session_start` (the 48 h is anchored to session 1's start, not
> to its completion or to `installAt`). Session 2 must follow session 1's
> `session_complete` by at least 60 minutes; that sitting boundary is a proposed
> operational definition (open questions, section 8). Denominator: installs in
> the cohort window with a first `session_start`; dropouts stay in the
> denominator.

How to apply it:

- Session 1 is the first `session_start` for the install.
- Session 1's completion is the first `session_complete` after session 1's
  `session_start` with no intervening `session_start`. If another start happens
  first, the completion belongs to that later sitting and session 1 is a
  dropout.
- Session 2 is the first `session_start` that satisfies both conditions: within
  48 elapsed hours of session 1's `session_start` and at least 60 minutes after
  session 1's `session_complete`.
- Numerator: installs with a qualifying session 2.
- Denominator: installs in the cohort window with a first `session_start`.
  Dropouts stay in the denominator.
- An install whose first `session_start` has no `session_complete` is a
  session-1 user who did not return. It stays in the denominator; it cannot
  have a qualifying session 2.
- Session 2 does not need its own `session_complete`; the metric is a return,
  not a completed second session.
- The 48-hour window is complete only when the export or data freeze is at least
  48 hours after session 1's `session_start`. If it is not, and no session 2 is
  found, report `window open`, not `no`.
- This is an elapsed-hour rule, not a calendar-day rule. Two sessions at 09:00
  and 21:00 the next day count (36 h); a session 49 hours later does not, even
  if it is on an adjacent local date.
- The 60-minute boundary is the dashboard's proposed operational definition,
  adopted here as the only definition for this beta by
  [decision 0013](decisions/0013-session-two-definition.md).

**The helper implements this rule.** `returnMetricsFromLog` in
`flutter_app/lib/core/retention/return_metrics.dart` computes session 1 from the
first `session_start`, session 2 from the first `session_start` that clears the
60-minute sitting boundary and the 48-hour window, and keeps an incomplete first
session in the denominator. T5.9 aligned it with KC-03, so the T5.6 reminder
report and any tool that calls it report the same definition as this page; there
is no second session-2 rule. The helper defaults `now` to the current clock, so
the analyst must pass the data-freeze time or filter the exported events to the
freeze before calling it; otherwise a later event can enter the result.

The per-arm reminder analysis is owned by the reminder report. This page defines
the KC-03 rule only; it does not duplicate the arm comparison, exposure
classification, or decision rule.

### First recording by day 7

**Definition:** an install with a `first_recording` event on a local date from
the install day through the end of local day 7, inclusive.

- Numerator: installs with `first_recording` in that window.
- Denominator: primary installs with a complete day-7 window.
- `first_recording` is written by a real saved take, not by a tap or a prompt.
  It is emitted once per install.
- The log does not count later takes. It cannot tell whether the first take was
  a guided first-session recording, a Practice recording, or another save.
- This is the KC-04 signal. P1.5 treats first recording by day 7 as report-only,
  while the dashboard keeps a locked line and an open question. The gate owner
  resolves that difference; this page does not change either threshold.

### Recording manifest and KC-12

KC-12 is **not** read from the retention log. It is read from the separate
one-file manifest that **Practice > Recordings > Beta recording index >
EXPORT RECORDINGS MANIFEST** writes. The participant sends only the JSON file,
never a `.wav` take.

Document fields:

| Field | Meaning |
|---|---|
| `schemaVersion` | `1`. Reject any other version. |
| `generatedAt` | UTC ISO-8601 export time. |
| `capture.assumed` | `true`. The rate and format are the export's assumption, not a per-take header read. |
| `capture.sampleRate` | The V1 recorder/encoder assumption: 22050 Hz. |
| `capture.format` | The V1 encoder assumption: `wav`. |
| `takes[].pieceId` | Piece id, or null for a free take. |
| `takes[].phraseId` | Phrase id, or null. |
| `takes[].createdAt` | UTC ISO-8601 save time. |
| `takes[].durationSeconds` | Stored take length in seconds. |
| `takes[].firstTake` | True for the earliest currently stored take of a non-null piece. |
| `takes[].lastTake` | True for the latest currently stored take of a non-null piece. |

Every currently stored take is one row. Per-piece retention deletes middle
takes, so the manifest is a snapshot of what is currently stored, not every take
ever saved. The document has no media id, absolute path, byte length, device
name, install id, participant name, free text, or audio bytes. A piece with one
take marks that row as both first and last; it does not qualify as a
before/after pair.

The export does not read each WAV header. `capture.assumed` is `true` and states
the V1 assumption once for the whole file. A future rate or AAC change must
update the assumption; `RecordingService.buildRecordingsManifest` asserts it and
the assumption test fails in CI.

**KC-12 definition:** distinct beta participants with at least two currently
stored takes of the same piece (a first and a last take) in the manifest during
the beta window.

- A participant qualifies when one `pieceId` group has at least two rows whose
  `createdAt` falls inside the participant's beta window, and the `firstTake`
  and `lastTake` flags are on different rows. A single-take group does not
  qualify.
- A participant with no currently stored takes still exports and sends the
  manifest. The file has `takes: []`; that participant stays in the denominator
  with no qualifying pair and must not silently disappear.
- Use the latest manifest export per participant. Do not merge an older export
  into a newer one; the newest `generatedAt` is the snapshot.
- The beta window is the participant's install day through the data-freeze time.
  The manifest has no `installAt`; take the install date from the retention log
  or the cohort sheet.
- Report the count of qualifying participants and the denominator of
  participants who sent a valid manifest, including empty manifests. The
  dashboard's KC-12 gate is a count of beta users, not a percentage; state both
  the count and the manifest denominator.
- The manifest is read-only. It never changes, deletes, or rewrites a take or
  the stored index.
- The participant sends only the JSON. Never ask for the audio, and do not
  attach a `.wav` to the report or a ticket.

### Completed sessions per install-anchored week

This is context for the plan's 3-sessions-per-week target. It is not a new gate.

- Week 0 is local days 0 through 6, week 1 is days 7 through 13, week 2 is days
  14 through 20, and week 3 is days 21 through 27 after the install day.
- Count `session_complete` events in each block. A session that starts in one
  block and completes in the next counts where it completes.
- Denominator for a week: primary installs with a complete block.
- Report the count per install and the share with at least three. Do not
  average weekly percentages across participants.
- The install-anchored week is not the app's local-Monday quest week. State the
  difference if you compare this number to a Quests screen.
- [`KILL_CRITERIA_DASHBOARD.md`](KILL_CRITERIA_DASHBOARD.md) treats "3+
  sessions/week for 4 weeks" as an open definition. Report this as context and
  let the gate owner confirm the reading.

### Session counts, not minutes

The log has no duration. Do not multiply a session count by an assumed number
of minutes. The weekly goal (30 minutes by default) is stored in the app as
real measured seconds, but it is not in the export. Weekly minutes and
weekly-goal completion are interview evidence only. Label them as self-report.

## 3. Aggregation

1. Freeze the participant list, the primary install per participant, the
   timezone map, and the data-freeze time before opening a file. Write the
   freeze date in the report.
2. Compute one row per primary install using section 2. Do not compute a
   percentage per participant and then average those percentages. Sum the
   numerators and the denominators.
3. Report every percentage with its numerator, denominator, and a 95% Wilson
   interval. For a proportion `p = n / d`, with `z = 1.96`:

   ```text
   center = (p + z^2 / (2d)) / (1 + z^2 / d)
   half   = z * sqrt(p * (1 - p) / d + z^2 / (4d^2)) / (1 + z^2 / d)
   interval = center +/- half
   ```

   Report the interval on the same scale as the percentage, to one decimal.
   When `d` is zero, write `INSUFFICIENT DATA`; do not compute an interval.
4. Do not compute a p-value for this cohort. Twenty hand-recruited users have
   wide intervals and no power for a small difference. A directional statement
   with intervals and denominators is the honest maximum.
5. Keep the same rule for every participant. If a definition changes after the
   first export, split the report into the old and new definitions and show
   both; do not rewrite the earlier numbers.
6. Report `INSUFFICIENT DATA` for an open window, an unknown timezone, an erased
   log, or a zero denominator. A missing value is not a zero.

### Data-quality flags to put in the report

- Number of enrolled participants, number with a valid export, number with a
  primary install, and number missing an export.
- Number with a missing `installAt` and the fallback used.
- Number with an unknown timezone and the affected metrics.
- Number of erased or empty logs.
- Number of files with a foreign `installId`, an unknown event, or a future
  timestamp, and how many events were ignored.
- Number of participants with more than one install, and which install is
  primary.
- Number with possible log trimming.
- The build commit or commits and the client split. A rebuild during the cohort
  splits the data; report the split.

## 4. What cannot be known

This list is deliberate. If a question is not here and not in section 2, the
export cannot answer it.

| Question | Can the export answer it? | Where the answer can come from |
|---|---|---|
| Store installs, store page views, install referrer | No | Not measured. There is no store listing or install referrer. |
| Share-to-install, invite attribution | No | Not measured. There is no share link or code. |
| Other participants' device data | No | Only the exports participants choose to send. |
| App version, device model, OS, locale | No | Facilitator records it at install. |
| Timezone at the moment of each event | No | Facilitator records the zone; travel and DST stay approximate. |
| Microphone accuracy, note accuracy, scored phrase accuracy | No | T1.6/T1.7 corpus and spike evidence. The scored loop is off. |
| Weekly minutes and weekly-goal completion | No | Interview self-report only. |
| P1.5 first note <60 s and first phrase <3 min | No | The log has no reliable start-to-event timer. `installAt` is the opt-in/app-open time, not the onboarding start, and event timestamps are not screen timings. Do not compute these targets from the log. |
| Placement completion or score | No | Interview only. |
| Reading Lab completion | No | Interview only. |
| Quest completion or claim | No | Interview only. Quests have no reward and no event. |
| Recordings beyond the first | No (retention log) | The separate recording-manifest JSON lists every currently stored take. |
| Two takes of the same piece, before/after pairs, KC-12 | No (retention log) | The separate recording-manifest JSON. See the manifest section above. |
| Notification permission grant | No | Facilitator records the answer once per participant. `reminder_opt_in` is a lower bound on exposure, not permission. |
| Reminder copy arm and per-arm session-2/D7 | Only with the reminder protocol | [`REMINDER_EXPERIMENT.md`](REMINDER_EXPERIMENT.md) and its report tool. Its session-2 helper now computes the same KC-03 rule. This page does not duplicate the arm comparison. |
| Uninstall, churn reason | No | Interview only. |
| Crashes, ANRs, frame time, battery | No | Not measured. There is no crash reporting or performance telemetry. |
| Revenue, paywall conversion, subscription | No | Not measured. There is no paywall or store product in this build. |
| Causality, the product's overall retention rate | No | The cohort is 20 hand-recruited volunteers. Results are directional for this cohort only. |
| D30 before the day-30 window closes | No | Wait for the final export on day 30 or later. |

### Source conflicts and caveats

- **Session-2 (resolved and aligned).** [Decision
  0013](decisions/0013-session-two-definition.md) rules that KC-03 is the only
  definition for a gate, a beta report, or the helper. T5.9 aligned
  `returnMetricsFromLog` with it: first `session_start`, the 60-minute sitting
  boundary, the 48-hour window anchored to session 1's start, and incomplete
  first sessions kept in the denominator. A rate computed before T5.9 is not
  comparable and must be recomputed from the exports.
- **P1.3 is not a beta source.** The Phase 1 gate listed T5.7 as a source for
  phrase false-fail and false-pass. This beta cannot supply that: the scored loop
  is off and the log has no note-level data. Phrase accuracy stays with T1.6 and
  T1.7; the gate source line is corrected.
- **KC-04 primary source.** The dashboard's primary evidence for KC-04 is the
  T5.7 cohort recording manifest and before/after evidence; the opt-in log's
  `first_recording` is diagnostic. The manifest export exists in this ticket, so
  use it as the primary source and report the log as diagnostic.
- **KC-12 source.** The participant-sent recording manifest is the source; the
  retention log cannot count takes. The export exists in this ticket. The
  dashboard's KC-12 row can now be updated by its owner.

## 5. Reporting rules

- Every percentage gets a numerator, a denominator, and a 95% Wilson interval.
  A percentage without a denominator is not a result.
- Report the cohort window, the data-freeze date, the build commit or commits,
  and the client split beside the metrics.
- Do not pool this cohort with opt-in users outside the beta, with another
  cohort, or with the reminder arms. Report each denominator separately.
- Do not describe an opt-in log as an unbiased baseline. It is diagnostic, and
  the hand-recruited cohort is not random.
- Do not call a difference a win, a loss, or a causal effect from 20 people.
  Say "in this cohort" and show the interval.
- Do not add a metric to the report after seeing the data. If a new question
  appears, mark it exploratory and keep it out of the pre-declared result.
- Do not put a participant's name, email, exact address, or raw export in the
  report or a public ticket. Use the participant code.
- A merged pull request, a green test suite, or this page is not a beta result.
  Only real exports from real participants are.

## 6. Cross-references

- [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md): event names,
  storage shape, opt-in, export, erase, and the bias caveat.
- [`REMINDER_EXPERIMENT.md`](REMINDER_EXPERIMENT.md): the pre-registered
  reminder-copy arm, its stricter D7, its KC-03 session-2 rule, and its decision
  rule. Its report tool owns the per-arm analysis and calls the shared helper.
- [`KILL_CRITERIA_DASHBOARD.md`](KILL_CRITERIA_DASHBOARD.md): locked thresholds
  for KC-03 (session-2), KC-04 (first recording), KC-06/KC-09 (D30/D7), and
  KC-12 (before/after recordings). This page defines the fields; the dashboard
  owns the pass, warn, fail, and insufficient-data status.
- [`PHASE_GATES.md`](PHASE_GATES.md): P1.4 (D7), P1.6 (session-2), and P1.3
  (phrase accuracy, which this beta cannot supply).
- [`BETA_RUNBOOK.md`](BETA_RUNBOOK.md): recruitment, install, the four-week
  schedule, export instructions, blocker ranking, and exit criteria.
- [`decisions/0001-conditional-go.md`](decisions/0001-conditional-go.md) and
  [`decisions/0010-first-session-practice-only.md`](decisions/0010-first-session-practice-only.md):
  why the scored phrase loop is off and why the first session is practice-only.
