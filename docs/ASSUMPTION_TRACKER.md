# Assumption tracker

**Status:** Living document. Every row starts `untested`; the current state is
in [§12](#12-current-status). Do not read a plan target as a measured result.
**Ticket:** [T9.5] / HEARM-100.
**Owner:** Human owner for evidence, manager for Plane state, engineering for
this file and its relative-link check.
**Last updated:** 2026-11-06.
**Source of truth:** Plane. The approved plan is
[`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md); the live
decision and risk registers are [T9.2] and [T9.1].

> **Read this first.** The two cheapest tests that can stop the plan are the
> demand test (A-001–A-004) and the phrase-assessment test (A-005–A-006). Run
> them before content, paywall, or growth spend. The corpus and the
> teacher/legal evidence are human-owned: an agent may prepare the protocol, the
> analysis, or the draft, but cannot produce or claim the evidence.

The app in this repository is still the 240-lesson notation course. The phrase
prompt and player exist behind `phraseLoopEnabled` ([T2.5]), but the loop has no
main-navigation entry and no microphone-accuracy claim is validated. A code
merge, a passing test suite, or a document in this repository is not evidence
for any row here.

---

## 1. How to use this tracker

This tracker lists the beliefs the approved plan depends on. Each row has one
statement, one category, one testable next step, and one decision it can
invalidate. It is not a second plan and it does not replace Plane. The plan owns
the targets; Plane owns the live status; this file owns the assumption index and
the experiment log.

The numbers in the statements are the plan's targets or gates, not measured
results. They are written down so a test can pass or fail against a
pre-registered rule. The cost/time column is a planning estimate for comparing
tests, not a quote; when the plan gives a budget, the row cites it.

A test may use a landing page, a clickable prototype, a spreadsheet, a memo, the
existing beta build, or a corpus session. It must not add a product feature or a
network path to the app.

### 1.1 Fields

| Field | Rule |
|---|---|
| **ID** | Stable `A-001` style. Never reuse an ID for a different statement. If a statement changes materially, add a new ID and link the replacement from the old row. |
| **Statement** | One testable sentence with the target population and the threshold or claim. |
| **Category** | Demand, Price, Mic accuracy, Content cost, Retention, Teacher willingness, or Legal status. |
| **Confidence** | `Low`, `Medium`, or `High`. A judgment, not a metric. See [§1.2](#12-confidence-is-a-judgment-not-a-metric). |
| **Evidence** | A link to a dated artifact, or `None yet`. Never a claim. See [§1.4](#14-what-counts-as-evidence). |
| **Cheapest next test** | The smallest test that could change the decision. Concrete: an interview script, a prototype, a corpus session, a pre-sale page, a teacher call, a legal memo, a beta cohort. |
| **Cost / time** | Planning estimate in cash and elapsed time, with the plan budget cited where one exists. Replace it with actuals in the log after the test. |
| **Owner** | The role that can produce the evidence. Human-owned rows say so. |
| **Status** | `untested`, `testing`, `supported`, `weakened`, or `rejected`. See [§1.3](#13-status-vocabulary). |
| **Last updated** | ISO date of the last change to that row. |
| **Decision affected** | The plan section, ticket, decision record, or gate the assumption can invalidate. |

### 1.2 Confidence is a judgment, not a metric

Confidence is a reviewer's judgment about how much trustworthy evidence supports
the statement. It is not a probability, a score, a percentage, or a KPI. Do not
average it, add rows together, or convert it to a number. Two reviewers can
disagree; record the reason in the evidence cell and the experiment log.

| Level | Meaning |
|---|---|
| **Low** | No direct evidence, or only a plan target, a code merge, a synthetic fixture, or an unverified anecdote. This is the starting value for every row in this file. |
| **Medium** | At least one dated, relevant artifact supports the statement, the sample is named, and a reviewer has checked it. Generalization is still limited. |
| **High** | More than one independent, dated artifact supports the statement in the target population, with no contradicting evidence of the same strength. |

A single interview, a merged pull request, a green unit test, a plan quote, or a
ticket marked Done does not move a row to Medium. Confidence can go down when a
test weakens the statement; that is a useful result, not a failure of the
tracker.

### 1.3 Status vocabulary

| Status | Meaning | Allowed when |
|---|---|---|
| `untested` | No dated evidence exists. | Default. Also after an inconclusive run that produced no usable evidence. |
| `testing` | A named test is running and has a start date and an owner. | A test card exists and the artifact location is named. |
| `supported` | The pre-registered gate was met on a named sample. | The result is in the experiment log with a link to the artifact. State the sample and the scope. |
| `weakened` | The evidence points against the statement, but the rejection rule was not met, or the sample is small. | The log records the result and why it is not a rejection. |
| `rejected` | The pre-registered rejection rule was met. | The log records the result and the decision it forces. |

Do not use `testing` to mean "we believe this". Do not use `supported` on the
strength of code, a merge, a plan, or an internal document.

### 1.4 What counts as evidence

| Valid evidence | Not evidence |
|---|---|
| A pre-sale dashboard export with cells, visitors, orders, and dates | This tracker, the plan, or a ticket description |
| A signed teacher LOI, with the scope and date | "Teachers liked it" |
| A dated counsel memo, naming the assumptions and the review scope | A generic "public domain" label or a `license` string |
| A corpus manifest, label files, validator output, and a metrics report | A synthetic fixture or a passing unit test |
| A supplier invoice and a time log for one piece | "The content calendar says $1,000" |
| A beta cohort report with a denominator and a date | An opt-in retention log presented as the product's retention rate |
| Dated interview notes or a consented recording | An agent's summary of an interview that did not happen |

The evidence cell must link to something a reviewer can open. If the artifact
cannot be shared, link the protocol and the aggregated table, and say why. A
link to a plan, ticket, or pull request is the test plan or the implementation,
not evidence of the assumption.

### 1.5 Update protocol after each experiment

1. **Before the test.** Write a test card (template in [§10.2](#102-test-card-template))
   with the pre-registered pass gate and rejection rule. Add or confirm the row's
   `testing` status, owner, and start date.
2. **Run the test.** Keep the raw artifact: dashboard export, memo, corpus
   manifest and labels, invoice and time log, beta report, or dated notes.
   Recordings stay local and are never uploaded; follow
   [`CORPUS_CONSENT.md`](CORPUS_CONSENT.md) and
   [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md).
3. **Append one row to the experiment log** ([§10.1](#101-log-format)). Do not
   rewrite an old row; to correct one, append a new row that supersedes it and
   links the old row.
4. **Update the assumption row.** Change only the evidence link, confidence,
   status, and last-updated date that the result supports. Keep the statement
   stable. If the statement must change materially, add a new ID.
5. **Record the decision.** If the result changes a decision or a risk, send the
   exact [T9.2] or [T9.1] entry to the manager. If it changes a phase gate,
   update [T9.8]. This tracker does not own those registers.
6. **Do not overclaim.** A small sample can inform a decision; it cannot prove a
   market. A plan target is not a result. A merge is not a result.
7. **Leave inconclusive runs visible.** Record the method and the reason it was
   inconclusive. Leave the status `untested` unless a named test is still running.

---

## 2. Weakest first: demand and phrase assessment

**First test: A-001–A-004 (demand). Second test: A-005–A-006 (phrase
assessment).** No content, paywall, or growth work should consume the validation
budget before these produce evidence.

### 2.1 Why demand is first

Demand is the first business assumption: no amount of engineering repairs a
market that will not practice or pay. The base case needs 3% install-to-paid
conversion, 50% annual renewal, and 625 / 1,667 / 3,333 installs per month in
Years 1–3 ([`FINANCIAL_MODEL.md`](FINANCIAL_MODEL.md) and plan §11.3). The demand
part of the Phase 0 gate is deliberately cheap: a three-cell pre-sale and a
12-person concierge (plan §11.5). If the best cell is below 1.5% or the pre-sale
has fewer than 15 pre-orders, demand is not proven (plan §12.4); the correct
response is to stop or narrow the product, not to build more features.

### 2.2 Why phrase assessment is second

Phrase assessment is the hard product gate ([T1.7]). The contract is per-phrase
false pass ≤5%, false fail ≤10%, per-note recall ≥99%, per-note precision ≥95%,
and the rest of plan §4.5. If the corpus misses it, the phrase loop does not
ship; the plan pivots to call-and-response, single-bar assessment, or the
notation trainer (plan §4.5; [decision 0001](decisions/0001-conditional-go.md)).
A synthetic test suite proves the code path, not real microphone accuracy.
[Decision 0001](decisions/0001-conditional-go.md) allows Phase 1 engineering in
parallel, but the phrase loop stays behind `phraseLoopEnabled` and no document,
ticket, or UI may claim validated mic accuracy. The corpus and the `T1.7`
decision are human-owned.

### 2.3 The first-test summary

| Order | Assumptions | Cheapest test | Pass gate | Kill / stop rule |
|---:|---|---|---|---|
| 1 | A-001–A-004 (demand) | 5-user interviews, 12-person concierge, three-cell pre-sale | 60% do 3+ concierge sessions/week; 50% would pay $8/month; 30+ pre-orders across cells or ≥3% in the best cell; email capture ≥10% (plan §11.5) | Best-cell <1.5% or <15 pre-orders (plan §12.4); the later retention kills are tracked under A-013–A-016 |
| 2 | A-005–A-006 (phrase assessment) | Corpus + latency/bleed rig | False pass ≤5%, false fail ≤10%, per-note recall ≥99%, per-note precision ≥95%; offset ≤10 ms, drift ≤20 ms/60 s, bleed gate (plan §4.5) | False fail >10% or false pass >5% → stop mic-first (plan §12.4); clock/bleed failure → headphones, notes-only, or drop the in-time claim (plan §4.4) |

### 2.4 Test card D-01: demand, interview, concierge, pre-sale

**Assumptions:** A-001, A-002, A-004, A-007, A-009.

**Question.** Do target beginners and returners describe a 5-minute,
notation-first practice as the thing they want; do they use it for four weeks;
and will they pay?

**Pre-registered pass.** The first item is a proposed qualitative gate for this
test, not a plan threshold; the concierge and pre-sale items are the plan gates.
- At least 3 of 5 interviewees choose the notation-first concept for the same
  job and describe a 5-minute session as plausible.
- Concierge: 60% complete 3+ sessions/week for four weeks; 50% say they would pay
  $8/month (plan §11.5).
- Pre-sale: 30+ pre-orders across cells, or ≥3% in the best cell; email capture
  ≥10% (plan §11.5).

**Pre-registered kill.** Best-cell pre-sale <1.5% or <15 pre-orders (plan
§12.4). After the concierge or the later beta, the plan's retention kills also
apply: <35% return for session 2 within 48 hours; <25% record by day 7. Do not
call demand proven on a 5-user sample.

**Interview script.**
1. "Tell me about the last time you tried to learn or return to guitar. What did
   you use? What stopped you?"
2. "How do you read music on guitar today? What is hard about it?"
3. "If you had five minutes today, what would you practice? Why?"
4. Show three one-page concepts: (a) notation-first real-music practice,
   (b) tab/song-first, (c) gamified drill. "Which would you try tonight? Which
   would you pay for? What would you expect it to do in five minutes?"
5. "What would make you stop after one session? What would bring you back
   tomorrow?"
6. "Would ads change your decision? Would you pay to remove them?"
7. "What would you pay per month or per year for the one you chose? Why?"

Do not lead with price; ask after the concept choice. Do not record audio
without consent. Do not promise a ship date.

**Sample.** 5 interview participants plus 12 adult returners for the concierge,
recruited outside the builder's immediate circle, screened for a guitar in hand
and intent to practice. Report the recruitment source and the number who
declined.

**Cost / time.** Interviews: 3–5 days, small incentive (planning estimate).
Concierge: four weeks and $25 × 12 = $300 (plan §11.5). Pre-sale: 2–3 weeks and
3,000 targeted visitors (plan §11.5). Use a share of the plan's $5–8k validation
budget.

**Owner.** Human owner. The manager schedules; an agent may draft the script and
the landing-page copy but must not run the sessions or report invented answers.

**Artifact.** Dated interview notes (no names), the concierge session log, and
the pre-sale dashboard export.

**Decision.** Pass → proceed to the remaining demand and price assumptions.
Fail → fix the message or loop, or stop before content spend; record [T9.2].

### 2.5 Test card P-01: phrase assessment, corpus and clock

**Assumptions:** A-005, A-006.

**Question.** Does the phrase scorer meet the assessment contract on real guitar
takes across devices and conditions, and is the clock usable?

**Pre-registered pass (plan §4.5).**
- Per-phrase false pass ≤5%; false fail ≤10%.
- Per-note recall ≥99%; precision ≥95%; per-string recall ≥90%; octave-error
  rate ≤2%; onset MAE ≤40 ms.
- Expert ICC(2,k) ≥0.75 and pass/fail kappa ≥0.70; 95% confidence intervals;
  results stratified by 4/8/16-note phrases and user segment; held-out split by
  player and piece.
- Corpus: 6–10 players; 4 devices; 3 conditions; ≥240 takes, ≥20 per
  device/condition cell; 4–8 and 16-note phrases at 60–90 BPM.
- Clock: offset ≤10 ms; drift ≤20 ms/60 s; bleed note-recall drop ≤5%; false
  onsets ≤1/minute (plan §4.4; [`LATENCY_RIG.md`](LATENCY_RIG.md#decision-gates)).

**Pre-registered kill.** False fail >10% or false pass >5% in the spike → stop
mic-first (plan §12.4); do not build the phrase loop. If the clock or bleed gate
fails, headphones are mandatory, or score notes only and drop the "in time"
claim (plan §4.4). Do not average a failing device into a passing result.

**Method.** Follow [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md) for consent,
recording, naming, labeling, and second-labeling. Use the latency/bleed rig
before scoring timing. Compute the metrics from labeled takes with 95% CIs; do
not use synthetic fixtures as accuracy evidence. Report every exclusion and the
indeterminate rate.

**Sample.** 6–10 players; mid-range Android, iPhone, tablet, and laptop/web;
quiet, room-noise, and click/drone conditions; ≥240 takes, ≥20 per cell; 4–8 and
16-note phrases at 60–90 BPM; nylon and steel strings; open and fretted notes.

**Cost / time.** Three weeks with a dedicated DSP engineer, five weeks otherwise;
$1–2k corpus/device budget (plan §4.5 and §11.5).

**Owner.** Human owner for recruitment, recording, labels, and the `T1.7`
decision. Engineering prepares the rig and the analysis.

**Artifact.** Corpus manifest, label files, validator output, metrics report,
and latency-rig JSON.

**Decision.** Pass → `T1.7` go; the owner may enable the phrase loop. Fail →
`T1.7` no-go; disable the loop, name the fallback, and record [T9.2].

---

## 3. Demand (A-001–A-004) — test first

| ID | Category | Assumption | Confidence | Evidence | Cheapest next test | Cost / time | Owner | Status | Updated | Decision affected |
|---|---|---|---|---|---|---|---|---|---|---|
| A-001 | Demand | Beginner and returning adult guitarists will practice for 5 minutes on 3+ sessions per week: 60% of a concierge cohort ($25 participant fee) and ≥30% of Phase 1 actives over four weeks. | Low | None yet | Concierge (12 adult returners, four weeks, 5 min/day, weekly Zoom) plus the 5-user interviews in [§2.4](#24-test-card-d-01-demand-interview-concierge-pre-sale); gate 60% do 3+ sessions/week (plan §11.5). The Phase 1 pilot ([T5.7]) confirms the ≥30% active figure. | Four weeks; $25 × 12 = $300 participant fee; interviews 3–5 days (plan §11.5). | Human owner | untested | 2026-11-06 | [§5](TRANSFORMATION_PLAN_FINAL.md#5-session-design), [§11.5](TRANSFORMATION_PLAN_FINAL.md#115-validation-before-build), [§13](TRANSFORMATION_PLAN_FINAL.md#13-roadmap), [T1.9], [T5.7] |
| A-002 | Demand | The wedge is sight-reading and playing real music: the target chooses a notation-first practice app over a song-first or drill-first app for the same five-minute job. | Low | None yet | 5-user interview with three one-page concepts (notation-first, song-first, drill-first); ask which they would try tonight and pay for. Directional only; the pre-sale is the quantitative test. | 3–5 days; 5 users; small incentive (planning estimate). | Human owner | untested | 2026-11-06 | [§2.2](TRANSFORMATION_PLAN_FINAL.md#22-positioning), [§2.3](TRANSFORMATION_PLAN_FINAL.md#23-why-this-wedge), [T1.8], [T1.9] |
| A-003 | Demand | Organic acquisition (SEO/content, the free web sight-reading test, communities, ASO) can produce the install volume the base case needs without paid user acquisition. | Low | None yet | Free web sight-reading test ([T8.1]) plus 2–3 SEO pages; measure four weeks of visits, email capture, and sharing. The plan's ≥10% email-capture gate belongs to the pre-sale (plan §11.5); use it here only as an adapted leading indicator, and do not infer the Year 1 install rate from four weeks. | 4–6 weeks; landing page + 2–3 articles; share of the plan's $5–8k validation budget. | Human owner | untested | 2026-11-06 | [§11.3](TRANSFORMATION_PLAN_FINAL.md#11-business-model), [§11.4](TRANSFORMATION_PLAN_FINAL.md#114-acquisition), [T6.2], [T8.1] |
| A-004 | Demand | The beachhead (consumer classical/folk returners) is large enough to support the base-case install and subscriber counts. | Low | None yet | Use the pre-sale and web-test funnel as the first proxy: 3,000 targeted visitors, 1,000 per price cell; gate 30+ pre-orders or ≥3% in the best cell. Compare the observed channel mix with the plan's 625 / 1,667 / 3,333 installs per month; one test cannot prove market size. | 2–3 weeks; 3,000 targeted visitors; share of the validation budget. | Human owner | untested | 2026-11-06 | [§11.3](TRANSFORMATION_PLAN_FINAL.md#11-business-model), [§14](TRANSFORMATION_PLAN_FINAL.md#14-risks-and-mitigations), [T6.2] |

The store listing, keyword, screenshot, and launch sequencing are specified in
[`ASO_PLAN.md`](ASO_PLAN.md). The screenshot test is `Not run`; it does not move
A-003 until real install, conversion, and retention data exist. No paid installs
are allowed before organic or teacher traction (see the ASO plan, section 5).

---

## 4. Mic accuracy / phrase assessment (A-005–A-006) — test first

| ID | Category | Assumption | Confidence | Evidence | Cheapest next test | Cost / time | Owner | Status | Updated | Decision affected |
|---|---|---|---|---|---|---|---|---|---|---|
| A-005 | Mic accuracy | Phrase-level scoring meets the assessment contract on real takes: false pass ≤5%, false fail ≤10%, per-note recall ≥99%, per-note precision ≥95%, and the rest of plan §4.5. | Low | None yet | [T1.6] corpus: 6–10 players, 4 devices, 3 conditions, ≥240 takes, ≥20 per cell, 4–8 and 16-note phrases at 60–90 BPM; label, second-label, compute metrics with 95% CIs; follow [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md). The [T2.5] screen and synthetic tests are code, not evidence. | Three weeks with a DSP engineer, five weeks otherwise; $1–2k (plan §4.5 and §11.5). | Human owner (recruitment, recording, labels, [T1.7]); engineering analysis | untested | 2026-11-06 | [§4](TRANSFORMATION_PLAN_FINAL.md#4-assessment-contract), [T1.6], [T1.7], [decision 0001](decisions/0001-conditional-go.md) |
| A-006 | Mic accuracy | A headphones + shared-sample-clock setup keeps timing usable: output offset ≤10 ms, drift ≤20 ms/60 s, and the bleed gate (note-recall drop ≤5%, false onsets ≤1/min) passes. | Low | None yet | [T1.4] latency/bleed rig on Android, iOS, tablet, and laptop/web; loopback calibration plus speaker click/drone vs headphones. If the gate fails, test the click-in-recording alternative or drop the in-time claim. | Inside the three-week spike; no extra cash beyond the corpus/device budget. | Human owner (hardware runs); engineering | untested | 2026-11-06 | [§4.4](TRANSFORMATION_PLAN_FINAL.md#44-latency-clock-and-bleed), [T1.4], [`LATENCY_RIG.md`](LATENCY_RIG.md#decision-gates), [decision 0001](decisions/0001-conditional-go.md) |

A timing failure does not always kill the phrase loop. It can force headphones,
notes-only scoring, or dropping the "in time" claim (plan §4.4). A phrase-scoring
failure is the V1 kill: stop mic-first and name the smaller fallback.

---

## 5. Price (A-007–A-009)

| ID | Category | Assumption | Confidence | Evidence | Cheapest next test | Cost / time | Owner | Status | Updated | Decision affected |
|---|---|---|---|---|---|---|---|---|---|---|
| A-007 | Price | The target will pay $8.99/month or $69/year for Pro; $69/year is the preferred annual price. | Low | None yet | [T1.8] three-cell pre-sale at $49/$69/$99 annual founding; 1,000 targeted visitors per cell; gate 30+ pre-orders across cells or ≥3% in the best cell; email capture ≥10% (plan §11.5). | 2–3 weeks; 3,000 targeted visitors; share of the $5–8k validation budget. | Human owner | untested | 2026-11-06 | [§11.1](TRANSFORMATION_PLAN_FINAL.md#111-pricing), [§11.5](TRANSFORMATION_PLAN_FINAL.md#115-validation-before-build), [T1.8], [T6.1], [T6.8] |
| A-008 | Price | The free tier is a demo that converts to Pro at 2–3% by day 30 without blocking the first session. | Low | None yet | Concierge exit question after four weeks: "Would you pay $8/month for this?" Gate 50% yes (plan §11.5). Then the [T6.4] paywall measures real free-to-Pro; the concierge answer is a leading indicator, not conversion. | Four weeks; piggyback on the concierge; no extra cash. | Human owner | untested | 2026-11-06 | [§11.2](TRANSFORMATION_PLAN_FINAL.md#112-paywall-timing), [§12.2](TRANSFORMATION_PLAN_FINAL.md#122-targets-category-benchmarks), [T1.9], [T6.4], [T6.8] |
| A-009 | Price | The product can be sold without ads and without ad revenue; the target prefers a paid, no-ads product to a free ad-supported one. | Low | None yet | Add to the 5-user interview and the concierge exit survey: what they would trade for no ads, and whether ads would stop them using it. Test the no-ads promise on the pre-sale page. | Piggyback on A-001/A-002 and the concierge; no extra cash. | Human owner | untested | 2026-11-06 | [§11.1](TRANSFORMATION_PLAN_FINAL.md#111-pricing), [§15](TRANSFORMATION_PLAN_FINAL.md#15-what-not-to-do), [T1.9] |

The $49/$99 pre-sale cells bracket the $69 annual price; they do not test the
monthly price. The concierge asks the $8/month willingness question. Ads stay
out of V1 regardless; a weak no-ads result changes price or cost, not the rule.

---

## 6. Content cost (A-010–A-012)

| ID | Category | Assumption | Confidence | Evidence | Cheapest next test | Cost / time | Owner | Status | Updated | Decision affected |
|---|---|---|---|---|---|---|---|---|---|---|
| A-010 | Content cost | A launch-quality piece costs $500–$1,500 and 8–16 production hours, including arrangement, notation/fingering, validation, QA, two reference takes, legal review, and release. | Low | None yet | Commission or produce one piece through the full [T3.8]/[T3.5] pipeline; time every task and record the invoice; compare with the range in [`CONTENT_CALENDAR.md` §4.1](CONTENT_CALENDAR.md#41-per-piece-cost-and-hours). | One piece; 2–3 weeks; cash = actual invoice (the test measures it; no result is pre-filled). | Human owner / content contractor | untested | 2026-11-06 | [§6.5](TRANSFORMATION_PLAN_FINAL.md#65-content-calendar), [`CONTENT_CALENDAR.md` §4.1](CONTENT_CALENDAR.md#41-per-piece-cost-and-hours), [T3.9], [T6.2] |
| A-011 | Content cost | The team can sustain the plan's 24-month piece cadence: 2 pieces/month in months 1–6, 3/month in months 7–12, 2/month in months 13–20, and 1/month in months 21–24, while also building the app. | Low | None yet | Run a four-week, two-piece production sprint with the chosen contractor, then the month-6 gate: count pieces shipped per month and contractor hours; gate ≥1 new piece/month and ≤80 content hours/month ([`CONTENT_CALENDAR.md` §6](CONTENT_CALENDAR.md#6-decision-gate-subscription-or-one-time-piece-packs), triggers 2 and 4). | Four weeks for the sprint; six months for the gate; cash per A-010. | Human owner | untested | 2026-11-06 | [§6.5](TRANSFORMATION_PLAN_FINAL.md#65-content-calendar), [§12.4](TRANSFORMATION_PLAN_FINAL.md#124-kill-criteria), [`CONTENT_CALENDAR.md` §6](CONTENT_CALENDAR.md#6-decision-gate-subscription-or-one-time-piece-packs), [T3.9] |
| A-012 | Content cost | Legal review, QA, and reference recording fit inside the per-piece cost and the monthly cadence, not as a separate bottleneck. | Low | None yet | In the one-piece test (A-010), route the piece through validator, [T3.8] QA, two [T3.5] reference takes, and [T6.3] legal review; record wait time and rework. Gate: legal clearance ≤30 days; QA rejection ≤20% ([`CONTENT_CALENDAR.md` §6.1](CONTENT_CALENDAR.md#61-measurable-triggers), triggers 5 and 6). | Same one-piece test; legal lead time 4–8 weeks for the first batch, 2–4 weeks later ([`CONTENT_CALENDAR.md` §7.4](CONTENT_CALENDAR.md#74-legal-review-lead-time-and-the-t63-dependency)). | Human owner / counsel | untested | 2026-11-06 | [§6.4](TRANSFORMATION_PLAN_FINAL.md#64-reference-recordings), [§11.6](TRANSFORMATION_PLAN_FINAL.md#116-funding-and-legal-gate), [T3.5], [T3.8], [T6.3] |

If a piece exceeds $1,500 or 16 hours for two consecutive months, freeze at two
pieces/month and re-quote ([T3.9] trigger 1). If fewer than one piece ships per
month for two consecutive months, the subscription promise is broken; switch to
one-time piece packs at $49–$79 (plan §6.5). A legal backlog is a hard stop, not
a reason to ship uncleared content.

---

## 7. Retention (A-013–A-016)

| ID | Category | Assumption | Confidence | Evidence | Cheapest next test | Cost / time | Owner | Status | Updated | Decision affected |
|---|---|---|---|---|---|---|---|---|---|---|
| A-013 | Retention | D7 retention is at least 18% for the hand-recruited beta cohort. | Low | None yet | [T5.7] 20-user beta, four weeks, 3+ sessions/week target; use the local opt-in log for the funnel and a follow-up survey for the cohort. Report the hand-recruited cohort separately from opt-in users ([`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md#bias-caveat)). | 4–6 weeks; 20 users; Phase 1 pilot budget. | Human owner | untested | 2026-11-06 | [§12.2](TRANSFORMATION_PLAN_FINAL.md#122-targets-category-benchmarks), [§13](TRANSFORMATION_PLAN_FINAL.md#13-roadmap), [T5.7], [T9.8] |
| A-014 | Retention | D30 retention is at least 10% for the beta cohort. | Low | None yet | Same 20-user beta with a day-30 follow-up; report D30 only when the window is complete. Do not infer D30 from D7. [T9.8] treats D30 as a Phase 2 gate. | 6–8 weeks; same cohort; no extra cash. | Human owner | untested | 2026-11-06 | [§12.2](TRANSFORMATION_PLAN_FINAL.md#122-targets-category-benchmarks), [§12.4](TRANSFORMATION_PLAN_FINAL.md#124-kill-criteria), [T5.7], [T9.8] |
| A-015 | Retention | 60% of new users reach their first note in under 60 seconds. | Low | None yet | 5-user moderated test of the onboarding prototype or the built [T5.1]/[T5.2] flow; start at install/open, stop at the first scored note; record seconds and hesitation points. The beta confirms with real new installs. | 3–5 days; 5 users; small incentive (planning estimate). | Human owner | untested | 2026-11-06 | [§5.4](TRANSFORMATION_PLAN_FINAL.md#54-onboarding-and-placement), [§12.2](TRANSFORMATION_PLAN_FINAL.md#122-targets-category-benchmarks), [T5.1], [T5.2], [T9.8] |
| A-016 | Retention | 50% of new users reach their first phrase in under three minutes. | Low | None yet | Same 5-user onboarding test; stop at the first phrase attempt; the beta confirms with the real phrase path ([T2.5]/[T2.6]). Do not claim the mic path works before [T1.7]. | Piggyback on A-015; no extra cash. | Human owner | untested | 2026-11-06 | [§5.4](TRANSFORMATION_PLAN_FINAL.md#54-onboarding-and-placement), [§12.2](TRANSFORMATION_PLAN_FINAL.md#122-targets-category-benchmarks), [T2.6], [T5.2], [T9.8] |

[T9.8] marks first note and first phrase as report-only Phase 1 targets, not
pass/fail gates. A miss is a loop signal, not a failed gate. D7 and D30 are
hard gates in [T9.8]; the opt-in log is diagnostic only and cannot replace the
hand-recruited cohort.

---

## 8. Teacher willingness (A-017–A-018)

| ID | Category | Assumption | Confidence | Evidence | Cheapest next test | Cost / time | Owner | Status | Updated | Decision affected |
|---|---|---|---|---|---|---|---|---|---|---|
| A-017 | Teacher willingness | After 10 interviews, 3 teachers will sign a non-binding LOI for a $19/month pilot with 20–30 students. | Low | None yet | [T7.1]: 10 structured teacher calls; ask about the current assignment/export workflow and willingness to pay; offer the LOI with the manual export scope (no dashboard, no cloud). Gate: 3 signed LOIs. A paid pilot is Phase 2 and needs the COPPA gate. | 2–3 weeks; 10 calls; no cash; LOIs are non-binding. | Human owner | untested | 2026-11-06 | [§11.3](TRANSFORMATION_PLAN_FINAL.md#11-business-model), [§11.5](TRANSFORMATION_PLAN_FINAL.md#115-validation-before-build), [T7.1], [T7.5] |
| A-018 | Teacher willingness | Teachers will accept the consent, deletion, and no-cloud workflow that the minors/guardian plan requires for a pilot. | Low | None yet | One or two teacher calls walking through the [T7.3] consent record, deletion rehearsal, and no-messaging rules; ask whether they would run it with a 20–30 student studio. This tests willingness, not legal sufficiency; counsel owns the gate. | One week; 1–2 calls; no cash. | Human owner | untested | 2026-11-06 | [§10.3](TRANSFORMATION_PLAN_FINAL.md#10-technical-plan), [T7.3], [`COPPA_GUARDIAN_CONSENT_PLAN.md` §7](COPPA_GUARDIAN_CONSENT_PLAN.md#7-legal-review-gate) |

Teacher and exam revenue is upside only, not the base case (plan §11.3). Failing
three LOIs removes the Phase 2 upside; it does not invalidate V1. The teacher
channel does not ship until the [T7.3] gates clear. An LOI is not consent
evidence.

---

## 9. Legal status (A-019–A-022)

| ID | Category | Assumption | Confidence | Evidence | Cheapest next test | Cost / time | Owner | Status | Updated | Decision affected |
|---|---|---|---|---|---|---|---|---|---|---|
| A-019 | Legal status | The 10 launch pieces and the 24-month content plan are public-domain or original in every launch territory, with new arrangements and no copied protected editions. | Low | None yet | [T6.3] counsel memo on the 10-piece launch list and source editions, per territory; use [`LAUNCH_PIECES.md`](LAUNCH_PIECES.md) open questions as the brief. Do not review the full 24-month calendar first. | 4–8 weeks for the first batch; $5–10k legal budget (plan §11.6; [`CONTENT_CALENDAR.md` §7.4](CONTENT_CALENDAR.md#74-legal-review-lead-time-and-the-t63-dependency)). | Human owner / counsel | untested | 2026-11-06 | [§11.6](TRANSFORMATION_PLAN_FINAL.md#116-funding-and-legal-gate), [T6.3], [T1.10], [`LAUNCH_PIECES.md`](LAUNCH_PIECES.md) |
| A-020 | Legal status | The COPPA/guardian consent plan is sufficient for a teacher pilot in the chosen territory, including verifiable consent and a tested deletion path. | Low | None yet | [T7.3] counsel review of the plan and one pilot territory; then the deletion rehearsal on iOS, Android, and web ([`COPPA_GUARDIAN_CONSENT_PLAN.md` §4.8](COPPA_GUARDIAN_CONSENT_PLAN.md#48-test-before-any-claim)). No pilot starts while any gate row is Open. | 4–8 weeks; part of the legal budget; deletion rehearsal 1–2 days. | Human owner / counsel | untested | 2026-11-06 | [§10.3](TRANSFORMATION_PLAN_FINAL.md#10-technical-plan), [§11.6](TRANSFORMATION_PLAN_FINAL.md#116-funding-and-legal-gate), [T7.3], [`COPPA_GUARDIAN_CONSENT_PLAN.md` §7](COPPA_GUARDIAN_CONSENT_PLAN.md#7-legal-review-gate) |
| A-021 | Legal status | Apple and Google store policies permit the planned subscription, local recording, and privacy copy without an account or cloud. | Low | None yet | [T6.3] consumer legal-review scope (plan §11.6: app-store subscription terms, recording consent, privacy policy) plus an engineering checklist against current App Store and Google Play rules; cite the policy sections and the date. This is a policy check, not legal advice. The [`COPPA_GUARDIAN_CONSENT_PLAN.md` §7.1 row 15](COPPA_GUARDIAN_CONSENT_PLAN.md#71-what-counsel-must-review) is a separate teacher-channel check and does not cover the consumer app. | 1–2 days; no cash. | Human owner / engineering | untested | 2026-11-06 | [§9](TRANSFORMATION_PLAN_FINAL.md#9-recording-and-privacy), [§11.6](TRANSFORMATION_PLAN_FINAL.md#116-funding-and-legal-gate), [T6.3], [T4.5] |
| A-022 | Legal status | V1 and the Phase 2 generic packs can use generic grade labels without any exam-board name, logo, or syllabus copy. | Low | None yet | Have counsel review the label list and the [T7.4] pack outline; keep board names out of the launch. If board names are required for demand, that is a licensing negotiation, not a cheap test. | 1–2 weeks; part of the legal budget; no pack build. | Human owner / counsel | untested | 2026-11-06 | [§11.1](TRANSFORMATION_PLAN_FINAL.md#111-pricing), [§16](TRANSFORMATION_PLAN_FINAL.md#16-open-decisions), [T7.4], [T7.6] |

A legal no-go can block a territory or the launch date even when demand and
phrase assessment pass. Do not ship on a `license` string, a generic "public
domain" label, or an agent's reading of a statute. The teacher channel has its
own gate and stays out of the base case.

---

## 10. Experiment log

### 10.1 Log format

The log is append-only. Add one row per experiment after the artifact exists.
Do not delete a row; to correct one, add a new row that supersedes it and links
the old row.

| Date | Assumption | Method | Sample | Result | Confidence change | Decision | Evidence link |
|---|---|---|---|---|---|---|---|
| _No experiment has run as of 2026-11-06._ | | | | | | | |

Rules:

- **Date** is the date the result was read, not the date the test was imagined.
- **Sample** states who and how many, and how they were recruited. A number
  without a denominator is not a result.
- **Result** is raw: counts, percentages with denominators, cost and hours,
  pass/fail per gate. "Worked well" is not a result.
- **Confidence change** is `Low → Low`, `Low → Medium`, `Medium → Weakened`, and
  so on. If the result does not change confidence, write `none`.
- **Decision** is `continue`, `iterate`, `stop`, or `pivot`, with the [T9.2]
  entry link when a decision changes.
- **Evidence link** points to the artifact, not to this tracker.

### 10.2 Test card template

Copy this block before a test and fill it in. A test without a pre-registered
gate is a conversation, not evidence.

```markdown
### Test card — A-xxx <short name>

- **Assumption:** A-xxx
- **Question:**
- **Pre-registered pass gate:**
- **Pre-registered kill / rejection rule:**
- **Method / script:**
- **Sample (n, who, recruitment):**
- **Cost / time:**
- **Owner / runner:**
- **Artifact location:**
- **Decision on pass / fail:**
```

### 10.3 Current log

The table in [§10.1](#101-log-format) is the whole log. It has no result rows
because no experiment has run. Do not add a row until the artifact exists and a
named person has read it.

---

## 11. Weakest assumptions and kill criteria

The live registers are Plane [T9.1] (risk), [T9.2] (decision), and [T9.8] (phase
gate). The plan's kill criteria are in
[`TRANSFORMATION_PLAN_FINAL.md` §12.4](TRANSFORMATION_PLAN_FINAL.md#124-kill-criteria).
The gate checklist is [`PHASE_GATES.md`](PHASE_GATES.md); its thresholds govern
a gate decision. This section is the index; it does not replace those sources. A
gate is not passed by a code merge, a green test suite, a plan quote, or an
agent's summary.

| Assumption | Failure signal / kill criterion | What it invalidates | Response |
|---|---|---|---|
| A-001–A-004 demand | Best-cell pre-sale <1.5% or <15 pre-orders (plan §12.4) | The consumer business and the base P&L. This is the V1 plan's demand premise. | Fix the message, the onboarding, or the loop; do not spend on content or growth. If the pre-sale kill fires, stop or narrow the product. |
| A-005–A-006 phrase assessment | False fail >10% or false pass >5% in the spike (plan §12.4) | The mic-first phrase loop and the assessment promise. It does not invalidate the notation trainer or a call-and-response fallback. | Stop mic-first; disable the loop; pivot to call-and-response, single-bar assessment, or the notation trainer ([decision 0001](decisions/0001-conditional-go.md)). |
| A-007–A-009 price | Free-to-Pro <1.5% after three months (plan §12.4) | The subscription model. The product can still exist at a different price or as piece packs. | Change price or paywall, or switch to one-time piece packs at $49–$79 (plan §6.5). |
| A-010–A-012 content cost | <1 new piece/month for two consecutive months; or >$1,500 / >16 h per piece for two consecutive months (plan §12.4; [T3.9] trigger 1) | The subscription supply promise. It does not invalidate the launch library. | Freeze cadence, re-quote or simplify, or switch to piece packs at $49–$79. |
| A-013–A-016 retention | D30 <8% after three months; D7 below 18% at the Phase 1 gate; <35% return for session 2 within 48 h; <25% record by day 7 (plan §12.4; [T9.8]) | The niche/positioning and the retention targets. The first-note/first-phrase targets are report-only, not pass/fail gates. | Fix onboarding, the first session, or the performance loop before scaling acquisition. |
| A-017–A-018 teacher willingness | Fewer than 3 LOIs after 10 interviews; teachers reject the consent workflow | The Phase 2 teacher/exam upside only. The base case is unchanged. | Keep the teacher channel out of the base case; revisit only with new evidence. |
| A-019–A-022 legal status | Counsel no-go; a store-policy conflict; a required board name; a piece or territory that is not clear | The affected channel, territory, piece, or launch date. A consumer legal no-go can block the V1 launch even if demand and phrase assessment pass. | Drop the piece, territory, or channel; do not ship uncleared content. Record the decision in [T9.2]. |

**What would invalidate the V1 plan.** The demand test (A-001–A-004) and the
phrase-assessment test (A-005–A-006) come first. A demand failure means there is
no business to build; a phrase failure means the mic-first product must become a
smaller fallback. The plan's later retention kills (A-013–A-016: D30 <8%, <35%
session-2 return, <25% record by day 7) can also invalidate the
niche/positioning after the loop exists. A legal no-go on the consumer launch
(A-019/A-021) can block the launch even when demand and phrase assessment pass.

**What would invalidate the subscription model.** A price/conversion failure
(A-007–A-009) or a content-supply failure (A-010–A-012). The fallback is
one-time piece packs at $49–$79, with the launch library and etudes as the
product (plan §6.5). The product can survive; the subscription promise cannot.

**What would invalidate the teacher channel.** A teacher-willingness failure
(A-017–A-018) or a COPPA/consent failure (A-020). The consumer base case is not
affected because teacher and exam revenue are upside only.

---

## 12. Current status

| Domain | Rows | Status | Evidence | Human-owned? | What moves it |
|---|---|---|---|---|---|
| Demand | A-001–A-004 | `untested` | None yet | Yes | 5-user interviews, 12-person concierge, three-cell pre-sale, free web test |
| Mic accuracy | A-005–A-006 | `untested` | None yet | Yes (corpus and hardware; engineering supports) | [T1.1]/[T1.4]/[T1.6] corpus and rig, then [T1.7] |
| Price | A-007–A-009 | `untested` | None yet | Yes | Pre-sale cells, concierge willingness question, later paywall experiment |
| Content cost | A-010–A-012 | `untested` | None yet | Yes (with a contractor) | One-piece production test, month-6 content gate |
| Retention | A-013–A-016 | `untested` | None yet | Yes | 5-user onboarding test, [T5.7] 20-user beta |
| Teacher willingness | A-017–A-018 | `untested` | None yet | Yes | [T7.1] teacher calls; [T7.3] consent walkthrough |
| Legal status | A-019–A-022 | `untested` | None yet | Yes (counsel) | [T6.3]/[T1.10]/[T7.3] memos and the store-policy checklist |

No row is `testing` or `supported`. No experiment log row exists. The confidence
is `Low` for every row because no direct evidence exists; a plan target, a code
merge, or a synthetic fixture is not evidence. Do not change a row to `supported`
because a pull request merged or a test suite passed.

**Human-owned work.** The corpus ([T1.1], [T1.6], [T1.7]), teacher willingness
([T7.1]), legal status ([T6.3], [T7.3], [T1.10]), demand and price
([T1.8], [T1.9], [T6.1]), the 20-user beta ([T5.7]), and the one-piece content
test need a named human session, a signed document, a supplier invoice, or a
business decision. An agent may prepare the protocol, the script, the landing
page copy, the analysis, or the draft memo. An agent must not record
participants, invent answers, sign a memo, or mark a human-owned ticket Done.

**What is not evidence.** The phrase screen and player ([T2.5]), the synthetic
corpus fixtures, a green unit test, a merged pull request, a document in this
repository, a ticket marked Done, or the local opt-in retention log presented as
the product's D1/D7/D30 rate. The opt-in log is diagnostic only; see
[`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md#bias-caveat) and
[decision 0006](decisions/0006-local-retention-instrumentation.md).

---

## 13. Links and change control

**Live sources.** [T9.5] (this ticket), [T9.1] (risk register), [T9.2] (decision
log), [T9.8] (phase-gate checklist). Plane wins if this file and Plane disagree;
correct this file and record the reason in [T9.2].

**Related documents.** [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md),
[`FINANCIAL_MODEL.md`](FINANCIAL_MODEL.md),
[`CONTENT_CALENDAR.md`](CONTENT_CALENDAR.md),
[`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md),
[`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md),
[`PHASE_GATES.md`](PHASE_GATES.md),
[`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md),
[`CORPUS_CONSENT.md`](CORPUS_CONSENT.md),
[`CORPUS_LABELING.md`](CORPUS_LABELING.md),
[`LATENCY_RIG.md`](LATENCY_RIG.md), and
[`LAUNCH_PIECES.md`](LAUNCH_PIECES.md).

**Change rules.**

- Keep the IDs stable. Add a new row for a materially different statement; do
  not reuse an old ID.
- Append to the experiment log; do not rewrite history. Correct an entry with a
  new row that links the old one.
- Do not copy a stale ticket list or a count into this file. Link Plane and the
  artifact. Counts and status change; the row's stable ID does not.
- Do not update a row from a merge, a plan quote, or an agent summary. The
  evidence cell must link to a dated artifact a reviewer can open.
- When a test changes a decision, send the exact [T9.2] entry to the manager and
  update the [T9.1] risk if the risk changed. This file does not edit Plane.
- When a phase gate changes, update [T9.8]. This file does not own the gate
  checklist.

**Change log.**

| Date | Change | Ticket |
|---|---|---|
| 2026-11-06 | Created the tracker with 22 untested assumptions, the demand and phrase first-test cards, and the empty experiment log. | [T9.5] / HEARM-100 |

---

[T1.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/89337a04-6de7-4ebc-b358-374b0e6addd4
[T1.4]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/17840c5e-c8fa-451e-abc9-ca343694980e
[T1.6]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/aa34cfe5-eede-405a-be53-07fab816d32f
[T1.7]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/b18f6b44-da9b-4fc0-990c-21f3e681d84a
[T1.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/b1220c5a-dc70-4fac-913d-9b7ab08e8d99
[T1.9]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/1d96beab-8dc4-490a-9d01-9f4fb80c748e
[T1.10]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/5ceef3fb-7a3f-4204-97eb-ef2eeef47365
[T2.5]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/cd0a96a8-c030-4ad1-bbb2-7834f7bfd256
[T2.6]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/08704d32-a7ef-4ff2-b7ee-1bc78599d3b6
[T3.5]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/9f648c7c-58ca-44c4-aea7-e049980771fa
[T3.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/2df35d39-ab9a-48a2-aaf4-b84d17d6cfe0
[T3.9]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/a8fef7ce-bf3e-49cd-ab49-1189ddda454f
[T4.5]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/099e3ba6-9810-43ad-8026-2c1ff8cc857f
[T5.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/09e19449-d873-443a-a1d9-2936650910b7
[T5.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/467b255a-10e1-460d-9c0c-8aa6946d2b2d
[T5.7]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/e41c7cb2-918d-41bf-afc4-b97d7e7005cb
[T6.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6b04a9be-cbe4-40bf-9f68-9573adf30218
[T6.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/9f35d8f8-5d33-4f88-ad04-a4d0c2f8b908
[T6.3]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/8ae3b050-4e45-491c-81b7-e949bbb56d66
[T6.4]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/ec0552b9-bccc-4c33-aa5b-b9f8a9804bef
[T6.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/341fcb3d-f496-4ec0-a45f-ea59d612f886
[T7.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6c27abcb-58a0-4990-b408-673424edf0e8
[T7.3]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/759fab60-28a4-4994-921c-d776cffac43a
[T7.4]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/5ff95969-7100-4955-b679-59b14fbeb829
[T7.5]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/99b52551-9412-4c72-b04c-ebc8855dfcdc
[T7.6]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/99daf74c-15d7-40a2-aaba-2946de05cdd0
[T8.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/7d2b9895-5375-4540-b63b-43c08197c358
[T9.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/694298da-0c68-4ae6-a03a-e349cb125176
[T9.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/5b34fd51-46d1-4121-b029-5560688ff9b7
[T9.5]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/a18e2eeb-b762-44cf-b3a1-8e792bcb3be3
[T9.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6f46f16c-bc01-4541-bbfa-cb7847d8a102
