# Costed P&L and downside cash model (T6.2)

**Status:** Planning model, not a forecast. Last updated 2026-11-06.
**Owner:** T6.2. **Dependencies:** T3.9 (content calendar), T6.3 (legal review).
**Source of truth:** [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md)
sections 11.1, 11.3, and 11.6; [`CONTENT_CALENDAR.md`](CONTENT_CALENDAR.md)
(T3.9) for every content number.
**Reproduce:** `python tool/finance/model.py` (stdlib only, no app dependency).
Tests: `python tool/finance/test_model.py`.

This document answers one question: **can the plan's revenue assumptions fund
the plan's cost base, and how much cash does it take before the business pays
for itself?** It is a planning tool. It does not predict installs, conversion,
renewal, store terms, contractor quotes, or tax. Every number is an estimate
with a stated source, and the two cases are deliberately simple.

## 1. Executive summary

| Metric | Base case | Downside case |
|---|---:|---:|
| Installs, Years 1–3 | 7,500 / 20,000 / 40,000 | 7,500 / 20,000 / 40,000 |
| Install → paid conversion | 3% | 2% |
| Annual renewal | 50% | 40% |
| Year 3 total Pro (year end) | 1,556.25 (plan rounding: 1,557) | 984 |
| Year 3 net billings | $86,710 | $54,826 |
| Year 3 cash costs | $77,940 | $77,940 |
| Year 3 cash profit | **+$8,770** | **−$23,114** |
| Peak cash need | **$119,979** | **$161,340** |
| Month of peak cash need | Month 24 (end of Year 2) | Month 36 (end of Year 3) |
| Operating break-even | Year 3 | Not in 36 months |
| 2,500 Pro reached at 40k installs/year? | No; steady state is 2,400 | No; steady state is 1,333 |
| Runway on the peak funding | 24 months, then cash-positive | 36 months, still burning |

Four findings matter more than the rest:

1. **The base case needs about $86k in Year 1 and ~$120k at the month-24
   trough, not the $42k that the old plan table implies for Year 1.** The old
   table understates Year 1 by $44,024 because it budgets $25k for content while
   the T3.9 calendar costs $69,024 in the first year. The three-year cash need is
   similar to the old table; the *timing* is much earlier.
2. **The downside needs about $161k to reach month 36 and still loses money.**
   At the Year 3 run rate it loses about $3,650 per year at 40,000 installs per
   year. It does not reach break-even in the modeled window, and it has no
   finite maximum cash need if nothing changes.
3. **The plan's ~2,500 Pro is a cash-recovery target, not the operating
   break-even.** At the reconciled Year 3 cost base (~$78k), operating
   break-even is ~1,399 annual Pro. At the plan's "$120k costs," it is ~2,154.
   At 2,500 Pro and ~$78k costs, the business makes ~$61k/year, enough to
   recover the ~$120k base cash need in about two years. The old sentence mixes
   a $139k revenue figure with a $120k cost figure; that combination is not
   break-even.
4. **Retention arithmetic:** 50% of 713 is 356.5, which rounds to **357**, not
   a vague "300–600" range. Year 2 is 600 new + 113 retained = 713. Year 3 is
   1,200 new + 357 retained = 1,557. The exact monthly-cohort values are 712.5
   and 1,556.25; the one-subscriber difference is rounding, not a different
   model.

The model excludes founder salary, teacher/exam revenue, ads, cloud AI, and a
licensed catalog. Those are deliberate exclusions, not omissions. Section 9
lists them.

## 2. Assumptions

### 2.1 Core assumptions

| Assumption | Value | Source or basis |
|---|---|---|
| Installs, Year 1 / 2 / 3 | 7,500 / 20,000 / 40,000 | Plan §11.3 |
| Install timing | Evenly through each year (625 / 1,666.67 / 3,333.33 per month) | Model simplification |
| Install → paid conversion, base | 3.0% | Plan §11.3 |
| Install → paid conversion, downside | 2.0% | Plan §11.3 |
| Plan mix | 100% annual plans at a blended $69/year | Plan §11.1 and §11.3 |
| Annual renewal, base | 50% | Plan §11.3 |
| Annual renewal, downside | 40% | Plan §11.3 |
| Equivalent monthly churn at 50% annual | 5.61% per month | `1 − 0.5^(1/12)` |
| Equivalent monthly churn at 40% annual | 7.35% per month | `1 − 0.4^(1/12)` |
| Store fee | 15% | Plan §11.3; assumes the small-business rate |
| Refunds and tax reserve | 5% | Plan §11.3 |
| Net per annual Pro | **$55.72/year** ($4.64/month) | $69 × 0.85 × 0.95 = $55.7175 |
| Content cost, launch + 24 months | **$103,214 base** (low $50,980, high $155,328) | T3.9 §4.5 |
| Content cost, Year 3 | **$23,940 base** (low $11,760, high $36,060) | T3.9 month-21–24 run rate extended to months 25–36 |
| DSP/dev contractor | $15,000 / $20,000 / $25,000 | Plan §11.3 |
| Legal/compliance | $8,000 / $3,000 / $3,000 | Plan §11.3; $6,000 one-time T6.3 review in month 0, $2,000 routine in Year 1 |
| Hosting/support | $2,000 / $5,000 / $10,000 | Plan §11.3 |
| Marketing | $3,000 / $8,000 / $12,000 | Plan §11.3; organic only, no paid UA |
| Tools/ops | $2,000 / $3,000 / $4,000 | Plan §11.3 |
| Founder salary | **Excluded** | Plan §11.3 |
| Teacher and exam revenue | **Excluded from the base** | Plan §11.3 |
| Ads, cloud AI, licensed catalog | **Excluded** | Plan §11.1 |

The plan's "Marketing/content" line is treated as **marketing only**. Content
production is the separate T3.9 line. Counting that line as content as well
would double-count the content budget.

### 2.2 Retention arithmetic, stated explicitly

The plan's annual table is a year-end count, not an average. It works like
this:

| Year | New Pro | Retained from prior year | Total Pro at year end | Arithmetic |
|---|---:|---:|---:|---|
| 1 | 7,500 × 3% = 225 | 0 | 225 | 225 |
| 2 | 20,000 × 3% = 600 | 225 × 50% = 112.5 ≈ 113 | 713 | 600 + 113 |
| 3 | 40,000 × 3% = 1,200 | **713 × 50% = 356.5 ≈ 357** | **1,557** | 1,200 + 357 |

**The correction:** 713 × 50% is 356.5, which rounds to **357**. A range of
300–600 would imply a retention rate between 42% and 84% of 713; that is not
the plan's 50% assumption. The model uses 357, and the exact cohort value is
356.25 before step rounding.

The monthly model keeps exact expected values: 712.5 Pro at the end of Year 2
and 1,556.25 at the end of Year 3. The plan's step-rounded 713 and 1,557 differ
by less than one subscriber; the net-billing difference is about $42 per year.
That is a rounding difference, not a second forecast.

**Monthly churn correction.** The plan's §11.3 text says "~4.2%/month churn
(50% annual)." That is not the same rate. A 50% annual retention corresponds to
**5.61% monthly geometric churn**:

```
1 − 0.50^(1/12) = 1 − 0.9439 = 5.61% per month
1 − 0.40^(1/12) = 1 − 0.9265 = 7.35% per month
```

Conversely, 4.2% monthly churn leaves `(1 − 0.042)^12 = 59.7%` after a year,
not 50%. The model uses **anniversary renewal** for annual plans, because an
annual subscriber does not churn monthly; the monthly equivalent is a
reporting metric, not the renewal mechanism.

**Downside arithmetic:** Year 1 is 150 Pro. Year 2 is 400 new + 150 × 40% = 60
retained = 460. Year 3 is 800 new + 460 × 40% = 184 retained = 984. These are
exact integers, so the downside table has no rounding difference.

### 2.3 Content cost reconciliation (T3.9 is authoritative)

T3.9 models the launch inventory plus 24 months. The plan's old table budgets
$25k / $40k / $60k for content. Those are not the same numbers. The reconciled
schedule is:

| Content window | T3.9 low | **T3.9 base** | T3.9 high | Old plan line | Base vs old plan |
|---|---:|---:|---:|---:|---:|
| Launch inventory (month 0) | $9,600 | **$19,800** | $30,000 | included below | — |
| Year 1 (launch + months 1–12) | $33,720 | **$69,024** | $104,268 | $25,000 | **+$44,024** |
| Year 2 (months 13–24) | $17,260 | **$34,190** | $51,060 | $40,000 | **−$5,810** |
| **Launch + 24-month total** | **$50,980** | **$103,214** | **$155,328** | **$65,000** | **+$38,214** |
| Year 3 extension (months 25–36) | $11,760 | **$23,940** | $36,060 | $60,000 | **−$36,060** |
| **3-year total** | **$62,740** | **$127,154** | **$191,388** | **$125,000** | **+$2,154** |

How to read it:

The comparison is launch + months 1–24 against the old plan's Years 1–2. The
launch inventory is a one-time cost that must be spent before revenue, so it
belongs in the first two years.

- The **launch + 24-month total is $103,214 base**, exactly T3.9's launch +
  24-month total. The old plan's two-year content line is $65,000. The gap is
  **$38,214**, which is the T3.9 "budget gap" restated as cash.
- The **3-year total is close** ($127,154 vs $125,000, +$2,154), but the timing
  is not. Year 1 is **$44,024 higher** than the old table; Year 3 is **$36,060
  lower**. A cash model cares about when the money leaves, not only the total.
- Year 3 is an **extension** beyond T3.9's 24-month window. It holds the
  month-21–24 cadence (1 piece/month, 4 etudes/month, 1 video/month, 1 etude
  take/month) at $1,995/month base. It is labeled as an extension, not a T3.9
  fact. If the cadence returns to 2–3 pieces/month, Year 3 content rises by
  roughly $12k–$24k (T3.9 §7.5).
- The T3.9 low/high cases are much wider than ±25%. At low content the base
  cash need falls to about $68k; at high content it rises to about $175k. See
  §7.4.

### 2.4 Non-content cost lines

These are the plan's §11.3 estimates, not vendor quotes:

| Line | Year 1 | Year 2 | Year 3 | What it covers |
|---|---:|---:|---:|---|
| DSP/dev contractor | $15,000 | $20,000 | $25,000 | Audio/DSP work, Flutter contractor, QA. The founder is not paid. |
| Legal/compliance | $8,000 | $3,000 | $3,000 | $6,000 one-time T6.3 territory/legal review in month 0, $2,000 routine in Year 1, $3,000/year after. |
| Hosting/support | $2,000 | $5,000 | $10,000 | Web demo, content delivery, email support, store fees. The app is local-only, so this is conservative. |
| Marketing | $3,000 | $8,000 | $12,000 | Organic/SEO/content marketing. No paid UA in the base (plan §11.4). |
| Tools/ops | $2,000 | $3,000 | $4,000 | CI, design tools, accounting, app-store fees, small software. |
| **Total non-content** | **$30,000** | **$39,000** | **$54,000** | |

The model spreads each annual line evenly by month, except the $6,000 legal
review, which is booked in month 0. That makes month 0 the true pre-launch cash
event:

```
Month 0 = $19,800 launch content + $6,000 legal review = $25,800
```

If the legal review lands at the top of the plan's $5–10k range, add $4,000 to
the cash need; at the bottom, subtract $1,000.

## 3. Base case, Years 1–3

Assumptions: 7,500 / 20,000 / 40,000 installs; 3% conversion; 50% annual
renewal; $69/year; 15% store fee; 5% refund/tax reserve; T3.9 base content.

| Line | Year 1 | Year 2 | Year 3 |
|---|---:|---:|---:|
| Installs | 7,500 | 20,000 | 40,000 |
| New Pro | 225 | 600 | 1,200 |
| Retained Pro (exact) | 0 | 112.5 | 356.25 |
| **Total Pro at year end (exact)** | **225** | **712.5** | **1,556.25** |
| Total Pro at year end (plan rounding) | 225 | 713 | 1,557 |
| Gross billings | $15,525 | $49,162 | $107,381 |
| Store fee (15%) | $2,329 | $7,374 | $16,107 |
| Refunds/tax reserve (5% of after-store) | $660 | $2,089 | $4,564 |
| **Net billings** | **$12,536** | **$39,699** | **$86,710** |
| Recognized revenue (memo) | $6,791 | $27,249 | $65,163 |
| Content (T3.9) | $69,024 | $34,190 | $23,940 |
| DSP/dev contractor | $15,000 | $20,000 | $25,000 |
| Legal/compliance | $8,000 | $3,000 | $3,000 |
| Hosting/support | $2,000 | $5,000 | $10,000 |
| Marketing | $3,000 | $8,000 | $12,000 |
| Tools/ops | $2,000 | $3,000 | $4,000 |
| **Total costs** | **$99,024** | **$73,190** | **$77,940** |
| **Cash profit** | **−$86,488** | **−$33,491** | **+$8,770** |
| **Cumulative cash** | **−$86,488** | **−$119,979** | **−$111,208** |

Rows may not sum exactly because of rounding.

What the table means:

- **Year 1 is the launch burn.** Month 0 spends $25,800. Months 1–12 spend
  $73,224 in content and non-content costs and collect $12,536, for another
  −$60,688. Total Year 1 cash need: **−$86,488**. That is about $5,057/month
  across months 1–12, plus the month-0 launch spend.
- **Year 2 is still cash-negative but improving.** Net billings rise to
  $39,699 as the Year 2 cohorts and the first renewals arrive; costs fall to
  $73,190 because content drops from $69,024 to $34,190. The year loses
  $33,491, and cumulative cash reaches its trough: **−$119,979 at month 24**.
- **Year 3 turns cash-positive.** Net billings rise to $86,710; costs rise to
  $77,940 because DSP/dev and hosting/support grow. The year makes **+$8,770**,
  and cumulative cash improves to **−$111,208** by month 36.
- **The base case is not self-funding within the three-year window.** It needs
  about **$120k** of committed cash to reach the month-24 trough. After that,
  the model is cash-positive at the Year 3 run rate, but it still has
  $111k of accumulated deficit to recover.

The plan's old table says Year 1 cumulative cash is −$42,464. The reconciled
model says −$86,488. The difference is almost exactly the content timing gap
(+$44,024). If the launch is funded on the old Year 1 number, it runs out of
cash before the Year 2 renewals arrive. Section 8 reconciles the rest.

## 4. Downside case

Assumptions: the same installs and cost base; **2% conversion** and **40%
annual renewal**. The non-content lines are identical to the base table, so
they are collapsed below.

| Line | Year 1 | Year 2 | Year 3 |
|---|---:|---:|---:|
| Installs | 7,500 | 20,000 | 40,000 |
| New Pro | 150 | 400 | 800 |
| Retained Pro | 0 | 60 | 184 |
| **Total Pro at year end** | **150** | **460** | **984** |
| Gross billings | $10,350 | $31,740 | $67,896 |
| **Net billings** | **$8,358** | **$25,630** | **$54,826** |
| Recognized revenue (memo) | $4,527 | $17,714 | $41,445 |
| Content (T3.9 base) | $69,024 | $34,190 | $23,940 |
| Other costs (all non-content lines) | $30,000 | $39,000 | $54,000 |
| **Total costs** | **$99,024** | **$73,190** | **$77,940** |
| **Cash profit** | **−$90,666** | **−$47,560** | **−$23,114** |
| **Cumulative cash** | **−$90,666** | **−$138,226** | **−$161,340** |

The old plan's downside net revenue differs by $2–$14/year because it rounds to
whole subscribers; the model uses exact cohort values. The difference is
immaterial to the cash need.

What the table means:

- **Year 1 is worse than the base by $4,178** because conversion is 2% instead
  of 3%: net billings fall from $12,536 to $8,358. The cost base is unchanged.
- **The deficit keeps growing.** Year 2 loses $47,560, Year 3 loses $23,114.
  The cumulative cash need reaches **−$161,340 at month 36**.
- **The point of maximum cash need in the 36-month model is month 36.** Unlike
  the base case, the downside has not turned cash-positive at the end of Year
  3. The monthly loss in Year 3 is about **−$1,926**.
- **There is no finite maximum if the run rate continues.** At 40,000 installs
  per year, 2% conversion, and 40% renewal, the steady-state Pro count is
  `800 / (1 − 0.40) = 1,333`. Net billings are about **$74,290/year** against
  **$77,940** of costs, a loss of about **$3,650/year**. The cumulative deficit
  therefore keeps growing by roughly that amount every year after the
  transition; $161,340 is the 36-month funding need, not the final need.

**Runway.** With **$161,340** committed at launch, the downside reaches month
36 with **zero buffer** and still burns about **$1,926/month**. That is a
funding runway of **36 months from launch**, not a runway to break-even. A
12-month buffer beyond month 36 would need roughly **$184k** ($161k + $23k).
Even that does not fix the steady-state loss; it buys time. The fix is
conversion, renewal, or cost, not more runway.

**What would fix the downside?** At the Year 3 cost base of $77,940, operating
break-even needs ~1,399 Pro. At 40% renewal, that requires about 840 new Pro
per year, or **2.10% conversion** at 40,000 installs. So a 0.1 percentage point
conversion improvement gets the downside to roughly zero at steady state.
Recovering the $161k cash need in three years, however, needs about $54k/year
of profit, which needs ~2,364 Pro, or about **3.55% conversion** at 40,000
installs/year. That is the difference between "stops losing money" and "pays
back the launch."

## 5. Monthly cohort model

The annual tables are summaries of a month-by-month cohort model. The script
in `tool/finance/model.py` is the executable version. This section explains
the mechanics so the annual tables can be checked by hand.

### 5.1 From installs to cohorts

Month 0 is launch preparation: no installs, no revenue, but the launch content
and the one-time legal review are spent. Months 1–36 are the operating model.
Installs are spread evenly through each year:

| Year | Annual installs | Monthly installs | Conversion | New Pro per month |
|---|---:|---:|---:|---:|
| 1 | 7,500 | 625.00 | 3% | 18.75 |
| 2 | 20,000 | 1,666.67 | 3% | 50.00 |
| 3 | 40,000 | 3,333.33 | 3% | 100.00 |

Each month's new Pro is a **cohort**. A cohort pays $69 in its install month.
At each anniversary it renews with probability `r` (50% base, 40% downside).
The expected number of paying subscribers from a cohort in a renewal month is:

```
cohort size × r^(number of anniversaries already passed)
```

For example, the month-1 cohort has 18.75 Pro. In month 13 (its first
anniversary), 18.75 × 0.50 = 9.375 are expected to renew. In month 25 (second
anniversary), 18.75 × 0.25 = 4.6875. The monthly model uses these expected
values; it does not simulate individual subscribers.

### 5.2 Active Pro and annual billings

The **active Pro** count in a month is the sum of all cohorts that have paid
and not lapsed. At the end of Year 1, no cohort has reached an anniversary, so
active Pro is exactly the 225 new subscribers. At the end of Year 2, the Year
1 cohorts have had one anniversary at 50%, and the Year 2 cohorts have not, so:

```
225 × 0.50 + 600 = 712.5
```

At the end of Year 3:

```
225 × 0.25 + 600 × 0.50 + 1,200 = 1,556.25
```

This is why the annual table's total Pro is a **year-end count**, not an
average. It also explains why annual net billings equal year-end Pro × $55.72:
in a level-install year, every active subscriber pays exactly once during the
year (new subscribers at install, retained subscribers at anniversary). The
average active count during a growing year is lower than the year-end count,
so "revenue per average active" would be higher than $55.72. The plan's table
uses the year-end convention; this model keeps it.

### 5.3 Store fee, refunds, and tax reserve

Every $69 payment is reduced by the store fee and the reserve:

```
$69.00 × (1 − 0.15) × (1 − 0.05) = $55.7175 ≈ $55.72
```

That is **$4.643/month** of net billings per annual Pro. The 5% reserve is
treated as a permanent haircut, not a refundable balance. It covers refunds,
sales tax/VAT leakage, and small payment costs. It is not a full tax model:
corporate income tax is excluded (the model is pre-tax). If the store fee is
30% instead of 15%, net per Pro falls to `$69 × 0.70 × 0.95 = $45.89`, and
break-even at the reconciled cost base rises from ~1,399 to ~1,699 Pro.

### 5.4 Revenue recognition (why the table has two revenue lines)

Annual plans are **collected up front**. The cash is available in the install
or renewal month. For accounting, that payment is earned over the following 12
months. The model uses **net billings** for the cash schedule because runway is
a cash question. It shows **recognized revenue** as a memo so the reader does
not mistake prepaid cash for earned revenue.

- Year 1 net billings are $12,536; recognized revenue is **$6,791**, because
  the 12 monthly cohorts have been recognized for 1–12 months, not a full year.
- Year 2 recognized revenue is **$27,249**; Year 3 is **$65,163**.
- At month 36, about **$39,742** of collected cash is still unrecognized
  deferred revenue. It is a liability, not profit, but it is cash in the bank.
- Over the life of a cohort, cumulative billings and cumulative recognized
  revenue are identical. Only the timing differs. The model's conclusions do
  not depend on the accounting choice.

The annual table's "cash profit" is **net billings minus cash costs**. It is a
cash P&L, not a GAAP P&L. Do not mix the recognized-revenue memo with the cash
profit line.

### 5.5 Monthly costs

Content costs follow T3.9's phase table, plus the three exam packs:

| Months | Content cost per month (base) | What is included |
|---|---:|---|
| 1–6 | $3,602 | 2 pieces, 8.67 etudes, 1 video, 1 etude take |
| 7–12 | $4,602 | 3 pieces, 8.67 etudes, 1 video, 1 etude take |
| 13–20 | $2,995 | 2 pieces, 4 etudes, 1 video, 1 etude take |
| 21–24 | $1,995 | 1 piece, 4 etudes, 1 video, 1 etude take |
| 25–36 | $1,995 | Extension at the month-21–24 run rate |
| Month 0 | $19,800 | Launch inventory (10 pieces, 60 etudes, 10 checklists) |
| Months 13, 16, 19 | +$750 each | Generic Grade 1–3 exam packs |

Non-content costs are the annual lines in §2.4 divided by 12. The $6,000 legal
review is the exception: it is booked in month 0. Month 0 is therefore
−$25,800 before any revenue.

### 5.6 36-month cash checkpoints

The full schedule has 37 rows (month 0 plus months 1–36). The script prints
all of them with `--json`. The compact checkpoint table below is enough to see
the shape of the two cases:

| Month | Base net billings | Base costs | Base cumulative | Downside net billings | Downside costs | Downside cumulative |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | $0 | $25,800 | −$25,800 | $0 | $25,800 | −$25,800 |
| 3 | $1,045 | $5,602 | −$39,472 | $696 | $5,602 | −$40,517 |
| 6 | $1,045 | $5,602 | −$53,144 | $696 | $5,602 | −$55,233 |
| 9 | $1,045 | $6,602 | −$69,816 | $696 | $6,602 | −$72,950 |
| 12 | $1,045 | $6,602 | −$86,488 | $696 | $6,602 | −$90,666 |
| 15 | $3,308 | $6,245 | −$96,048 | $2,136 | $6,245 | −$103,744 |
| 18 | $3,308 | $6,245 | −$105,608 | $2,136 | $6,245 | −$116,821 |
| 21 | $3,308 | $5,245 | −$114,169 | $2,136 | $5,245 | −$128,899 |
| 24 | $3,308 | $5,245 | **−$119,979** | $2,136 | $5,245 | −$138,226 |
| 27 | $7,226 | $6,495 | −$117,786 | $4,569 | $6,495 | −$144,005 |
| 30 | $7,226 | $6,495 | −$115,594 | $4,569 | $6,495 | −$149,783 |
| 33 | $7,226 | $6,495 | −$113,401 | $4,569 | $6,495 | −$155,562 |
| 36 | $7,226 | $6,495 | **−$111,208** | $4,569 | $6,495 | **−$161,340** |

The steps at months 13 and 25 are the annual renewals from the Year 1 and Year
2 cohorts. The step at month 25 is also when the Year 3 cohorts start: 100 new
Pro per month, or about $5,572 of net billings in their first month. The base
case turns cash-positive in month 25 (the first month of Year 3); the downside
never does within the window.

### 5.7 Rounding and determinism

The script rounds displayed dollars to the nearest dollar and keeps full
precision internally. The annual table's "plan rounding" row uses the plan's
step rounding (713, 1,557); the exact cohort values are 712.5 and 1,556.25.
The script is deterministic: running it twice produces identical output. The
test suite checks that, plus the arithmetic in this document.

## 6. Break-even

### 6.1 The per-Pro math

```
Net revenue per annual Pro = $69 × 0.85 × 0.95 = $55.7175/year
Operating break-even Pro    = annual cost / $55.7175
```

### 6.2 Reconciling the plan's ~2,500 Pro claim

The plan says: "Break-even: ~2,500 Pro at ~$172k gross / ~$139k net revenue,
with costs near $120k." The arithmetic does not support all four numbers at
once:

| Annual cost base | Source | Break-even Pro | What it means |
|---|---:|---:|---|
| **$77,940** | Reconciled Year 3: T3.9 base content at the month-21–24 run rate + plan non-content | **~1,399** | The model's operating break-even |
| $114,000 | The plan's own Year 3 total cost line | ~2,046 | Old table |
| $120,000 | The plan's "costs near $120k" | ~2,154 | Old text |
| $139,294 | The net revenue at 2,500 Pro | ~2,500 | The cost base needed for 2,500 to be break-even |

At 2,500 Pro, net revenue is:

```
2,500 × $55.7175 = $139,293.75
```

Against $120,000 of costs, that is a **+$19,294 profit**, not break-even.
Against the plan's own $114,000 Year 3 cost line, it is a **+$25,294 profit**.
The break-even at $120k is **~2,154 Pro**; at $114k it is **~2,046 Pro**.

**So what is ~2,500?** At the reconciled cost base of $77,940, 2,500 Pro
produces **$61,354/year** of cash profit. That is enough to recover the ~$120k
base peak cash need in about **2 years**. The ~2,500 figure is a useful
**cash-recovery target**, but it is not the operating break-even. The document
keeps the figure because it is a meaningful planning milestone, with the label
corrected.

If founder salary is added, the break-even rises. At the reconciled cost base,
a $60k salary moves operating break-even to **~2,476 Pro**; a $100k salary to
**~3,193 Pro**. The plan's 4,000–5,000 figure assumes a higher cost base or a
higher price; it is not wrong as a salary-inclusive target, but it is not the
operating break-even of this cost model.

### 6.3 Which year does break-even occur?

The cost base changes by year: Year 1 carries the launch content, Year 2 is
cheaper, and Year 3 adds DSP/dev and hosting/support while content tapers.
That gives a different break-even count each year:

| Year | Annual cash cost | Operating break-even Pro | Base year-end Pro | Downside year-end Pro |
|---|---:|---:|---:|---:|
| 1 | $99,024 | 1,777 | 225 | 150 |
| 2 | $73,190 | 1,314 | 712.5 | 460 |
| 3 | $77,940 | **1,399** | **1,556.25** | 984 |

The base case is below break-even in Years 1 and 2 and above it in Year 3. The
downside is below break-even in all three years. That is why the answer is
"Year 3" for the base and "not in 36 months" for the downside, not a single
count for every year.

| Case | Operating break-even (annual cash profit ≥ 0) | 2,500 Pro target | Cumulative cash recovery |
|---|---|---|---|
| Base | **Year 3** (+$8,770) | Not at 40k installs/year; steady state is 2,400. At 60k installs/year, crossed in Year 4. | **Year 6** at flat 40k installs/year (extension, not the 36-month model) |
| Downside | **Not within 36 months**; Year 3 is −$23,114 | Never at 40k installs/year; steady state is 1,333 | Never at the flat run rate; the steady-state loss is ~$3,650/year |

The base case's Year 3 operating break-even is thin: Year 3 ends at 1,556 Pro,
only ~157 above the 1,399 break-even. It does not produce enough profit to
recover the accumulated deficit quickly. The flat extension at the Year 3 run
rate shows:

| Year | End active Pro | Net billings | Costs | Cash profit | Cumulative cash |
|---|---:|---:|---:|---:|---:|
| 4 | 1,978 | $110,216 | $77,940 | +$32,276 | −$78,932 |
| 5 | 2,189 | $121,969 | $77,940 | +$44,029 | −$34,903 |
| 6 | 2,295 | $127,846 | $77,940 | +$49,906 | **+$15,002** |

This extension is **not part of the required 36-month model**. It assumes the
Year 3 install rate, conversion, renewal, content run rate, and non-content
cost base all continue unchanged. It is included only to answer "when does the
accumulated cash come back?" The answer at flat 40k installs/year is **Year 6**,
not Year 4. If installs keep growing to 60k/year, the recovery is earlier; if
content returns to 2–3 pieces/month, it is later.

At 40k installs/year, the base case **never reaches 2,500 Pro** because the
steady state is `1,200 / (1 − 0.50) = 2,400`. To reach 2,500 at 3% conversion
and 50% renewal, the install rate must be:

```
2,500 × (1 − 0.50) / 0.03 = 41,667 installs/year
```

That is only 4% above the Year 3 rate, but it is above it. At 60k installs/year,
the Year 4 cohort alone is 1,800 new Pro; with 50% of the 1,556 Year 3 base,
Year 4 ends at ~2,578 Pro, so 2,500 is crossed during Year 4.

## 7. Sensitivity

### 7.1 Single-variable results

Each row changes one assumption and holds the rest at base. "Peak cash need" is
the lowest cumulative cash through month 36; "month-36 cash" is the cumulative
cash at the end of the window. The peak is the funding requirement; the
month-36 number shows whether the case is improving or still deteriorating at
the end of the window.

| Variable | Cases | Peak cash need | Month-36 cumulative cash | Swing (peak) |
|---|---|---:|---:|---:|
| Installs | −25% / +25% | $145,945 / $106,920 | −$145,945 / −$76,472 | $39,025 |
| Conversion | 1% / 2% / 3% / 4% | $203,839 / $157,524 / $119,979 / $102,567 | −$203,839 / −$157,524 / −$111,208 / −$64,893 | **$101,272** (1% vs 4%) |
| Renewal | 30% / 40% / 50% / 60% | $122,486 / $121,232 / $119,979 / $118,725 | −$122,408 / −$116,933 / −$111,208 / −$105,233 | $3,761 |
| Content cost | 75% / 100% / 125% | $94,175 / $119,979 / $145,782 | −$79,420 / −$111,208 / −$142,997 | **$51,607** |

### 7.2 Which two variables matter most?

**On the funding measure (peak cash need), the two largest are conversion and
content cost.** Conversion's 1%–4% range swings the cash need by **$101,272**;
content ±25% swings it by **$51,607**; installs ±25% swings it by **$39,025**;
renewal 30%–60% swings it by only **$3,761**.

**On the fixed month-36 measure, conversion and installs are the top two**
($138,946 and $69,473), with content a close third ($63,577) and renewal last
($17,175). The difference is the trough timing: the T3.9 high content case
pushes the trough from month 24 to month 36, so the later content costs count
in full on the peak measure.

The honest answer is:

- **Conversion is the single largest variable in every measure.** A 1%
  conversion case needs ~$204k; a 4% case needs ~$103k.
- **Content cost and install volume are effectively tied for second**,
  depending on whether you measure the peak or the fixed horizon. Content is
  the largest cost-side lever; installs is the largest demand-side lever.
- **Renewal is the smallest over 36 months** because the subscriber base is
  young and most revenue comes from new cohorts. It is **not** unimportant:
  at 40k installs/year, the steady-state Pro count is 1,714 at 30% renewal,
  2,400 at 50%, and 3,000 at 60%. Renewal controls the long-run scale; it just
  does not change the first 36 months much.

If the team can only track two demand numbers, track **conversion** and
**installs**. If it can only cut one cost, cut **content** (or hold the cadence
at the low end of T3.9). Section 7.4 shows why content is a first-order risk,
not a rounding item.

### 7.3 Steady-state scale

At 40,000 installs/year:

| Annual renewal | Conversion 2% | Conversion 3% | Conversion 4% |
|---|---:|---:|---:|
| 30% | 1,143 | 1,714 | 2,286 |
| 40% | 1,333 | 2,000 | 2,667 |
| 50% | 1,600 | 2,400 | 3,200 |
| 60% | 2,000 | 3,000 | 4,000 |

The base case (3%, 50%) is 2,400; the downside (2%, 40%) is 1,333. This is why
the 2,500 target is a stretch at 40k installs/year even in the base: the
asymptote is 2,400. It is reachable with 60k installs/year, a 4% conversion
rate, or a 60% renewal rate.

### 7.4 T3.9 content range at base demand

The T3.9 low/high cases are wider than the ±25% sensitivity:

| Content case | Launch + 24 months | Year 3 extension | 3-year total | Peak cash need | Trough month |
|---|---:|---:|---:|---:|---:|
| T3.9 low | $50,980 | $11,760 | $62,740 | **$67,745** | 24 |
| **T3.9 base** | **$103,214** | **$23,940** | **$127,154** | **$119,979** | 24 |
| T3.9 high | $155,328 | $36,060 | $191,388 | **$175,442** | 36 |

A high content case raises the base cash need by about 46% and pushes the trough
to month 36. That is the strongest argument for the T3.9 month-6 gate: content
overrun is not a small variance, it is the difference between a ~$120k launch
and a ~$175k launch.

## 8. Reconciliation with the plan's old table

The plan's §11.3 table is retained as the **historical plan**, not as the cash
plan. This section shows exactly where the new model differs. Do not delete the
old table; use the new model for cash.

| Line | Old plan | Reconciled model | Difference | Why |
|---|---:|---:|---:|---|
| Year 1 net revenue | $12,536 | $12,536 | $0 | Same price, conversion, and year-end count |
| Year 1 content | $25,000 | $69,024 | **+$44,024** | T3.9 launch + 12 months |
| Year 1 total costs | $55,000 | $99,024 | +$44,024 | Content |
| Year 1 cash profit | −$42,464 | −$86,488 | −$44,024 | Content timing |
| Year 2 net revenue | $39,726 | $39,699 | −$27 | Exact 712.5 vs rounded 713 |
| Year 2 content | $40,000 | $34,190 | −$5,810 | T3.9 |
| Year 2 total costs | $79,000 | $73,190 | −$5,810 | Content |
| Year 2 cash profit | −$39,274 | −$33,491 | +$5,783 | Lower content |
| Year 3 net revenue | $86,752 | $86,710 | −$42 | Exact 1,556.25 vs rounded 1,557 |
| Year 3 content | $60,000 | $23,940 | **−$36,060** | T3.9 run-rate extension |
| Year 3 total costs | $114,000 | $77,940 | −$36,060 | Content |
| Year 3 cash profit | −$27,248 | **+$8,770** | +$36,018 | Lower content |
| Year 3 cumulative cash | −$108,986 | −$111,208 | −$2,222 | Earlier Year 1 burn |
| Peak cash need | −$108,986 at Year 3 (annual) | **$119,979 at month 24** | +$10,993 | Content timing |

The old table's **three-year total cash need is close** (−$108,986 vs
−$111,208), but the path is wrong. It puts the cash need in Years 2–3, when the
business has more revenue; the reconciled model puts $44,024 more of it in Year
1, before the renewals arrive. A launch funded on the old table's Year 1 line
runs out of cash in Year 1.

The old table's **content total** over three years is also close ($125,000 vs
$127,154), which is why the gap was easy to miss. The 24-month content total is
not close: $65,000 vs $103,214. The old Year 1 line is approximately the launch
inventory alone ($19,800 base), leaving no room for the 12 months of post-launch
cadence ($49,224 base). That is the reconciliation, not a new content estimate.

## 9. Exclusions and honesty

### 9.1 What is excluded

- **Founder salary.** The model is pre-salary. If the founder needs a market
  salary of $60–100k, add it to the cost base. At the reconciled Year 3 cost
  base, that moves operating break-even to ~2,476–3,193 Pro (see §6.2).
- **Teacher and exam revenue.** Excluded from the base. The plan's
  "3,000 Pro + 100 teachers ≈ $220k gross, ~$50–80k profit" is an **upside
  case only**, not a base assumption. Do not use it for runway. It is not
  counted until three paid teacher pilots pass (plan §11.3).
- **Exam packs.** The model includes the **cost** of producing three generic
  Grade 1–3 packs ($2,250 base, inside the T3.9 content line). It excludes
  their revenue ($19–29 per grade). That is conservative: the packs cost money
  before they earn any.
- **Lifetime plan.** The $129 lifetime option is excluded. It is capped at 500
  and would cannibalize annual revenue; treat any lifetime revenue as upside
  only.
- **Ads, cloud AI, and a licensed catalog.** No ad revenue, no cloud inference
  cost, no licence fees. The app is local-only and rule-based. A licensed pop
  catalog would add both licence cost and legal lead time; it is not in the
  plan or this model.
- **Corporate income tax, VAT/sales tax beyond the 5% reserve, payment
  processing beyond the store fee, currency movement, and equipment.** The 5%
  reserve is a planning haircut, not a tax return.
- **Paid user acquisition.** Marketing is organic/SEO/content only. The plan
  says paid UA is unfavorable at $5+ CPI and 3% conversion; this model does not
  assume it. If paid UA is added, add its cash cost and its conversion lift
  explicitly; do not hide it in marketing.

### 9.2 What is estimated, and what would change it

- **Content costs** are T3.9 estimates, not vendor quotes. A 30% change in
  contractor rates moves the 24-month base by about $31k (T3.9 §7.5). A
  founder-led cadence lowers cash but consumes 30–80 hours/month in months
  1–12; the model does not assume free founder content.
- **Non-content costs** are the plan's estimates, not quotes. DSP/dev,
  hosting/support, marketing, and tools could each move by 25–50%.
- **Conversion, renewal, and installs** are assumptions, not measured results.
  The plan's 3%/50% and 2%/40% are planning cases. The sensitivity table shows
  how much they matter.
- **Store fee** assumes the 15% small-business rate. At 30%, net per Pro is
  $45.89 and break-even rises to ~1,699 Pro; the cash need also rises.
- **Refunds/tax** assumes a 5% reserve. A higher refund rate or sales-tax
  obligation reduces net revenue proportionally.
- **Legal review** assumes $6k in month 0. The plan's range is $5–10k; the
  difference is $1k–$4k of cash need.
- **Content high case** is ~$175k of cash need at base demand, versus ~$120k
  base. That is the largest single cost risk in the model.

### 9.3 This is a planning tool, not a forecast

The model does not predict that 7,500 people will install in Year 1, that 3%
will pay, that 50% will renew, or that contractors will charge T3.9 rates. It
tests whether the plan's own assumptions can fund the plan's own cost base. If
the assumptions are wrong, the sensitivity table shows the range. No market
research, competitor data, or invented benchmark is used. Every number is
either from the plan, from T3.9, or is a clearly labeled model assumption.

The model also does not add a network, analytics, cloud, or account surface to
the app. It is a docs-and-stdlib-script deliverable. The app remains local-only.

## 10. Reproduce the numbers

From the repository root:

```powershell
python tool/finance/model.py              # human-readable summary
python tool/finance/model.py --markdown   # Markdown tables used in this doc
python tool/finance/model.py --json       # full month 0-36 schedule
python tool/finance/test_model.py         # 20 stdlib-only tests
```

The script imports only the Python standard library and has no dependency on
the Flutter app. It requires Python 3.10+ (for `dataclasses` and the `X | Y`
type syntax). It is deterministic: running it twice produces identical output.
The test suite checks the retention arithmetic, the T3.9 content totals, the
base and downside cash troughs, the break-even counts, the sensitivity ranking,
and deterministic output.

The docs-only change was verified with:

```powershell
git diff --check
python tool/finance/test_model.py
```

The Flutter suite was not run because no app code changed.

## 11. References

- [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md), §11.1
  (pricing), §11.3 (base case P&L and cash model), §11.4 (acquisition), §11.6
  (funding and legal gate).
- [`CONTENT_CALENDAR.md`](CONTENT_CALENDAR.md), §4 (cost model), §4.5
  (24-month totals), §5 (revenue sanity check), §6 (subscription/piece-pack
  gate), §7.2 (assumptions).
- [`LAUNCH_PIECES.md`](LAUNCH_PIECES.md), launch inventory and legal questions.
- [`../tool/finance/model.py`](../tool/finance/model.py), the executable model.
- [`../tool/finance/test_model.py`](../tool/finance/test_model.py), the tests.
