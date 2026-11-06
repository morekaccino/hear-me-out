# Phase gates

**Status:** Active process checklist. Last updated 2026-11-06.
**Process owner:** The delivery manager. Each gate names a decision owner in its
record.
**Source of truth:** [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md)
sections 4.3, 4.5, 11.5, 11.6, 12.2, 12.4, and 13; the Plane work items linked
below. If this page and Plane disagree, Plane wins; correct this page and record
the reason in [T9.2].

This page is a checklist, not a second plan. The plan owns the full metric
tables. This page repeats only the thresholds a gate decision needs, links the
evidence, and records the decision.

## 1. How to use a gate

A phase gate is a decision about evidence. It is not a milestone, a release, or
a reward for shipping. Work in the next phase does not start until the gate
decision is recorded.

Every gate has five parts:

1. **A checklist** — the checks below, each with a metric, source, measured
   value, date, owner, and decision.
2. **Evidence links** — the report, dataset, query, or decision record that
   proves the measured value. The evidence must be dated and reproducible.
3. **An owner** — one named person who signs the decision. Evidence can have
   several owners; the gate decision has one.
4. **A decision** — pass, fail, or conditional, using the definitions below.
5. **A record** — an entry in [T9.2] with the decision, evidence links, and fail
   action. Update [T9.1] if the gate changes a risk.

**A gate is not passed by a code merge, a green test suite, a plan quote, or an
agent's summary.** Those can support evidence; they are not evidence of a user,
learning, demand, legal, or funding outcome.

### Decision definitions

| Decision | Meaning | What happens next |
|---|---|---|
| **Pass** | Every hard threshold is met with linked evidence, and no kill criterion is active. | Record in [T9.2]. The next phase may start. |
| **Fail** | Any hard threshold is missed, or a kill criterion fires. | Execute the gate's fail action. Do not start the next phase. Record in [T9.2]. |
| **Conditional** | Evidence is incomplete because the measurement window has not closed, or a named non-core item is short with a dated remediation. | Record the missing evidence, date, owner, and the work that stays locked. A conditional gate cannot override a measured failure. If the condition is not met by its date, it becomes a fail. |

**Conditional is not a soft pass.** It is for missing evidence, not bad
evidence. It cannot unlock irreversible work: a piano build, a paid teacher
launch, a public social surface, or a price change. Those need a pass.

### Gate review

1. The evidence owner fills the checklist and links the raw evidence.
2. The decision owner checks that each threshold is measured, not asserted.
3. The decision owner records pass, fail, or conditional in [T9.2].
4. If the decision is fail, the fail action starts before any new feature work.
5. The next gate review starts from the recorded decision, not from memory.

### Reopening a gate

Do not reopen a settled gate because a later metric looks better. Add a new
decision record in [T9.2] with the new evidence and say why the earlier decision
no longer holds. Do not rewrite the old record.

## 2. Gate summary

| Gate | Core question | Hard thresholds (short) | Fail action |
|---|---|---|---|
| Phase 0 | Is the phrase loop honest and the business viable? | T1.6 validity gates; T1.7 go; pre-sale 30+ or 3%; concierge 60%; legal go; funding decision | Disable the phrase loop; fall back or pivot; no features |
| Phase 1 | Does the loop activate and retain? | 20 users, 3x/week, 4 weeks; false fail ≤10%; D7 ≥18%; first note 60%, first phrase 50%, first recording 25%; launch inventory | Fix onboarding/first session/return trigger; no new content or surfaces |
| Phase 2 | Does it retain, convert, and pull teachers? | D30 ≥10%; free→Pro ≥2%; 3 paid teacher pilots; T3.9/T6.2 limits; COPPA plan | Piece packs or narrow scope; no social/AI/teacher dashboard |
| Phase 3 | Is expansion earned? | Guitar retention proof; 10k MAU + moderation/privacy for social; accounts/cloud conditions; separate piano spike | No expansion |

The full thresholds are in the phase sections. The plan owns the metric tables;
this table is only an index.

## 3. Checklist format

Copy this block for each check:

```markdown
- [ ] **P0.1 — Short name**
  - **Metric:** exact threshold and unit.
  - **Source:** evidence link and plan section.
  - **Measured:** value, sample size, and denominator.
  - **Date:** YYYY-MM-DD.
  - **Owner:** named person who produced the evidence.
  - **Decision:** pass / fail / conditional.
```

Copy this block for each gate:

```markdown
### Gate record — Phase N

- **Decision:** pass / fail / conditional
- **Date:** YYYY-MM-DD
- **Decision owner:** name
- **Evidence bundle:** links
- **Thresholds met:** list
- **Thresholds missed:** list
- **Conditional scope and expiry:** list, or "none"
- **Fail action taken:** list, or "none"
- **T9.2 entry:** link
- **T9.1 update:** link, or "no change"
```

Rules for filling it:

- Put a number and a denominator in **Measured**. "Good" and "improved" are not
  measurements.
- Link the raw report, not a summary of the report. If the raw data cannot be
  shared, link the protocol and the aggregated table.
- A blank **Measured** means the check is not done; it is not a pass.
- Use the same date format everywhere: `YYYY-MM-DD`.

## 4. Phase 0 — assessment spike and business viability

**Question:** Is the mic-first phrase loop honest enough to build, and is there
enough demand and a legal/funding path to justify Phase 1?

**Entry:** none.
**Decision owner:** founder/product owner.
**Plan sources:** section 4.3, 4.5, 11.5, 11.6, and 13.

### 4.1 Assessment spike (T1.6, T1.7)

- [ ] **P0.1 — Corpus coverage**
  - **Metric:** ≥240 real accepted takes; 6–10 players (beginner/returner); 4 devices (mid-range Android, iPhone, tablet, laptop/web); 3 conditions (quiet, room noise, click/drone); ≥20 takes per device/condition cell; 4–8-note phrases plus 16-note phrases; 60–90 BPM; actual piece phrases with slurs, ties, rests, shifts, nylon and steel strings, open and fretted notes.
  - **Source:** [T1.6], [CORPUS_PROTOCOL.md](CORPUS_PROTOCOL.md), [CORPUS_LABELING.md](CORPUS_LABELING.md), plan section 4.5.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P0.2 — Phrase and note validity**
  - **Metric:** per-phrase false pass ≤5%; false fail ≤10%; per-note recall ≥99%; per-note precision ≥95%; per-string recall ≥90% (E2/A2/D3/G3/B3/E4, open and fretted); octave-error rate ≤2%; expert ICC(2,k) ≥0.75 and pass/fail kappa ≥0.70; 95% confidence intervals; results stratified by 4/8/16-note phrases and user segment; held-out split by player and piece.
  - **Source:** [T1.6], plan sections 4.3 and 4.5.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P0.3 — Scoring rules are the contract**
  - **Metric:** indeterminate does not update FSRS, streaks, XP, or daily counters; unattempted notes are indeterminate, not wrong; extra notes are errors; >20% indeterminate makes the take incomplete; per-note confidence <0.6 is indeterminate; the same WAV produces the same score on Android, iOS, and web with no `DateTime.now()` or random seed in scoring.
  - **Source:** [T1.6], plan section 4.3, [`../LEARNING_ALGORITHM.md`](../LEARNING_ALGORITHM.md).
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P0.4 — Timing, latency, and bleed**
  - **Metric:** output-to-input offset ≤10 ms; clock drift ≤20 ms/60 s; onset MAE ≤40 ms; speaker/headphone bleed note-recall drop ≤5%; false onsets ≤1/min. If any timing gate fails, headphones are mandatory or timing is not scored.
  - **Source:** [T1.4], [LATENCY_RIG.md](LATENCY_RIG.md), plan sections 4.4 and 4.5.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P0.5 — Robustness, endpoints, and device performance**
  - **Metric:** tuning offsets 0/30/50 cents; >30 cents prompts tune/indeterminate, not "wrong"; artifacts (squeak, buzz, body thump, chair, breathing, speech, TV, clipping) false positive ≤5% and noise indeterminate ≥90%; endpoints (count-in, pickup, rest, early stop, one missed note, one extra note, false start) behave as specified; unattempted notes are not wrong; one 48 kHz-only Android case and one stereo case, pitch error <10 cents after resampling; 30 s analysis <2 s mid-range Android and <4 s mobile Safari; memory <100 MB; ≥50 fps; no ANR; 60 s WAV ≤6 MB; 20 takes ≤120 MB; delete/export works; no OOM.
  - **Source:** [T1.6], [LATENCY_RIG.md](LATENCY_RIG.md), plan section 4.5.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P0.6 — T1.7 go/no-go recorded**
  - **Metric:** a written go/no-go decision that cites the evidence for P0.1–P0.5. A conditional engineering start behind a feature switch (decision 0001) is not a pass. If no-go, the phrase loop is disabled and the fallback is named: single-bar assessment, call-and-response, or the notation trainer.
  - **Source:** [T1.7], [decisions/0001-conditional-go.md](decisions/0001-conditional-go.md), plan sections 4.5 and 10.1.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

### 4.2 Demand, legal, and funding (T1.8–T1.11)

- [ ] **P0.7 — Three-cell pre-sale**
  - **Metric:** three landing-page cells at $49/$69/$99 annual founding pre-order; 1,000 targeted visitors per cell (3,000 total); gate: 30+ pre-orders across cells OR ≥3% conversion in the best cell; email capture ≥10%. Kill: best-cell conversion <1.5% or <15 pre-orders means demand is not proven.
  - **Source:** [T1.8], [T6.1], plan sections 11.5 and 12.4.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P0.8 — Concierge program**
  - **Metric:** 12 adult returners; 4 weeks; 5 min/day; weekly Zoom; $25; gate: 60% do 3+ sessions/week; 50% would pay $8/month.
  - **Source:** [T1.9], plan sections 11.5 and 13.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P0.9 — Legal review and go/no-go**
  - **Metric:** written legal go/no-go covering public-domain status by territory, arrangement copyright, exam-board IP (no board names until licensed), pre-sale consumer terms, recording consent and privacy policy, and app-store subscription terms. Budget $5–10k. No launch with a blocking question unresolved.
  - **Source:** [T1.10], [T6.3], plan section 11.6.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P0.10 — Funding decision**
  - **Metric:** one-page bootstrap-vs-venture decision. Bootstrap: $250k ARR target, 24-month runway, ~$110–160k cash need. Venture: only with a credible piano/schools/exam path to $10M+ ARR. Use the reconciled T6.2 cash model: Year 1 ~$86,488; base peak ~$119,979 at month 24; downside ~$161,340 at month 36. Record bootstrap, venture, or an explicit pivot. If none, do not start Phase 1.
  - **Source:** [T1.11], [T6.6], [FINANCIAL_MODEL.md](FINANCIAL_MODEL.md), plan section 11.6.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P0.11 — Gate decision recorded**
  - **Metric:** [T9.2] entry with decision, date, owner, evidence links, thresholds met/missed, and fail action. Update [T9.1] if the gate changes a risk.
  - **Source:** [T9.2], [T9.1], [PLANE.md](PLANE.md).
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

### 4.3 Phase 0 gate record

Use the gate record block from section 3. The fail action is:

**Disable the phrase loop. Fall back to single-bar assessment, call-and-response,
or the notation trainer. Or pivot. Do not add features to rescue a failed
assessment gate.** Decision 0001 already requires the phrase loop to stay behind
a feature switch until T1.7 passes; a failed T1.7 keeps it off.

If the pre-sale fails, do not build Phase 1 to "see if it works." Narrow the
promise or stop. If the legal or funding decision is conditional, the condition
must have a date and a named owner, and Phase 1 work that depends on it stays
locked.

## 5. Phase 1 — product loop

**Question:** Does the core loop get a new user to a first note, a first phrase,
and a first recording, and bring them back for a second session and week 2?

**Entry:** Phase 0 decision recorded in [T9.2]. A pass unlocks Phase 1; a
conditional unlocks only the work named in the condition.
**Decision owner:** product/beta lead.
**Plan sources:** sections 12.2, 12.4, and 13.

- [ ] **P1.1 — Pilot cohort and duration**
  - **Metric:** 20 users; 4 weeks; 3 sessions/week target. Report the number recruited, the number still active in week 4, and the per-user session frequency. A dropout stays in the denominator.
  - **Source:** [T5.7], plan section 13.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P1.2 — Session frequency**
  - **Metric:** ≥3 sessions/week (the plan's Phase 1 gate). Report the share of users at ≥3 sessions/week and the median; do not hide users below target in an average.
  - **Source:** [T5.7], plan section 13.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P1.3 — Phrase accuracy in the pilot**
  - **Metric:** phrase-level false fail ≤10% (hard gate); false pass ≤5% (guardrail; plan kill criterion). Report the number of scored takes, the denominator, and the indeterminate rate. A take with >20% indeterminate notes is incomplete, not a pass or fail.
  - **Source:** [T5.7], [T1.6], plan sections 4.3 and 12.4.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P1.4 — D7 retention**
  - **Metric:** D7 ≥18% (plan target range 18–22%). State the day-7 definition and the denominator. Use the pilot cohort; report the opt-in log separately as diagnostic only.
  - **Source:** [T5.7], [RETENTION_INSTRUMENTATION.md](RETENTION_INSTRUMENTATION.md), plan sections 12.2 and 13.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P1.5 — First-session funnel**
  - **Metric:** first note <60 s for 60% of new users; first phrase <3 min for 50%; first recording by day 7 for 25%. Report each with its denominator. The first recording is the plan's section 12.2 target and a Phase 1 gate check in this ticket.
  - **Source:** [T5.2], [T5.7], [RETENTION_INSTRUMENTATION.md](RETENTION_INSTRUMENTATION.md), plan section 12.2.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P1.6 — Session-2 return**
  - **Metric:** ≥35% return for session 2 within 48 hours (plan section 12.4 kill criterion; T5.7 acceptance criterion). If below, fix onboarding/loop before adding content or surfaces.
  - **Source:** [T5.7], plan section 12.4.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P1.7 — Launch content inventory**
  - **Metric:** 10 pieces; 60 etudes; 20 human reference recordings (each launch piece at target and slow tempo); 10 technique checklists. Count from the content registry, not from a plan quote. A shortfall is allowed only if recorded in [T9.2] with a dated plan and a price/promise adjustment; do not claim a monthly cadence you cannot supply.
  - **Source:** [T3.9], [CONTENT_CALENDAR.md](CONTENT_CALENDAR.md), [LAUNCH_PIECES.md](LAUNCH_PIECES.md), plan sections 6.4 and 6.5.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P1.8 — Gate decision recorded**
  - **Metric:** [T9.2] entry with decision, date, owner, evidence links, thresholds met/missed, and fail action. Update [T9.1] if the gate changes a risk.
  - **Source:** [T9.2], [T9.1], [PLANE.md](PLANE.md).
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

### 5.1 Phase 1 gate record

Use the gate record block from section 3. The fail action is:

**Fix onboarding, the first session, and the return trigger before adding
content or surfaces.** A D7 or session-2 miss is a loop problem, not a
content-volume problem. If the launch inventory is short, record the shortfall
and adjust the promise; do not paper over it with more features.

## 6. Phase 2 — retention and teacher pull

**Question:** Does the loop retain past week 1, convert free users to paid, and
pull teachers into a paid pilot?

**Entry:** Phase 1 decision recorded in [T9.2]. A pass unlocks Phase 2; a
conditional unlocks only the work named in the condition.
**Decision owner:** product/growth lead.
**Plan sources:** sections 10.3, 11.2, 11.5, 12.2, 12.4, and 13.

- [ ] **P2.1 — D30 retention**
  - **Metric:** D30 ≥10% (plan target range 10–15%). State the cohort window, the day-30 definition, and the denominator. Use real cohort data, not the opt-in log alone.
  - **Source:** [T9.9], [RETENTION_INSTRUMENTATION.md](RETENTION_INSTRUMENTATION.md), plan sections 12.2 and 13.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P2.2 — Free-to-Pro conversion**
  - **Metric:** ≥2% by day 30 (plan target range 2–3%). Count paid conversions, not trial starts; report refunds separately. The paywall is after the first recording and the day-7 recap; do not gate the first recording or the first week.
  - **Source:** [T6.4], [T6.8], plan sections 11.2 and 12.2.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P2.3 — Three paid teacher pilots**
  - **Metric:** 3 teachers paying $19/month, each using the manual export flow with real students. The plan's LOI scope is 20–30 students per teacher; do not claim that scale until it happens. No persistent cloud; consent and deletion path documented.
  - **Source:** [T7.1], [T7.2], plan sections 10.3 and 11.5.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P2.4 — Content cadence**
  - **Metric:** at least 1 new piece shipped per month (plan section 12.4). No T3.9 production trigger fires for its stated window: piece cost >$1,500 or >16 hours (two consecutive months); capacity >80 hours/month (two consecutive months); calendar slip <1 piece/month (two consecutive months); legal backlog >30 days (two consecutive batches); QA rejection >20% (two consecutive months). Report pieces shipped, not planned.
  - **Source:** [T3.9], [CONTENT_CALENDAR.md](CONTENT_CALENDAR.md) section 6.1, plan section 12.4.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P2.5 — Content cost and cash**
  - **Metric:** actual content spend is within the T3.9 base ($103,214 launch + 24 months; Year 1 $69,024; Year 2 $34,190) or a recorded, approved variance. Subscriber coverage: trailing 3-month net revenue ≥ trailing 3-month content cost; below that for two consecutive quarters is a T3.9 switch-to-packs trigger. At month 24, Pro is ≥~615 annual-equivalent (or ~395 monthly); below that, T3.9 says switch to packs for year 3. If cost is at the T3.9 high case (~$155,328 launch + 24 months), re-run T6.2: the base peak cash need rises to ~$175,442 (T6.2 section 7.4), and the funding decision must be re-confirmed. The T6.2 base case must still show a fundable path: ~$119,979 peak at month 24; downside ~$161,340 at month 36.
  - **Source:** [T3.9], [T6.2], [CONTENT_CALENDAR.md](CONTENT_CALENDAR.md), [FINANCIAL_MODEL.md](FINANCIAL_MODEL.md).
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P2.6 — Legal and COPPA for the teacher path**
  - **Metric:** T7.3 COPPA/guardian consent plan complete and legally reviewed before any under-13 student participates; parental consent, data minimization, deletion, moderation; no public recital for minors; no persistent cloud in V1.
  - **Source:** [T7.3], plan sections 10.3 and 11.5.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P2.7 — Gate decision recorded**
  - **Metric:** [T9.2] entry with decision, date, owner, evidence links, thresholds met/missed, and fail action. Update [T9.1] if the gate changes a risk.
  - **Source:** [T9.2], [T9.1], [PLANE.md](PLANE.md).
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

### 6.1 Phase 2 gate record

Use the gate record block from section 3. The fail action is:

**Switch to one-time piece packs at $49–$79 or narrow the scope. Do not add
social, AI, or teacher-dashboard features to rescue a retention or conversion
miss.** If the teacher path fails, keep teacher revenue out of the base case
and fix the consumer loop first.

## 7. Phase 3 — expansion

**Question:** Is the guitar business durable enough to expand, and is each
expansion independently gated?

**Entry:** Phase 2 decision recorded in [T9.2]. A pass unlocks Phase 3; a
conditional unlocks only the work named in the condition.
**Decision owner:** founder/product owner.
**Plan sources:** sections 10.4, 10.5, 12.2, 12.4, and 13.

The plan's roadmap labels social/recital as Phase 4 (months 12+). This page
keeps the ticket's Phase 3 label for the whole expansion decision and separates
the sub-gates, so no expansion is bundled with retention proof.

- [ ] **P3.1 — Guitar retention proof**
  - **Metric:** the latest complete cohort meets D30 ≥10% and free-to-Pro ≥2%; no active kill criterion: session-2 <35%, D7 <18%, or content cadence <1 new piece/month. When the first annual cohort is measurable, annual renewal ≥45% (plan target 45–55%; T9.9). Report the cohort window, denominator, and the previous cohort for context; do not cherry-pick a single month.
  - **Source:** [T9.9], plan sections 12.2 and 12.4.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P3.2 — No piano before P3.1**
  - **Metric:** no piano code, content, or assessment work starts before P3.1 passes. Research is allowed; build is not. Any piano expansion needs its own assessment spike with the Phase 0 validity gates, because polyphonic assessment is a separate problem.
  - **Source:** plan sections 10.4 and 13.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P3.3 — Social/recital gate**
  - **Metric:** 10,000 MAU and a moderation/privacy plan before any social, recital, UGC, leaderboard, or marketplace surface. The plan puts this in Phase 4; do not pull it into Phase 3.
  - **Source:** plan sections 10.5 and 13.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P3.4 — Accounts/cloud gate**
  - **Metric:** accounts/cloud only if users ask and the privacy model is updated; a new decision record in [T9.2]; local-only remains the default; no account requirement for the core loop. Record the request source and count.
  - **Source:** plan section 10.4, [decisions/0002-backup-exclusion-no-opt-in.md](decisions/0002-backup-exclusion-no-opt-in.md), [decisions/0006-local-retention-instrumentation.md](decisions/0006-local-retention-instrumentation.md).
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P3.5 — AI feedback gate**
  - **Metric:** rule-based feedback proves learning gains and costs <$0.02/session before AI feedback. No AI in V1.
  - **Source:** plan sections 10.4 and 15.
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

- [ ] **P3.6 — Gate decision recorded**
  - **Metric:** [T9.2] entry with decision, date, owner, evidence links, thresholds met/missed, and fail action. Update [T9.1] if the gate changes a risk.
  - **Source:** [T9.2], [T9.1], [PLANE.md](PLANE.md).
  - **Measured:**
  - **Date:**
  - **Owner:**
  - **Decision:**

### 7.1 Phase 3 gate record

Use the gate record block from section 3. The fail action is:

**No expansion. Keep fixing the guitar loop.** A failed Phase 3 sub-gate stops
that expansion only; it does not authorize a different expansion.

## 8. Anti-patterns

- **Feature work to hit a metric.** If a gate fails, fix the loop or pivot.
  Adding a surface, a notification, a streak, or more content does not fix a
  retention or accuracy problem.
- **Invented metrics.** Do not substitute installs for MAU, trial starts for
  paid conversions, opt-in D7 for product D7, app accuracy for learning, or test
  count for evidence.
- **Passing a gate without evidence.** A merge, a green suite, a plan quote, a
  demo, or an agent summary is not a gate pass. The checklist needs measured
  values and links.
- **Reopening a settled gate without new evidence.** Add a new [T9.2] record; do
  not rewrite the old one.
- **"We'll fix it after launch."** A known gate failure does not become a launch
  task. It blocks the phase.
- **Moving the goalposts after seeing the data.** The thresholds are set before
  the measurement. Changing one needs a new decision record and a reason.
- **Silent scope expansion.** A new surface needs a new ticket, not a gate
  waiver.
- **Counting a conditional as a pass.** A conditional gate has a date and a
  locked scope. It does not unlock the next phase's irreversible work.
- **Shipping uncleared content to hit a cadence.** Legal and QA are hard stops.
  A cadence miss is recorded, not hidden.
- **Using the opt-in log as an unbiased baseline.** It is diagnostic. The pilot
  cohort is the retention evidence.

## 9. Evidence sources

| Evidence | Where it lives |
|---|---|
| Plan thresholds and roadmap | [TRANSFORMATION_PLAN_FINAL.md](TRANSFORMATION_PLAN_FINAL.md) sections 4.3, 4.5, 11.5, 11.6, 12.2, 12.4, and 13 |
| Corpus protocol and labels | [CORPUS_PROTOCOL.md](CORPUS_PROTOCOL.md), [CORPUS_LABELING.md](CORPUS_LABELING.md), [CORPUS_CONSENT.md](CORPUS_CONSENT.md), [T1.6] |
| Latency, clock, bleed | [LATENCY_RIG.md](LATENCY_RIG.md), [T1.4] |
| Spike go/no-go | [T1.7], [decisions/0001-conditional-go.md](decisions/0001-conditional-go.md) |
| Pre-sale | [T1.8], [T6.1] |
| Concierge | [T1.9] |
| Legal | [T1.10], [T6.3] |
| Funding and cash | [T1.11], [T6.6], [FINANCIAL_MODEL.md](FINANCIAL_MODEL.md) |
| Beta pilot and funnel | [T5.7], [RETENTION_INSTRUMENTATION.md](RETENTION_INSTRUMENTATION.md) |
| Content supply and cost | [T3.9], [CONTENT_CALENDAR.md](CONTENT_CALENDAR.md), [LAUNCH_PIECES.md](LAUNCH_PIECES.md) |
| Teacher path | [T7.1], [T7.2], [T7.3] |
| Risk and decision logs | [T9.1], [T9.2], [T9.4], [T9.9] |
| Plane project | [Hear Me Out — Guitar Practice OS](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780) |

## 10. Maintenance

- This page is evergreen: do not add a gate status or a "current phase" line.
  Outcomes live in [T9.2].
- When a plan threshold changes, update the plan first, then this page, and
  record the reason in [T9.2].
- When a new phase or expansion surface is added, add a gate section before the
  work starts.
- When a gate decision is made, link the [T9.2] entry from the gate record. Do
  not edit the checklist to look complete.

[T1.4]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/17840c5e-c8fa-451e-abc9-ca343694980e
[T1.6]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/aa34cfe5-eede-405a-be53-07fab816d32f
[T1.7]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/b18f6b44-da9b-4fc0-990c-21f3e681d84a
[T1.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/b1220c5a-dc70-4fac-913d-9b7ab08e8d99
[T1.9]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/1d96beab-8dc4-490a-9d01-9f4fb80c748e
[T1.10]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/5ceef3fb-7a3f-4204-97eb-ef2eeef47365
[T1.11]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6caa88d3-12fe-487e-8a62-826bf2e4d200
[T3.9]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/a8fef7ce-bf3e-49cd-ab49-1189ddda454f
[T5.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/467b255a-10e1-460d-9c0c-8aa6946d2b2d
[T5.7]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/e41c7cb2-918d-41bf-afc4-b97d7e7005cb
[T6.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6b04a9be-cbe4-40bf-9f68-9573adf30218
[T6.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/9f35d8f8-5d33-4f88-ad04-a4d0c2f8b908
[T6.3]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/8ae3b050-4e45-491c-81b7-e949bbb56d66
[T6.4]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/ec0552b9-bccc-4c33-aa5b-b9f8a9804bef
[T6.6]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/d6135c20-d7bf-4e33-9546-b8583aea66d2
[T6.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/341fcb3d-f496-4ec0-a45f-ea59d612f886
[T7.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6c27abcb-58a0-4990-b408-673424edf0e8
[T7.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/b3941675-2fbc-4160-908c-6c7c58d7f41d
[T7.3]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/759fab60-28a4-4994-921c-d776cffac43a
[T9.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/694298da-0c68-4ae6-a03a-e349cb125176
[T9.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/5b34fd51-46d1-4121-b029-5560688ff9b7
[T9.4]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/533d68cf-06b0-451d-8f54-bfa1ce6825c4
[T9.9]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/a74b28eb-9528-481a-8baf-950414b16660
