# Weekly review

**Status:** Active process. Last updated 2026-11-06.
**Process owner:** The delivery manager. The decision owner signs the one
decision each review produces.
**Ticket:** [T9.7] — Set the weekly review cadence.
**Source of truth:** Plane. This page defines the cadence and the note; the live
risks, decisions, cycle scope, and status stay in Plane. If this page and Plane
disagree, Plane wins; correct this page and record the reason in [T9.2].

A 30-minute weekly review keeps the plan honest. It is where risks, decisions,
cycle progress, blockers, and real metrics are reconciled, and where the next
cycle and the [D0.1] status are updated. The review happens every week,
including a busy build week. A busy week changes the depth of the discussion,
not whether the review happens.

## 1. When and who

| Item | Rule |
|---|---|
| Cadence | 30 minutes, same slot each week. Default: the first working day of the week at 09:00 local. Set the recurring slot at the start of each cycle; move the slot only by moving the recurring booking. |
| Facilitator | One named role owns the agenda, the pre-read, the note, and the timebox. Default: the delivery manager, because that role owns Plane state. |
| Decision owner | One named role signs the single decision the review produces. Product, pricing, funding, legal, and gate decisions belong to the human owner; ticket, cycle, and process decisions belong to the manager. |
| Solo or distributed team | The facilitator and decision owner may be the same person, but both roles are named in the note. Use the async fallback below when there is no shared room. |
| Busy build week | Keep the slot. If the full 30 minutes is impossible, hold the minimum version in 15 minutes: lesson learned, blockers, actions, and one decision. Skipping is not the fallback. |

The review is not a status meeting. The note answers what changed, what it
means, who acts, and by when.

### Async fallback

Use this when the team is distributed or the week has no shared meeting slot. It
is the same review, written.

1. The facilitator posts the note skeleton on [D0.1] 24 hours before the slot,
   with the input links and the question for the decision owner.
2. Each attendee adds wins, risks, blockers, and metrics with sources by the
   slot. A claim without a source stays out of the note.
3. The facilitator fills the lesson learned and the action table, then posts the
   note within one working day.
4. The decision owner replies in Plane with the decision, or with the evidence
   needed before deciding. Silence is not a decision.
5. If the decision owner cannot reply within one working day, the review records
   the decision as open, with an owner and a date. The next review starts there.

For a solo team, the async fallback is a 30-minute writing block. Set a timer,
fill the note, and post it. The lesson learned and the next action are still
required.

## 2. Inputs (10 minutes before)

Read these before the review starts. The facilitator posts the note skeleton and
the links the working day before; each attendee adds evidence, not opinions.

| Input | Where | What to extract |
|---|---|---|
| Risk register | [T9.1] | New risks, changed likelihood or impact, closed risks, missing owners or mitigations, and kill criteria that moved. |
| Decision log | [T9.2] | Decisions due, decisions superseded, and decisions that need a new record. Do not reopen a settled decision without new evidence. |
| Current cycle | Plane Cycles view ([project]) | Shipped, in progress, not started, slipped, and the remaining capacity. |
| Blocked tickets | Plane ([project], state = Blocked) | The blocker, its owner, the dependency that clears it, and when it was last checked. |
| Phase gates | [PHASE_GATES.md](PHASE_GATES.md), [KILL_CRITERIA_DASHBOARD.md](KILL_CRITERIA_DASHBOARD.md), [T9.8] | Any threshold at risk, missing evidence, or gate decision due. |
| Assumption tracker | [T9.5] | Assumptions whose confidence moved, and the cheapest next test for each. |
| Content calendar | [CONTENT_CALENDAR.md](CONTENT_CALENDAR.md), [T3.9] | Only when the week touched content supply, cost, or cadence. |
| Financial model | [FINANCIAL_MODEL.md](FINANCIAL_MODEL.md), [T6.2] | Only when the week touched pricing, cost, cash, or the funding decision. |
| Metrics | The owning source (section 6) | The value, denominator, date, and link. If there is no data, write `no data` and name the missing instrument. |

Ten minutes is enough because the inputs are links, not a report. Do not rebuild
the plan in the pre-read.

## 3. Agenda (30 minutes)

| Minutes | Item | Output |
|---:|---|---|
| 5 | Wins and one lesson learned | One lesson learned, written in the template in section 5. Required even in a week with no shipped work. |
| 10 | Risks, decisions, and blockers | One owner and one next action per item. Update [T9.1] and [T9.2]. |
| 5 | Cycle progress against the plan | What shipped, what slipped, what was learned. Update the current cycle and draft the next. |
| 5 | Metrics and assumption changes | Each metric with a value, denominator, source, and confidence up, down, or unchanged, with evidence. Update [T9.5]. |
| 5 | Next cycle and START HERE, plus one decision | The next cycle's committed scope, the [D0.1] status change, and one recorded decision. |

Rules for the facilitator:

- Start with the lesson learned if the week was hard; do not let a good-news
  round use the time.
- Keep each risk, blocker, and decision to one owner and one date.
- If discussion runs over, cut the discussion, not the lesson learned or the
  actions. Park the rest in a ticket.
- End by reading the actions aloud. An action without an owner and a date is not
  an action.

"One decision" means exactly that: record one decision that changes what happens
next, or record "no change" with the evidence that supports it. "No change" is a
decision only when it is recorded in [T9.2].

## 4. Outputs (recorded in Plane)

The review is not finished until every output below exists in Plane.

| Output | Where | Done when |
|---|---|---|
| Risk changes | [T9.1] | Each new or changed risk has likelihood, impact, owner, mitigation ticket, and a next-action date. |
| Decision | [T9.2] | The decision has context, alternatives considered, the decision, consequences, date, and owner. Append; never rewrite an accepted record. |
| Cycle and START HERE status | Current cycle and [D0.1] | The current cycle's remaining scope is accurate; the next cycle's draft scope and the [D0.1] status reflect the review. |
| Lesson learned | Review note in Plane | The five fields in the lesson template below are filled. |
| Actions | Review note in Plane | Every action has an owner and a date; blockers name the clearing ticket. |
| Gate risk | Review note, [T9.2], and [T9.1] if the risk changed | A dated note names the gate, the threshold at risk, the evidence, the owner, and the date the gate decision will be taken. |

Post the review note as a comment on [D0.1]. It is the stable status hub and the
first page a new agent reads. Apply the risk, decision, and cycle changes to
their owning tickets; do not keep a second local log. If Plane state is reserved,
the facilitator sends the note to the manager, who posts it.

## 5. Templates

### Review note template

Copy this block into a Plane comment and fill every field. Delete only a field
that truly does not apply, and say why.

```markdown
# Weekly review — YYYY-MM-DD

- **Date:** YYYY-MM-DD
- **Attendees:** names or roles
- **Facilitator:** role
- **Decision owner:** role
- **Cycle:** C# (YYYY-MM-DD → YYYY-MM-DD)

## Wins

- ...

## Lesson learned

- **Expected:**
- **Happened:**
- **Why:**
- **Change next time:**
- **Owner / ticket:**

## Risks

- **T9.1:** <risk> — likelihood: low/medium/high — impact: low/medium/high —
  owner: <role> — mitigation: <ticket> — next action: <action> by YYYY-MM-DD.

## Decisions

- **T9.2:** <decision> — context: <why now> — alternatives: <what else> —
  consequences: <what changes> — owner: <role> — date: YYYY-MM-DD.

## Blockers

- <ticket> — blocked by <ticket or decision> — owner: <role> — next check:
  YYYY-MM-DD.

## Metrics

| Metric | Value | Denominator | Date | Source | Confidence |
|---|---:|---:|---|---|---|
| ... | ... | ... | YYYY-MM-DD | <link> | up / down / unchanged |

## Next cycle

- **Committed:**
- **Slipped:**
- **Learned:**

## START HERE update

- **D0.1:** <status change, or "no change">

## Actions

| Action | Owner | Date | Ticket |
|---|---|---|---|
| ... | ... | YYYY-MM-DD | T#.# |
```

If a section has no change, write `no change`; do not leave it blank.

### Lesson learned (required)

Every review records one lesson learned, including a week with no shipped work.

```markdown
- **Expected:**
- **Happened:**
- **Why:**
- **Change next time:**
- **Owner / ticket:**
```

A lesson learned that ends with "be more careful" is not a lesson. Name the
change, the owner, and the ticket that carries it.

### Gate at risk

Use this line in the review note when a [T9.8] threshold is at risk:

```text
Phase # gate — at risk: <threshold> — evidence: <link> — owner: <role> — decision due: YYYY-MM-DD
```

A gate at risk is still open. It needs evidence, a date, and an owner, not
reassurance.

## 6. Metrics: real numbers only

Every number in the review comes from a named source and states its denominator
and date. A number without a source is an opinion.

| Question | Metric | Source |
|---|---|---|
| Is the cycle moving? | Work items done, in progress, and blocked in the current cycle | Plane cycle view ([project]) |
| Is the loop honest? | Gate thresholds and evidence for the current phase | [PHASE_GATES.md](PHASE_GATES.md), [KILL_CRITERIA_DASHBOARD.md](KILL_CRITERIA_DASHBOARD.md), [T9.8] |
| Do users return? | Pilot cohort retention and session frequency | [T5.7], [RETENTION_INSTRUMENTATION.md](RETENTION_INSTRUMENTATION.md) |
| Is demand real? | Pre-orders, best-cell conversion, and concierge retention | [T1.8], [T1.9] |
| Does the money work? | Price, cost per piece, and the cash path | [FINANCIAL_MODEL.md](FINANCIAL_MODEL.md), [T6.2] |
| Can content keep up? | Pieces and etudes shipped against the calendar | [CONTENT_CALENDAR.md](CONTENT_CALENDAR.md), [T3.9] |

The local opt-in usage log is diagnostic. It is not a retention baseline; the
pilot cohort is. Test counts, green suites, and merged PRs are delivery
evidence, not user or learning evidence.

## 7. Anti-patterns

| Anti-pattern | What it looks like | Do instead |
|---|---|---|
| Skipping during a build week | "We are too busy to review." | Keep the slot. Hold the 15-minute minimum: lesson learned, blockers, actions, and one decision. |
| Status theater | Reading updates for 30 minutes with no decision, owner, or date. | Start from the lesson learned and end with one decision and dated actions. |
| Feature work to hit a metric | Adding a surface, notification, or content to move a number that a gate says is broken. | Fix the loop or pivot. A metric is not a reason to expand scope. |
| Invented metrics | A number with no source, denominator, or date. | Write `no data`, name the missing instrument, and assign the measurement. |
| Reopening a settled decision | Arguing an accepted decision again without new evidence. | Add a new [T9.2] record with the evidence and say why the old decision no longer holds. |
| Review with no owner or date | Actions like "improve onboarding" or "look into retention". | Name one owner, one date, and the ticket that carries the work. |

## 8. Checklist

Before the review:

- [ ] The slot is booked (30 minutes; 15-minute minimum in a busy week).
- [ ] The facilitator and decision owner are named.
- [ ] [T9.1], [T9.2], [T9.5], [T9.8], the current cycle, and blocked tickets are
      open.
- [ ] The note skeleton and links are posted.

During the review:

- [ ] One lesson learned is written.
- [ ] Every risk, blocker, and decision has one owner and one date.
- [ ] Every metric has a value, denominator, source, and date.
- [ ] One decision is recorded, or "no change" is recorded with evidence.

After the review:

- [ ] [T9.1] and [T9.2] are updated.
- [ ] The current cycle and the next cycle are updated.
- [ ] The [D0.1] status is updated.
- [ ] The note is posted in Plane.
- [ ] Gate-at-risk lines are recorded where they belong.

[D0.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/3bc42073-d36c-48df-b7bc-27ad89338ac7
[project]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/
[T1.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/b1220c5a-dc70-4fac-913d-9b7ab08e8d99
[T1.9]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/1d96beab-8dc4-490a-9d01-9f4fb80c748e
[T3.9]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/a8fef7ce-bf3e-49cd-ab49-1189ddda454f
[T5.7]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/e41c7cb2-918d-41bf-afc4-b97d7e7005cb
[T6.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/9f35d8f8-5d33-4f88-ad04-a4d0c2f8b908
[T9.1]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/694298da-0c68-4ae6-a03a-e349cb125176
[T9.2]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/5b34fd51-46d1-4121-b029-5560688ff9b7
[T9.5]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/a18e2eeb-b762-44cf-b3a1-8e792bcb3be3
[T9.7]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/e995d3ac-d6bb-4203-82ad-772a15d461d6
[T9.8]: https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6f46f16c-bc01-4541-bbfa-cb7847d8a102
