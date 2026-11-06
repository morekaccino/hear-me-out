# Plane Project Manual

This is the operating manual for AI agents and humans working on Hear Me Out.
Plane is the **source of truth** for product direction, work breakdown, research,
decisions, risks, and delivery status.

---

## 1. Project identity

| Item | Value |
|---|---|
| Plane instance | https://plane.mrkazemi.com |
| Workspace | `hear-me-out` |
| Project | **Hear Me Out — Guitar Practice OS** |
| Project ID | `8c4e095a-f411-4e2d-8f92-f558b6701780` |
| Project identifier | `HEARM` |
| Project URL | https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780 |
| START HERE ticket | `D0.1` — `3bc42073-d36c-48df-b7bc-27ad89338ac7` |
| START HERE URL | https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/3bc42073-d36c-48df-b7bc-27ad89338ac7 |
| Local canonical plan | `docs/TRANSFORMATION_PLAN_FINAL.md` |

The project currently has 99 work items, 10 modules, 10 cycles, 48 labels, and
8 workflow states (as of 2026-11-04). Counts will grow; trust Plane, not this
document, for the current state.

---

## 2. MCP access

Plane is exposed as an MCP server named **`plane`** using the local stdio
transport. The client is the Community-Edition build
(`plane-mcp-server-ce==0.4.0`), wrapped by `tools/plane_mcp_ce/`:

```json
{
  "command": "uvx",
  "args": [
    "--from",
    "./tools/plane_mcp_ce",
    "plane-mcp-server-ce-fixed",
    "stdio"
  ],
  "env": {
    "PLANE_API_KEY": "<workspace-scoped key>",
    "PLANE_WORKSPACE_SLUG": "hear-me-out",
    "PLANE_BASE_URL": "https://plane.mrkazemi.com",
    "PLANE_MCP_EDITION": "community"
  }
}
```

Why this build:

- The instance is self-hosted **Plane Community 1.4.2**. The upstream
  `plane-mcp-server` 0.3.x calls Cloud-only routes (`/dependencies/`, `/api/v2`
  pages, `/initiatives/`), which return 404 here.
- `plane-mcp-server-ce` targets the Community API and, with
  `PLANE_MCP_EDITION=community`, advertises only the 82 tools whose routes
  exist. Unavailable tools are hidden instead of failing later.
- Plane 1.4.2 returns relations as `{"project_id": ..., "issue_id": ...}`
  objects while `plane-sdk` expects plain IDs. `tools/plane_mcp_ce/` normalizes
  that one payload, then runs the stock server. Remove the wrapper only after
  upstream fixes the model.

Run clients from the repository root so the relative `--from` path resolves.
The wrapper is pinned to `plane-mcp-server-ce==0.4.0` in
`tools/plane_mcp_ce/pyproject.toml`; bump both together.

Client configuration files in this repo:

| Client | MCP config | Instruction file |
|---|---|---|
| Claude Code / Codex / generic MCP | `.mcp.json` (`mcpServers.plane`) | `AGENTS.md`, `CLAUDE.md` |
| OpenCode | `opencode.json` (verified with `opencode mcp list` → `plane connected`) | `AGENTS.md` |
| VS Code / Copilot | `.vscode/mcp.json` (`servers.plane`) | `.github/copilot-instructions.md` |
| Cursor | `.cursor/mcp.json` (`mcpServers.plane`) | `AGENTS.md` |
| Gemini CLI | `.gemini/settings.json` (`mcpServers.plane`) | `GEMINI.md`, `AGENTS.md` |

Verify access:

```powershell
opencode mcp list
```

Expected:

```text
✓ arxiv   connected
✓ notion  connected
✓ plane   connected
```

If `plane` is missing, check that you are running from the repository root (not
a parent directory) and that the client has reloaded its MCP configuration.

The API key is workspace-scoped. Do not paste it into Plane tickets, chat
messages, logs, screenshots, or public issues. If it is exposed, rotate it in
Plane.

---

## 3. Read order for a new agent

[`AI_HANDOFF_PROTOCOL.md`](AI_HANDOFF_PROTOCOL.md) is the process contract for
roles, branches, pull requests, reviews, evidence, and resuming interrupted work.
Read it with this section; it links back here for Plane mechanics.

1. **`D0.1 — START HERE`** in Plane.
2. **`D0.2` — Strategy & executive summary.**
3. **`D0.3` — Current-state audit & evidence.**
4. **`D0.4` — Target user, positioning, V1 scope.**
5. **`D0.5` — Assessment contract & 3-week spike.**
6. The ticket for the work you are about to do.
7. The current cycle (`C0` on 2026-11-04).

Do not start from the codebase alone. The current code is still the 240-lesson
notation course; the approved transformation is planned but not implemented.
Read `AGENTS.md`, `LEARNING_ALGORITHM.md`, and the relevant `docs/` file before
changing code.

---

## 4. Project model

### 4.1 Workflow states

| State | Group | Meaning |
|---|---|---|
| Backlog | backlog | Captured, not scheduled |
| Ready | unstarted | Refined and ready to start |
| In Progress | started | Actively being worked |
| In Review | started | Implementation complete; awaiting review/QA |
| Validating | started | Experiment/spike/user test is running |
| Blocked | started | Cannot proceed until a named dependency is cleared |
| Done | completed | Acceptance criteria met and evidence recorded |
| Cancelled | cancelled | Deliberately dropped or superseded |

### 4.2 Labels

Labels are grouped under parent labels so the project stays filterable:

- **Area**: `area:assessment`, `area:audio`, `area:content`, `area:product`,
  `area:design`, `area:business`, `area:growth`, `area:research`,
  `area:platform`, `area:legal`.
- **Type**: `type:epic`, `type:feature`, `type:story`, `type:task`, `type:spike`,
  `type:bug`, `type:decision`, `type:risk`, `type:experiment`, `type:content`,
  `type:research`.
- **Phase**: `phase:0-validation`, `phase:1-core`, `phase:2-expansion`,
  `phase:3-scale`.
- **Risk**: `risk:high`, `risk:medium`, `risk:low`.
- **Workstream**: `ws:assessment-spike`, `ws:core-loop`,
  `ws:content-repertoire`, `ws:recording-performance`,
  `ws:onboarding-retention`, `ws:monetization-legal`, `ws:teacher-exam`,
  `ws:growth-distribution`.
- **Platform**: `platform:ios`, `platform:android`, `platform:web`,
  `platform:backend`, `platform:content-pipeline`, `platform:docs`.

Use the ticket type label **and** the `Type` label group; `type:epic`,
`type:spike`, `type:decision`, etc. are the practical work-item types on this
Plane build.

### 4.3 Modules (workstreams)

| Module | Purpose |
|---|---|
| `00 — Charter, Plan & AI Handoff` | Plan, audit, research, AI context |
| `01 — Assessment Spike & Corpus` | Mic/phrase assessment proof |
| `02 — Core Product Loop` | Piece/phrase model, Today, placement |
| `03 — Content & Repertoire` | 10 pieces, 60 etudes, recordings |
| `04 — Recording & Performance` | MediaStore, A/B, before/after |
| `05 — Onboarding & Retention` | First session, mastery map, reminders |
| `06 — Monetization, Legal & Funding` | Pre-sale, P&L, paywall, legal |
| `07 — Teacher & Exam Expansion` | LOIs, manual export, grade packs |
| `08 — Growth & Distribution` | Web test, ASO, content, community |
| `09 — Risks, Decisions & Research` | Risk register, decision log, research |

### 4.4 Cycles

| Cycle | Dates | Focus |
|---|---|---|
| C0 | 2026-11-04 → 2026-11-17 | Validation & assessment spike |
| C1 | 2026-11-18 → 2026-12-01 | Spike close, demand test, foundation |
| C2 | 2026-12-02 → 2026-12-15 | Core models & phrase assessment |
| C3 | 2026-12-16 → 2026-12-29 | Today loop & recording |
| C4 | 2026-12-30 → 2027-01-12 | Content batch 1 & paywall |
| C5 | 2027-01-13 → 2027-01-26 | Content batch 2 & private pilot |
| C6 | 2027-01-27 → 2027-02-09 | Learning pilot & beta launch |
| C7 | 2027-02-10 → 2027-02-23 | Phase 2 expansion |
| C8 | 2027-02-24 → 2027-03-09 | Teacher pilot & exam content |
| C9 | 2027-03-10 → 2027-03-23 | Scale research & next gate |

Every work item is assigned to one module and one cycle.

### 4.5 Ticket naming

| Prefix | Meaning |
|---|---|
| `E0`–`E9` | Epics |
| `D0.1`–`D0.13` | Context documents (plan, audit, research, manual) |
| `T#.#` | Delivery, risk, decision, or experiment ticket |
| `T1.7` | The hard assessment go/no-go gate |
| `T2.1` | The core domain model; blocked by T1.7 |
| `T9.1` | Risk register |
| `T9.2` | Decision log |

---

## 5. Critical path and gates

```text
T1.1–T1.5  →  T1.6  →  T1.7  →  T2.1
                                      ↓
                     T2.2 / T2.3 / T2.4 / T2.5
                                      ↓
                                   T2.6  →  T5.2  →  T6.4  →  T6.5
```

- **T1.7 is the hard gate.** No core product work before the assessment spike
  passes. If it fails, pivot to call-and-response, single-bar assessment, or a
  pure notation trainer.
- **T2.1 is blocked by T1.7.** Do not start the Piece/Phrase model early.
- **T1.11** (funding decision) is blocked by T1.8 (pre-sale), T1.9 (concierge),
  and T6.2 (P&L).
- **T3.2** (content validator) blocks arrangement and etude work.
- **T4.1 → T4.2 → T4.3/T4.4** is the recording chain.
- **T6.4** (paywall) is blocked by T4.4 (before/after card) and T3.8 (content QA).

Open a ticket's **Relations** section to see `blocked_by` and `blocking`. Do not
start a ticket with unresolved blockers.

---

## 6. How to work on a ticket

### Before coding

1. Read `AGENTS.md` and the relevant architecture/design doc.
2. Read the ticket's purpose, scope, and acceptance criteria.
3. Check `blocked_by`; if blocked, comment with the blocker and move to Blocked.
4. Move the ticket to **In Progress**.
5. If the ticket is missing or ambiguous, comment and ask; do not invent scope.

### After coding

1. Run the required checks:
   ```powershell
   cd flutter_app
   flutter analyze
   flutter test
   flutter build web --release
   ```
2. Add a comment with:
   - what changed,
   - files touched,
   - commands run and results,
   - device/mic testing if relevant,
   - known limitations.
3. Move to **Done** only when every acceptance criterion is met and evidence is
   in the ticket.
4. If the work changes a decision or risk, update `T9.2` (decision log) or
   `T9.1` (risk register).
5. If the work reveals new scope, create a new ticket under the correct epic,
   module, and cycle; do not silently expand the current ticket.

### If you are blocked

- Move the ticket to **Blocked**.
- Comment with the exact blocker and the ticket/decision needed.
- Add or update the `blocked_by` relation.
- Do not work around a gate by starting downstream tickets.

---

## 7. Source-of-truth rules

1. **Plane wins** over local notes, old docs, and chat.
2. The local canonical plan is `docs/TRANSFORMATION_PLAN_FINAL.md`; the Plane
   docs `D0.2`–`D0.12` mirror it. If they diverge, update both and record the
   reason in `T9.2`.
3. The current code is the **old** 240-lesson notation course. Do not describe
   planned features as shipped.
4. Never invent metrics, progress, or completion. Use the ticket's acceptance
   criteria and real command output.
5. Do not reopen a settled decision without new evidence. Add a new decision
   record instead.
6. Do not add social/cloud/AI/accounts to V1 without a new decision. The current
   plan explicitly excludes them.

---

## 8. Current phase and next action

**Phase 0 — Validation & Assessment Spike (C0).**

Start with:

1. `T1.1` — recruit the corpus.
2. `T1.2` — write the protocol/consent/labeling guide.
3. `T1.3` — fix sample-rate/channel handling and add sample-clock timestamps.
4. `T1.4` — build the latency/clock/bleed rig.
5. `T1.5` — implement onset detection, constrained alignment, tri-state.
6. `T1.6` — run the corpus and compute validity metrics.
7. `T1.7` — go/no-go decision.

In parallel: `T1.8` pre-sale, `T1.9` concierge, `T1.10` legal review, `T6.2`
P&L. Do not start `T2.1` before `T1.7` is Done.

---

## 9. Known Plane/API quirks on this self-hosted instance

- **Pages**, **Milestones**, **Work Item Types**, **Worklogs**, **count**, and
  **Initiatives** endpoints return 404. The plan is stored as rich context work
  items; types are labels. The CE build hides the tools that cannot work here.
- PQL filtering is unsupported on this edition. The server returns an explicit
  error; filter results client-side instead.
- Work item creation uses `/projects/{project_id}/issues/`.
- Relations use `/projects/{project_id}/work-items/{work_item_id}/relations/`
  with a trailing slash. Body: `{"relation_type": "blocked_by", "issues": ["<id>"]}`.
  The inverse `blocking` edge is created automatically. The CE build reads this
  route; the wrapper normalizes the `{project_id, issue_id}` items that Plane
  1.4.2 returns. Relations are read + create only — no delete route works here,
  so a wrong edge must be removed in the Plane UI.
- Cycle membership uses `/cycles/{cycle_id}/cycle-issues/` with a trailing
  slash. Body: `{"issues": ["<id>"]}`.
- Module membership uses `/modules/{module_id}/module-issues/` with a trailing
  slash. Body: `{"issues": ["<id>"]}`.
- Rate limits are real. Bulk operations should batch IDs and retry on HTTP 429
  with backoff. The helper scripts in `tools/` do this.
- The current project has `intake_view`, time tracking, cycle view, module view,
  page view, and issue types enabled at the project level, but the API surface
  above is what actually works.

---

## 10. Helper scripts

| Script | Purpose |
|---|---|
| `tools/plane_bootstrap.py` | Create the docs, epics, tickets, links, comments. Idempotent by name. |
| `tools/plane_relations.py` | Create the `blocked_by` graph. Skips existing edges. |
| `tools/plane_assign.py` | Assign tickets to modules/cycles. |
| `tools/plane_assign_missing.py` | Add only missing module/cycle memberships. |
| `tools/plane_mcp_ce/` | MCP wrapper: CE build plus the relation-payload fix. |

They read:

```powershell
$env:PLANE_API_KEY = "..."
$env:PLANE_BASE_URL = "https://plane.mrkazemi.com"
$env:PLANE_WORKSPACE = "hear-me-out"
$env:PLANE_PROJECT_ID = "8c4e095a-f411-4e2d-8f92-f558b6701780"
```

Run from the repository root with the Python environment that has `requests`.
The scripts are safe to rerun; they reuse existing tickets by name and skip
already-present relations/memberships.

---

## 11. Quick verification

```powershell
opencode mcp list
```

Must show `plane connected`. The server advertises 82 tools in Community mode.

Then confirm live data:

- `list_work_items` on the project returns 99 items.
- `list_work_item_relations` on `T6.8` returns 3 `blocked_by` IDs.
- `list_work_item_activities` on `D0.1` returns its history.

In Plane:

- `D0.1 — START HERE` opens and lists all context docs.
- C0 contains the assessment spike tickets.
- `T1.7` has a `blocked_by` relation to `T1.6`; `T2.1` is blocked by `T1.7`.
- Every ticket has a state, priority, assignee, labels, dates, module, cycle,
  and parent epic.

If any of these is false, fix the project before writing code.
