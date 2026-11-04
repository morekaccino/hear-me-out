#!/usr/bin/env python3
"""Bootstrap the Hear Me Out Plane project.

Reads the final transformation plan, creates the full work breakdown, cycles,
modules, labels, dependencies, links, and context documents.

Requires:
  PLANE_API_KEY
  PLANE_BASE_URL   (e.g. https://plane.mrkazemi.com)
  PLANE_WORKSPACE  (e.g. hear-me-out)
  PLANE_PROJECT_ID

The script is idempotent for work items: it matches existing items by name and
reuses them instead of creating duplicates.
"""
from __future__ import annotations

import html
import os
import re
import sys
import time
from pathlib import Path

import requests

BASE = os.environ["PLANE_BASE_URL"].rstrip("/")
WS = os.environ["PLANE_WORKSPACE"]
PID = os.environ["PLANE_PROJECT_ID"]
KEY = os.environ["PLANE_API_KEY"]
API = f"{BASE}/api/v1/workspaces/{WS}"
HEADERS = {"X-API-Key": KEY, "Content-Type": "application/json"}
USER_ID = "f0bc715c-3e5d-496f-858e-d4da87dcb4c2"  # Mohamad Kazemi
PLAN_PATH = Path(r"C:\Users\morekaccino\Codes\hear-me-out\docs\TRANSFORMATION_PLAN_FINAL.md")

STATE_IDS = {
    "Backlog": "ef4b833e-3e8c-45f7-85a9-83bd72ce450e",
    "Ready": "dc6df1b1-3903-43d3-bcd9-cc9936c7f612",
    "In Progress": "9f00ed5f-da97-4c55-b87a-99552d07f014",
    "In Review": "73182854-fd92-4752-8cce-5a0a3e59a750",
    "Blocked": "60904f45-0e20-4aae-a0fd-f6df65fb8ce9",
    "Validating": "c5cb6ccc-e64a-4e67-8fc5-48a2602d59ef",
    "Done": "c0bb1dd1-842b-4f6b-8575-55cc2ddec7aa",
    "Cancelled": "58baca9a-255a-4e7d-8978-6da1831d7433",
}

MODULE_IDS = {
    "M0": "b4a9fe22-ac8e-4122-bf79-db50ce1a2de9",
    "M1": "46bc8930-f848-4d69-80e1-6deabeeb8b96",
    "M2": "4603b836-a232-4422-9fc4-10a1961f415a",
    "M3": "c6488435-17f5-4bb0-9203-1e2977ea2b8c",
    "M4": "ff565d71-a6e9-4365-af3c-1394ba51281c",
    "M5": "2fbc9546-a6ed-4a42-b3d2-8b5d5af999fb",
    "M6": "cc71dfd7-d070-408b-8542-149690178bfe",
    "M7": "51f70f91-9ecf-4b70-9b7b-80661a0f9cb5",
    "M8": "b8347d79-26be-4478-9277-69505f464ba6",
    "M9": "15dd0140-e4d6-4135-a5b5-51dac6ab7271",
}

CYCLE_IDS = {
    "C0": "4aa0d11d-cbbe-4235-b11f-834d93b088bc",
    "C1": "f59b1fa1-41bf-4e67-a8a4-a53e97f2621b",
    "C2": "26eec9a8-ef87-43c2-a6a7-fe84aa6c9605",
    "C3": "da255e52-53ac-4030-bc65-1694f5899bc7",
    "C4": "e0f80672-fa2a-4087-9936-f6a7459e3ff5",
    "C5": "769ae549-3fde-4dc3-a108-cda2113d7837",
    "C6": "ece84e6c-df5e-47e4-9a01-0fbc1e624fac",
    "C7": "ded75a2f-8b3b-46a7-96c5-471129b68783",
    "C8": "fad5f41d-48f4-4265-8168-4fde0a22a3f4",
    "C9": "ee982361-cc24-4818-a050-649688157aaf",
}

session = requests.Session()
session.headers.update(HEADERS)


def api(method: str, path: str, json_body=None, retries: int = 6):
    url = path if path.startswith("http") else API + path
    for attempt in range(retries):
        r = session.request(method, url, json=json_body, timeout=60)
        if r.status_code == 429:
            wait = 5 * (attempt + 1)
            print(f"  429 rate limit; sleeping {wait}s", flush=True)
            time.sleep(wait)
            continue
        if r.status_code >= 400:
            print(f"  HTTP {r.status_code} {method} {path}: {r.text[:300]}", flush=True)
        return r
    return r


def list_all(path: str):
    results = []
    cursor = None
    while True:
        sep = "&" if "?" in path else "?"
        url = path + (f"{sep}cursor={cursor}" if cursor else "")
        r = api("GET", url)
        if r.status_code >= 400:
            break
        data = r.json()
        results.extend(data.get("results", []))
        if not data.get("next_page_results") or not data.get("next_cursor"):
            break
        cursor = data["next_cursor"]
    return results


# ---------------------------------------------------------------------------
# Markdown -> HTML (deliberately small; good enough for Plane's editor)
# ---------------------------------------------------------------------------

def inline(s: str) -> str:
    s = html.escape(s)
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"`(.+?)`", r"<code>\1</code>", s)
    s = re.sub(r"\[(.+?)\]\((.+?)\)", r'<a href="\2">\1</a>', s)
    return s


def md_to_html(md: str) -> str:
    lines = md.splitlines()
    out: list[str] = []
    in_ul = False
    in_code = False
    in_table = False

    def close_ul():
        nonlocal in_ul
        if in_ul:
            out.append("</ul>")
            in_ul = False

    def close_table():
        nonlocal in_table
        if in_table:
            out.append("</pre>")
            in_table = False

    for raw in lines:
        line = raw.rstrip()
        if line.startswith("```"):
            close_ul(); close_table()
            if in_code:
                out.append("</code></pre>")
                in_code = False
            else:
                out.append("<pre><code>")
                in_code = True
            continue
        if in_code:
            out.append(html.escape(raw))
            continue
        if not line.strip():
            close_ul(); close_table()
            continue
        if line.startswith("|"):
            close_ul()
            if not in_table:
                out.append('<pre style="white-space:pre-wrap">')
                in_table = True
            out.append(html.escape(line))
            continue
        close_table()
        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if m:
            close_ul()
            level = min(len(m.group(1)) + 1, 4)
            out.append(f"<h{level}>{inline(m.group(2))}</h{level}>")
            continue
        if line.startswith(("- ", "* ")):
            if not in_ul:
                out.append("<ul>")
                in_ul = True
            out.append(f"<li>{inline(line[2:])}</li>")
            continue
        if re.match(r"^\d+\.\s+", line):
            if not in_ul:
                out.append("<ul>")
                in_ul = True
            out.append(f"<li>{inline(re.sub(r'^\d+\.\s+', '', line))}</li>")
            continue
        close_ul()
        out.append(f"<p>{inline(line)}</p>")
    close_ul(); close_table()
    if in_code:
        out.append("</code></pre>")
    return "\n".join(out)


PLAN = PLAN_PATH.read_text(encoding="utf-8")


def section(prefix: str) -> str:
    """Return the markdown section beginning with the given heading prefix."""
    pattern = re.compile(rf"^## {re.escape(prefix)}.*?(?=^## |\Z)", re.M | re.S)
    m = pattern.search(PLAN)
    return m.group(0).strip() if m else ""


def doc_html(title: str, body_md: str, source: str = "TRANSFORMATION_PLAN_FINAL.md") -> str:
    return (
        f"<h2>{html.escape(title)}</h2>"
        + md_to_html(body_md)
        + f"<hr><p><strong>Local source:</strong> <code>{html.escape(str(PLAN_PATH))}</code></p>"
        + f"<p><strong>Document:</strong> {html.escape(source)}</p>"
    )


AUDIT_HTML = """
<h2>Current-state audit (evidence)</h2>
<p>Built from the actual generated course and code, not the README.</p>
<table>
<tr><th>Metric</th><th>Value</th></tr>
<tr><td>Lessons</td><td>240</td></tr>
<tr><td>Total prompts</td><td>3,984</td></tr>
<tr><td>Unique objectives</td><td>153</td></tr>
<tr><td>Multiple-choice / order</td><td>~54%</td></tr>
<tr><td>Note-play (mic)</td><td>15%</td></tr>
<tr><td>Repertoire objectives</td><td>0</td></tr>
<tr><td>Sight-reading objectives</td><td>0</td></tr>
<tr><td>Improvisation objectives</td><td>0</td></tr>
<tr><td>Technique prompts</td><td>22</td></tr>
</table>
<p><strong>Root cause:</strong> the unit of content is a lesson, not a performance. The path can be completed; the learner's relationship with music does not deepen.</p>
<p><strong>Assets to protect:</strong> FSRS-style scheduler, guitar-correct written-vs-sounding pitch, YIN mic detection, clean architecture, 224 passing tests, local-first privacy.</p>
<p><strong>What the learner experiences today:</strong> a 240-node linear path of identical locked notes; "Today" is just the next lesson; single-note naming/playing and multiple-choice theory; no piece, phrase, recording, performance, or teacher loop.</p>
"""


def task_html(summary: str, scope: list[str], acceptance: list[str], evidence: list[str] | None = None,
              blocked_by: list[str] | None = None, estimate: str | None = None) -> str:
    parts = [f"<h2>Purpose</h2><p>{inline(summary)}</p>"]
    if scope:
        parts.append("<h2>Scope</h2><ul>" + "".join(f"<li>{inline(x)}</li>" for x in scope) + "</ul>")
    if acceptance:
        parts.append("<h2>Acceptance criteria</h2><ul>" + "".join(f"<li>{inline(x)}</li>" for x in acceptance) + "</ul>")
    if evidence:
        parts.append("<h2>Evidence / context</h2><ul>" + "".join(f"<li>{inline(x)}</li>" for x in evidence) + "</ul>")
    if blocked_by:
        parts.append("<h2>Blocked by</h2><p>" + inline(", ".join(blocked_by)) + "</p>")
    if estimate:
        parts.append(f"<h2>Effort estimate</h2><p>{inline(estimate)}</p>")
    parts.append(f"<hr><p><strong>Local source:</strong> <code>{html.escape(str(PLAN_PATH))}</code></p>")
    return "".join(parts)


# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

EPICS = [
    {
        "key": "E0", "name": "00 — Project Charter, Master Plan & AI Handoff",
        "priority": "urgent", "state": "In Progress", "start": "2026-11-04", "target": "2026-11-06",
        "module": "M0", "cycle": "C0",
        "labels": ["type:epic", "area:product", "phase:0-validation", "ws:core-loop", "risk:low", "platform:docs"],
        "summary": "The single source of truth for the transformation. Every future AI or human starts here.",
        "scope": ["Store the approved v3.1 plan, audit, research, assessment contract, business model, roadmap, risks, and glossary in Plane.", "Explain how to use the project: states, labels, cycles, modules, dependencies, and decision log.", "Keep the plan and execution tickets linked so context is never lost."],
        "acceptance": ["A new AI can open this epic and find the full plan, current status, next actions, and the rules for updating the project.", "Every context document is a child of this epic.", "The project description points to the START HERE ticket."],
    },
    {
        "key": "E1", "name": "01 — Assessment Spike & Corpus",
        "priority": "urgent", "state": "In Progress", "start": "2026-11-04", "target": "2026-11-24",
        "module": "M1", "cycle": "C0",
        "labels": ["type:epic", "area:assessment", "phase:0-validation", "ws:assessment-spike", "risk:high", "platform:ios"],
        "summary": "Prove or disprove that a phone mic can score beginner monophonic phrases honestly enough to power the product.",
        "scope": ["Build a labeled corpus across players, devices, rooms, guitars, and conditions.", "Fix sample-rate, channel, clock, latency, and bleed issues.", "Implement onset detection, constrained alignment, tri-state scoring, and validity metrics.", "Make a go/no-go decision before any product UI or content spend."],
        "acceptance": ["Phrase-level false pass ≤5% and false fail ≤10%.", "Per-note recall ≥99%, per-string recall ≥90%, expert ICC ≥0.75.", "A written spike report with confidence intervals and a go/no-go recommendation."],
    },
    {
        "key": "E2", "name": "02 — Song-First Core Loop",
        "priority": "high", "state": "Ready", "start": "2026-11-25", "target": "2027-02-09",
        "module": "M2", "cycle": "C2",
        "labels": ["type:epic", "area:product", "phase:1-core", "ws:core-loop", "risk:high", "platform:ios"],
        "summary": "Turn the notation trainer into a 5-minute daily practice loop around real monophonic pieces.",
        "scope": ["Piece/phrase domain model and schema migration.", "PhrasePlayPrompt, PhraseVerifier, tri-state outcomes, and PracticeSession.", "Today session, placement, technique, notifications, Reading Lab integration.", "Remove hearts and replace the punishment economy."],
        "acceptance": ["A returner can open the app and play a real phrase in under 3 minutes.", "A 5-minute session contains technique, model, acquire, apply, and reflect.", "A learner can return daily without losing progress or being punished for mistakes."],
    },
    {
        "key": "E3", "name": "03 — Content & Repertoire",
        "priority": "high", "state": "Ready", "start": "2026-12-02", "target": "2027-02-23",
        "module": "M3", "cycle": "C2",
        "labels": ["type:epic", "area:content", "phase:1-core", "ws:content-repertoire", "risk:high", "platform:content-pipeline"],
        "summary": "Create the 10 monophonic pieces, 60 reviewed etudes, human reference recordings, and a sustainable content calendar.",
        "scope": ["Lock the 10-piece list and map to V1 stages.", "Author in a validated format that enforces one sounding note at a time.", "Record human references at target and slow tempo.", "QA notation, fingering, playability, license, and musical payoff."],
        "acceptance": ["10 pieces × 4 phrases, all strictly monophonic and validated.", "60 reviewed etudes across levels 1–5.", "20 reference recordings (each piece at target and slow tempo).", "A 24-month calendar with 2–3 new pieces/month or a one-time pricing fallback."],
    },
    {
        "key": "E4", "name": "04 — Recording & Performance",
        "priority": "high", "state": "Backlog", "start": "2026-12-16", "target": "2027-01-12",
        "module": "M4", "cycle": "C3",
        "labels": ["type:epic", "area:audio", "phase:1-core", "ws:recording-performance", "risk:medium", "platform:ios"],
        "summary": "Let the learner hear themselves improve: local recording, A/B comparison, and a private before/after card.",
        "scope": ["MediaStore across mobile and web.", "WAV analysis then AAC storage; quota, delete, export.", "A/B playback with loudness normalization.", "Privacy copy, backup exclusion, and performance-day flow."],
        "acceptance": ["A learner can record a take, play it back, compare to a previous take, and delete/export it.", "Recordings never enter ProgressState or cloud backup by default.", "The privacy copy and iOS usage string match the actual behavior."],
    },
    {
        "key": "E5", "name": "05 — Onboarding & Retention",
        "priority": "high", "state": "Ready", "start": "2026-12-16", "target": "2027-02-09",
        "module": "M5", "cycle": "C4",
        "labels": ["type:epic", "area:product", "phase:1-core", "ws:onboarding-retention", "risk:high", "platform:ios"],
        "summary": "Make the first session musical, place returners correctly, and build a durable habit without punishment.",
        "scope": ["3-screen onboarding and 3–5 minute placement (skippable).", "First note <60s and first phrase <3min.", "Mastery map and can-play progress.", "Local reminders, weekly recap, retention instrumentation."],
        "acceptance": ["60% first note <60s; 50% first phrase <3min in beta.", "A returner can start at stage 3, 5, or 9, not open strings.", "No heart loss, no punishment loop, and a clear next step every session."],
    },
    {
        "key": "E6", "name": "06 — Monetization, Legal & Funding",
        "priority": "high", "state": "Validating", "start": "2026-11-04", "target": "2027-01-12",
        "module": "M6", "cycle": "C0",
        "labels": ["type:epic", "area:business", "phase:0-validation", "ws:monetization-legal", "risk:high", "platform:backend"],
        "summary": "Prove demand, price correctly, protect the public-domain strategy, and decide bootstrap vs venture before building.",
        "scope": ["Three-cell pre-sale at $49/$69/$99.", "Costed P&L and downside case.", "Legal review: public domain, arrangements, exam IP, consent.", "Paywall after first recording + day-7 recap; store IAP; refunds/tax."],
        "acceptance": ["30+ pre-orders or ≥3% conversion in the best cell.", "A one-page funding decision with runway and break-even.", "Legal go/no-go before Phase 1."],
    },
    {
        "key": "E7", "name": "07 — Teacher & Exam Expansion",
        "priority": "medium", "state": "Backlog", "start": "2027-02-10", "target": "2027-04-06",
        "module": "M7", "cycle": "C7",
        "labels": ["type:epic", "area:business", "phase:2-expansion", "ws:teacher-exam", "risk:medium", "platform:web"],
        "summary": "Add the second distribution channel only after guitar retention is proven.",
        "scope": ["Teacher interviews and 3 LOIs at $19/month.", "Manual export workflow; no persistent cloud.", "COPPA/guardian consent plan.", "Generic Grade 1–3 sight-reading packs without board names."],
        "acceptance": ["3 signed LOIs or paid pilots.", "A manual export workflow a teacher can use without support.", "No exam-board trademark use until licensed."],
    },
    {
        "key": "E8", "name": "08 — Growth & Distribution",
        "priority": "medium", "state": "Backlog", "start": "2026-11-18", "target": "2027-04-06",
        "module": "M8", "cycle": "C1",
        "labels": ["type:epic", "area:growth", "phase:1-core", "ws:growth-distribution", "risk:medium", "platform:web"],
        "summary": "Build an organic acquisition engine: free web test, SEO, short-form, community, and teacher referrals.",
        "scope": ["Free web sight-reading test with email capture.", "ASO subtitle, screenshots, keywords.", "12-month content calendar with 20 free lessons/tools.", "Short-form video engine and community launch plan."],
        "acceptance": ["The web test captures emails and is shareable.", "The first 20 free assets are published.", "Two short-form videos per week for 8 weeks."],
    },
    {
        "key": "E9", "name": "09 — Risks, Decisions & Research",
        "priority": "high", "state": "In Progress", "start": "2026-11-04", "target": "2027-04-06",
        "module": "M9", "cycle": "C0",
        "labels": ["type:epic", "area:research", "phase:0-validation", "ws:core-loop", "risk:high", "platform:docs"],
        "summary": "Keep the assumptions, risks, decisions, and evidence visible so the plan stays honest.",
        "scope": ["Risk register with severity, likelihood, mitigation, owner, and kill criteria.", "Decision log with context, alternatives, and consequences.", "Research dossier with sources and claim caveats.", "Assumption tracker and phase-gate checklist."],
        "acceptance": ["Every major risk has a ticket and a mitigation.", "Every major decision has a dated record.", "Every research claim used in marketing has a source and a caveat."],
    },
]

DOCS = [
    ("D0.1", "START HERE — Project Charter & AI Handoff", "This is the index. Read the docs in order, then open the current cycle. The full plan is stored in the child docs; the local canonical file is listed below.", "type:decision", "area:product"),
    ("D0.2", "Master Plan — Strategy & Executive Summary", "The thesis, the strategic choice, and what changed after three adversarial reviews.", "type:decision", "area:product"),
    ("D0.3", "Current-State Audit & Evidence", "The code-level audit: 240 lessons, 3,984 prompts, 153 objectives, 54% multiple choice, 0 repertoire/sight-reading/improvisation objectives.", "type:research", "area:research"),
    ("D0.4", "Target User, Positioning & V1 Scope", "Who V1 is for, who it is not for, the positioning, and the exact in/out scope.", "type:decision", "area:product"),
    ("D0.5", "Assessment Contract & 3-Week Spike", "What the mic measures, what it does not, the tri-state rules, false pass/fail gates, latency/bleed, corpus, and go/no-go.", "type:spike", "area:assessment"),
    ("D0.6", "Session, Curriculum, Mastery & Content", "The 5-minute Today session, 12 stages, 10-piece map, 60 etudes, technique strand, and performance-only mastery.", "type:decision", "area:product"),
    ("D0.7", "Gamification, Recording & Technical Architecture", "No hearts, optional streak, MediaStore, recording/privacy, data model, migrations, CI, and prompt types.", "type:decision", "area:platform"),
    ("D0.8", "Business Model, Pricing & P&L", "Free demo, $69/year Pro, three-cell pre-sale, base/downside P&L, teacher/exam upside, and funding gate.", "type:decision", "area:business"),
    ("D0.9", "Metrics, Roadmap, Cycles & Kill Criteria", "North star, realistic benchmarks, 90-day sprint, phase gates, and the conditions that stop the project.", "type:decision", "area:product"),
    ("D0.10", "Risks, Non-Goals & Open Decisions", "Risk register, what not to do, and the decisions still open after V1.", "type:risk", "area:research"),
    ("D0.11", "Research Dossier & Sources", "The evidence base, with caveats about sample sizes and what each source does and does not prove.", "type:research", "area:research"),
    ("D0.12", "Competitor Map & Public-Domain Shortlist", "Who owns what, the gap, and the launch repertoire candidates that need legal review.", "type:research", "area:research"),
    ("D0.13", "Glossary, Naming & AI Operating Manual", "Definitions, naming conventions, how to update Plane, and the rules for future agents.", "type:decision", "area:product"),
]

TASKS = [
    # E1 — assessment spike
    ("T1.1", "E1", "Recruit 6–10 players for the assessment corpus", "Ready", "high", "M1", "C0", "2026-11-04", "2026-11-08", 3,
     ["area:assessment", "phase:0-validation", "ws:assessment-spike", "risk:high", "platform:docs"],
     "Recruit beginner and returner guitarists across the target range, with a mix of nylon and steel strings.",
     ["6–10 players; at least 3 returners and 3 near-beginners.", "At least 2 guitar types and 3 playing levels.", "Consent covers audio capture, local storage, and anonymized metrics."],
     ["Corpus must include 4-, 8-, and 16-note phrases.", "No player should feel pressured to perform; capture natural takes."], []),
    ("T1.2", "E1", "Write the corpus protocol, consent, and labeling guide", "Ready", "high", "M1", "C0", "2026-11-04", "2026-11-08", 3,
     ["area:assessment", "phase:0-validation", "ws:assessment-spike", "risk:medium", "platform:docs"],
     "Define exactly what is recorded, how it is labeled, and how ground truth is established.",
     ["Protocol covers devices, rooms, guitar types, conditions, takes, and failed takes.", "Labels include target notes, onset times, and expert pass/fail.", "Consent and deletion path are documented."],
     ["Use a subset of MIDI/interface recordings to validate labels.", "Store only what the spike needs; delete raw audio after analysis unless consent says otherwise."], []),
    ("T1.3", "E1", "Fix sample-rate/channel handling and add sample-clock timestamps", "In Progress", "urgent", "M1", "C0", "2026-11-04", "2026-11-10", 5,
     ["area:audio", "phase:0-validation", "ws:assessment-spike", "risk:high", "platform:ios", "platform:android"],
     "The current pipeline assumes 44.1 kHz mono. A 48 kHz-only device will report pitches ~8.8% high; stereo negotiation can corrupt decoding.",
     ["Read the effective RecordConfig sample rate and channel count.", "Resample/convert explicitly; add tests for 44.1/48 kHz and mono/stereo.", "Add monotonic sample-clock timestamps to PitchFrame; never use DateTime.now() for audio alignment."],
     ["This is a latent bug that will look like 'the app can't hear me' and will not reproduce in CI.", "Block the spike until fixed."], []),
    ("T1.4", "E1", "Build the latency, clock, and bleed test rig", "Ready", "high", "M1", "C0", "2026-11-05", "2026-11-12", 5,
     ["area:audio", "phase:0-validation", "ws:assessment-spike", "risk:high", "platform:ios", "platform:android"],
     "Measure output-to-input latency per device, clock drift, and backing/click bleed before trusting any timing score.",
     ["Loopback or tap calibration; record residual offset.", "Test speaker vs wired headphones vs Bluetooth.", "Report false onsets per minute and note-recall drop."],
     ["Require offset ≤10 ms and drift ≤20 ms/60 s for scored timing.", "If the rig fails, score notes only and drop the 'in time' claim."], []),
    ("T1.5", "E1", "Implement onset detection, constrained alignment, and tri-state scoring", "In Progress", "urgent", "M1", "C1", "2026-11-06", "2026-11-18", 8,
     ["area:assessment", "phase:0-validation", "ws:assessment-spike", "risk:high", "platform:ios"],
     "Build the phrase matcher: spectral-flux onsets, harmonic-aware f0, constrained alignment, exact pitch, fixed-click timing, and indeterminate results.",
     ["Exact pitch class; ±30 cents intonation; octave errors separate.", "Timing against fixed click, not a DTW-warped grid.", "Tri-state: correct, incorrect, indeterminate; indeterminate updates nothing.", "Null model: random notes pass ≤5%; one semitone error fails 100%; silence/noise is indeterminate ≥90%."],
     ["This is the core technical risk. Do not build the Today UI before it passes.", "Use held-out players and pieces, not random takes."], []),
    ("T1.6", "E1", "Run the corpus and compute validity metrics", "Validating", "urgent", "M1", "C1", "2026-11-12", "2026-11-20", 5,
     ["area:assessment", "phase:0-validation", "ws:assessment-spike", "risk:high", "platform:docs"],
     "Execute the protocol and produce the evidence table: false pass, false fail, per-note recall, per-string recall, onset MAE, expert ICC/kappa, and confidence intervals.",
     ["≥240 takes across 4 devices × 3 conditions.", "Per-string recall ≥90%; octave-error rate ≤2%.", "Report stratified results for 4/8/16-note phrases and user segment."],
     ["Do not tune thresholds on the held-out set.", "Publish the raw metric table in the spike report."], ["T1.1", "T1.2", "T1.3", "T1.4", "T1.5"]),
    ("T1.7", "E1", "Make the spike go/no-go decision", "Ready", "urgent", "M1", "C1", "2026-11-20", "2026-11-21", 1,
     ["area:assessment", "phase:0-validation", "ws:assessment-spike", "risk:high", "platform:docs"],
     "Decide whether the mic can power the product, or whether to pivot to call-and-response/single-bar/pure notation.",
     ["Written decision with the exact metrics, confidence intervals, and dissenting risks.", "If fail: choose the pivot and update the roadmap.", "If pass: unlock Phase 1 and remove the gate label."],
     ["This is a hard gate. No product/content spend before it."], ["T1.6"]),
    ("T1.8", "E1", "Launch the three-cell pre-sale at $49/$69/$99", "In Progress", "high", "M6", "C0", "2026-11-04", "2026-11-18", 3,
     ["area:business", "phase:0-validation", "ws:monetization-legal", "risk:high", "platform:web"],
     "Test willingness to pay before building the full product. Three landing-page cells, same copy, different annual founding price.",
     ["1,000 targeted visitors per cell (3,000 total).", "Gate: 30+ pre-orders across cells or ≥3% conversion in the best cell.", "Email capture ≥10%; refundable pre-order terms."],
     ["Do not anchor low with a $39 price; it selects bargain hunters and does not validate $69.", "Track which channel produced each visitor."], ["T6.1"]),
    ("T1.9", "E1", "Run the 4-week concierge program with 12 returners", "Validating", "high", "M1", "C0", "2026-11-04", "2026-12-01", 5,
     ["area:research", "phase:0-validation", "ws:assessment-spike", "risk:medium", "platform:docs"],
     "Manually deliver the 5-minute loop before the app exists: piece choice, one correction, before/after recording.",
     ["12 adult returners; 4 weeks; 5 min/day; weekly 15-min Zoom.", "Gate: 60% do 3+ sessions/week; 50% would pay $8/mo.", "Capture the exact language learners use for the problem and the payoff."],
     ["This is the cheapest demand test. It also gives you the first 12 beta users."], []),
    ("T1.10", "E1", "Commission the legal review: public domain, arrangements, exam IP, consent", "Ready", "high", "M6", "C0", "2026-11-05", "2026-11-20", 5,
     ["area:legal", "phase:0-validation", "ws:monetization-legal", "risk:high", "platform:docs"],
     "Get written guidance before publishing the catalog, using exam-board names, or shipping recordings.",
     ["Public-domain status by territory; arrangement copyright; exam-board IP; pre-sale terms; recording consent; app-store subscription terms.", "Budget $5–10k; written opinion, not a checklist.", "Go/no-go before Phase 1."],
     ["Do not treat 'traditional' as automatically public domain; arrangements and recordings are separate works."], []),
    ("T1.11", "E1", "Make the bootstrap-vs-venture funding decision", "Ready", "high", "M6", "C1", "2026-11-25", "2026-12-01", 1,
     ["area:business", "phase:0-validation", "ws:monetization-legal", "risk:high", "platform:docs"],
     "Use the pre-sale, concierge, P&L, and legal review to decide the funding path before building.",
     ["One page: bootstrap target $250k ARR and 24-month runway, or venture path with piano/schools/exam boards.", "Include cash need, break-even, and the downside case.", "Record the decision and its consequences."],
     ["The current plan is a profitable niche, not a venture-scale consumer app. Do not raise on a $600k business."], ["T1.8", "T1.9", "T6.2"]),

    # E2 — core loop
    ("T2.1", "E2", "Define the Piece, Phrase, NoteEvent, Score, and MediaStore domain models", "Ready", "high", "M2", "C2", "2026-12-02", "2026-12-08", 8,
     ["area:product", "phase:1-core", "ws:core-loop", "risk:medium", "platform:ios"],
     "Add the score model that the rest of Phase 1 depends on. Keep it pure Dart and widget-free.",
     ["Piece: title, composer, license, tuning, capo, time signature, key, sections.", "Phrase: bars, notes, rests, ties, fingering, written vs sounding MIDI, skills, difficulty.", "Validator enforces one sounding note at a time for V1.", "MediaStore abstraction for recordings."],
     ["Do not use a loose note list; the current written-vs-sounding bug is exactly what this model must prevent.", "Add parser and validator tests before content."], ["T1.7"]),
    ("T2.2", "E2", "Add schema v5 with pure versioned migrations and fixtures", "Ready", "high", "M2", "C2", "2026-12-07", "2026-12-11", 5,
     ["area:platform", "phase:1-core", "ws:core-loop", "risk:high", "platform:ios", "platform:android"],
     "Persist pieces, phrases, recordings, and phrase attempts without breaking existing progress.",
     ["Version-gated migration functions, not data-driven guessing.", "Fixtures for v1–v5; explicit rollback behavior.", "Separate progress, media, content, and account stores.", "Never put recordings in ProgressState."],
     ["Test migration from a real v4 backup.", "Future versions should be rejected, not partially parsed."], ["T2.1"]),
    ("T2.3", "E2", "Propagate AttemptOutcome tri-state through the learning engine", "Ready", "urgent", "M2", "C2", "2026-12-07", "2026-12-12", 5,
     ["area:assessment", "phase:1-core", "ws:core-loop", "risk:high", "platform:ios"],
     "Indeterminate must not update FSRS, XP, streaks, hearts, or daily counters. It means retry, not fail.",
     ["AttemptOutcome { correct, incorrect, indeterminate } at the domain boundary.", "SkillAnswer, SkillProgress, ProgressState, controller, UI, and tests updated.", "Test: indeterminate changes nothing; low-confidence take is incomplete."],
     ["This is the difference between an honest coach and a noisy scorekeeper."], ["T2.1"]),
    ("T2.4", "E2", "Create the PracticeSession aggregate separate from LessonRun", "Ready", "high", "M2", "C2", "2026-12-08", "2026-12-14", 5,
     ["area:product", "phase:1-core", "ws:core-loop", "risk:medium", "platform:ios"],
     "The 5-minute Today loop is not a lesson. Do not force it through the lesson composer, hearts, or pacing.",
     ["PracticeSession blocks: technique, model, acquire, apply, reflect.", "Session length 5/10/20; one target; maintenance-day variant.", "Reading Lab keeps LessonRun.", "No duplicated state or scoring logic."],
     ["Keep the engine topic-agnostic; do not add content imports to core."], ["T2.1"]),
    ("T2.5", "E2", "Implement PhrasePlayPrompt, PhraseVerifier, and the phrase player UI", "Ready", "urgent", "M2", "C2", "2026-12-10", "2026-12-20", 8,
     ["area:assessment", "phase:1-core", "ws:core-loop", "risk:high", "platform:ios"],
     "The learner sees a short phrase, plays it, and gets one actionable correction.",
     ["Prompt carries note events, BPM, tolerance, and backing/click spec.", "Verifier returns note accuracy, timing, completeness, worst bar, confidence.", "UI shows the phrase, a play button, a record/stop control, and one correction.", "No bar/beat feedback unless confidence is high."],
     ["Use real corpus phrases in tests, not only synthetic tones.", "Scored takes require wired headphones or a verified clock."], ["T2.1", "T2.3"]),
    ("T2.6", "E2", "Build the Today 5-minute session UI", "Ready", "high", "M2", "C3", "2026-12-16", "2026-12-24", 8,
     ["area:product", "phase:1-core", "ws:core-loop", "risk:medium", "platform:ios"],
     "The home screen becomes a daily plan: tune, technique, model, acquire, apply, reflect.",
     ["Default 5 minutes; 10-minute option; 20-minute deep practice.", "One target; one correction; one next step.", "No hearts; no punishment; clear stop point.", "The learner always knows what to do and why."],
     ["Measure time on instrument, not prompt count.", "A 5-minute session should have 3+ minutes of guitar in hand."], ["T2.4", "T2.5"]),
    ("T2.7", "E2", "Add the technique checklist, 60-second drill, and video demos", "Ready", "high", "M2", "C3", "2026-12-16", "2026-12-23", 5,
     ["area:content", "phase:1-core", "ws:core-loop", "risk:medium", "platform:ios"],
     "The mic cannot see hands. Teach setup, posture, hands, picking, fretting, muting, and pain warnings explicitly.",
     ["Per-stage technique focus; 3-item rubric; 60-second drill in rotation.", "Video demos for each drill.", "Export-for-teacher review in V1.", "Pain/numbness/tingling warning; no medical claims."],
     ["Do not claim automated hand assessment.", "Returners may already have habits; make the checklist non-judgmental."], []),
    ("T2.8", "E2", "Build the 3–5 minute placement diagnostic and manual override", "Ready", "medium", "M5", "C4", "2026-12-30", "2027-01-06", 5,
     ["area:product", "phase:1-core", "ws:onboarding-retention", "risk:medium", "platform:ios"],
     "Returners should not start at open strings. Place within stages that have V1 content (1–3, 5, 9–10).",
     ["Three screens; skippable; infer tier from first 30–60 seconds.", "If placement suggests stage 6–8, map to 5 or 9 and label the gap Phase 2.", "Manual override; three-piece starter set; re-test every 4–6 weeks."],
     ["Protect the first phrase <3 min target; do not force a long test."], ["T2.6"]),
    ("T2.9", "E2", "Add local notifications, weekly recap, and before/after trigger", "Ready", "medium", "M5", "C4", "2027-01-02", "2027-01-08", 3,
     ["area:product", "phase:1-core", "ws:onboarding-retention", "risk:low", "platform:ios"],
     "A 5-minute habit needs a specific return trigger, not a generic streak guilt.",
     ["Local notification at user-chosen time with the specific task.", "Weekly recap: minutes, phrases, one before/after.", "Trigger when a new before/after is ready.", "No account required; opt-in."],
     ["Measure opt-in and session-2 lift.", "Do not notify during quiet hours."], ["T2.6"]),
    ("T2.10", "E2", "Remove hearts and replace with optional streak/weekly goal", "Ready", "high", "M2", "C3", "2026-12-16", "2026-12-20", 3,
     ["area:product", "phase:1-core", "ws:core-loop", "risk:medium", "platform:ios"],
     "Hearts punish the exact mistakes beginners need to make. Replace with a non-lossy habit signal.",
     ["No hearts in lessons or practice.", "Optional streak; effective practice counts; freeze; no loss framing.", "Weekly goal in minutes/phrases, not XP.", "Update economy, shop, quests, tests, and copy."],
     ["Do not reintroduce punishment through streak loss.", "Measure session completion and return rate before/after."], []),
    ("T2.11", "E2", "Add runtime phrase-objective resolution and content versioning", "Ready", "medium", "M2", "C2", "2026-12-10", "2026-12-15", 3,
     ["area:platform", "phase:1-core", "ws:core-loop", "risk:medium", "platform:ios"],
     "Phrase skills must reappear in practice, and content edits must not orphan progress.",
     ["Runtime resolver maps phrase IDs to objectives.", "Content version IDs; migration when a phrase changes.", "Test: a phrase skill returns in due practice; an edited phrase preserves progress."],
     ["The current static catalog would drop unknown phrase IDs."], ["T2.1"]),
    ("T2.12", "E2", "Integrate the existing 240-lesson course as the optional Reading Lab", "Backlog", "low", "M2", "C4", "2027-01-02", "2027-01-12", 3,
     ["area:product", "phase:1-core", "ws:core-loop", "risk:low", "platform:ios"],
     "Keep the notation/theory course as a supporting path, not the home.",
     ["Reading Lab entry point from Today/Profile.", "No hearts; no forced linearity.", "Guidebook/reference content remains available.", "Clear copy: 'structured reading practice, optional'."],
     ["Do not delete the existing course or user progress.", "This is a bridge for current users, not the new core."], []),

    # E3 — content
    ("T3.1", "E3", "Lock the 10-piece launch list and map each piece to a V1 stage", "Ready", "high", "M3", "C2", "2026-12-02", "2026-12-05", 3,
     ["area:content", "phase:1-core", "ws:content-repertoire", "risk:high", "platform:content-pipeline"],
     "Choose pieces for musical payoff, monophonic playability, range, and stage fit.",
     ["10 pieces: 5 Foundation (stages 1–3), 5 Returner (stages 5, 9–10).", "Every piece is strictly monophonic or has an explicit single-line reduction.", "Map to stage, tier, skills, and performance outcome.", "Legal review per territory."],
     ["Do not include two-voice Sor/Giuliani/Carcassi studies in V1.", "Avoid arrangements associated with copyrighted recordings."], ["T1.7"]),
    ("T3.2", "E3", "Build the authoring format and monophonic validator", "Ready", "high", "M3", "C2", "2026-12-07", "2026-12-12", 5,
     ["area:content", "phase:1-core", "ws:content-repertoire", "risk:high", "platform:content-pipeline"],
     "Content must be data, not code. The validator must prevent unplayable or unassessable phrases.",
     ["YAML/JSON with time signature, key, tuning, capo, rests, ties, pickup, written/sounding pitch, fingering, skills.", "Validator: one sounding note at a time, valid position, bar duration, license, reference recording.", "Parser tests and a content CI check."],
     ["The current model lacks time signature, rests, ties, capo, and tuning.", "Do not author 10 pieces before the validator exists."], ["T2.1"]),
    ("T3.3", "E3", "Arrange the 5 Foundation pieces (4 phrases each)", "Ready", "high", "M3", "C2", "2026-12-10", "2026-12-22", 8,
     ["area:content", "phase:1-core", "ws:content-repertoire", "risk:medium", "platform:content-pipeline"],
     "Create the beginner tier: recognizable melodies, first position, simple rhythms, no polyphony.",
     ["5 pieces × 4 phrases; all monophonic.", "Difficulty ladder: range, rhythm, accidentals, shifts.", "Notation + tab toggle; fingering hints.", "One performance outcome per piece."],
     ["Reject any arrangement that sounds like an exercise or requires untaught technique.", "Playtest with 3 beginners."], ["T3.1", "T3.2"]),
    ("T3.4", "E3", "Arrange the 5 Returner pieces (4 phrases each)", "Ready", "high", "M3", "C3", "2026-12-16", "2026-12-29", 8,
     ["area:content", "phase:1-core", "ws:content-repertoire", "risk:medium", "platform:content-pipeline"],
     "Create the returner tier: longer phrases, position shifts, more expressive potential, still monophonic.",
     ["5 pieces × 4 phrases; all monophonic.", "At least 2 pieces with a position shift; at least 2 in a minor key.", "Performance outcome inside the assessment contract (1–4 bars per phrase).", "Reference recording at target and slow tempo."],
     ["Do not use two-voice studies as 'returner' content.", "Check hand stretch and position comfort."], ["T3.1", "T3.2"]),
    ("T3.5", "E3", "Record 20 human reference takes (target + slow)", "Ready", "high", "M3", "C3", "2026-12-22", "2027-01-05", 5,
     ["area:content", "phase:1-core", "ws:content-repertoire", "risk:medium", "platform:content-pipeline"],
     "A synth is not a model of guitar tone, articulation, or phrasing.",
     ["Each of 10 pieces at target and slow tempo (20 takes).", "Good audio quality; no talk; count-in included.", "Store metadata: piece, phrase, BPM, guitar, mic.", "Use as the model in the session; allow A/B."],
     ["This is non-negotiable for a repertoire product.", "Do not use copyrighted recordings."], ["T3.3", "T3.4"]),
    ("T3.6", "E3", "Author 60 reviewed sight-reading etudes (levels 1–5)", "Ready", "high", "M3", "C3", "2026-12-16", "2027-01-08", 8,
     ["area:content", "phase:1-core", "ws:content-repertoire", "risk:high", "platform:content-pipeline"],
     "Create the finite reviewed library before the generator beta. First read is scored silently; feedback after the second read.",
     ["60 etudes, 12 per level; 2–4 bars each.", "Each etude has a musical shape, not just a note sequence.", "First-read accuracy/timing is the sight-reading metric.", "No 'unlimited' claim until the generator is validated."],
     ["The generator beta must have a playability validator and pedagogue QA sample.", "Do not ship 30 etudes and call it infinite."], ["T3.2"]),
    ("T3.7", "E3", "Build the sight-reading generator beta and playability validator", "Backlog", "medium", "M3", "C5", "2027-01-13", "2027-01-26", 8,
     ["area:content", "phase:1-core", "ws:content-repertoire", "risk:high", "platform:content-pipeline"],
     "Generate level-matched etudes without producing unplayable or musically incoherent material.",
     ["Grammar: key, meter, rhythm cells, intervals, range, position.", "Validator: max stretch, string crossings, shifts, open strings, repeated notes, cadence.", "Pedagogue review of a stratified sample.", "Human approval before a generated etude enters the library."],
     ["Do not market generated etudes as unlimited until validated.", "Keep the 60 reviewed etudes as the stable core."], ["T3.6"]),
    ("T3.8", "E3", "Run content QA: playthrough, notation, fingering, license, musical payoff", "Ready", "high", "M3", "C4", "2027-01-04", "2027-01-12", 5,
     ["area:content", "phase:1-core", "ws:content-repertoire", "risk:high", "platform:content-pipeline"],
     "Catch the errors that automated validation cannot: playability, notation, fingering, and whether the piece is worth playing.",
     ["Every piece/phrase played by a guitarist.", "Notation and tab checked; written vs sounding pitch correct.", "License/territory checked; reference recording matches.", "At least 3 beginners/returners play the first session."],
     ["Reject any piece that is not musical or not playable at the target level.", "Do not ship with a known wrong fingering."], ["T3.3", "T3.4", "T3.5", "T3.6"]),
    ("T3.9", "E3", "Build the 24-month content calendar and cost model", "Ready", "medium", "M3", "C1", "2026-11-25", "2026-12-01", 2,
     ["area:business", "phase:1-core", "ws:content-repertoire", "risk:high", "platform:docs"],
     "A subscription needs a credible supply of new pieces. Model it before promising it.",
     ["2–3 new pieces/month after launch; 40–60 pieces by year 2.", "Cost per piece: $500–1,500 and 8–16 hours.", "If the calendar is not sustainable, switch to one-time piece packs."],
     ["The 10-piece launch is a 2–3 month supply, not a year.", "Include QA, recording, and legal review in the cost."], []),
    ("T3.10", "E3", "Publish the piece-to-stage/tier map and performance outcomes", "Ready", "medium", "M3", "C2", "2026-12-05", "2026-12-08", 2,
     ["area:content", "phase:1-core", "ws:content-repertoire", "risk:low", "platform:docs"],
     "Make it obvious what the learner can play at each stage and what 'done' means.",
     ["Table: piece, stage, tier, skills, target BPM, performance outcome.", "V1 stages only (1–3, 5, 9–10); label 4/6/7/8 Phase 2.", "Placement and Today use the same map."],
     ["Every launch piece must have a stage and an outcome inside the assessment contract."], ["T3.1"]),

    # E4 — recording
    ("T4.1", "E4", "Build the MediaStore abstraction (mobile files + web IndexedDB)", "Ready", "high", "M4", "C3", "2026-12-16", "2026-12-22", 5,
     ["area:platform", "phase:1-core", "ws:recording-performance", "risk:medium", "platform:ios", "platform:web"],
     "Recordings are not progress JSON. They need their own store, quota, and deletion path.",
     ["Conditional imports for mobile/desktop/web.", "Manifest: id, piece/phrase, duration, created, score, analysis version.", "Quota, delete, export, orphan reconciliation on startup."],
     ["Do not base64 audio into ProgressState.", "Exclude recordings from iCloud/Android backup by default."], ["T2.1"]),
    ("T4.2", "E4", "Record WAV for analysis, compress to AAC, and enforce quota/delete/export", "Ready", "high", "M4", "C3", "2026-12-22", "2026-12-29", 5,
     ["area:audio", "phase:1-core", "ws:recording-performance", "risk:medium", "platform:ios"],
     "Recording must be reliable and private. Analyze after stop; never stream to two consumers.",
     ["WAV analysis → AAC storage; keep first and last take per piece.", "Cap 60 s/take, 20 takes; delete/export; disk-full handling.", "No simultaneous record + stream on one AudioRecorder."],
     ["Test permission denied, disk full, delete, export, and orphan reconciliation.", "Do not ship recording before updating privacy copy."], ["T4.1"]),
    ("T4.3", "E4", "Add A/B playback with loudness normalization", "Ready", "medium", "M4", "C4", "2027-01-02", "2027-01-08", 3,
     ["area:audio", "phase:1-core", "ws:recording-performance", "risk:low", "platform:ios"],
     "Comparing takes is the emotional payoff. Louder is not better.",
     ["A/B two takes with matched loudness.", "Show date, tempo, and one metric.", "Allow delete/export from the comparison."],
     ["Normalize before comparing; do not let volume bias the judgment."], ["T4.2"]),
    ("T4.4", "E4", "Build the private before/after card", "Ready", "medium", "M4", "C4", "2027-01-04", "2027-01-10", 3,
     ["area:product", "phase:1-core", "ws:recording-performance", "risk:low", "platform:ios"],
     "Give the learner a shareable proof of progress without a public score.",
     ["Card: piece, phrase, date, one metric, optional audio clip.", "No public score or leaderboard.", "Default private; explicit export only."],
     ["The card should make the learner feel progress, not judged."], ["T4.2"]),
    ("T4.5", "E4", "Update privacy copy, iOS usage string, and backup exclusion", "Ready", "high", "M4", "C3", "2026-12-16", "2026-12-18", 2,
     ["area:legal", "phase:1-core", "ws:recording-performance", "risk:high", "platform:ios"],
     "The current app says audio is analyzed live and never recorded. That becomes false when recording ships.",
     ["Profile copy, onboarding copy, and iOS NSMicrophoneUsageDescription match the new behavior.", "Recordings excluded from cloud backup unless opted in.", "Delete/export path documented."],
     ["This is a trust and App Store review issue, not a copy tweak."], []),
    ("T4.6", "E4", "Implement the performance-day flow (record 1–2×/week)", "Ready", "medium", "M4", "C4", "2027-01-05", "2027-01-12", 3,
     ["area:product", "phase:1-core", "ws:recording-performance", "risk:low", "platform:ios"],
     "Recording every session contradicts the 30% record-by-day-7 target and adds friction.",
     ["Performance day: one take, no score on the first run, then feedback.", "Daily sessions use a no-record run.", "Weekly before/after is the default share."],
     ["Make recording feel like a recital, not surveillance."], ["T4.3"]),

    # E5 — onboarding/retention
    ("T5.1", "E5", "Build the three-screen onboarding", "Ready", "high", "M5", "C4", "2026-12-30", "2027-01-05", 5,
     ["area:product", "phase:1-core", "ws:onboarding-retention", "risk:medium", "platform:ios"],
     "One decision per screen: guitar in hand, reading level, first piece.",
     ["No account; no daily XP goal in onboarding.", "Mic permission at first play, with listen-first fallback.", "First note <60s; first phrase <3min."],
     ["Do not front-load a 5-minute placement test.", "Let the learner skip and start with a 4-note phrase."], ["T2.6"]),
    ("T5.2", "E5", "Build the first-session flow: first note <60s, first phrase <3min", "Ready", "high", "M5", "C4", "2027-01-02", "2027-01-08", 5,
     ["area:product", "phase:1-core", "ws:onboarding-retention", "risk:high", "platform:ios"],
     "The first session must end with the learner playing something real and hearing it back.",
     ["Hear 4 notes → play 4 notes → see one correction → record 10s → stop.", "No diagnosis on day 1 unless confidence is high.", "First phrase is recognizable and inside the assessment contract."],
     ["Measure the exact funnel: install → first note → first phrase → first recording.", "If <40% play a phrase, fix onboarding before adding content."], ["T5.1", "T2.6"]),
    ("T5.3", "E5", "Build the mastery map / can-play progress UI", "Ready", "medium", "M5", "C4", "2027-01-04", "2027-01-12", 5,
     ["area:product", "phase:1-core", "ws:onboarding-retention", "risk:low", "platform:ios"],
     "Progress should mean 'I can play this,' not 'I completed a lesson.'",
     ["Can play / shaky / reading / next.", "Piece and phrase level, tempo, date, recording.", "No lesson-completion percentage as the primary metric."],
     ["Only performance-mastered items get the 'can play' badge.", "Do not fake progress."], ["T2.5"]),
    ("T5.4", "E5", "Add privacy-preserving retention instrumentation", "Ready", "high", "M5", "C3", "2026-12-16", "2026-12-22", 3,
     ["area:research", "phase:1-core", "ws:onboarding-retention", "risk:medium", "platform:ios"],
     "You cannot improve retention without measuring it, but you cannot betray the privacy promise.",
     ["Opt-in, pseudonymous events; no audio, no free text.", "Funnel: install, onboarding, first note, first phrase, first recording, D1/D7/D30.", "Exportable local log for beta users; aggregate only with consent."],
     ["Do not use opt-in analytics as an unbiased baseline; use a hand-recruited cohort for the pilot.", "Document exactly what is collected."], []),
    ("T5.5", "E5", "Migrate the no-hearts economy and update quests/shop/copy", "Ready", "high", "M5", "C3", "2026-12-16", "2026-12-22", 3,
     ["area:product", "phase:1-core", "ws:onboarding-retention", "risk:medium", "platform:ios"],
     "Hearts, gem refills, and heart-loss copy must disappear together, or the product will contradict itself.",
     ["Remove hearts from lessons/practice/result screens.", "Remove heart refills from shop; keep optional cosmetics if desired.", "Quests become musical behaviors: play 3 phrases, record a take, learn 4 bars."],
     ["Do not replace hearts with another loss-aversion mechanic.", "Update tests and onboarding copy."], ["T2.10"]),
    ("T5.6", "E5", "Test the session-2 return trigger and reminder copy", "Ready", "medium", "M5", "C5", "2027-01-13", "2027-01-20", 2,
     ["area:growth", "phase:1-core", "ws:onboarding-retention", "risk:low", "platform:ios"],
     "D7 is won or lost on the first return. Test the specific-task reminder against a generic one.",
     ["Specific task: 'Today: bars 5–8 of [piece], 5 min.'", "Generic: 'Time to practice!'", "Measure session-2 within 48h and D7."],
     ["Do not use guilt or streak-loss copy.", "Respect quiet hours."], ["T2.9"]),

    # E6 — monetization/legal
    ("T6.1", "E6", "Run the three-cell pre-sale and record the result", "Validating", "high", "M6", "C0", "2026-11-04", "2026-11-18", 3,
     ["area:business", "phase:0-validation", "ws:monetization-legal", "risk:high", "platform:web"],
     "Validate price and demand before building the paywall.",
     ["$49/$69/$99 annual founding; 1,000 targeted visitors per cell.", "30+ pre-orders or ≥3% best-cell conversion.", "Email capture ≥10%; record channel attribution."],
     ["Do not use a $39 anchor; it undercuts the $69 value.", "Refundable pre-orders; clear terms."], []),
    ("T6.2", "E6", "Build the costed P&L and downside cash model", "Ready", "high", "M6", "C1", "2026-11-18", "2026-11-25", 3,
     ["area:business", "phase:0-validation", "ws:monetization-legal", "risk:high", "platform:docs"],
     "Revenue-only forecasts are not a business. Include content, DSP/dev, legal, hosting, support, marketing, tools, refunds, and store fees.",
     ["Base case: 7,500/20,000/40,000 installs; 3% conversion; 50% renewal.", "Downside: 2% conversion, 40% renewal; cumulative cash need.", "Break-even ~2,500 Pro; founder salary excluded; state the runway."],
     ["Correct the retention arithmetic: 50% of 713 is ~357, not 300–600.", "Teacher/exam revenue excluded from base case."], []),
    ("T6.3", "E6", "Complete the legal review and go/no-go", "Ready", "high", "M6", "C0", "2026-11-05", "2026-11-20", 5,
     ["area:legal", "phase:0-validation", "ws:monetization-legal", "risk:high", "platform:docs"],
     "Public-domain status, arrangements, exam IP, pre-sale terms, recording consent, and subscription law.",
     ["Written opinion per territory.", "Budget $5–10k; list of approved launch pieces.", "Go/no-go before Phase 1."],
     ["Do not use exam-board names until licensed.", "Do not treat a public-domain composition as a public-domain recording."], []),
    ("T6.4", "E6", "Implement the paywall after first recording + day-7 recap", "Ready", "high", "M6", "C4", "2027-01-04", "2027-01-10", 5,
     ["area:business", "phase:1-core", "ws:monetization-legal", "risk:high", "platform:ios"],
     "The paywall should arrive after the learner has felt the value, not before.",
     ["Free demo: 3 pieces, 10 etudes, 3 recordings.", "Pro: all pieces/etudes, recordings, advanced feedback, offline.", "7-day trial; test gating etudes/diagnosis vs piece count."],
     ["Do not gate the first recording or the first week's progress.", "Measure free→paid at day 30."], ["T4.4", "T3.8"]),
    ("T6.5", "E6", "Add store IAP and restore purchases without an app account", "Ready", "high", "M6", "C4", "2027-01-06", "2027-01-12", 5,
     ["area:platform", "phase:1-core", "ws:monetization-legal", "risk:medium", "platform:ios", "platform:android"],
     "A local-first app can still sell Pro without forcing an account.",
     ["StoreKit/Play Billing; server receipt validation or local entitlement with restore.", "Restore purchases on reinstall.", "No account required; entitlement stored locally."],
     ["Use store billing for mobile digital goods; do not link to an external web paywall in-app.", "Test restore and refund paths."], ["T6.4"]),
    ("T6.6", "E6", "Write the bootstrap-vs-venture decision memo", "Ready", "high", "M6", "C1", "2026-11-25", "2026-12-01", 1,
     ["area:business", "phase:0-validation", "ws:monetization-legal", "risk:high", "platform:docs"],
     "The revised numbers point to a profitable niche, not a venture-scale consumer app. Decide deliberately.",
     ["One page: bootstrap target $250k ARR and 24-month runway; venture path needs piano/schools/exam boards.", "Cash need, break-even, downside case.", "Record the decision in the decision log."],
     ["Do not raise venture capital on a $600k business.", "If bootstrap, set a 24-month runway plan."], ["T6.2", "T1.8"]),
    ("T6.7", "E6", "Write the refund, tax, and VAT policy", "Ready", "medium", "M6", "C1", "2026-11-25", "2026-12-01", 2,
     ["area:legal", "phase:0-validation", "ws:monetization-legal", "risk:medium", "platform:backend"],
     "Subscription revenue needs refund, tax, and store-fee handling before launch.",
     ["Refund policy for pre-orders and subscriptions.", "VAT/sales-tax approach by market.", "Store fee and net revenue assumptions in the P&L."],
     ["Pre-sale terms must be clear about refunds.", "Do not promise lifetime access without a cap."], ["T6.3"]),

    # E7 — teacher/exam
    ("T7.1", "E7", "Interview 10 teachers and secure 3 LOIs at $19/month", "Ready", "medium", "M7", "C7", "2027-02-10", "2027-02-17", 3,
     ["area:business", "phase:2-expansion", "ws:teacher-exam", "risk:medium", "platform:docs"],
     "Validate the teacher channel before building a dashboard.",
     ["10 interviews; 3 non-binding LOIs at $19/mo for 20–30 students.", "Define the manual export workflow and the teacher's actual job.", "Do not claim weekly assignment use before the product exists."],
     ["No persistent cloud in V1.", "COPPA/guardian consent before any under-13 student."], []),
    ("T7.2", "E7", "Build the manual export flow (audio + JSON/PDF summary)", "Ready", "medium", "M7", "C7", "2027-02-17", "2027-02-24", 5,
     ["area:product", "phase:2-expansion", "ws:teacher-exam", "risk:medium", "platform:ios"],
     "A teacher should be able to review a student's take without a cloud account.",
     ["Student selects a take → export audio + one-page summary via share sheet.", "Teacher opens in app/web viewer; no persistent sync.", "Consent and deletion path documented."],
     ["This is a workflow, not a dashboard.", "Do not build multi-tenant cloud for a pilot."], ["T4.2"]),
    ("T7.3", "E7", "Write the COPPA/guardian consent plan", "Ready", "high", "M7", "C7", "2027-02-10", "2027-02-17", 3,
     ["area:legal", "phase:2-expansion", "ws:teacher-exam", "risk:high", "platform:docs"],
     "Teacher studios necessarily include minors. Do not ship the channel without consent and deletion.",
     ["Parental consent, data minimization, deletion, and moderation.", "No public recital for minors.", "Legal review before pilot."],
     ["This is a compliance gate, not a feature.", "If not ready, keep teacher out of the base case."], []),
    ("T7.4", "E7", "Create generic Grade 1–3 sight-reading packs (no board names)", "Backlog", "medium", "M7", "C8", "2027-02-24", "2027-03-09", 8,
     ["area:content", "phase:2-expansion", "ws:teacher-exam", "risk:high", "platform:content-pipeline"],
     "Exam-style practice is a clear willingness-to-pay use case. Build generic packs first.",
     ["Original exercises aligned to published parameters, not past papers.", "No ABRSM/RCM/Trinity names or logos until licensed.", "Legal review; clear disclaimer."],
     ["Exam boards protect names, syllabi, and past papers.", "Treat official affiliation as upside, not base case."], ["T3.2", "T6.3"]),
    ("T7.5", "E7", "Build the teacher dashboard only if LOIs pass", "Backlog", "low", "M7", "C8", "2027-03-02", "2027-03-09", 8,
     ["area:product", "phase:2-expansion", "ws:teacher-exam", "risk:medium", "platform:web"],
     "A dashboard is a separate product with accounts, permissions, and support. Earn it.",
     ["Assign pieces/drills; view practice data; review recordings; comment.", "Roles, invites, audit log, deletion.", "Only after 3 paid pilots."],
     ["Do not build this before the core loop retains consumers.", "Teacher support can exceed revenue at small scale."], ["T7.2", "T7.3"]),
    ("T7.6", "E7", "Decide on an exam-board partnership", "Backlog", "low", "M7", "C8", "2027-03-02", "2027-03-09", 2,
     ["area:business", "phase:2-expansion", "ws:teacher-exam", "risk:medium", "platform:docs"],
     "Official affiliation could unlock trust and content, but the sales cycle is long.",
     ["Identify one board; request partnership terms.", "Compare against generic packs.", "Do not block V1 on it."],
     ["A board deal is upside, not a dependency.", "Get legal review before using any board name."], ["T6.3"]),

    # E8 — growth
    ("T8.1", "E8", "Build the free web sight-reading test + email capture", "Ready", "high", "M8", "C1", "2026-11-18", "2026-12-01", 8,
     ["area:growth", "phase:1-core", "ws:growth-distribution", "risk:medium", "platform:web"],
     "A shareable, useful top-of-funnel asset that proves the assessment and captures demand.",
     ["2-minute test; 2–4 bars; shareable result; email capture.", "No account required; clear privacy copy.", "Links to the app waitlist/pre-sale."],
     ["This is the only scalable viral asset in the plan.", "Do not require a download to try it."], ["T1.7"]),
    ("T8.2", "E8", "Write the ASO subtitle, screenshots, and keyword plan", "Ready", "medium", "M8", "C4", "2026-12-30", "2027-01-05", 3,
     ["area:growth", "phase:1-core", "ws:growth-distribution", "risk:low", "platform:ios", "platform:android"],
     "The name 'Hear Me Out' has no guitar/learn keyword. The subtitle and screenshots must carry discovery.",
     ["Subtitle: 'Guitar Sight-Reading & Practice'.", "Screenshots show notation, a real phrase, before/after, 5-minute session.", "Keyword list: guitar sight reading, learn notation, classical guitar practice, adult guitar."],
     ["Do not buy installs before organic/teacher traction.", "Test screenshots with 10 target users."], []),
    ("T8.3", "E8", "Publish 20 free lessons/tools in 12 months", "Ready", "medium", "M8", "C1", "2026-11-25", "2026-12-15", 3,
     ["area:growth", "phase:1-core", "ws:growth-distribution", "risk:medium", "platform:web"],
     "SEO and community trust need free, genuinely useful assets, not landing-page fluff.",
     ["20 assets: sight-reading basics, rhythm, practice method, first pieces, tuning/intonation.", "Each links to the web test or waitlist.", "Track which assets produce signups."],
     ["Do not gate the free assets.", "Write for the adult returner, not the conservatory student."], []),
    ("T8.4", "E8", "Run the short-form video engine (2/week for 8 weeks)", "Ready", "medium", "M8", "C2", "2026-12-02", "2027-01-26", 5,
     ["area:growth", "phase:1-core", "ws:growth-distribution", "risk:medium", "platform:web"],
     "Short-form is the cheapest organic reach for 'can you sight-read this?' and 'fix this bar' demos.",
     ["Formats: 30-second sight-reading challenge, before/after, teacher tip, 'why your G chord buzzes' (later).", "2/week for 8 weeks; measure views, clicks, signups.", "Repurpose into the community plan."],
     ["Do not chase viral trends that misrepresent the product.", "Use real students with consent."], []),
    ("T8.5", "E8", "Write the community launch plan (r/classicalguitar, Delcamp, teachers)", "Ready", "medium", "M8", "C4", "2027-01-02", "2027-01-10", 3,
     ["area:growth", "phase:1-core", "ws:growth-distribution", "risk:medium", "platform:docs"],
     "Communities are promotion-sensitive. Give value first, then ask.",
     ["Participate for 4 weeks before launching.", "Share free tools/lessons, not ads.", "Teacher newsletter/association outreach; 3 partnerships."],
     ["Do not spam subreddits or forums.", "Respect each community's self-promotion rules."], []),
    ("T8.6", "E8", "Build the referral/share-card loop", "Backlog", "low", "M8", "C5", "2027-01-13", "2027-01-20", 3,
     ["area:growth", "phase:1-core", "ws:growth-distribution", "risk:low", "platform:ios"],
     "A private before/after card can be shared without exposing a score or account.",
     ["Share card includes piece, date, one metric, optional audio.", "Referral link/code; no public leaderboard.", "Measure shares → installs."],
     ["Do not share recordings by default.", "No score-based social comparison."], ["T4.4"]),

    # E9 — risks/decisions
    ("T9.1", "E9", "Maintain the risk register", "In Progress", "high", "M9", "C0", "2026-11-04", "2026-11-06", 3,
     ["area:research", "phase:0-validation", "ws:core-loop", "risk:high", "platform:docs"],
     "Track likelihood, impact, mitigation, owner, and kill criteria for every major risk.",
     ["At least: phrase false negatives, bleed, content cost, market size, privacy, copyright, solo bandwidth.", "Each risk links to a mitigation ticket.", "Review weekly; update status."],
     ["A risk without an owner and a mitigation is a wish.", "Surface risks in the weekly review."], []),
    ("T9.2", "E9", "Maintain the decision log", "In Progress", "high", "M9", "C0", "2026-11-04", "2026-11-06", 2,
     ["area:research", "phase:0-validation", "ws:core-loop", "risk:medium", "platform:docs"],
     "Record context, alternatives, decision, and consequences so future agents do not relitigate.",
     ["Decisions: 5-minute default, monophonic V1, no social/cloud/AI in V1, notation wedge, $69 price test, teacher Phase 2.", "Each decision has a date and owner.", "Link to the relevant work items."],
     ["Do not rewrite history; add a new decision if the context changes."], []),
    ("T9.3", "E9", "Maintain the research dossier with caveats", "In Progress", "high", "M9", "C0", "2026-11-04", "2026-11-06", 5,
     ["area:research", "phase:0-validation", "ws:core-loop", "risk:medium", "platform:docs"],
     "Every claim used in the plan or marketing should have a source and a caveat.",
     ["15+ sources with title, year, link, what it proves, what it does not prove.", "Separate peer-reviewed evidence from industry estimates.", "Link from relevant tickets."],
     ["Do not overstate small studies or marketing stats.", "Use 'promising' where the evidence is thin."], []),
    ("T9.4", "E9", "Build the kill-criteria dashboard", "Ready", "high", "M9", "C1", "2026-11-25", "2026-12-01", 2,
     ["area:research", "phase:0-validation", "ws:core-loop", "risk:high", "platform:docs"],
     "Know when to stop or pivot before spending months.",
     ["Spike metrics, session-2 return, day-7 recording, pre-sale conversion, D30, free→paid, content cadence.", "Each has a threshold and an owner.", "Review at every phase gate."],
     ["Do not move the goalposts after seeing the data.", "A failed gate is information, not failure."], []),
    ("T9.5", "E9", "Maintain the assumption tracker", "Ready", "medium", "M9", "C1", "2026-11-25", "2026-12-01", 2,
     ["area:research", "phase:0-validation", "ws:core-loop", "risk:medium", "platform:docs"],
     "List the beliefs the plan depends on and the cheapest test for each.",
     ["Demand, price, mic accuracy, content cost, retention, teacher willingness, legal status.", "Each assumption has evidence, confidence, and a test.", "Update after each experiment."],
     ["The weakest assumptions are demand and phrase assessment; test them first."], []),
    ("T9.6", "E9", "Write the AI handoff protocol", "Ready", "high", "M9", "C0", "2026-11-04", "2026-11-05", 2,
     ["area:product", "phase:0-validation", "ws:core-loop", "risk:low", "platform:docs"],
     "Future agents must know where to start, what is decided, what is blocked, and how to update the project.",
     ["Read START HERE → strategy → assessment → current cycle → ticket.", "Update decision log, risk register, and ticket status after work.", "Do not reopen settled decisions without new evidence."],
     ["Keep the plan and the tickets linked.", "Never invent metrics or mark work done without acceptance criteria."], []),
    ("T9.7", "E9", "Set the weekly review cadence", "Ready", "medium", "M9", "C0", "2026-11-04", "2026-11-06", 1,
     ["area:research", "phase:0-validation", "ws:core-loop", "risk:low", "platform:docs"],
     "A 30-minute weekly review keeps the plan honest.",
     ["Review risks, decisions, cycle progress, blockers, and metrics.", "Update the next cycle and the START HERE status.", "Record one lesson learned."],
     ["Do not skip the review during a busy build week; it is where the plan stays real."], []),
    ("T9.8", "E9", "Create the phase-gate checklist", "Ready", "medium", "M9", "C6", "2027-01-27", "2027-02-02", 2,
     ["area:research", "phase:1-core", "ws:core-loop", "risk:high", "platform:docs"],
     "Gate each phase on evidence, not enthusiasm.",
     ["Phase 0: spike pass, pre-sale, legal/funding.", "Phase 1: 20 users, 3x/week, 4 weeks, false fail ≤10%, D7 ≥18%.", "Phase 2: D30 ≥10%, free→Pro ≥2%, 3 teacher pilots.", "Phase 3: guitar retention proven before piano."],
     ["If a gate fails, fix the loop or pivot; do not add features."], []),
]

# Relations: dependent -> blockers
RELATIONS = {
    "T1.6": ["T1.1", "T1.2", "T1.3", "T1.4", "T1.5"],
    "T1.7": ["T1.6"],
    "T1.11": ["T1.8", "T1.9", "T6.2"],
    "T2.1": ["T1.7"],
    "T2.2": ["T2.1"],
    "T2.3": ["T2.1"],
    "T2.4": ["T2.1"],
    "T2.5": ["T2.1", "T2.3"],
    "T2.6": ["T2.4", "T2.5"],
    "T2.8": ["T2.6"],
    "T2.9": ["T2.6"],
    "T2.11": ["T2.1"],
    "T3.2": ["T2.1"],
    "T3.3": ["T3.1", "T3.2"],
    "T3.4": ["T3.1", "T3.2"],
    "T3.5": ["T3.3", "T3.4"],
    "T3.6": ["T3.2"],
    "T3.7": ["T3.6"],
    "T3.8": ["T3.3", "T3.4", "T3.5", "T3.6"],
    "T4.2": ["T4.1"],
    "T4.3": ["T4.2"],
    "T4.4": ["T4.2"],
    "T4.6": ["T4.3"],
    "T5.2": ["T5.1", "T2.6"],
    "T5.3": ["T2.5"],
    "T6.4": ["T4.4", "T3.8"],
    "T6.5": ["T6.4"],
    "T6.6": ["T6.2", "T1.8"],
    "T6.7": ["T6.3"],
    "T7.2": ["T4.2"],
    "T7.4": ["T3.2", "T6.3"],
    "T7.5": ["T7.2", "T7.3"],
    "T7.6": ["T6.3"],
    "T8.6": ["T4.4"],
}

# Links to add
LINKS = {
    "T9.3": [
        ("https://pubmed.ncbi.nlm.nih.gov/24986855/", "Macnamara et al. 2014 — deliberate practice meta-analysis"),
        ("https://doi.org/10.1037/a0037123", "Ma et al. 2014 — intelligent tutoring systems meta-analysis"),
        ("https://doi.org/10.3389/fpsyg.2016.01251", "Interleaved practice in music (2016)"),
        ("https://doi.org/10.1177/1029864914568044", "Evans 2015 — self-determination theory in music education"),
        ("https://doi.org/10.3390/ijerph18073550", "Gamification meta-analysis (2021)"),
        ("https://doi.org/10.3389/fpsyg.2025.1675762", "AI-assisted practice app study (2025)"),
        ("https://doi.org/10.3389/fpsyg.2021.648479", "Violin real-time feedback RCT (2021)"),
        ("https://arxiv.org/abs/2509.16913", "Difficulty-aware score generation (2025)"),
        ("https://arxiv.org/abs/2511.16228", "Difficulty-controlled simplification (2025)"),
        ("https://arxiv.org/abs/2412.13514", "Tuning Music Education (2024)"),
        ("https://arxiv.org/abs/2004.13362", "Flow and adaptive music software (2020)"),
        ("https://doi.org/10.3389/fpsyg.2026.1776445", "Empowerment vs dependency review (2026)"),
        ("https://doi.org/10.1016/j.caeo.2026.100354", "Technology-enhanced music learning review (2026)"),
        ("https://doi.org/10.1371/journal.pone.0259105", "Ruth & Müllensiefen 2021 — musical dropout"),
        ("https://naavik.co/digest/music-games-and-the-setlist-problem/", "Naavik — music games and the setlist problem"),
    ],
    "T3.1": [
        ("https://imslp.org/", "IMSLP — public-domain scores (verify edition/territory)"),
        ("https://www.pdinfo.com/", "PD Info — public-domain status reference"),
    ],
    "E0": [
        ("https://github.com/morekaccino/hear-me-out", "Hear Me Out repository"),
    ],
}

COMMENTS = {
    "E0": "<p><strong>Read order:</strong> START HERE → Strategy → Audit → Target/Scope → Assessment → Session/Curriculum → Technical → Business → Metrics/Roadmap → Risks → Research. Then open the current cycle (C0).</p><p>Update the decision log and risk register after every meaningful change. Do not reopen a settled decision without new evidence.</p>",
    "T1.6": "<p><strong>Spike report must include:</strong> per-phrase false pass/fail, per-note recall/precision, per-string recall, octave-error rate, onset MAE, expert ICC(2,k)/kappa, confidence intervals, and stratified 4/8/16-note results.</p><p>If the gate fails, do not build the Today UI; pivot to call-and-response, single-bar, or pure notation.</p>",
    "T6.1": "<p><strong>Pre-sale gate:</strong> 30+ pre-orders across cells or ≥3% conversion in the best cell. Track channel attribution and email capture. Do not lower the price to rescue a weak signal.</p>",
    "T9.1": "<p><strong>Risk review:</strong> phrase false negatives, backing bleed, content cost, market size, privacy, copyright, solo bandwidth. Each risk needs an owner, a mitigation ticket, and a kill criterion.</p>",
}


def create_issue(name, parent, state, priority, module, cycle, start, target, labels, description, existing):
    if name in existing:
        issue = existing[name]
        print(f"  = {name} ({issue['id']})", flush=True)
        return issue
    payload = {
        "name": name,
        "description_html": description,
        "priority": priority,
        "state": STATE_IDS[state],
        "assignees": [USER_ID],
        "labels": labels,
        "parent": parent,
        "start_date": start,
        "target_date": target,
    }
    r = api("POST", f"/projects/{PID}/issues/", payload)
    if r.status_code >= 400:
        print(f"  !! failed {name}: {r.status_code} {r.text[:300]}", flush=True)
        return None
    issue = r.json()
    print(f"  + {name} ({issue['id']})", flush=True)
    # Add to module and cycle (best-effort; ignore already-present errors).
    api("POST", f"/projects/{PID}/modules/{MODULE_IDS[module]}/module-issues", {"issues": [issue["id"]]})
    api("POST", f"/projects/{PID}/cycles/{CYCLE_IDS[cycle]}/cycle-issues", {"issues": [issue["id"]]})
    time.sleep(0.8)
    return issue


def main():
    print("Fetching existing issues and labels...", flush=True)
    existing_list = list_all(f"/projects/{PID}/issues/?per_page=100")
    existing = {i["name"]: i for i in existing_list}
    labels_list = list_all(f"/projects/{PID}/labels/?per_page=100")
    label_map = {l["name"]: l["id"] for l in labels_list}
    print(f"  {len(existing)} existing issues, {len(label_map)} labels", flush=True)

    # E0 first
    e0_data = next(e for e in EPICS if e["key"] == "E0")
    e0 = create_issue(
        e0_data["name"], None, e0_data["state"], e0_data["priority"], e0_data["module"], e0_data["cycle"],
        e0_data["start"], e0_data["target"], [label_map[x] for x in e0_data["labels"]],
        task_html(e0_data["summary"], e0_data["scope"], e0_data["acceptance"]), existing,
    )
    if not e0:
        sys.exit(1)
    created = {"E0": e0}

    # Documents under E0
    doc_sections = {
        "D0.2": section("0. The one-paragraph plan") + "\n\n" + section("1. Why this plan, and what changed"),
        "D0.4": section("2. Target user and positioning") + "\n\n" + section("3. V1 scope"),
        "D0.5": section("4. Assessment contract"),
        "D0.6": section("5. Session design") + "\n\n" + section("6. Curriculum and content") + "\n\n" + section("7. Mastery, FSRS, and progress"),
        "D0.7": section("8. Gamification and social") + "\n\n" + section("9. Recording and privacy") + "\n\n" + section("10. Technical plan"),
        "D0.8": section("11. Business model"),
        "D0.9": section("12. Metrics and experiments") + "\n\n" + section("13. Roadmap"),
        "D0.10": section("14. Risks and mitigations") + "\n\n" + section("15. What not to do") + "\n\n" + section("16. Open decisions"),
        "D0.11": section("Appendix A - Research base (use carefully)"),
        "D0.12": section("Appendix B - Competitor gap") + "\n\n" + section("Appendix C - Public-domain shortlist (verify per territory)"),
    }
    for key, name, summary, typ, area in DOCS:
        if key == "D0.1":
            body = "<p>This page is the index. Read the child documents in order, then open the current cycle.</p>"
        elif key == "D0.3":
            body = AUDIT_HTML
        elif key == "D0.13":
            body = """<h2>Glossary</h2><ul>
<li><strong>Piece / Phrase:</strong> a complete monophonic work, and a 1–4 bar segment used for daily practice.</li>
<li><strong>Can recognize / Can play slowly / Can perform:</strong> three separate claims; only the third is mastery.</li>
<li><strong>Practice pass:</strong> ≥85% determinate notes correct, timing within pedagogical tolerance; for drilling.</li>
<li><strong>Performance mastery:</strong> 100% determinate notes correct, no bar with an error, in time, 3 separate days, ≥7 days after first, novel transfer, delayed uncheckpoint.</li>
<li><strong>Indeterminate:</strong> the mic could not hear enough; retry, never fail, no FSRS/XP/streak update.</li>
<li><strong>Tempo ladder:</strong> 50/60/70/80/90/100% of target; advance after two clean passes.</li></ul>
<h2>AI operating manual</h2><ul>
<li>Start at START HERE (HEARM-1) and read the strategy, audit, assessment, and current cycle.</li>
<li>Never reopen a settled decision without new evidence; add a new decision record instead.</li>
<li>Before changing code, read <code>AGENTS.md</code>, <code>LEARNING_ALGORITHM.md</code>, and the assessment contract.</li>
<li>After work, update the ticket status, decision log, risk register, and next-cycle plan.</li>
<li>Do not invent metrics or mark a ticket done without its acceptance criteria.</li></ul>"""
        else:
            body = doc_html(name, doc_sections.get(key, summary), key)
        issue = create_issue(
            f"{key} — {name}", e0["id"], "Done" if key != "D0.1" else "In Progress", "high",
            "M0", "C0", "2026-11-04", "2026-11-05",
            [label_map[typ], label_map[area], label_map["phase:0-validation"], label_map["platform:docs"]],
            body, existing,
        )
        if issue:
            created[key] = issue

    # Remaining epics
    for epic in EPICS:
        if epic["key"] == "E0":
            continue
        issue = create_issue(
            epic["name"], None, epic["state"], epic["priority"], epic["module"], epic["cycle"],
            epic["start"], epic["target"], [label_map[x] for x in epic["labels"]],
            task_html(epic["summary"], epic["scope"], epic["acceptance"]), existing,
        )
        if issue:
            created[epic["key"]] = issue

    # Tasks
    for (key, epic_key, name, state, priority, module, cycle, start, target, _effort, labels, summary, scope, acceptance, blocked_by) in TASKS:
        if epic_key not in created:
            print(f"  !! missing epic {epic_key} for {key}", flush=True)
            continue
        desc = task_html(summary, scope, acceptance, blocked_by=blocked_by, estimate=f"{_effort} ideal days")
        issue = create_issue(
            f"{key} — {name}", created[epic_key]["id"], state, priority, module, cycle, start, target,
            [label_map[x] for x in labels], desc, existing,
        )
        if issue:
            created[key] = issue

    # Relations
    print("Adding dependencies...", flush=True)
    for dependent, blockers in RELATIONS.items():
        if dependent not in created:
            continue
        ids = [created[b]["id"] for b in blockers if b in created]
        if not ids:
            continue
        r = api("POST", f"/projects/{PID}/work-items/{created[dependent]['id']}/dependencies/",
                {"relation_type": "blocked_by", "work_item_ids": ids})
        print(f"  {dependent} blocked_by {blockers}: {r.status_code}", flush=True)
        time.sleep(0.5)

    # Links
    print("Adding links...", flush=True)
    for key, links in LINKS.items():
        if key not in created:
            continue
        for url, title in links:
            r = api("POST", f"/projects/{PID}/work-items/{created[key]['id']}/links", {"url": url, "title": title})
            print(f"  {key} link {title[:40]}: {r.status_code}", flush=True)
            time.sleep(0.4)

    # Comments
    print("Adding comments...", flush=True)
    for key, body in COMMENTS.items():
        if key not in created:
            continue
        r = api("POST", f"/projects/{PID}/work-items/{created[key]['id']}/comments/", {"comment_html": body})
        print(f"  {key} comment: {r.status_code}", flush=True)
        time.sleep(0.4)

    # Build START HERE index with links
    if "D0.1" in created:
        rows = []
        for key, name, summary, typ, area in DOCS:
            if key == "D0.1" or key not in created:
                continue
            issue = created[key]
            url = f"{BASE}/{WS}/projects/{PID}/issues/{issue['id']}"
            rows.append(f'<li><a href="{url}">{html.escape(name)}</a> — {html.escape(summary)}</li>')
        index_html = f"""<h2>Start here</h2>
<p>This project is the single source of truth for the Hear Me Out transformation. Read the documents in order, then open the current cycle (C0 — Validation &amp; Assessment Spike).</p>
<h2>Context documents</h2><ul>{''.join(rows)}</ul>
<h2>How to use this project</h2><ul>
<li><strong>States:</strong> Backlog → Ready → In Progress → In Review / Validating → Blocked → Done / Cancelled.</li>
<li><strong>Labels:</strong> Area (product, assessment, audio, content, business, growth, research, legal), Type (epic, feature, story, task, spike, bug, decision, risk, experiment, content, research), Phase (0–3), Risk (high/medium/low), Workstream, Platform.</li>
<li><strong>Cycles:</strong> 10 two-week cycles from C0 (Nov 4–17) through C9 (Mar 10–23). Tickets are assigned to the cycle where the work should happen.</li>
<li><strong>Modules:</strong> 10 workstreams from charter to risks. Every ticket belongs to one module.</li>
<li><strong>Dependencies:</strong> use the Relations section on a ticket to see what blocks it and what it blocks. The critical gate is T1.7 (spike go/no-go) → T2.1 (core model).</li>
<li><strong>Decision log:</strong> D0.13 and T9.2. Do not reopen a settled decision without new evidence.</li>
<li><strong>Risk register:</strong> T9.1. Every risk has an owner, mitigation ticket, and kill criterion.</li>
</ul>
<h2>Current status</h2><p><strong>Phase 0 — Validation &amp; Assessment Spike.</strong> The only build work allowed before the gate is the corpus, audio fixes, phrase matcher, pre-sale, concierge, legal review, and funding decision. If the spike fails, pivot to call-and-response, single-bar, or a pure notation trainer.</p>
<p><strong>Local canonical plan:</strong> <code>{html.escape(str(PLAN_PATH))}</code></p>"""
        r = api("PATCH", f"/projects/{PID}/issues/{created['D0.1']['id']}/", {"description_html": index_html})
        print(f"  START HERE index updated: {r.status_code}", flush=True)

    # Project description points to START HERE
    start_url = f"{BASE}/{WS}/projects/{PID}/issues/{created['D0.1']['id']}" if "D0.1" in created else ""
    desc = (
        "Single source of truth for the Hear Me Out transformation: strategy, audit, assessment contract, "
        "content plan, business model, roadmap, risks, and AI handoff. "
        f"START HERE: {start_url}. Local canonical plan: {PLAN_PATH}"
    )
    api("PATCH", f"/projects/{PID}/", {"description": desc})
    print("Done.", flush=True)
    print(f"Created/reused {len(created)} work items.", flush=True)


if __name__ == "__main__":
    main()
