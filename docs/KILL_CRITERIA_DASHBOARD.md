# Kill-criteria dashboard

**Status:** Single status page. Baseline created 2026-11-07; no phase gate has
been held and no criterion has been measured.
**Ticket:** [T9.4] — Build the kill-criteria dashboard.
**Maintainer:** The delivery manager owns this page in Plane; the gate decision
owner signs each review.
**Source of truth:** Plane. The approved plan owns the thresholds,
[`PHASE_GATES.md`](PHASE_GATES.md) owns the gate checklist, and [T9.2] owns every
decision. If this page and Plane disagree, Plane wins; correct this page and
record the reason in [T9.2].

---

## 1. Purpose and use

This page is reviewed at every phase gate. It is the single place that shows,
for each locked kill and gate threshold, the current measured value with its
source, owner, and date. A failed criterion is **information, not failure**: it
tells the team which loop to fix, not which surface to add. A kill threshold
that fires stops mic-first or subscription work even when the rest of the gate
looks green, and a gate cannot pass while a kill criterion is active. A
criterion with no measurement is `INSUFFICIENT DATA`; it is never a pass, and a
number is never invented to fill the cell. The thresholds are pre-registered:
they are compared against the data, not adjusted to it (see section 5).

## 2. Reading the table

| Threshold | Meaning |
|---|---|
| **Kill / stop** | The measured value has crossed the pre-registered stop line. Execute the fail action immediately; do not wait for the phase gate and do not add a surface to rescue the number. |
| **Warning band** | The value sits between the plan's kill line and the later gate-pass line. It is a `WARN`: keep measuring, fix the loop, and do not expand scope. The band exists only where the plan and T9.9 use different numbers for the same metric. |
| **Gate pass** | The value meets the pre-registered gate. `PASS` requires a dated artifact with a denominator, not a summary, merge, test run, or plan quote. |

| Status | Meaning |
|---|---|
| `PASS` | The gate-pass threshold is met with linked evidence. |
| `WARN` | The value is inside the warning band, above the kill line and below the gate-pass line. |
| `FAIL` | The kill threshold fired, or the gate-pass threshold is missed where no warning band is defined. |
| `INSUFFICIENT DATA` | No measurement exists, the window has not closed, or the denominator is missing. This is not a pass and not a fail. |

Rules applied to every row:

- Put the value, denominator, sample size, and data date in the cell; a bare
  percentage is not a measurement.
- A kill threshold fires on the measured value even if the phase decision is
  `conditional`.
- Do not move a threshold after seeing the data. A change needs a new [T9.2]
  decision record (section 5).

## 3. Dashboard

Baseline status: every row is `INSUFFICIENT DATA` because the beta has not run,
no corpus exists, and the spike report is not final (section 6). `Not measured`
appears in the current-value cell rather than any invented number.

| Criterion and definition | Kill / stop | Warning band | Gate pass | Current value (2026-11-07) | Data source | Owner (role) | Last reviewed | Status | Response if failed |
|---|---|---|---|---|---|---|---|---|---|
| **KC-01 Phrase false fail.** Per-phrase false-fail rate on the T1.6 corpus: takes the expert labels a pass that the scorer fails ÷ expert-labelled passing takes. A take with >20% indeterminate notes is incomplete and excluded. Window: 6–10 players, 4 devices, 3 conditions, ≥240 takes, 4/8/16-note phrases at 60–90 BPM, held-out split by player and piece, 95% CI. | >10% | None (single boundary) | ≤10% | `Not measured` | T1.6 corpus metrics report and T1.7 go/no-go; [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md), [`CORPUS_LABELING.md`](CORPUS_LABELING.md), [`LATENCY_RIG.md`](LATENCY_RIG.md) | Assessment lead (human-owned corpus and T1.7; engineering analysis) | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Stop mic-first; keep `phraseLoopEnabled` off; pivot to call-and-response, single-bar assessment, or the notation trainer; record in [T9.2] |
| **KC-02 Phrase false pass.** Per-phrase false-pass rate on the T1.6 corpus: takes the expert labels a fail that the scorer passes ÷ expert-labelled failing takes. Same corpus, indeterminate rule, split, and confidence interval as KC-01. | >5% | None (single boundary) | ≤5% | `Not measured` | T1.6 corpus metrics report and T1.7 go/no-go; [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md), [`CORPUS_LABELING.md`](CORPUS_LABELING.md), [`LATENCY_RIG.md`](LATENCY_RIG.md) | Assessment lead (human-owned corpus and T1.7; engineering analysis) | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Stop mic-first; keep `phraseLoopEnabled` off; pivot to call-and-response, single-bar assessment, or the notation trainer; record in [T9.2] |
| **KC-03 Session-2 within 48 h.** Share of new users with a second session whose `session_start` is within 48 h of session 1's `session_start`. Session 2 must follow session 1's `session_complete` by at least 60 minutes; that sitting boundary is a proposed operational definition (open question, section 7). Denominator: installs in the cohort window with a completed first session. Dropouts stay in the denominator. | <35% | None (single boundary) | ≥35% | `Not measured` | T5.7 beta cohort session log (primary); local opt-in log events `session_start`, `session_complete` (diagnostic); [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md) | Product/beta lead | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Fix onboarding, the first session, and the return trigger before adding content or surfaces; record in [T9.2] |
| **KC-04 Record by day 7.** Share of installs with a real saved take (`first_recording`) within 7 local days of `installAt`. Denominator: installs with a pinned install day in the cohort. A tap or a prompt never counts as a recording. | <25% | None (single boundary) | ≥25% | `Not measured` | Local opt-in log `app_open`/`installAt` and `first_recording` (diagnostic); T5.7 beta cohort recording manifest and before/after evidence (primary); [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md) | Product/beta lead | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Performance is not compelling; fix the recording/performance loop and the day-7 trigger before adding content or surfaces; record in [T9.2] |
| **KC-05 Best-cell pre-sale conversion.** Best of the three $49/$69/$99 annual founding cells: orders ÷ targeted visitors in that cell. Each cell targets 1,000 visitors (3,000 total). Report total pre-orders across cells and the email-capture rate beside it; email capture is a Phase 0 gate condition without its own kill line. | Best cell <1.5% OR <15 pre-orders across cells | Best cell 1.5% to <3% AND 15–29 pre-orders across cells | Best cell ≥3% OR ≥30 pre-orders across cells | `Not measured` | T1.8/T6.1 pre-sale dashboard export with per-cell visitors, orders, dates, and channel attribution; email-capture report | Founder/product owner | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Demand is not proven; stop or narrow the product. Do not build Phase 1 to see if it works; record in [T9.2] |
| **KC-06 D30 retention.** Share of installs active on local day 30 after install day, where the day-30 window has closed. The opt-in log's `retainedOnDay(30)` diagnostic uses the same local-day rule. Plan §12.4 evaluates the kill after 3 months of cohort data. | <8% | 8% to <10% | ≥10% | `Not measured` | T5.7 beta cohort day-30 follow-up (primary); local opt-in log `daily_active`/`app_open` and `retainedOnDay(30)` (diagnostic); [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md) | Product/growth lead | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Niche/positioning wrong; switch to one-time piece packs at $49–$79 or narrow the scope. No social, AI, or teacher-dashboard surface; record in [T9.2] |
| **KC-07 Free→Pro by day 30.** Paid conversions by day 30 ÷ installs reaching day 30. Count paid conversions only, not trial starts; report refunds separately. The paywall sits after the first recording and the day-7 recap; the first week is never gated. Plan §12.4 evaluates the kill after 3 months. | <1.5% | 1.5% to <2% | ≥2% | `Not measured` | Store/subscription ledger matched to install cohorts (T6.4/T6.8); no in-app payment exists in the current build | Product/growth lead (monetization) | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Paywall or value is wrong; change price/paywall or switch to one-time piece packs at $49–$79; record in [T9.2] |
| **KC-08 Content cadence.** Released new pieces per calendar month, counted from the release log, never from the plan or the calendar's intent. Report shipped pieces and the T3.9 cost/hours report beside it. | <1 new piece/month | None (single boundary) | ≥1 new piece/month | `Not measured` | [`CONTENT_CALENDAR.md`](CONTENT_CALENDAR.md) release log and T3.9 production report; count shipped pieces | Content lead | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Subscription promise broken; apply the T3.9 trigger-4 response: freeze cadence, fix the cause, and switch to one-time packs if it persists; record in [T9.2] |
| **KC-09 D7 retention.** Share of installs active on local day 7 after install day, where the day-7 window has closed. Same local-day rule and cohort as KC-06. | None defined | None defined | ≥18% | `Not measured` | T5.7 beta cohort day-7 follow-up (primary); local opt-in log `daily_active`/`app_open` and `retainedOnDay(7)` (diagnostic); [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md) | Product/beta lead | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Fix onboarding, the first session, and the return trigger; no new content or surfaces; record in [T9.2] |
| **KC-10 3+ sessions/week.** Share of actives (≥1 session in the 4-week pilot) with ≥3 sessions in each of 4 consecutive weeks. Report the denominator and the median sessions/week. The "each of 4 weeks" reading is an open question (section 7). | None defined | None defined | ≥30% of actives | `Not measured` | T5.7 beta cohort session log (primary); local opt-in log `session_start`/`session_complete` (diagnostic) | Product/beta lead | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | Fix onboarding, the first session, and the return trigger; no new content or surfaces; record in [T9.2] |
| **KC-11 Annual renewal.** Share of annual subscribers whose first renewal succeeds at 12 months ÷ annual subscribers reaching their renewal date. Monthly subscribers are not counted; refunds are reported separately. | None defined | None defined | ≥45% | `Not measured` | Store/subscription ledger; first measurable after 12 months of paid cohorts (T9.9) | Product/growth lead (monetization) | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | The renewal gate blocks Phase 3; fix the price/promise or switch to packs; record in [T9.2] |
| **KC-12 Beta users with before/after recordings.** Distinct beta users with at least two saved takes of the same piece (first and last take) in the recordings manifest during the beta window. Takes stay local; the user or researcher exports the manifest. | None defined | None defined | ≥20 beta users | `Not measured` | Local recordings manifest `hear_me_out_recordings_v1`, exported by the beta researcher; T5.7 beta cohort | Product/beta lead | 2026-11-07 (baseline) | `INSUFFICIENT DATA` | No performance-improvement claim; keep the before/after card private; extend the beta or fix the record/compare funnel; record in [T9.2] |

Status legend: `PASS`, `WARN`, `FAIL`, `INSUFFICIENT DATA`. The `WARN` state is
possible only for KC-05, KC-06, and KC-07 because only those rows have a warning
band.

## 4. Measurement notes

### 4.1 Phrase validity (KC-01, KC-02)

- The number comes from the T1.6 corpus metrics report, built from labelled real
  takes under [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md) and
  [`CORPUS_LABELING.md`](CORPUS_LABELING.md). The spike report and the T1.7
  decision are human-owned; an agent may prepare the analysis, not the labels or
  the decision.
- False fail is computed over expert-labelled **passing** takes; false pass over
  expert-labelled **failing** takes. Report the denominator, the indeterminate
  rate, and 95% confidence intervals. A take with more than 20% indeterminate
  notes is incomplete, not a pass or a fail, and is excluded from both rates.
- Timing and bleed gates live in [`LATENCY_RIG.md`](LATENCY_RIG.md) and plan
  §4.4. A timing failure does not change KC-01/KC-02; it forces headphones,
  notes-only scoring, or dropping the "in time" claim.
- As of 2026-11-07 no corpus has been recorded and no spike report is final
  ([`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md) status). Both rows stay
  `INSUFFICIENT DATA`.

### 4.2 Retention and recording (KC-03, KC-04, KC-06, KC-09)

- **Cohort rule.** The T5.7 hand-recruited beta cohort is the evidence. Every
  dropout stays in the denominator. State the cohort window, install count, and
  data-freeze date in the review note.
- **D7 and D30.** A user is retained on day N when at least one event exists on
  the local calendar day N after the install day. The local log implements this
  as `retainedOnDay(N)` against a pinned `installAt`. The pilot report must use
  the same rule or state the difference.
- **Session 2 within 48 h.** See KC-03. `session_start` fires per lesson,
  practice, or jump test, so two lessons in one sitting are not a return. The
  60-minute sitting boundary separates sittings; confirm the definition in
  [T9.2] before the first measurement.
- **Record by day 7.** `first_recording` is emitted once per install by the real
  recording save path (`recording_controller.dart`), not by a tap or prompt.
  The denominator is installs with a pinned install day. The local log is
  opt-in, so the beta recording manifest is the primary evidence.
- **Event names.** `app_open`, `session_start`, `session_complete`,
  `daily_active`, `first_recording`, and `installAt` are defined in
  [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md). Do not rename
  the wire names.

### 4.3 Pre-sale (KC-05)

- The number comes from the three-cell pre-sale dashboard export (T1.8/T6.1):
  per-cell visitors, orders, dates, and channel attribution. Each cell targets
  1,000 targeted visitors; the total is 3,000.
- The pass rule is "30+ pre-orders across cells OR ≥3% in the best cell"; the
  kill rule is "best cell <1.5% OR <15 pre-orders". The warning band is the
  region where neither rule fires: best cell 1.5% to <3% **and** 15–29 pre-orders.
- Email capture ≥10% is part of the Phase 0 pre-sale gate (plan §11.5) but has
  no kill line in the locked table. Report it beside KC-05; it does not change
  the row's status on its own.

### 4.4 Content cadence (KC-08)

- Count released pieces per calendar month from the release log, not from the
  plan or the content calendar's intended cadence. Report cost and hours per
  piece for the same month so the T3.9 triggers are visible.
- [`CONTENT_CALENDAR.md`](CONTENT_CALENDAR.md) §6.1 defines the measurable
  triggers. Trigger 4 uses two consecutive months below one piece/month; the
  locked dashboard kill is one month below one piece/month. That window
  difference is an open question in section 7, not a silent choice.

### 4.5 Conversion, renewal, and recordings (KC-07, KC-10, KC-11, KC-12)

- **Free→Pro and renewal.** Use the store or subscription ledger, matched to
  install cohorts. Count paid conversions and successful renewals, not trial
  starts. Report refunds separately. No paywall or subscription exists in the
  current build, so the rows cannot be measured yet.
- **3+ sessions/week.** Use the pilot session log. Report the active-user
  denominator, the share meeting the weekly bar, and the median. A 3x/week
  average across all users is not the gate.
- **Before/after recordings.** Use the versioned local manifest
  `hear_me_out_recordings_v1`; a qualifying user has at least two saved takes of
  the same piece. Recordings never leave the device except through the user's
  explicit export.

### 4.6 Bias and what is not evidence

The local retention log is **opt-in and biased**: people who enable a beta log
differ from people who ignore it and know they are observed. It is diagnostic,
not an unbiased baseline. The beta is a **hand-recruited cohort**, not a random
install population. Do not present opt-in D1/D7/D30 as the product's retention
rate. A merged pull request, a green test suite, a plan quote, this page, or an
agent summary is not user, learning, demand, legal, or funding evidence.

## 5. Gate review protocol

At every phase gate, in this order:

1. **Freeze the data date and the cohort window.** Write both in the review
   note; do not add later data to an earlier decision.
2. **Fill every current value.** Put the value, denominator, sample size, and
   source link. If there is no measurement, write `Not measured` and
   `INSUFFICIENT DATA`; do not leave a blank and do not estimate.
3. **Compare against the locked thresholds.** Mark `PASS`, `WARN`, `FAIL`, or
   `INSUFFICIENT DATA` for each row. A conditional gate is not a pass.
4. **Record the decision and the evidence link in [T9.2].** Update [T9.1] if the
   gate changed a risk. Update [`PHASE_GATES.md`](PHASE_GATES.md) with the
   evidence link for each gate record.
5. **Do not add a surface while a loop metric fails.** KC-01–KC-04 and KC-09 are
   loop metrics; fix onboarding, the first session, the return trigger, or the
   performance loop before adding content, notifications, or a new surface.
6. **Execute the fail action.** A kill threshold runs its response immediately.
   A missed gate-pass threshold is a gate fail, not a launch task.
7. **Carry the decision forward.** The next review starts from the recorded
   decision, not from memory.

## 6. Change control

The thresholds on this page are **locked**. They were set before the
measurements and are not adjusted after seeing the data.

- Any change requires a new decision record in [T9.2] with: the old value, the
  new value, the date, the evidence, and the reason.
- "We did not hit it" is not a reason. Neither is "the number looks close". A
  threshold may change only for a stated, dated reason tied to new evidence
  (for example, a definitional fix that makes two sources comparable).
- Do not rewrite an old gate record or a past decision. Append the new record
  and link the old one.
- The dashboard keeps the old value visible next to the new one until the next
  gate review, so a moved goalpost cannot be hidden.
- If Plane and this page disagree, Plane wins; correct this page and record the
  reason in [T9.2].

## 7. Current honest status (2026-11-07)

The beta has not run, no corpus has been recorded, the spike report is not
final, and no pre-sale exists. **All twelve rows are `INSUFFICIENT DATA`.** None
is `PASS`, `WARN`, or `FAIL`. No row has a measured value, and this page does not
copy a plan target as if it were measured.

What is known from the code and docs, stated without presenting planned work as
shipped:

- The app is still the **240-lesson notation course**. The approved
  transformation is planned and partially implemented.
- The local opt-in retention log exists and records `app_open`,
  `onboarding_start`, `onboarding_complete`, `first_note`, `first_phrase`,
  `first_recording`, `session_start`, `session_complete`, `daily_active`, and
  `reminder_opt_in`. It is diagnostic only and not part of the progress backup.
- The phrase prompt and player exist, but `phraseLoopEnabled` is false, the
  scored screen has no main-navigation entry, and **no microphone-accuracy
  claim is validated**. The phrase path cannot supply KC-01/KC-02 evidence.
- The recordings screen exists: bounded local WAV takes, local playback,
  delete/clear, export, an in-memory A/B comparison, and a private before/after
  PNG card. `first_recording` is wired from the real save path. This makes KC-04
  and KC-12 measurable once a beta runs; it is not evidence that users record.
- The guided first session after onboarding is practice-only and writes no
  scored progress. It is not a beta.
- There is no paywall, subscription, store product, piece library, etude
  library, or pre-sale page, so KC-05, KC-07, KC-08, and KC-11 have no data
  source in the current build.

**What would produce the missing values:** the Phase 0 assessment spike (KC-01,
KC-02), the T1.8/T6.1 pre-sale (KC-05), the T5.7 hand-recruited beta with real
sessions and recordings (KC-03, KC-04, KC-06, KC-09, KC-10, KC-12), the T6.4/T6.8
paywall and store ledger (KC-07, KC-11), and the T3.9 content release log
(KC-08). Each needs a date, a denominator, and a link before it can change a
status.

## 8. Open questions and conflicts

Do not resolve these silently. The manager records the answer in [T9.2] before
the first gate that depends on it.

1. **D30 band.** The plan's kill is D30 <8% after 3 months (§12.4); the T9.9
   gate is D30 ≥10%. The dashboard encodes 8% to <10% as the warning band. T9.2
   must confirm that the plan's 8% is a stop line and the T9.9 10% is the gate,
   not two competing targets.
2. **Free→Pro band.** The plan's kill is Free→Pro <1.5% after 3 months (§12.4);
   the T9.9 gate is ≥2% by day 30. The dashboard encodes 1.5% to <2% as the
   warning band. Same confirmation needed.
3. **False pass is not in T9.9.** T9.9 lists only "False fail ≤10%"; the plan and
   the manager's table also lock false pass at ≤5%. The dashboard keeps KC-02 as
   a locked criterion. T9.9's omission is recorded here; it is not a reason to
   drop the false-pass guardrail.
4. **Session-2 definition.** The plan says "<35% return for session 2 within
   48 h" but does not define a session boundary. The dashboard proposes a
   60-minute gap after `session_complete` (KC-03). T9.2 must confirm or replace
   it before the first measurement; changing it later would move the metric.
5. **3+ sessions/week window.** "≥3 sessions/week for 4 weeks" is read here as
   ≥3 sessions in **each of four consecutive weeks**. If the intent is a 4-week
   rolling average or at least one qualifying week, T9.2 must define it before
   Phase 1. The reading changes the gate materially.
6. **D7/D30 day rule.** The local log uses local calendar day N after install
   (`retainedOnDay`). The beta report must use the same rule or state the
   difference. A rolling 24-hour definition would produce different numbers and
   cannot be swapped in after the first report.
7. **Content-cadence window.** The locked kill is <1 new piece/month; the T3.9
   trigger 4 response uses two consecutive months below one piece/month. T9.2
   must say whether the dashboard kill fires on the first month or after two.
8. **Pre-sale email capture.** Plan §11.5 includes email capture ≥10% in the
   Phase 0 pre-sale gate, but the locked threshold table has no kill line for
   it. The dashboard reports it beside KC-05; T9.2 must say whether it is a gate
   condition or report-only.
9. **Report-only targets.** D1 (35–40%), first note <60 s (60%), first phrase
   <3 min (50%), and NPS (20–30 early) are plan targets with no kill or gate
   row in the locked table. The dashboard does not invent one. Report them in
   the review note as context only.

---

## Page history

| Date | Change | Ticket |
|---|---|---|
| 2026-11-07 | Created the baseline: twelve criteria, locked thresholds, measurement notes, review protocol, change control, and open questions. All values `INSUFFICIENT DATA`. | [T9.4] |

[T1.6]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/aa34cfe5-eede-405a-be53-07fab816d32f
[T1.7]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/b18f6b44-da9b-4fc0-990c-21f3e681d84a
[T1.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/b1220c5a-dc70-4fac-913d-9b7ab08e8d99
[T3.9]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/a8fef7ce-bf3e-49cd-ab49-1189ddda454f
[T5.7]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/e41c7cb2-918d-41bf-afc4-b97d7e7005cb
[T6.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6b04a9be-cbe4-40bf-9f68-9573adf30218
[T6.4]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/ec0552b9-bccc-4c33-aa5b-b9f8a9804bef
[T6.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/341fcb3d-f496-4ec0-a45f-ea59d612f886
[T9.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/694298da-0c68-4ae6-a03a-e349cb125176
[T9.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/5b34fd51-46d1-4121-b029-5560688ff9b7
[T9.4]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/533d68cf-06b0-451d-8f54-bfa1ce6825c4
[T9.9]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/a74b28eb-9528-481a-8baf-950414b16660
