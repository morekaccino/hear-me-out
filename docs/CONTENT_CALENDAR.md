# 24-month content calendar and cost model (T3.9)

**Status:** Planning model, not a shipping claim. Last updated 2026-11-06.
**Owner:** T3.9. **Dependencies:** T3.5 (reference recordings), T3.6
(etudes), T3.8 (content QA), T2.7 (technique), T6.3 (legal review).
**Source of truth:** [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md)
sections 6.5, 7.2, 11, and 12.4. Launch inventory and legal questions:
[`LAUNCH_PIECES.md`](LAUNCH_PIECES.md). Authoring rules:
[`CONTENT_AUTHORING.md`](CONTENT_AUTHORING.md).

This document models whether a subscription can be supplied with 2–3 new
pieces per month for 24 months. It is built from the plan's own numbers and the
ticket's unit-cost ranges. It contains no market research, vendor quotes, or
claimed shipped content. Every number is an estimate with a range. The base
case is a midpoint, not a promise.

## 1. Executive summary

- **The 10-piece launch is a 2–3 month supply of active repertoire, not a
  year.** The plan keeps 3–5 pieces in rotation (section 7.2). Assuming an
  active learner retires 3–5 pieces per month, 10 pieces lasts 2–3 months. The
  first post-launch piece is due in month 1.
- **Base cadence:** 2 pieces/month in months 1–6, 3/month in months 7–12,
  2/month in months 13–20, and 1/month in months 21–24. That reaches **40
  pieces at month 12 and 60 at month 24**.
- **Etudes:** 2/week in months 1–12 (104 new, 164 total at month 12) and
  4/month in months 13–24 (48 new, 212 total at month 24). That clears the
  plan's 100+ and 200+ floors.
- **Technique and recordings:** 24 technique videos and **144 total reference
  takes (20 launch + 124 new)** over 24 months, plus 3 generic exam-style
  packs.
- **Cost:** about **$51k low / $103k base / $155k high** for launch plus 24
  months, at contractor/loaded rates. The 24 months after launch alone are
  about $41k / $83k / $125k including the three exam packs. These totals
  exclude the one-time $5–10k T6.3 territory review; add it for an all-in legal
  figure.
- **Budget gap:** the plan budgets $25k in Year 1 and $40k in Year 2 ($65k
  total) for content. The base model is about **$38k above that** over 24
  months, concentrated in the first 12 months after launch. The plan's Year 1
  line is approximately the cost of the launch inventory alone.
- **Revenue check:** at the plan's blended $69/year and 15% store fee + 5%
  refund/tax reserve, net revenue is about **$55.72** per annual Pro per year
  (about $4.64/month). Content-only break-even is about **1,240 annual Pro in
  Year 1, 615 in Year 2, and 925 averaged over 24 months**. The plan's base
  case reaches 225 Pro in Year 1 and 713 in Year 2, so Year 1 content is
  cash-funded and Year 2 is roughly content-neutral before other costs. The
  company-level break-even remains about 2,500 Pro (plan section 11.3).
- **Recommendation:** do not promise a monthly content cadence until the
  month-6 gate passes. Fund the base cadence at the modeled level, or run
  founder-led content at a capped 1–2 pieces/month. If neither is true, switch
  to one-time piece packs at $49–$79 (plan section 6.5). The measurable gate is
  in section 6.

## 2. Launch inventory and the 2–3 month supply

### 2.1 What "launch" means

The plan's launch inventory is **10 pieces, 60 etudes, 10 technique
checklists, and 20 reference recordings** (plan section 6.5). The 20 recordings
are the 10 pieces at target and slow tempo. The plan treats etude-level
references as "as needed" (section 6.4), not as part of the 20.

This is a planning inventory, not a shipped state. At the time of writing:

| Asset | Plan count | Repository status | Owner |
|---|---:|---|---|
| Monophonic pieces | 10 | 10 arrangements exist and pass the T3.2 validator; **not** musically reviewed, recorded, or legally cleared | T3.3/T3.4; review T3.8; recordings T3.5; legal T6.3 |
| Sight-reading etudes | 60 | No etude files are in the repo yet | T3.6 |
| Technique checklists | 10 | 8 checklists exist in code (stages 1, 2, 3, 5, 9, 10, 11, 12); the plan says 10 | T2.7 |
| Reference recordings | 20 | No piece or etude reference recordings are in the repo; only UI sounds exist | T3.5 |

The gap between the plan's 10 technique checklists and the 8 in code is small
but real. Either add the two missing checklists or amend the plan's launch
count before launch.

The 20 launch reference recordings are two takes per piece and are priced
inside the per-piece cost in section 4.1. They are not a separate cost line.

### 2.2 Why 10 pieces is 2–3 months, not a year

The plan's repertoire model keeps **3–5 pieces in rotation**, with one
maintenance play per session and a monthly full performance (section 7.2). This
is a **per-learner** rotation, not a library release rate. If an active learner
retires about one piece per week, that learner consumes **3–5 pieces per
month**; ten pieces is therefore **2–3 months of individual learner supply**,
not 12 months. The library is shared across learners at different stages, so
the release cadence does not need to match one learner's consumption.

| Consumption assumption (per active learner) | Pieces per month | Months of supply from 10 pieces |
|---|---:|---:|
| Slower: one piece every two weeks | 2 | 5 |
| Plan rotation, low | 3 | 3.3 |
| Plan rotation, high | 5 | 2 |

The 2–3 month figure is an **estimate**, not a measured completion time. It
uses the plan's rotation, not a T3.8 playtest. If learners keep the same 3–5
pieces for six months, the launch lasts longer; that is not the retention path
the calendar is sized for. The release cadence of 2–3 pieces/month is a
**library-growth rate**, not a per-learner replacement rate. It is below the
3–5-piece per-learner consumption estimate because the library is shared:
different learners are at different stages, and the same piece can serve more
than one learner. The cadence keeps the library deep enough for the learner
population; it is not a promise that each learner gets 2–3 new pieces every
month.

The 60 etudes are a separate supply. At 2 new etudes/week, the etude library
grows from week 1. The 20 reference recordings are a listening library, not a
content cadence.

## 3. Supply model, months 0–24

### 3.1 The first three months

The first three months make the launch supply explicit:

| Month | Pieces (new / total) | Etudes (new / total) | Technique videos (new / total) | Reference takes (new / total) | Exam packs (new / total) |
|---|---:|---:|---:|---:|---:|
| **0 (launch)** | — / **10** | — / **60** | — / **0** (10 checklists) | — / **20** | — / **0** |
| **1** | 2 / **12** | 9 / **69** | 1 / **1** | 5 / **25** | 0 / **0** |
| **2** | 2 / **14** | 8 / **77** | 1 / **2** | 5 / **30** | 0 / **0** |
| **3** | 2 / **16** | 9 / **86** | 1 / **3** | 5 / **35** | 0 / **0** |

By the end of month 3 the library has 16 pieces, 86 etudes, 3 technique
videos, and 35 reference takes. The launch 10 are 62% of the piece library.
By month 6 they are 45%; by month 12 they are 25%. The launch is a starting
library, not a year of supply.

The counts above include all human takes. The 20 launch takes and the 4 piece
takes/month are inside the per-piece cost; only the 1 etude take/month is
priced separately in section 4.4.

### 3.2 Full calendar

Counts are cumulative at the end of each month. "Reference takes" counts human
recordings: 2 per new piece (target and slow) plus 1 representative etude take
per month. The etude take is a planning assumption, not a promise to record
every etude; the plan says etude-level references are "as needed."

| Month | Pieces (new / total) | Etudes (new / total) | Technique videos (new / total) | Reference takes (new / total) | Exam packs (new / total) | Milestone |
|---|---:|---:|---:|---:|---:|---|
| 0 | — / 10 | — / 60 | — / 0 (10 checklists) | — / 20 | — / 0 | Launch inventory |
| 1 | 2 / 12 | 9 / 69 | 1 / 1 | 5 / 25 | 0 / 0 | First post-launch release |
| 2 | 2 / 14 | 8 / 77 | 1 / 2 | 5 / 30 | 0 / 0 | |
| 3 | 2 / 16 | 9 / 86 | 1 / 3 | 5 / 35 | 0 / 0 | Launch is 62% of pieces |
| 4 | 2 / 18 | 8 / 94 | 1 / 4 | 5 / 40 | 0 / 0 | |
| 5 | 2 / 20 | 9 / 103 | 1 / 5 | 5 / 45 | 0 / 0 | 20 pieces; 100+ etudes |
| 6 | 2 / 22 | 9 / 112 | 1 / 6 | 5 / 50 | 0 / 0 | **Gate 1: six-month review** |
| 7 | 3 / 25 | 9 / 121 | 1 / 7 | 7 / 57 | 0 / 0 | Cadence rises to 3/month |
| 8 | 3 / 28 | 8 / 129 | 1 / 8 | 7 / 64 | 0 / 0 | |
| 9 | 3 / 31 | 9 / 138 | 1 / 9 | 7 / 71 | 0 / 0 | |
| 10 | 3 / 34 | 8 / 146 | 1 / 10 | 7 / 78 | 0 / 0 | |
| 11 | 3 / 37 | 9 / 155 | 1 / 11 | 7 / 85 | 0 / 0 | |
| 12 | 3 / 40 | 9 / 164 | 1 / 12 | 7 / 92 | 0 / 0 | **40 pieces; 100+ etudes; Gate 2** |
| 13 | 2 / 42 | 4 / 168 | 1 / 13 | 5 / 97 | 1 / 1 | Generic Grade 1 pack |
| 14 | 2 / 44 | 4 / 172 | 1 / 14 | 5 / 102 | 0 / 1 | |
| 15 | 2 / 46 | 4 / 176 | 1 / 15 | 5 / 107 | 0 / 1 | |
| 16 | 2 / 48 | 4 / 180 | 1 / 16 | 5 / 112 | 1 / 2 | Generic Grade 2 pack |
| 17 | 2 / 50 | 4 / 184 | 1 / 17 | 5 / 117 | 0 / 2 | |
| 18 | 2 / 52 | 4 / 188 | 1 / 18 | 5 / 122 | 0 / 2 | **Gate 3: 18-month review** |
| 19 | 2 / 54 | 4 / 192 | 1 / 19 | 5 / 127 | 1 / 3 | Generic Grade 3 pack |
| 20 | 2 / 56 | 4 / 196 | 1 / 20 | 5 / 132 | 0 / 3 | |
| 21 | 1 / 57 | 4 / 200 | 1 / 21 | 3 / 135 | 0 / 3 | 200 etudes |
| 22 | 1 / 58 | 4 / 204 | 1 / 22 | 3 / 138 | 0 / 3 | |
| 23 | 1 / 59 | 4 / 208 | 1 / 23 | 3 / 141 | 0 / 3 | |
| 24 | 1 / 60 | 4 / 212 | 1 / 24 | 3 / 144 | 0 / 3 | **60 pieces; 200+ etudes** |

The plan's floors are met: 40 pieces and 100+ etudes at month 12; 60 pieces
and 200+ etudes at month 24. The exam packs are generic Grade 1–3 sight-reading
packs. They use no exam-board names, syllabi, or past papers (plan section
11.1 and 10.3).

The 144 total reference takes are **20 launch + 100 piece takes + 24 etude
takes**. The 20 launch and 100 piece takes are inside the per-piece cost; only
the 24 etude takes are priced separately in section 4.4.

### 3.3 Cadence rules and what they assume

| Period | Pieces/month | Etudes/month | Videos/month | Why this rate |
|---|---:|---:|---:|---|
| Months 1–6 | 2 | 8–9 (2/week) | 1 | Prove the pipeline and review capacity |
| Months 7–12 | 3 | 8–9 (2/week) | 1 | Reach 40 pieces and 100+ etudes |
| Months 13–20 | 2 | 4 | 1 | Deepen the library; add exam packs |
| Months 21–24 | 1 | 4 | 1 | Reach 60 pieces and 200+ etudes without overrun |

The calendar is deliberately front-loaded. Months 7–12 are the most expensive
and the most capacity-sensitive: 3 pieces/month is the only way to reach 40
pieces by month 12 from 22 at month 6. If the gate fails, 2 pieces/month yields
34 pieces at month 12, not 40. That is an honest fallback, not a hidden miss.

**Scope deviation:** months 21–24 run at 1 piece/month, below the ticket's
2–3 pieces/month scope. This is a deliberate taper to land on 60 pieces at
month 24 without overrun. If 2–3 pieces/month is mandatory through month 24,
the library reaches about 64–68 pieces and the base cost rises by roughly
$4k–$8k. The model chooses 60 to match the plan's upper bound.

## 4. Cost model

### 4.1 Per-piece cost and hours

The ticket's range is **$500–$1,500 and 8–16 hours per piece**. The breakdown
below is an allocation, not a vendor quote. It uses a blended contractor rate of
about $60–$95/hour; legal review uses a higher rate for a small allocation.

| Task | Low hours | High hours | Low cost | High cost | What it covers |
|---|---:|---:|---:|---:|---|
| Arrangement | 2.5 | 5.0 | $150 | $450 | Reduce the source to a monophonic line, choose key/position, set phrases and tempo |
| Notation and fingering | 2.0 | 3.5 | $120 | $330 | Engrave, mark every string/fret, check ties, rests, pickup, bar coverage |
| Machine validation | 0.5 | 1.0 | $30 | $90 | Run the T3.2 validator, fix errors and warnings, record the output |
| Human playthrough / QA | 1.0 | 2.0 | $60 | $180 | Play from the JSON or engraving; check melody, rhythm, fingering, musical payoff |
| Reference recording | 1.0 | 2.0 | $80 | $210 | Two takes (target and slow), setup, edit, normalize |
| Legal / licence review | 0.5 | 1.0 | $30 | $120 | Confirm source edition, public-domain status, and arrangement originality; record the review |
| Release | 0.5 | 1.5 | $30 | $120 | Metadata, content pipeline, app-side spot check, changelog |
| **Total** | **8.0** | **16.0** | **$500** | **$1,500** | |

The low case assumes no rework and a public-domain melody with a clean source
edition. The high case assumes a commissioned arrangement, a difficult source,
or one round of rework. Both include QA, recording, and legal review; neither
includes the one-time T6.3 territory review (section 7.4).

The two reference takes are $40–$105 each at the per-take rate used in section
4.2. The per-piece total already includes them; section 4.4 does not add them
again.

### 4.2 Other unit costs

| Unit | Low | Base | High | Hours | What it covers |
|---|---:|---:|---:|---:|---|
| Etude | $60 | $130 | $200 | 1.0–2.5 | Compose/arrange, notate, validate, human QA, release. Etude reference take is separate. |
| Technique video | $200 | $400 | $600 | 3–6 | Script, film, edit, captions, review. The checklist text is not included. |
| Etude reference take | $40 | $75 | $105 | 0.5–1.0 | One short etude take with setup and edit. Piece takes are inside the per-piece cost. |
| Technique checklist | $100 | $200 | $300 | 2–4 | Text, rubric, drill description, review. Launch only in this model. |
| Generic exam pack | $500 | $750 | $1,000 | 8–12 | 10–15 sight-reading items, answer key, validation, QA, release. |

These are estimates. They are not quotes from a specific arranger, engraver,
guitarist, videographer, or lawyer. A single contractor may cover several
roles; the model prices the work, not the org chart.

The per-piece recording row in section 4.1 covers two piece takes at the same
$40–$105 per-take rate. This line prices only the separate etude take; it is
not a second charge for the piece takes.

Legal review for etudes, videos, checklists, and exam packs is covered by the
same T6.3 framework and is not itemized per unit. If a per-unit allocation is
required, add about $10–$30 per etude and $50–$100 per pack.

### 4.3 Launch inventory cost

| Item | Count | Low | Base | High |
|---|---:|---:|---:|---:|
| Pieces (including their two reference takes) | 10 | $5,000 | $10,000 | $15,000 |
| Etudes | 60 | $3,600 | $7,800 | $12,000 |
| Technique checklists | 10 | $1,000 | $2,000 | $3,000 |
| **Launch total** | | **$9,600** | **$19,800** | **$30,000** |

This is the full cost of the inventory at the model's unit costs. The 20 launch
reference takes are two per piece and are inside the piece cost; they are not a
separate line. Some launch arrangement work is already done (T3.3/T3.4), so the
forward cash cost from today is lower. The line is kept at full cost so it can
be compared with the plan's Year 1 content budget. The 60 etudes and 20 takes
do not exist yet; their cost is still ahead.

### 4.4 Monthly cost at low, base, and high

The monthly totals use the base cadence and the unit costs above. They exclude
the launch inventory and the three exam packs, which are added separately.

| Phase | Months | Pieces/month | Etudes/month | Videos/month | Etude takes/month | Monthly low | Monthly base | Monthly high |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1–6 | 2 | 8.67 | 1 | 1 | $1,760 | $3,602 | $5,439 |
| 2 | 7–12 | 3 | 8.67 | 1 | 1 | $2,260 | $4,602 | $6,939 |
| 3 | 13–20 | 2 | 4 | 1 | 1 | $1,480 | $2,995 | $4,505 |
| 4 | 21–24 | 1 | 4 | 1 | 1 | $980 | $1,995 | $3,005 |

Monthly totals are constant within each phase because the cadence is constant;
the month-by-month counts are in section 3.2. The three exam packs are one-time
additions in months 13, 16, and 19. The per-piece cost already includes two
piece reference takes; the only reference cost added here is one etude take per
month at $40/$75/$105.

Worked base example, phase 1: 2 pieces × $1,000 = $2,000; 8.67 etudes × $130 =
$1,127; 1 video × $400 = $400; 1 etude take × $75 = $75; total $3,602. The 8.67
figure is 2 etudes/week averaged over 12 months; the calendar rounds to 8 or 9
in individual months.

### 4.5 24-month cumulative cost

| Cost block | Low | Base | High |
|---|---:|---:|---:|
| Launch inventory (month 0) | $9,600 | $19,800 | $30,000 |
| Months 1–6 | $10,560 | $21,612 | $32,634 |
| Months 7–12 | $13,560 | $27,612 | $41,634 |
| Months 13–20 | $11,840 | $23,960 | $36,040 |
| Months 21–24 | $3,920 | $7,980 | $12,020 |
| 3 generic exam packs | $1,500 | $2,250 | $3,000 |
| **Total, launch + 24 months** | **$50,980** | **$103,214** | **$155,328** |

Cumulative checkpoints:

| Milestone | Low | Base | High |
|---|---:|---:|---:|
| Month 0 (launch) | $9,600 | $19,800 | $30,000 |
| Month 6 | $20,160 | $41,412 | $62,634 |
| Month 12 | $33,720 | $69,024 | $104,268 |
| Month 18 | $42,600 | $86,994 | $131,298 |
| Month 24 | $50,980 | $103,214 | $155,328 |

The 24 months **after launch** cost about $41k low, $83k base, and $125k high
including the three exam packs. The launch inventory adds about $10k, $20k, and
$30k. Use the post-launch number for the ongoing subscription supply and the
total for the full program.

The total excludes the one-time $5–10k T6.3 territory review. The per-piece
legal allocation covers routine review only; add the T6.3 figure for an all-in
legal number.

### 4.6 What is not in the cost

- App engineering, DSP, hosting, support, marketing, and founder salary. These
  are separate lines in the plan's P&L (section 11.3).
- The one-time T6.3 legal review and territory framework ($5–10k, plan section
  11.6). The per-piece legal allocation covers routine review only. The
  headline totals in section 4.5 exclude it.
- Music licence fees for copyrighted works. The plan excludes pop songs and
  copyrighted arrangements (section 6.2); this model does not price them.
- Taxes, VAT/sales tax, payment processing beyond the plan's 15% store fee and
  5% refund/tax reserve, currency movement, and equipment.
- Rework beyond the high case. A failed musical review, a rejected arrangement,
  or a legal problem can add a full piece cost or stop a release.

## 5. Revenue sanity check

### 5.1 Pricing and net revenue

The plan's pricing is **$8.99/month or $69/year** for Pro (section 11.1). The
P&L uses a **$69/year blended** price, a **15% store fee**, and a **5%
refunds/tax reserve** (section 11.3). That gives:

- Net per annual Pro: $69 × 0.85 × 0.95 = **$55.72/year**, or **$4.64/month**.
- Net per monthly Pro: $8.99 × 0.85 × 0.95 = **$7.26/month**, or **$87.11/year**.

The plan's own net revenue per Pro matches this: $12,536 ÷ 225 = $55.72, and
$39,726 ÷ 713 = $55.72.

### 5.2 Cost against the plan's base case

| Metric | Year 1 | Year 2 | 24-month total |
|---|---:|---:|---:|
| Modeled content cost (base) | $69,024 | $34,190 | $103,214 |
| Plan content budget | $25,000 | $40,000 | $65,000 |
| Difference | **−$44,024** | **+$5,810** | **−$38,214** |
| Plan base-case Pro (plan table) | 225 | 713 | — |
| Plan net revenue | $12,536 | $39,726 | — |
| Net revenue ÷ content cost | 18% | 116% | — |
| Content-only break-even, annual plans | **~1,240 Pro** | **~615 Pro** | **~925 Pro** |
| Content-only break-even, monthly plans | ~790 Pro | ~395 Pro | ~590 Pro |

How to read it:

- **Year 1 is cash-funded, not revenue-funded.** At 225 Pro, net revenue is
  about $12.5k. The modeled Year 1 content cost is about $69k. Even the plan's
  $25k content line is about twice the net revenue. That is normal for a
  launch, but the cash plan must include it.
- **Year 2 is roughly content-neutral.** At 713 Pro, net revenue is about
  $39.7k; modeled Year 2 content is about $34.2k. That covers content and
  leaves about $5.5k for DSP, legal, hosting, marketing, or tools. The plan's
  full break-even of about 2,500 Pro is still the real gate.
- **The gap is concentrated in Year 1.** The plan's $25k Year 1 line is close
  to the launch inventory alone ($19.8k base). It does not also fund 12 months
  of post-launch cadence ($49.2k base). The 24-month gap is about $38k. The low
  case is about $14k under the $65k budget (a surplus); the high case is about
  $90k over it.

These are estimates, not a forecast. The break-even counts use the model's
base unit costs and the plan's blended annual price. A different price or plan
mix changes the count; a different cost changes it proportionally.

### 5.3 What the break-even count means

The content-only break-even is the number of Pro subscribers whose net revenue
covers content, before every other cost. It is not the company break-even. At
about 925 annual-equivalent Pro averaged over 24 months, content pays for
itself; the plan's company break-even is about 2,500 Pro because DSP, legal,
hosting, marketing, and tools also need funding (section 11.3).

If all subscribers choose the monthly plan, the content-only break-even falls
to about 590 averaged over 24 months because monthly net revenue per subscriber
is higher. The plan's blended $69/year assumption is the safer base.

## 6. Decision gate: subscription or one-time piece packs

### 6.1 Measurable triggers

The plan's hard rule is: do not promise a subscription supply you cannot
sustain. The fallback is one-time piece packs at **$49–$79** instead of a
subscription (plan section 6.5). Use these triggers:

| # | Trigger | How to measure | Threshold | Window | Action |
|---:|---|---|---|---|---|
| 1 | Piece cost overrun | Actual cash plus loaded hours per released piece | > $1,500 or > 16 hours | Two consecutive months | Freeze at 2 pieces/month; re-quote or simplify |
| 2 | Capacity overrun | Total content hours per month | > 80 hours | Two consecutive months | Add a contractor or cut cadence |
| 3 | Subscriber coverage | Trailing 3-month net revenue vs trailing 3-month content cost | Net revenue < content cost | Two consecutive quarters | Hold cadence and review price/acquisition; switch to packs if it persists |
| 4 | Calendar slip | New pieces shipped per month | < 1 piece/month | Two consecutive months | Subscription promise is broken (plan section 12.4); switch to packs |
| 5 | Legal backlog | Days from "ready for legal" to written clearance | > 30 days | Two consecutive batches | Hard stop on releases; do not ship uncleared content |
| 6 | QA rejection | Share of pieces rejected at T3.8 review | > 20% | Two consecutive months | Fix the briefs and reviewer capacity; cut cadence |
| 7 | Demand shortfall at month 24 | Pro subscribers at month 24 | < ~615 annual-equivalent (or < ~395 monthly) | Month 24 | Switch to packs for year 3 |

Trigger 7 is a month-24 test against the Year 2 content break-even. Do not apply
the Year 1 break-even (~1,240) at month 12: the plan's own base case is 225 Pro
at the end of Year 1, so Year 1 is expected to be cash-funded. A month-12 test
at the Year 1 break-even would fire on the plan's base case and would not
distinguish a content problem from the planned launch cash gap.

### 6.2 Action rules

- **Any single trigger:** freeze the cadence at 1 piece/month for one quarter,
  fix the cause, and re-measure. Do not quietly ship late.
- **Two or more triggers, or trigger 4 at any time:** switch to one-time piece
  packs at $49–$79. Keep the launch library and etudes as the core product.
  Stop marketing a monthly cadence.
- **Trigger 5 (legal):** hard stop. No release until T6.3 has cleared the
  source, the arrangement, and the territory. A legal backlog is not a reason
  to ship anyway.
- **Trigger 7 (demand at month 24):** the subscriber base cannot cover year-3
  content. Switch to packs for year 3 even if the content pipeline is healthy.
- **Trigger 3 (coverage) for two consecutive quarters:** the subscriber base
  cannot cover the cadence. Switch to packs even if the content pipeline is
  healthy.

### 6.3 Recommendation

**Recommendation: launch with the subscription and the 10-piece library, but do
not promise a monthly cadence in marketing until the month-6 gate passes.**

The base calendar is credible only if one of these is true:

1. **Contractor-funded:** content is funded at about $103k over 24 months
   (base), including the launch inventory. This is about $38k above the plan's
   current $65k content budget. The plan's P&L must be reconciled before the
   cadence is promised.
2. **Founder-led with a capped cadence:** the founder does arrangement and
   notation, and the cadence is capped at 1–2 pieces/month. The cash cost falls,
   but the founder still spends roughly 30–80 hours/month on content in months
   1–12. That is not free, and it competes with app work. Do not use founder
   hours to justify 3 pieces/month while also expecting the founder to build the
   product.

If neither is true, **switch to one-time piece packs at $49–$79** and keep the
10-piece launch plus the etude library as the product. That is the honest
fallback; a subscription with a slipping calendar is worse than a smaller,
complete product.

The month-6 gate is the decision point. Check triggers 1, 2, 4, 5, and 6 at
month 6. Check trigger 3 quarterly (months 3, 6, 9, and 12). At month 24, check
trigger 7 against the Year 2 break-even before committing to year 3. If the
base case holds, continue to 40 pieces at month 12 and 60 at month 24. If it
does not, switch to packs and record the decision.

## 7. Sources, assumptions, and legal review

### 7.1 Sources

- **Plan section 6.5:** launch inventory, cadence, 40/100+/200+ targets, cost
  range, and the $49–$79 piece-pack fallback.
- **Plan section 6.4:** human reference recordings at target and slow tempo for
  every launch piece and etude level.
- **Plan section 7.2:** 3–5 pieces in rotation, one maintenance play per
  session, monthly full performance.
- **Plan section 11.1:** $8.99/month, $69/year, exam packs at $19–$29 per grade.
- **Plan section 11.3:** 15% store fee, 5% refunds/tax reserve, 225/713 Pro base
  case, ~2,500 Pro company break-even.
- **Plan section 11.6:** $5–10k legal review before launch.
- **Plan section 12.4:** content calendar slips below 1 new piece/month →
  subscription promise broken.
- **`docs/LAUNCH_PIECES.md`:** the 10-piece list, 20 reference takes, stage map,
  and open legal questions.
- **`docs/CONTENT_AUTHORING.md`:** monophonic rules, 1–4 bar phrases, explicit
  string/fret, validator and review checklist.
- **`flutter_app/lib/content/pieces/launch_pieces.dart`:** machine-readable
  launch metadata.
- **Repository inspection (November 2026):** 10 piece arrangements, 8 technique
  checklists, no etude files, no reference recordings.

### 7.2 Assumptions and what would change them

| # | Assumption | Value used | Basis | What would change it |
|---:|---|---|---|---|
| 1 | Launch inventory | 10 pieces, 60 etudes, 10 checklists, 20 takes | Plan 6.5 | T3.6/T3.8 deliver a different count; the code has 8 checklists |
| 2 | Launch status | Pieces arranged, not reviewed/recorded/cleared; no etudes or takes in repo | `LAUNCH_PIECES.md`, repo | T3.5/T3.6/T3.8/T6.3 complete |
| 3 | Piece cadence | 2/month (1–6), 3/month (7–12), 2/month (13–20), 1/month (21–24) | Plan 6.5 plus this model | Funding, demand, capacity |
| 4 | Etude cadence | 2/week (1–12), 4/month (13–24) | Plan 6.5 for 1–6; extrapolated | Generator beta, pedagogue capacity |
| 5 | Technique videos | 1/month, 24 total | Plan 6.5 for 1–6; extrapolated | T2.7 scope; a 12-video library may be enough |
| 6 | Reference takes | 2 per new piece (inside the piece cost); 1 etude take/month (priced separately); 20 at launch (inside the piece cost) | Plan 6.4/6.5; this model | Batch recording; etude reference policy |
| 7 | Piece unit cost | $500–$1,500, 8–16 h | Ticket and plan 6.5 | Quotes, scope, founder-led work |
| 8 | Etude unit cost | $60–$200, 1–2.5 h | Estimate | Length, generator, review |
| 9 | Video unit cost | $200–$600, 3–6 h | Estimate | Production quality, presenter, editing |
| 10 | Etude reference take cost | $40–$105, 0.5–1 h | Estimate | Studio, session player, batch size |
| 11 | Exam pack cost | $500–$1,000, 8–12 h | Estimate | Item count, answer key, QA |
| 12 | Launch cost | $9.6k / $19.8k / $30k | Derived | Actual launch scope |
| 13 | 24-month cost | $51k / $103k / $155k | Derived | Any of the above |
| 14 | Plan content budget | $25k Year 1, $40k Year 2, $65k total | Plan 11.3 | Plan revision |
| 15 | Pricing and fees | $69/year blended, 15% store fee, 5% reserve; net $55.72/year | Plan 11.1/11.3 | Price test, store terms, tax |
| 16 | Plan base case | 225 Pro Year 1, 713 Year 2 | Plan 11.3 | Conversion and renewal |
| 17 | Content-only break-even | ~1,240 / ~615 / ~925 annual Pro (Year 1/2/24-month) | Derived | Cost, price, plan mix |
| 18 | Company break-even | ~2,500 Pro | Plan 11.3 | Cost base and price |
| 19 | 10-piece supply | 2–3 months at 3–5 pieces/month per active learner | Plan 7.2 plus estimate | T3.8 measured completion time |
| 20 | Legal review | 4–8 weeks first batch, 2–4 weeks later; $5–10k one-time | Plan 11.6; `LAUNCH_PIECES.md` | Territory, source edition, licensed work |
| 21 | Exclusions | App, DSP, hosting, marketing, salary, taxes, currency, one-time T6.3 review | Plan 11.3 | Scope change |

### 7.3 Public-domain, IMSLP, and commissioned arrangements

The cost model assumes every new piece is **public-domain or original**. That
keeps legal review bounded and avoids licence fees. The distinction matters:

| Source type | What it means | Cost effect | Legal work |
|---|---|---|---|
| Public-domain melody, new engraving | The work is out of copyright; our arrangement and engraving are new | Low end of the piece range | Confirm the work is PD in US, UK, EU, Canada; confirm the source edition is PD or newly engraved; do not copy a protected edition's fingerings, dynamics, or editorial marks |
| IMSLP source | A convenient scan or edition, not a licence by itself | Low to mid | Check the file's licence: some IMSLP files are public domain, some are CC BY-NC-SA or similar. A paid app may not satisfy a non-commercial term. Prefer a PD edition or make a new engraving from a PD source |
| Commissioned arrangement of a PD work | We pay an arranger to make the monophonic setting; the underlying work is PD | Mid to high | Written work-for-hire or assignment; warranty that the arranger did not copy a protected edition; record the contributor agreement |
| Original work | Written for Hear Me Out | Low to mid | Contributor agreement and originality warranty; no source licence |
| Licensed copyrighted work | A pop song or a protected arrangement | Not in this model | Licence fee, territory restrictions, 4–8 weeks or more. The plan excludes this (section 6.2) |

The 10 launch pieces are public-domain or original, but their legal status is
not settled. `LAUNCH_PIECES.md` records open questions about source editions,
arrangement originality, moral rights, and contributor agreements. No piece
ships on the strength of a `license` string alone.

Etudes, videos, checklists, and exam packs are assumed original or
public-domain. Their contributor agreements and originality warranties are
covered by the same T6.3 framework and are not itemized per unit. If a per-unit
allocation is required, add about $10–$30 per etude and $50–$100 per pack.

### 7.4 Legal-review lead time and the T6.3 dependency

- **T6.3 owns legal review.** The calendar cannot release a piece until T6.3
  has cleared the source, the arrangement, and the territory. This is a hard
  dependency, not a parallel task.
- **First batch:** assume 4–8 weeks for the territory framework and the first
  pieces. That work must start before launch; the month-1 release needs
  clearance in month 0.
- **Later batches:** assume 2–4 weeks per monthly batch once the template
  exists. A new territory or a new source edition adds 4–8 weeks.
- **One-time cost:** the plan budgets $5–10k for legal review before launch
  (section 11.6). This is separate from the per-piece legal allocation in
  section 4.1.
- **Per-piece allocation:** 0.5–1 hour and $30–$120 assumes the framework is
  already in place. If every piece needs a fresh territory opinion, the cost and
  lead time are higher.
- **Do not ship uncleared content.** If T6.3 is late, the calendar slips. That
  is a trigger-5 hard stop, not a reason to lower the review bar.

### 7.5 What would change the answer

- **Contractor rates:** a 30% change in rates moves the 24-month base by about
  $31k.
- **Founder-led work:** cash cost falls, but capacity falls with it. The 30–80
  hours/month in months 1–12 is the constraint, not the invoice.
- **Etude generator:** if T3.7 produces validated etudes, etude authoring hours
  fall. The model does not assume generator savings because the plan says no
  "unlimited" claim until the generator is validated.
- **Reuse:** if one arrangement can serve more than one stage or tier, the
  piece count falls. The plan's stage map is one piece per stage outcome, so
  this model does not assume reuse.
- **Batch recording:** recording several pieces in one session lowers the
  per-take cost. The model already assumes a session guitarist and a project
  studio, not a commercial studio.
- **Legal findings:** a clean public-domain opinion lowers review time; a
  protected edition or a new territory raises it.
- **Price:** a higher annual price lowers the break-even count proportionally.
  A lower price or a monthly-heavy mix raises it.
- **Conversion and renewal:** these change how fast the subscriber base reaches
  the break-even count, not the count itself. The plan's 3% conversion and 50%
  renewal are assumptions, not measured results.
- **Scope:** 2 vs 3 pieces/month changes the base cost by about $12k/year.
  2 vs 1 etude/week changes it by about $6.8k/year. A 12-video technique
  library instead of 24 saves about $4.8k base.
- **Exam packs:** each pack adds about $750 base. More grades or more items add
  cost; the plan prices packs at $19–$29, which is separate revenue.

## 8. Open questions

1. **Which public-domain edition is the engraving source for each of the 10
   launch pieces?** T6.3 and T3.8 must answer before release.
2. **Are the two original studies covered by a contributor agreement?** The
   launch legal questions in `LAUNCH_PIECES.md` leave this open.
3. **Do the 60 launch etudes need human reference recordings?** The plan says
   "etude-level references as needed"; this model budgets one representative
   take per month, not one per etude. T3.5 should confirm.
4. **Who owns ongoing content QA after T3.8?** T3.8 is a ticket, not a standing
   role. The calendar assumes a named reviewer every month. Without one, the
   cadence is not credible.
5. **Is the plan's Year 1 content line launch-only or launch plus cadence?** The
   model reads it as approximately launch-only. If it is meant to cover both,
   the plan is about $44k short in Year 1.
6. **Will the subscription be marketed as a monthly content promise?** The
   recommendation is no, until the month-6 gate passes. The plan's pricing page
   should say what is actually shipped, not what is planned.

## 9. References

- [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md), sections 6.4,
  6.5, 7.2, 10.3, 11.1, 11.3, 11.6, and 12.4.
- [`LAUNCH_PIECES.md`](LAUNCH_PIECES.md), launch list, stage map, and legal
  questions.
- [`CONTENT_AUTHORING.md`](CONTENT_AUTHORING.md), monophonic rules, validator,
  and review checklist.
- [`ARCHITECTURE.md`](ARCHITECTURE.md), score and media models.
- `flutter_app/lib/content/pieces/launch_pieces.dart`, machine-readable launch
  metadata.
- `flutter_app/lib/content/technique/technique_content.dart`, the 8 technique
  checklists currently in code.
