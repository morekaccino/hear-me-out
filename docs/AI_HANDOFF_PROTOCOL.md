# AI Handoff Protocol

> **Status:** Process contract for agents and humans working on Hear Me Out.
> Plane is the source of truth for product direction, work breakdown, decisions,
> risks, and status. This document explains how to read and update that source;
> it is not a second source of truth. When it disagrees with
> [`PLANE.md`](PLANE.md), Plane, or a newer decision record, the newer source
> wins and this document is corrected.

This protocol is written for a manager agent, implementation agents, independent
reviewers, and the human owner. It applies to code, content, docs, research, and
process work.

---

## 1. Read order

Read in this order before changing code, content, or a decision. Do not start
from the codebase alone.

| Order | Source | What it is for |
|---:|---|---|
| 1 | [`D0.1 — START HERE`](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/3bc42073-d36c-48df-b7bc-27ad89338ac7) | Charter, context-document index, project conventions, and current status. |
| 2 | `D0.2`–`D0.5` in Plane | Strategy and executive summary (`D0.2`), current-state audit and evidence (`D0.3`), target user and V1 scope (`D0.4`), and the assessment contract and spike (`D0.5`). These constrain what the ticket is allowed to build. |
| 3 | [`D0.13 — Glossary, Naming & AI Operating Manual`](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/de8d99d5-8da5-4acf-8926-e139c7527a2d) | Shared definitions, naming rules, and the Plane-side operating manual for future agents. |
| 4 | The current cycle in Plane | What is scheduled now, the cycle focus, and what is explicitly out of scope for this cycle. Open the Cycles view; do not assume the cycle from an old doc. |
| 5 | [`AGENTS.md`](../AGENTS.md) | Repository rules, commands, architecture map, protected behavior, and the last verified project state. |
| 6 | [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) | Layers, dependency direction, data flow, and invariants of the code that exists. |
| 7 | The ticket and its relations | Purpose, scope, acceptance criteria, comments, owner, module, cycle, labels, and `blocked_by` / `blocking`. |
| 8 | The relevant local docs | The approved plan, design, sound, learning algorithm, content guides, corpus docs, retention rules, and decision records for the area you will touch. |

Useful starting points for step 8:

- [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md) — approved v3.1 plan.
- [`ASSUMPTION_TRACKER.md`](ASSUMPTION_TRACKER.md) — the beliefs the plan
  depends on, the weakest-first tests, and the experiment log.
- [`DESIGN.md`](DESIGN.md), [`SOUND.md`](SOUND.md), and
  [`../LEARNING_ALGORITHM.md`](../LEARNING_ALGORITHM.md) — user-facing behavior.
- [`CONTENT_AUTHORING.md`](CONTENT_AUTHORING.md),
  [`CONTENT_CALENDAR.md`](CONTENT_CALENDAR.md),
  [`LAUNCH_PIECES.md`](LAUNCH_PIECES.md),
  [`FOUNDATION_ARRANGEMENTS.md`](FOUNDATION_ARRANGEMENTS.md), and
  [`RETURNER_ARRANGEMENTS.md`](RETURNER_ARRANGEMENTS.md) — content work.
- [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md),
  [`CORPUS_CONSENT.md`](CORPUS_CONSENT.md),
  [`CORPUS_LABELING.md`](CORPUS_LABELING.md), and
  [`LATENCY_RIG.md`](LATENCY_RIG.md) — assessment evidence.
- [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md) — the only
  usage log.
- [`decisions/`](decisions/) — accepted decision records.

### Conflict rules

1. **Plane wins** over local notes, old docs, chat, and this protocol.
2. The local plan is `docs/TRANSFORMATION_PLAN_FINAL.md`; Plane mirrors it. If
   the plan and Plane diverge, update both and record the reason in `T9.2`.
3. The **code and tests are the truth about what is shipped**. A doc that
   describes an unbuilt feature as shipped is wrong; fix the doc, do not treat
   the claim as evidence.
4. A ticket that contradicts a settled decision is not permission to reopen the
   decision. Stop, cite the decision, and ask the manager for a new decision
   record.
5. If two sources disagree and neither is authoritative, ask the manager. Do not
   silently choose the interpretation that is easiest to implement.

---

## 2. Roles and boundaries

| Role | Owns | Must not |
|---|---|---|
| **Human owner** | Product direction, funding/legal/pricing calls, human-only evidence (playtests, recordings, corpus takes, hardware checks), and final acceptance. | Delegate judgement to an agent where the evidence must be human. |
| **Manager** | Plane state, ticket scope and acceptance criteria, cycle/module assignments, the dependency graph, work distribution, review coordination, and merge/release decisions. | Invent implementation evidence or edit an author's branch. |
| **Implementation agent** | One ticket, one branch/worktree, the smallest correct change, tests/docs, verification, the PR, and an honest evidence report. | Merge the PR, edit another author's branch, invent acceptance criteria, or claim evidence it did not produce. |
| **Independent reviewer** | A read-only review in a separate worktree, findings by severity, and a verdict. | Edit or push to the author's branch, merge, or rewrite the ticket. |

### Branch → PR → review → fix → merge

```text
Plane ticket (Ready)
  → branch/worktree t#.#-slug from origin/year-long-rewrite
  → commits (Conventional Commit, suffix "(T#.#)")
  → rebase on origin/year-long-rewrite
  → push + PR (base year-long-rewrite)
  → independent review (separate worktree)
  → author fixes blocking findings on the same branch
  → re-review
  → manager or human owner merges
  → Plane ticket moves to Done with evidence
```

Rules:

- **One ticket, one branch, one PR.** Do not bundle unrelated tickets.
- **Implementers do not merge.** The implementation agent opens the PR and
  stops there. The manager or human owner owns the merge.
- **Reviewers do not edit the author's branch.** A reviewer works in
  `review-t#.#`, leaves findings in `.review-findings.md` and on the PR, and
  gives one of: `APPROVE`, `REQUEST CHANGES`, or `BLOCKED`.
- Review findings are labeled **blocking** or **non-blocking**, with a file and
  line reference and a concrete required change. Blocking findings must be
  fixed and re-reviewed; non-blocking findings may be deferred only with a
  reason.
- Never force-push a branch that someone else is reviewing. Rebase only your
  own ticket branch, and tell the reviewer when the head commit changes.

### Tooling conventions

| Concern | Convention |
|---|---|
| Agent harness | OpenCode. |
| Manager channel | `hc send <manager> "DONE T#.# PR #n <summary>"` or `hc send <manager> "BLOCKED T#.# <reason and what you tried>"`, where `<manager>` is the terminal address named in your handoff brief (currently `t1z`). |
| Branch | `t#.#-slug`, cut from `origin/year-long-rewrite`. |
| Implementation worktree | `../t#.#-slug`. |
| Review worktree | `../review-t#.#`, detached at the PR head. |
| Plane access | Plane MCP (`opencode mcp list` must show `plane connected`). |
| PR tool | `gh pr create --base year-long-rewrite` and `gh pr view`. |
| Local-only files | `.ticket-brief.md`, `.ticket-report.md`, and `.review-findings.md` stay uncommitted unless a ticket says otherwise. |

The manager may reserve Plane state. When the handoff brief says "do not edit
Plane" or "the manager owns ticket state," the agent reports status and evidence
through `.ticket-report.md` and `hc send`; the manager performs the state
transitions. Otherwise the implementing agent updates its own ticket as
described below.

The manager owns the `T9.2` decision log and the `T9.1` risk register. The
implementing agent supplies the exact entry text, links, and evidence. It edits
those logs only when the handoff brief explicitly delegates Plane updates;
otherwise the manager applies the entry.

---

## 3. Before work

1. **Read the ticket's acceptance criteria**, scope, comments, parent epic,
   module, cycle, and labels. If the acceptance criteria are missing or cannot
   be tested, stop and ask the manager before writing code.
2. **Check relations.** Open `blocked_by` and `blocking`. Do not start a ticket
   with an unresolved blocker. Do not work around a gate by starting downstream
   work.
3. **Move the ticket to In Progress** (or ask the manager to do it when Plane is
   reserved). A ticket should not be In Progress in more than one worktree.
4. **Record assumptions** in the ticket comment or `.ticket-report.md`:
   interpretation of the ticket, expected files, verification plan, and anything
   explicitly out of scope. If you had to choose between two readings, say which
   one you chose and why.
5. **Create or enter the branch/worktree.** Start from a fresh base:

   ```powershell
   git fetch origin
   git worktree add ../t#.#-slug -b t#.#-slug origin/year-long-rewrite
   ```

   Reuse the assigned worktree instead of creating a second one for the same
   ticket.
6. **Map the ticket to the plan.** Know which plan phase and section it serves
   and which decision records constrain it. If the ticket has no traceable link
   to the plan, ask the manager before expanding scope.
7. **Re-read the relevant docs and code** before editing. Do not infer behavior
   from an old summary.

### Ambiguous or conflicting tickets

- **Missing or untestable acceptance criteria:** ask the manager with concrete
  options. Do not invent criteria to make the work closeable.
- **Conflict with a settled decision:** stop and cite the decision. A new
  decision record is required before the behavior changes. Do not relabel the
  old decision as "outdated" in a PR.
- **Conflict between the ticket and the plan or code:** report both readings to
  the manager. If the work must continue while waiting, choose the smallest
  reversible interpretation, record it as an assumption, and flag it in the
  final report.
- **New scope discovered during work:** create a follow-up ticket through the
  manager; do not silently expand the current ticket or PR.
- **A decision is genuinely needed:** write a decision record using the format
  in section 5 and send the proposed `T9.2` entry to the manager (section 2).

---

## 4. After work

1. **Review your own diff** before committing. Remove debug code, unrelated
   formatting, generated files, secrets, and local-only files.
2. **Run the required checks.** Use the ticket's commands plus the repository
   defaults:
   - Docs-only: `git diff --check` and a relative-link check.
   - App code: `flutter pub get` when dependencies changed, `flutter analyze`,
     `flutter test`, and `flutter build web --release`.
   - Content/audio/tooling: the check named in the ticket and in the relevant
     guide.
   - Device, microphone, corpus, and recording evidence only if it actually
     happened. Otherwise write "not run" and say what is still pending.
3. **Update the docs** that the change invalidates: `AGENTS.md` for a rule,
   command, storage format, or verification step; `ARCHITECTURE.md` for a layer
   or invariant; `DESIGN.md` for user-facing behavior; a decision record for a
   decision; the README docs index for a new doc; and
   [`ASSUMPTION_TRACKER.md`](ASSUMPTION_TRACKER.md) when an experiment changes
   an assumption or its confidence.
4. **Commit** with a Conventional Commit message ending in the ticket ID:

   ```text
   docs: add the AI handoff protocol (T9.6)
   feat: propagate AttemptOutcome tri-state (T2.3)
   ```

5. **Rebase on the current base before opening the PR:**

   ```powershell
   git fetch origin
   git rebase origin/year-long-rewrite
   ```

   Resolve conflicts, rerun the checks, and confirm the branch still contains
   only this ticket's work.
6. **Push and open the PR** against `year-long-rewrite`. The body must contain:
   - the Plane ticket (`T#.#` and `HEARM-n` where available),
   - a short summary,
   - files changed,
   - verification commands and real results,
   - the acceptance-criteria checklist,
   - known limitations and out-of-scope work,
   - the line `Do not merge.`

7. **Comment on the ticket** with files, commands, results, PR link, and
   device/mic or human evidence if relevant. Real output, not a summary that
   hides a failure.
8. **Move the ticket to In Review when the PR opens.** Move it to **Done** only
   when every acceptance criterion is met and the manager or human owner has
   accepted the merge. If the brief reserves Plane state, report the same
   evidence to the manager instead.
9. **Send the `T9.2` (decision log) or `T9.1` (risk register) entry** when the
   work changes a decision or risk. Include the exact text, PR, and affected
   tickets; section 2 defines who edits Plane.
10. **Link the PR to the ticket.** The PR body names the ticket; the ticket
    comment names the PR; the Plane link field or a comment carries the URL.
11. **Write `.ticket-report.md`** in the worktree and report to the manager:

    ```powershell
    hc send <manager> "DONE T#.# PR #n <one-line summary>"
    hc send <manager> "BLOCKED T#.# <reason and what you tried>"
    ```

    `<manager>` is the terminal address named in your handoff brief (currently
    `t1z`). Do not commit `.ticket-brief.md`, `.ticket-report.md`,
    `.review-findings.md`, or `.opencode/`.

---

## 5. Evidence and truthfulness

The project's credibility depends on the difference between what was observed
and what was hoped for. These rules are not optional.

### Truth rules

- **No invented metrics.** Test counts, accuracy, timing, retention, coverage,
  device results, and user counts must come from a command, a fixture, or a
  named artifact. If you did not run it, say so.
- **No "validated" claim without evidence.** A synthetic test proves the code
  path, not real-world microphone accuracy. Hardware, corpus, and human evidence
  must be named and dated. Until then, write "not yet verified on hardware" or
  "pending corpus evidence."
- **No marking work Done without acceptance criteria.** Every criterion needs a
  check and a link to the evidence. Partial work stays In Review, moves to
  Blocked, or splits into a follow-up ticket. Never check a box for work that is
  not finished.
- **No claimed human playtests, recordings, corpus takes, or device checks that
  did not happen.** An agent may write the protocol, build the rig, and prepare
  the analysis, but only a named human session produces human evidence. Record
  who, when, on what device/instrument, and where the artifact lives. If that
  information does not exist, the evidence does not exist.
- **No reopening a settled decision without new evidence.** Add a new decision
  record that supersedes the old one and links the evidence. Never rewrite an
  accepted record's content in place.
- **No stale numbers presented as current.** Link the command or Plane view
  instead of copying a count. Counts in old tickets and docs are snapshots, not
  state.

### Evidence package

A reviewable ticket comment contains:

```text
Ticket: T#.# / HEARM-n
PR: #n <url>
Branch: t#.#-slug
Head: <sha>
Files: <paths>
Commands:
  <command> -> <real result>
Tests added: <names and what they prove>
Manual/device evidence: <who, when, device, artifact> or "not run"
Known limitations: <...>
Acceptance criteria: <checked list with evidence links>
```

Screenshots are required for user-facing UI changes. Device and microphone
evidence follows the checklist in `README.md` and `docs/DEVELOPMENT.md`.

### Decision-record format

Decision records live in `docs/decisions/` as
`NNNN-kebab-case-title.md`, numbered in order. Use the shape of the existing
records:

```markdown
# Decision NNNN — <short title>

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Superseded by NNNN
**Owner:** <human or role>
**Supersedes:** <record or "Nothing">
**Related:** T#.#, T9.2, <plan section>

## Context

What forced the decision, what was tried, and what evidence exists.

## Decision

The exact rule, behavior, or boundary that now applies. Include defaults and
gates, not just a direction.

## Consequences

What gets easier, what gets harder, what remains unverified, and who owns the
follow-up.

## Evidence

Commands, fixtures, device runs, corpus results, or links. If the evidence is
human-only, name the session; if it has not happened, say so.

## Follow-up

The Plane ticket and owner for anything this record does not close.
```

Accepted records are append-only history. To change one, create a new record
with the next number and set the old record's `Status:` line to
`Superseded by NNNN`; that status line is the only permitted edit to the old
record. Link both records from `T9.2`.

---

## 6. Resuming after an interruption

Resume from evidence, not memory. Assume another agent may have changed the
branch, the ticket, or the base while you were away.

### Find the current state

1. **Plane:** open the ticket. Read its state, acceptance criteria, latest
   comments, activity, relations, module, and cycle. Open `D0.1` if the project
   status is unclear.
2. **Git:** run

   ```powershell
   git worktree list
   git branch -a
   git status
   git log --oneline --decorate -20
   git log --oneline origin/year-long-rewrite..HEAD
   ```

   Confirm which worktree and branch actually hold the ticket's commits.
3. **PR:** search all states, not just open:

   ```powershell
   gh pr list --head t#.#-slug --state all
   gh pr view <n> --json state,headRefOid,reviewDecision,statusCheckRollup
   ```

   Read review comments and check failures, not only the PR title.
4. **Local artifacts:** read `.ticket-report.md`, `.review-findings.md`,
   `.ticket-brief.md`, and any notes in the worktree. They are uncommitted and
   may be the only record of what was already tried.
5. **Branch contents:** run `git diff --stat origin/year-long-rewrite...HEAD` and
   review the changed files. A commit message is not evidence that the work is
   complete.

### Reconcile a half-finished branch

- **Branch behind the base:** rebase on `origin/year-long-rewrite`, resolve
  conflicts, rerun the checks, and report the new head to the reviewer.
- **Commits but no PR:** verify the acceptance criteria and evidence, then open
  the PR. Do not restart the work from scratch.
- **PR open with findings:** fix blocking findings first, reply to each finding,
  push to the same branch, and request re-review. Do not open a second PR for the
  same ticket.
- **PR merged:** stop. Do not reopen or duplicate it. If something is missing,
  create a follow-up ticket through the manager.
- **Uncommitted or half-finished work:** inspect the diff before touching it.
  Preserve user work. Never run `git reset --hard`, `git clean -fd`, or discard
  changes without explicit approval.
- **Branch diverged from the ticket:** stop and ask the manager whether the
  ticket or the branch is authoritative. Do not quietly change the acceptance
  criteria to match the code.
- **A newer branch or PR for the same ticket exists:** continue that work
  instead of creating another branch. One ticket, one branch, one PR.

### Avoid duplicating work

Before starting or resuming:

- Search Plane for the ticket ID, title keywords, and plan section.
- Search git history: `git log --all --oneline --grep="T#.#"`.
- Search PRs in all states: `gh pr list --state all`.
- Check other worktrees: `git worktree list`.
- Check `T9.2` and `T9.1` for a decision or risk that already covers the change.

If the work already exists, continue it or report the duplicate to the manager.
Do not create a parallel implementation.

---

## 7. Current project map

This is the shape of the approved plan, not the ticket list. Plane is the live
plan; the roadmap table in
[`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md#13-roadmap) is the
canonical summary.

| Phase | Plan scope | Gate or outcome |
|---|---|---|
| **Phase 0** | Validation and assessment spike: corpus, latency/bleed rig, sample-clock and resampling fixes, tri-state matcher, pre-sale, concierge, legal, funding. | Spike pass (`T1.7`); 30+ pre-orders or 3% best-cell conversion; 60% concierge retention; legal go/no-go. [T9.8](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6f46f16c-bc01-4541-bbfa-cb7847d8a102) owns the live gate checklist; the phrase loop does not ship before `T1.7` passes. |
| **Phase 1** | Core product loop: `AttemptOutcome`, `PracticeSession`, piece/phrase models, phrase assessment, Today session, recording/A-B, technique, paywall. | 20 users, 3×/week for 4 weeks; false fail ≤10%; D7 ≥18%. |
| **Phase 2** | Expansion: MusicXML import, generic grade packs, teacher pilot, generator v2, opt-in aggregate analytics research. | D30 ≥10%; free→Pro ≥2%; three teacher pilots. |
| **Phase 3** | Months 6–12: technique video review, ear-to-hand, cloud/AI evaluation, piano research only. | Guitar retention proven; a separate assessment gate for any expansion. |
| **Phase 4** | Months 12+: social/recital, UGC, marketplace, optional piano. | 10k MAU, moderation/privacy plan, and a passing piano assessment spike. |

The shipped app is whatever the current branch contains, not what the plan says
it will become. [`AGENTS.md`](../AGENTS.md) records the last verified state. The
approved transformation is implemented ticket by ticket; do not describe planned
behavior as shipped.

### Feature gates that are easy to break

- **Phrase loop — decision
  [0001](decisions/0001-conditional-go.md).** Phase 1 engineering may proceed
  while the corpus gate is open, but the phrase loop and any content that
  depends on validated phrase scoring stay unreachable from main navigation
  behind a single feature switch. The switch has no production "on" path before
  `T1.7` passes. No doc, ticket, or UI may claim mic accuracy is validated. The
  Reading Lab and single-note features stay available.
- **Local-only retention — decision
  [0006](decisions/0006-local-retention-instrumentation.md).** No network,
  cloud, accounts, remote analytics, or third-party trackers. The only usage log
  is local, opt-in, bounded at 500 events, and eraseable. Logging is off by
  default; consent is on the first onboarding screen and in Profile. The app
  never uploads the log; export is a user clipboard action.
- **Recording privacy — decision
  [0002](decisions/0002-backup-exclusion-no-opt-in.md).** Recordings are
  excluded from cloud backup where the platform confirms it, with no V1 opt-in.
  The recording UI must consume `mediaBackupStatusProvider` and must not claim
  exclusion when the status is unconfirmed.

### Documentation map

| Area | Documents |
|---|---|
| Plane context | [D0.1 — START HERE](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/3bc42073-d36c-48df-b7bc-27ad89338ac7), [D0.13 — Glossary, Naming & AI Operating Manual](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/de8d99d5-8da5-4acf-8926-e139c7527a2d); D0.13 holds the definitions, naming rules, and Plane operating manual. |
| Process and project | [`../AGENTS.md`](../AGENTS.md), [`PLANE.md`](PLANE.md), [`PHASE_GATES.md`](PHASE_GATES.md), [`WEEKLY_REVIEW.md`](WEEKLY_REVIEW.md), [`../CONTRIBUTING.md`](../CONTRIBUTING.md), this protocol |
| Product and plan | [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md), [`DESIGN.md`](DESIGN.md) |
| Assumptions | [`ASSUMPTION_TRACKER.md`](ASSUMPTION_TRACKER.md) — beliefs, confidence, cheapest tests, and the experiment log (T9.5). |
| Code | [`ARCHITECTURE.md`](ARCHITECTURE.md), [`DEVELOPMENT.md`](DEVELOPMENT.md), [`../LEARNING_ALGORITHM.md`](../LEARNING_ALGORITHM.md) |
| Sound | [`SOUND.md`](SOUND.md) |
| Content | [`CONTENT_AUTHORING.md`](CONTENT_AUTHORING.md), [`CONTENT_CALENDAR.md`](CONTENT_CALENDAR.md), [`LAUNCH_PIECES.md`](LAUNCH_PIECES.md), [`FOUNDATION_ARRANGEMENTS.md`](FOUNDATION_ARRANGEMENTS.md), [`RETURNER_ARRANGEMENTS.md`](RETURNER_ARRANGEMENTS.md) |
| Assessment evidence | [`CORPUS_PROTOCOL.md`](CORPUS_PROTOCOL.md), [`CORPUS_CONSENT.md`](CORPUS_CONSENT.md), [`CORPUS_LABELING.md`](CORPUS_LABELING.md), [`LATENCY_RIG.md`](LATENCY_RIG.md) |
| Privacy | [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md), [`decisions/0002-backup-exclusion-no-opt-in.md`](decisions/0002-backup-exclusion-no-opt-in.md), [`decisions/0006-local-retention-instrumentation.md`](decisions/0006-local-retention-instrumentation.md) |
| Decisions | [`decisions/`](decisions/) |

---

## 8. Open decisions and blockers

Do not copy a decision or risk list into this protocol. The live lists are:

- **Decision log:** Plane `T9.2` —
  <https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/5b34fd51-46d1-4121-b029-5560688ff9b7>.
  Read it before proposing a change to a settled rule. Local decision records in
  [`decisions/`](decisions/) are the detailed evidence; `T9.2` is the index.
- **Risk register:** Plane `T9.1` —
  <https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/694298da-0c68-4ae6-a03a-e349cb125176>.
  Every risk needs an owner, a mitigation ticket, and a kill criterion.
- **Weekly review:** [`WEEKLY_REVIEW.md`](WEEKLY_REVIEW.md) — the 30-minute
  cadence that reconciles risks, decisions, cycle progress, blockers, and real
  metrics. It runs every week, including a busy build week.
- **Current cycle:** open the Cycles view in Plane for the active plan and
  blockers.
- **Dependencies:** open the ticket's Relations section for `blocked_by` and
  `blocking`.

### Human-owned tickets

Some acceptance criteria require people, hardware, or a business decision. An
agent may prepare the code, protocol, rig, analysis, or draft, but it must not
mark the ticket Done or claim the human evidence.

The current human-owned set includes:

`T1.1`, `T1.6`, `T1.7`, `T1.8`, `T1.9`, `T1.10`, `T1.11`, `T3.5`, `T3.8`,
`T4.5`, `T5.7`, `T6.1`, `T6.3`, `T6.8`, `T7.1`.

Treat this as a **principle, not a permanent exhaustive list**: a ticket is
human-owned when it needs participant recruitment, corpus recording, a beginner
playtest, a physical-device or backup check, legal review, pricing or funding
approval, a go/no-go decision, or any other evidence an agent cannot honestly
produce. When in doubt, ask the manager before closing it.

If a ticket is blocked:

1. Comment with the exact blocker and the decision or ticket needed to clear it.
2. Set `blocked_by` if the dependency is missing.
3. Move it to **Blocked** (or report it to the manager when Plane is reserved).
4. Do not start downstream work to fill the time.

---

## 9. One-screen checklist

**Before**

- Read `D0.1` → `D0.2`–`D0.5` → `D0.13` → current cycle → `AGENTS.md` →
  `ARCHITECTURE.md` → ticket and relations → relevant local docs.
- Acceptance criteria are present and testable; `blocked_by` is clear.
- Ticket is In Progress; branch `t#.#-slug` is cut from the current base.
- Assumptions and expected files are recorded.

**After**

- Self-reviewed diff; checks run with real output.
- Docs, decision record, or risk update written when needed.
- Commit message ends in `(T#.#)`; branch rebased on
  `origin/year-long-rewrite`.
- PR open against `year-long-rewrite` with ticket, summary, files, verification,
  acceptance-criteria checklist, and `Do not merge`.
- Ticket comment has evidence; state is In Review, or Done only after every
  criterion is met and the merge is accepted.
- PR is linked from the ticket; `.ticket-report.md` written; manager notified
  with `hc send <manager>` using the handoff address (currently `t1z`).

**Never**

- Merge the PR.
- Edit or push to another author's branch.
- Invent a metric, test result, ticket count, or user count.
- Claim a playtest, recording, corpus take, or device check that did not happen.
- Mark Done without acceptance criteria.
- Reopen a settled decision without new evidence.
- Use this protocol as a second source of truth; link Plane and the owning doc.
