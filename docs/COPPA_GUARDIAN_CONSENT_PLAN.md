# COPPA and guardian consent plan

**Version:** 0.1 (draft for counsel review).
**Status:** Not approved. No gate in [§7](#7-legal-review-gate) is cleared.
**Ticket:** T7.3 / HEARM-86.
**Applies to:** the Phase 2 teacher and exam channel only. The Phase 1 consumer
app is not gated by this plan.
**Owner:** Human owner (business and legal decisions). Engineering owns the
workflows this plan requires.
**Last updated:** 2026-11-06.

> **This is a product, engineering, and operations plan, not legal advice.**
> It records the controls the project believes it needs and the evidence it
> must collect. A qualified lawyer must review it for each pilot territory
> before any minor uses the teacher channel. Where this plan and the law
> differ, the law wins. Do not describe the product as "COPPA compliant,"
> "COPPA certified," or "legally approved" on the basis of this document.
>
> **This is a compliance gate, not a feature.** It does not add an app screen,
> a setting, a teacher workflow, or a new data path. It says what must be true
> before the Phase 2 teacher channel may be built or sold.

**Marker used in this document.** Every legal statement is marked
**counsel to confirm**. That marker means the project has not received a
written legal opinion on the statement and must not rely on it. The marker
stays until counsel supplies a dated memo that is linked in the gate table.

**Status vocabulary.**

| Status | Meaning |
|---|---|
| `Open` | No evidence yet. The gate is not met. |
| `Draft` | A document or workflow exists but is not approved or tested. |
| `Not built` | The product surface does not exist in the repository. |
| `Not run` | The test or rehearsal has not happened. |
| `Shipped` | The rule or capability exists in the approved plan or the code. It is not a legal clearance. |
| `Cleared` | A dated, named piece of evidence exists and counsel has approved it. **No gate is Cleared today.** |

---

## 0. Current state, so the plan is not mistaken for shipped behavior

The teacher channel is a Phase 2 plan. The repository currently contains the
consumer notation course. It has no teacher accounts, no student roster, no
teacher dashboard, and no teacher consent flow. The table separates what exists
from what this plan would require.

| Capability | Today | Evidence | Status |
|---|---|---|---|
| Consumer app has no account, cloud sync, remote analytics, or third-party tracker | Shipped rule | [`../AGENTS.md`](../AGENTS.md) hard rule 1; [decision 0006](decisions/0006-local-retention-instrumentation.md) | Shipped |
| Progress is local in `shared_preferences` | Shipped | `flutter_app/lib/core/storage/progress_store.dart` | Shipped |
| Recordings use a local `MediaStore` and are excluded from cloud backup when the platform confirms it | Shipped | T4.1, T4.5; [decision 0002](decisions/0002-backup-exclusion-no-opt-in.md) | Shipped |
| Recording, delete, and export controls in the UI | Not built | T4.2 and T7.2 are not merged into this branch | `Not built` |
| Teacher dashboard, roster, assignments, comments | Not built by design before three paid pilots | T7.5; plan §10.3 | `Not built` |
| Parent/guardian consent for the teacher channel | No in-app flow; this document defines a manual pilot process | This document | `Draft` |
| Deletion rehearsal for recordings and exports | Not run | [§4.8](#48-test-before-any-claim) | `Not run` |
| AI feedback on a minor's audio | Not built and not allowed in V1 | Plan §10.4 and §15; [§5](#5-moderation-and-safety) | Excluded |
| Public recital, social feed, direct messages, or UGC for minors | Not built and not allowed | Plan §10.5, §15; [§5](#5-moderation-and-safety) | Excluded |

The rest of this document describes the planned teacher path, not a shipped
feature. Do not copy its commitments into marketing copy until the gate table
is cleared.

---

## 1. Scope and trigger

### 1.1 What counts as the teacher channel

The teacher channel is any use of the app or its exports in a teacher-led
setting, including:

- a teacher assigns a piece, phrase, or drill to a student;
- a student exports a take plus a JSON/PDF summary for a teacher to review;
- a teacher buys a Teacher Studio subscription or an exam pack;
- a school, studio, or exam preparation business deploys the app to students;
- a teacher reviews a student's recording outside the app after the student
  shares it;
- a pilot described as a "teacher pilot," "studio pilot," "school pilot," or
  "exam pilot."

The consumer app used by an adult on their own, with no teacher involvement, is
outside this plan. A minor who uses the consumer app without a teacher is also
outside this plan, but the consumer app's own privacy rules still apply. If the
project markets the consumer app to children or schools, or adds a child-facing
feature, this plan's scope must be reopened before that change. Counsel to
confirm.

The teacher channel **does not ship at all** until every gate in §7 is cleared.
It is not enough to exclude under-13 students. The product cannot reliably
separate a 12-year-old from an adult in a local-only app with no accounts, so
the whole channel is gated. This is the conservative reading; counsel to
confirm.

### 1.2 Who is covered

The plan uses two thresholds:

1. the legal threshold for parental consent in each territory; and
2. the project's stricter operational threshold: **every student under 18 is a
   minor for this plan's rules**, even where consent can be given at 13 or 16.

| Territory | Legal age for consent to an information-society service | What this plan does | Marker |
|---|---|---|---|
| United States | Under 13 is a child under COPPA and the FTC COPPA Rule (16 C.F.R. Part 312) | Treat every under-18 student as a minor; require guardian consent for under-13 students and for any student the teacher cannot confirm is 18 or older | Counsel to confirm |
| European Union | GDPR Article 8 sets 16, but a member state may lower the age to 13 (not below 13) | Require guardian consent below the age set by the pilot member state; default to under 16 until counsel confirms the state | Counsel to confirm |
| United Kingdom | 13 under the UK GDPR and the Data Protection Act 2018; the ICO Age Appropriate Design Code applies to services likely to be accessed by children | Require guardian consent below 13; apply the code's design standards to the pilot | Counsel to confirm |
| Canada | PIPEDA does not set one age; the Office of the Privacy Commissioner treats under-13 data as requiring parental consent in practice, and Quebec has separate rules for younger minors | Require guardian consent below 13 by default; check the province before a Canadian pilot | Counsel to confirm |
| Other pilot markets | Varies | Do not pilot until counsel names the age and consent rule for that market | Counsel to confirm |

The stricter internal rule (under 18) exists because the teacher channel has no
age verification and because the plan promises no public recital, no
messaging, and no AI feedback for minors. It is easier to apply one safe rule
across the pilot than to prove a student's exact age.

### 1.3 Trigger checklist

Run this checklist before a teacher, studio, or school receives a pilot build
or an assignment sheet.

- [ ] The pilot territory is named and counsel has confirmed its age rule.
- [ ] Every participating student is listed with a year-of-birth or age band
      and a minor/adult flag. A full date of birth is not collected.
- [ ] A parent/guardian consent record exists for every minor.
- [ ] The parent or guardian has seen the current parent notice and the
      data list in §2.
- [ ] The teacher has signed the attestation in §6.1.
- [ ] The project lead has checked the redacted consent register against the
      roster.
- [ ] The deletion rehearsal in §4.8 has been run for the devices in scope.
- [ ] The pilot plan names an incident contact and a 24-hour escalation path.
- [ ] No public recital, leaderboard, social feed, direct messaging, or UGC is
      enabled for the pilot.
- [ ] The app build has no network, cloud, account, or analytics path beyond
      the local opt-in retention log. The log stays off for minors.

If any box is unchecked, the pilot does not start.

### 1.4 What this plan does not decide

This plan does not decide whether the project is legally required to obtain
consent in a given territory. It assumes the stricter reading for the pilot
and asks counsel to confirm the actual obligation. In particular, counsel must
answer whether a fully local app with no server-side collection is an
"operator" collecting personal information under COPPA, and whether the
project is a controller or processor for data the teacher holds. Counsel to
confirm.

---

## 2. Data minimization

### 2.1 Principles

1. **The app holds the practice, not the child's identity.** There is no
   account, no student profile, no school record, and no name field in the
   app's progress data.
2. **The teacher holds the consent record, not the app.** Parent names,
   signatures, and contact details do not go into the app or into an export.
3. **Recordings stay local by default.** A saved take leaves the device only
   when the student starts a manual export.
4. **The export carries the minimum needed for a lesson review.** No device
   identifier, install id, email, location, or contact list.
5. **No behavioral advertising and no sale of data.** There is no ad SDK and
   no data broker in the product.
6. **Keep data for a stated period, then delete it.** "Keep it forever in case
   it is useful" is not allowed.

### 2.2 Data inventory for the planned teacher path

This table describes the smallest data set the pilot needs. It is not a
description of shipped code.

| Data | Why it is needed | Where it lives | Default retention | In an export? | Marker |
|---|---|---|---|---|---|
| Student label (a short code such as `stu_7f3a`, or a self-chosen nickname; no legal name) | The teacher needs to know whose work they are reviewing | Teacher's roster and, optionally, the export header | Until the student leaves the pilot plus 14 days | Only if the student chooses to include it | Counsel to confirm |
| Assignment label or piece/phrase id | Match the take to the assigned work | App progress and export header | Local until reset; export 30 days | Yes | N/A (not personal data) |
| Practice summary: skill ids, pass/fail, accuracy, minutes, dates | Show what was practiced and what needs work | Local progress; optional export summary | Local until reset; export 30 days | Yes | Counsel to confirm |
| Take audio (WAV/AAC, 60 s cap, 20 takes) | Let the teacher hear the take | Local `MediaStore` only; the teacher receives a copy only through manual export | Local until the student deletes it; teacher copy 30 days, hard cap 90 days | Only with separate recording/export consent | Counsel to confirm |
| Take metadata: piece id, phrase id, duration, score, analysis version | Reproduce the review without the audio | Local `MediaStore` manifest and export summary | Same as the take | Yes | N/A (not personal data) |
| Consent record: parent/guardian name, contact, signature, date, scopes, student label, age band | Prove consent and handle revocation | Teacher's locked file or the project's approved register; **not the app** | Participation plus 12 months, then destroy | No | Counsel to confirm |
| Redacted consent register entry: record id, student label, age band, scopes, dates | Audit that a record exists without copying parent details | Project register held by the pilot lead | Participation plus 12 months | No | Counsel to confirm |
| Deletion and incident log: record id, dates, scope, action | Show that a request was handled | Project register | 24 months | No | Counsel to confirm |
| Support message from a parent or teacher | Resolve a problem | The project's support mailbox or ticket system | 90 days after resolution | No | Counsel to confirm |

The following are **not** collected in the teacher path:

| Never collected | Reason |
|---|---|
| Full date of birth | An age band or year of birth is enough to apply the minor rule |
| Home address, school address, or geolocation | Not needed for practice review |
| School student id, timetable, grades, IEP, or health data | Not needed and creates a student-record obligation |
| Parent's government id, unless a verification method in §3.2 requires it | Disproportionate for a small pilot |
| Contacts, calendar, photos, camera, or microphone outside a practice session | Outside the feature |
| Advertising id, device fingerprint, or cross-app tracking | No ads or trackers |
| Voiceprint or biometric template | The microphone is for pitch analysis, not identity |
| Payment card or bank data | Teacher billing is handled by the app store or a separate contract, not by the student app |
| Free-text notes about a child's behavior or ability | The summary uses fixed fields; free text is not needed |

### 2.3 Local-only architecture

The consumer app is local-only today. The same rule applies to the teacher
path.

- No network, cloud, accounts, remote analytics, or third-party trackers. The
  only usage log is the local, opt-in retention log in
  [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md); it is never
  uploaded and it is off by default.
- Progress lives in `shared_preferences` under the app's own key. It contains
  lesson, skill, and phrase progress, not a name, email, or school.
- Recordings live in the local `MediaStore`. Android Auto Backup and device
  transfer exclude the recording directory; iOS asks the system to exclude it
  and the profile card says when that confirmation is missing. See
  [decision 0002](decisions/0002-backup-exclusion-no-opt-in.md).
- The only way data leaves the device is a manual export the user starts. For
  progress, that is the clipboard backup in Profile. For a teacher review, it
  is the T7.2 share-sheet export.
- There is no server that could receive a recording, a roster, or a consent
  record. There is no "delete from our server" step because there is no
  server.

**Retention-log rule for minors.** The local retention log stays off for every
minor in the teacher pilot. A parent may refuse it without affecting the
lesson. If a future pilot wants to study minors' usage, it needs a separate
consent, a separate purpose, and counsel review. Counsel to confirm.

**Device backup gap.** Progress may be included in the platform's device
backup even though recordings are excluded. The pilot must either disable
device backup on the pilot device or tell the parent that progress may be in
the device's own backup. The current privacy card does not make a claim about
progress backup. Counsel to confirm whether the pilot can accept this gap.

### 2.4 Pseudonymous identifiers

- The app's local retention log uses a random `installId` made from 16 bytes
  from `Random.secure()`. It is not derived from hardware, an account, or an
  advertising id. It never goes into a teacher export.
- The pilot register uses a student label such as `stu_7f3a`. The mapping from
  the label to a legal name stays in the teacher's consent file, not in the
  app, not in the export, and not in the central register.
- Export file names use the student label and the assignment id, for example
  `stu_7f3a_sor-study-01_2026-11-06.m4a`. Do not put a legal name in a file
  name, a folder name, or a share-sheet message.
- The teacher's roster is the only place where a label and a name can meet.
  It is stored separately from the exported takes.

### 2.5 Retention limits

| Record | Default limit | What happens at the limit | Owner | Marker |
|---|---|---|---|---|
| Local progress | Until the student resets progress or uninstalls the app | Deleted with the app's local storage | Student/guardian | N/A |
| Local takes | Until the student deletes them. The planned cap is 20 takes and 60 s per take; the current `MediaStore` does not enforce it, so T4.2 must add the cap or the pilot must enforce it | The student or guardian deletes them; uninstall removes the local store | Student/guardian | N/A |
| Export received by a teacher | 30 days after the review; hard maximum 90 days | Teacher deletes the file and confirms in the deletion log | Teacher | Counsel to confirm |
| Teacher roster | Until the student leaves the pilot plus 14 days | Teacher deletes the row; the redacted register keeps the record id and dates | Teacher | Counsel to confirm |
| Consent record | Participation plus 12 months, then destroy | Shred or securely delete; the deletion log keeps only the record id and dates | Teacher/pilot lead | Counsel to confirm |
| Redacted register | Participation plus 12 months | Delete; keep only aggregate counts | Pilot lead | Counsel to confirm |
| Deletion and incident log | 24 months | Delete; no audio, no name, no parent contact | Pilot lead | Counsel to confirm |
| Aggregate pilot report | No fixed end | Contains no student label, no audio, and no reversible key | Human owner | Counsel to confirm |

The limits are deliberately short. A teacher who needs a take for a longer
period must ask the parent for a new, specific consent; "it is already on my
device" is not a retention right. Counsel to confirm.

### 2.6 No accounts in V1

The teacher path has no student account, no teacher account, no cloud roster,
and no cross-device sync. The manual export flow is the integration. This is a
privacy choice and a scope choice:

- there is no login to phish and no password to reset for a child;
- there is no server-side roster to breach;
- the project cannot see a student's practice data unless the student or
  teacher sends it;
- the project also cannot remotely delete a teacher's copy, which is why the
  teacher agreement and deletion confirmation in §4 exist.

A future dashboard with accounts is T7.5 and is blocked by this plan and T7.2.
It needs a new decision record, a new data map, and a new legal review.

---

## 3. Verifiable parental consent

### 3.1 Standard

Before a minor uses the teacher channel, the project must have a record that a
parent or legal guardian:

1. saw the current parent notice and the data list in §2;
2. understood that the app is local-only and that the teacher receives only
   what the student exports;
3. agreed to the required scope and separately agreed to each optional scope;
4. was told how to revoke and how to request deletion; and
5. was not pressured by the teacher to consent.

The child cannot consent. The teacher cannot consent for the child. A school
may consent only in the limited circumstances counsel confirms in §3.2. Counsel
to confirm.

### 3.2 Consent methods

Use one method per pilot territory. The method must be documented in the
consent record.

| Method | How it works | Evidence produced | Fits the pilot? | Marker |
|---|---|---|---|---|
| Signed form plus live video call | The parent signs the form (wet ink or an approved e-signature) and the teacher or pilot lead holds a short video call to confirm the signer is the parent/guardian and to answer questions. The call is not recorded. | Signed form, call date, teacher attestation, redacted register entry | **Default** | Counsel to confirm |
| Signed form plus parent-initiated email from the address on the form | The parent prints, signs, scans, and sends the form from the contact address in the record. The teacher verifies the reply address. | Signed form, email header, attestation | Fallback where video is not possible | Counsel to confirm |
| Credit-card or government-id verification through a specialist provider | The parent verifies identity with a provider; the project receives only a pass/fail token. | Provider token, no card or id data retained by the project | **Not in the pilot**: adds sensitive data and a vendor for a small manual pilot | Counsel to confirm |
| School authorization | A school with the legal authority consents on parents' behalf under a written agreement, with notice to parents and an opt-out where required. | Signed school agreement, authorized signatory, parent notice | Conditional; only after counsel approves the school path | Counsel to confirm |
| Teacher attestation alone | The teacher signs a statement that consent exists. | Teacher attestation only | **Not sufficient** for a minor | Counsel to confirm |
| Email-only checkbox | A parent ticks a box in an email or web form. | Email/checkbox | **Not sufficient** for the pilot | Counsel to confirm |

The default is deliberately manual. At pilot scale (three teachers, up to 30
students each) a signed form and a video call are feasible. The project should
not collect identity documents or card data to save a few minutes of
administration.

### 3.3 What the parent must see before consenting

The parent notice is a separate one-page document. It must show all of the
following:

- [ ] The product name, the teacher's name and contact, and the pilot name.
- [ ] The exact data in §2.2, including a plain-language example of an export.
- [ ] That the app has no account, no cloud sync, and no remote analytics, and
      that the project cannot see the student's practice unless a file is sent.
- [ ] That a saved take stays on the device until the student deletes it or
      uninstalls the app, and that the teacher receives a copy only if the
      student exports it.
- [ ] That the teacher must delete an exported copy after the review and no
      later than 90 days.
- [ ] That no one will publish the recording, use it in a recital, or use it
      to train an AI model in this pilot.
- [ ] That there is no behavioral advertising and no sale of data.
- [ ] That the local opt-in retention log stays off for minors.
- [ ] That the parent can refuse any optional scope and still take part in the
      required practice.
- [ ] That the parent can revoke consent at any time and request deletion, and
      how to do it.
- [ ] The retention periods in §2.5 and what happens at the end.
- [ ] The incident contact and the project's response commitment.
- [ ] The date and version of the notice, so the consent record can point to
      the exact text the parent saw.
- [ ] A statement that the notice is not legal advice to the parent and that
      the parent may ask questions before signing.

If the notice changes, the project must decide whether existing consents still
cover the new processing. A material change needs a new consent, not a silent
update.

### 3.4 Consent record

The record is held by the teacher. The project keeps only a redacted register
row. Neither copy is stored in the app. The record must contain enough to prove
consent and to honor a revocation, and nothing more.

**Sample record (illustrative only; no real personal data).**

| Field | Example value | Notes |
|---|---|---|
| Record id | `CONSENT-2026-0001` | Stable; used in the redacted register |
| Pilot id | `TP-1` | Teacher pilot 1 |
| Plan and notice version | `COPPA-PLAN-0.1`, `NOTICE-0.1` | The exact documents the parent saw |
| Student label | `stu_7f3a` | No legal name in the app or export |
| Student age band | `10–12` | Minor flag: `yes`; full date of birth not collected |
| Parent/guardian name | `Parent A` | Legal name stays in this record only |
| Parent contact | `guardian.a@example.invalid` | Used for the notice and revocation |
| Relationship | `Parent` | Or legal guardian |
| Consent date | `2026-11-06` | UTC or local date with time zone |
| Method | `Signed form + video call` | Matches §3.2 |
| Required scope: teacher-assigned practice and local analysis | Agreed | Cannot be optional if the student takes part |
| Optional scope: save takes on the device | Agreed / declined | Separate tick |
| Optional scope: export a take and summary to the teacher | Agreed / declined | Separate tick |
| Optional scope: teacher keeps the export for 30 days | Agreed / declined | Separate tick |
| Optional scope: de-identified aggregate pilot report | Agreed / declined | Separate tick |
| Revocation channel | `guardian.a@example.invalid` or teacher phone | The parent can use either |
| Teacher attestation id | `ATT-2026-0001` | Links to §6.1 |
| Project lead check | `Checked 2026-11-07` | Redacted register updated |
| Status | `Active` | `Revoked` and `Expired` are the other values |

**Signature block.**

```text
Parent/guardian signature: ______________________  Date: __________

Teacher signature: _____________________________  Date: __________

Pilot lead signature: __________________________  Date: __________

I gave the parent the current notice and answered their questions.
I did not make participation conditional on an optional scope.
```

The parent gets a copy. The teacher keeps the original in a locked file or an
approved encrypted folder. The project keeps only the redacted register row.

### 3.5 How the teacher proves consent before a student uses the app

There is no server and no account, so the app cannot check consent. The
control is procedural and auditable:

1. The teacher collects the signed form and holds the video call.
2. The teacher creates the record in §3.4 and signs the attestation in §6.1.
3. The teacher sends the redacted register row (record id, student label, age
   band, scopes, dates) to the pilot lead. No parent name or contact is sent.
4. The pilot lead checks the row against the roster and marks it `Checked`.
5. Only then does the teacher give the student an assignment sheet or a pilot
   build.
6. The pilot lead spot-checks at least 20% of records each month: the full
   record is viewed on a call or in a secure screen share, and no copy is
   retained centrally.

If a student appears on the roster without a `Checked` row, the teacher stops
the assignment and the pilot lead investigates. A missing record is a pilot
incident, not a paperwork problem.

**Honest limitation.** A teacher who ignores the process can give the app to a
minor without a record. The app cannot prevent that in V1. The mitigations are
the signed teacher agreement, the register check, the monthly audit, and the
right to remove a teacher from the pilot. If counsel says this control is
insufficient, the teacher channel does not proceed until an in-app gate exists.

### 3.6 Consent lifecycle

| Stage | Action | Owner | Evidence | Status |
|---|---|---|---|---|
| Before enrollment | Give the parent notice and answer questions | Teacher | Notice version recorded | `Draft` |
| Enrollment | Collect the signed form, verify identity, record scopes | Teacher | §3.4 record | `Draft` |
| Pre-access check | Check the redacted register against the roster | Pilot lead | `Checked` row | `Draft` |
| During the pilot | Re-check at each term or at least every 12 months | Teacher | New record or re-attestation | `Open` |
| Material change | New notice and new consent | Teacher/pilot lead | New record id | `Open` |
| Revocation | Freeze assignments, delete exports, update the register | Teacher/pilot lead | Revocation record and deletion log | `Open` |
| Exit | Delete the consent record after the retention period | Pilot lead | Destruction entry | `Open` |

### 3.7 Revocation

A parent or guardian can revoke any scope, or all scopes, at any time, in
writing or verbally. The teacher writes down a verbal request and reads it
back.

Effects:

- New teacher assignments stop the same day.
- The student can keep using the consumer app on their own device if they
  choose, but the teacher must not review new work.
- The teacher deletes exported takes and summaries within 7 days, unless the
  parent asks for a copy first.
- The student or guardian deletes local takes and progress. If they want help,
  the teacher walks them through the app's delete and reset controls.
- The consent record is marked `Revoked`; the redacted register keeps the date
  and scope but not the reason.
- The project confirms the actions in writing within 14 days.
- A deletion log entry records the request and completion dates, with no audio
  and no name.

Revocation does not require the parent to give a reason, and it does not
affect any payment the teacher already made to the project. Counsel to
confirm.

---

## 4. Deletion and revocation

### 4.1 Rule

Do not claim "delete on request" until the workflow in this section has been
run end to end on the devices in scope and the evidence is in the pilot file.
The app currently has **Reset progress** and **Erase log** in Profile. It does
not have recording delete or export controls. Those arrive with T4.2 and T7.2
and must be tested before a pilot.

### 4.2 Request channels

| Requester | Channel | First response | Owner |
|---|---|---|---|
| Parent/guardian | The contact in the parent notice, the teacher, or the pilot lead | Acknowledge within 2 business days | Pilot lead |
| Teacher | The pilot lead's incident contact | Acknowledge within 1 business day | Pilot lead |
| Student | The teacher, or the app's own delete/reset controls | Same day for app controls; 2 business days for a mediated request | Teacher |
| School | The signed school agreement's contact | Per the agreement; default 2 business days | Human owner |

A request can be verbal. The receiver writes it down and reads it back. Do not
ask for a special form.

### 4.3 Deletion workflow

| Step | Action | Owner | Maximum time | Evidence |
|---|---|---|---|---|
| 1 | Log the request: date, requester role, scopes, record id. Do not log audio or a legal name in the central log. | Pilot lead | Same day | Request row |
| 2 | Acknowledge in writing and explain what will be deleted and what must be kept for audit. | Pilot lead | 2 business days | Acknowledgement copy |
| 3 | Freeze new assignments for the student. | Teacher | Same day | Roster note |
| 4 | Delete exported takes and summaries, including files in a local backup. | Teacher | 7 days | Deletion confirmation with file names |
| 5 | Delete local takes on the student's device. Use the recording delete control when it exists; until then, uninstall the app or clear the app's storage with the guardian present. | Student/guardian, teacher helps | 7 days | Signed confirmation or screenshot without personal data |
| 6 | Reset local progress, or delete the whole app if the guardian prefers. | Student/guardian | 7 days | Confirmation |
| 7 | Remove the teacher's roster row. | Teacher | 14 days | Roster note |
| 8 | Redact the consent record: remove the parent name, contact, and signature image; keep the record id, dates, scopes, and status `Revoked`. | Pilot lead | 14 days | Redacted record |
| 9 | Confirm all actions in writing, with the date and any backup purge date. | Pilot lead | 14 days | Confirmation letter |
| 10 | Purge backups, including the teacher's local backup and any approved encrypted archive. | Teacher/pilot lead | 30 days | Purge confirmation |
| 11 | Add the completion entry to the deletion log. No audio, no name. | Pilot lead | Same day as step 10 | Deletion log row |

If a step cannot be completed, the confirmation says which step is open, why,
and the date it will be completed. Do not send a generic "deleted" message.

### 4.4 App deletion paths

These are the controls the pilot can use. Their status is part of the gate.

| Path | What it deletes | Status | Evidence required |
|---|---|---|---|
| Profile → Reset progress | Local progress, streak, skill and phrase state | Shipped; not covered by a dedicated test in this branch | Manual check in the §4.8 rehearsal |
| Profile → Erase log | Local usage events; keeps install id, install day, and opt-in choice | Shipped; tested | `test/retention_profile_test.dart` |
| Take delete control | One local recording and its manifest | `Not built` (T4.2) | Widget test plus device check |
| Delete all recordings | Every local recording and manifest | `Not built` (T4.2) | Widget test plus device check |
| Uninstall the app | Local progress, settings, media store, and retention log | Platform behavior; `Not run` for the pilot devices | Device check on iOS and Android; web storage clear |
| Web: clear site data | IndexedDB media and local storage | Platform behavior; `Not run` for the pilot browsers | Browser check |

The app must not offer a "delete my data" button that only clears one store
while leaving takes, the retention log, or a backup copy behind. The delete
flow must name what it removes and show a confirmation. Until the recording
controls exist, the only honest instruction for a saved take is to uninstall
or clear the app's storage with the guardian present.

### 4.5 Export-file deletion

The project cannot reach a teacher's device. The teacher agreement must make
deletion a contractual duty, and the pilot must audit it.

- Teacher copies live in one approved local folder, encrypted at rest where the
  platform supports it. No personal cloud drive, email attachment, chat app, or
  shared family folder.
- The teacher deletes the take and summary after the review and no later than
  30 days after receipt. The hard maximum is 90 days.
- The teacher confirms the deletion to the pilot lead with the student label,
  the file type, and the date. Do not send the file as evidence.
- If a file was forwarded to another person, the teacher reports it as an
  incident under §5.4. The project cannot recall it; the response is to ask
  the recipient to delete it and to tell the parent.
- The project's own copies of a parent notice, consent form, or support email
  are deleted on the §2.5 schedule.

### 4.6 Audit record

The deletion log has one row per request:

| Field | Example | Notes |
|---|---|---|
| Request id | `DEL-2026-0007` | Stable |
| Record id | `CONSENT-2026-0001` | Links to the consent record |
| Student label | `stu_7f3a` | No legal name |
| Request date | `2026-11-20` | UTC |
| Requester role | `Parent` | Parent, guardian, teacher, school, student |
| Scopes | `audio, export, progress` | What was deleted |
| Completion date | `2026-12-01` | UTC |
| Backup purge date | `2026-12-15` | UTC, or `none` |
| Open items | `none` | Or a short factual note |
| Handler | `Pilot lead` | Role, not a personal name in the central log |

The log is kept for 24 months, then deleted. It contains no audio, no parent
name, no contact detail, and no free-text description of the child. Counsel to
confirm the retention period.

### 4.7 What happens to a student's recordings and progress

| Data | On revocation | On leaving the pilot | On uninstall |
|---|---|---|---|
| Local progress | Reset if the guardian asks; otherwise it stays local and the teacher cannot see it | Student keeps it or resets it | Deleted with app storage |
| Local takes | Deleted if the guardian asks; otherwise the student keeps them | Student keeps them or deletes them | Deleted with app storage |
| Exported take and summary | Teacher deletes within 7 days | Teacher deletes within 30 days | Not affected by the student's uninstall; teacher must delete |
| Consent record | Redacted; record id and dates kept for audit | Deleted after participation plus 12 months | Not affected by the student's uninstall |
| Redacted register | Status set to `Revoked` or `Left` | Row deleted after the retention period | Not affected |
| Deletion log | Completion row kept for 24 months | Completion row kept for 24 months | Not affected |

A student's uninstall does not delete a teacher's export. The parent notice
must say so, and the teacher workflow must close that gap.

### 4.8 Test before any claim

Before a teacher pilot, run this rehearsal with a dummy student on each device
class in scope (iOS phone, Android phone, web browser). It is a manual test
with no real child data.

- [ ] Create a dummy profile and a take. Confirm the take is in the local media
      store and not in the progress document.
- [ ] Export the take and summary. Confirm the export contains only the fields
      in §2.2 and no install id, email, device model, or parent detail.
- [ ] Delete the take with the app control (when T4.2 lands). Confirm the file
      and manifest are gone.
- [ ] Reset progress. Confirm progress is gone and the retention log is not
      silently changed.
- [ ] Erase the retention log. Confirm the events are gone and the install id
      remains.
- [ ] Uninstall the app. Confirm the local media store and progress are gone.
      On iOS, check the app's container is removed. On Android, check the
      app-specific directory. On web, clear site data and check IndexedDB.
- [ ] Restore a backup after a reset. Confirm the restore is deliberate and
      does not resurrect a deleted take.
- [ ] Delete an exported file from the teacher's folder. Confirm it is gone
      and the deletion log entry is written.
- [ ] Repeat with a device that has device backup enabled. Record whether
      progress reappears after restore and document the result.

Evidence: date, device, OS version, app build, tester initials, result, and any
failure. "Not run" is the current state. Until it is run, the project must not
say "delete on request works."

---

## 5. Moderation and safety

### 5.1 Prohibited surfaces for minors

The following are not part of the teacher pilot and must not be enabled for a
minor:

| Surface | Rule | Why | Status |
|---|---|---|---|
| Public recital or performance feed | No public recital for minors, including a private link that can be forwarded | A recording of a child can identify them and cannot be recalled | Excluded |
| Leaderboard, league, or ranking | No ranking of minors against other students | Creates pressure and exposes progress | Excluded |
| Social feed, comments, or likes | No feed and no comments | UGC needs moderation the project does not have | Excluded |
| Direct messaging | No in-app teacher-student or student-student messages | The project cannot moderate a child's private messages | Excluded |
| Public profile or share link | No public profile and no permanent share URL | The export is a file the student chooses to send | Excluded |
| AI feedback on audio | No AI model trained or run on a minor's audio in V1 | Consent, accuracy, and vendor risk are unresolved | Excluded |
| Advertising or sponsored content | No ads and no behavioral targeting | Also a product rule | Excluded |
| Teacher marketplace reviews | No public reviews of teachers or students | Not in the pilot | Excluded |

The Phase 4 social/recital plan in §10.5 of the transformation plan is not
permission to add any of these for minors. A future recital for adults still
needs the Phase 4 gate; a future recital that includes a minor needs a new
guardian consent, a moderation plan, and counsel review.

### 5.2 Teacher-student communication

- The app has no messaging. Teacher and student use the teacher's existing
  channel (email, studio portal, phone, or in-person lesson).
- The teacher agreement must say that the teacher does not move a minor to a
  private one-to-one channel that the parent cannot see.
- The project does not monitor the teacher's external channel. It can only set
  the rule, train the teacher, and respond to a report.
- If a teacher uses video review, the parent must be able to join or see the
  recording. The app does not host the call.
- No teacher may ask a minor for photos, video of their hands, or a live call
  through the app. The app has no camera use.

### 5.3 Content in the pilot

- The pilot uses the app's existing notation and practice content. It does not
  add student-uploaded pieces, comments, or teacher-authored public content.
- A teacher may assign a piece or drill from the approved list and may write a
  short assignment note in the teacher's own channel. The note is not stored in
  the app.
- The export summary uses fixed fields, not free text about the child.
- Do not add a "teacher says" block to a minor's app screen until the project
  has a content review and a way to remove it.

### 5.4 Incident reporting and abuse escalation

Every pilot participant gets the incident contact in the parent notice and the
teacher agreement. The project lead is the first responder; the human owner
makes the legal and relationship call.

| Incident | Examples | Report within | Immediate action | Escalation | Marker |
|---|---|---|---|---|---|
| Suspected data breach | Lost teacher phone with exports, stolen laptop, accidental upload to a cloud drive, email sent to the wrong parent | 24 hours to the pilot lead | Stop the exposure, preserve evidence, do not delete the only copy | Human owner and counsel assess notification duties; GDPR supervisory notification is 72 hours where it applies | Counsel to confirm |
| Unauthorized export or sharing | Teacher forwards a minor's take, posts it, or puts it in a group chat | 24 hours | Ask the recipient to delete, document who received it, suspend the teacher pending review | Human owner; parent notified without undue delay | Counsel to confirm |
| Abuse, harassment, or grooming concern | A teacher or adult behaves inappropriately toward a minor, in or outside the app | Immediately, and no later than 24 hours | Remove the teacher from the pilot, preserve messages, do not investigate alone | Human owner; report to the authorities where the law requires it | Counsel to confirm |
| Bystander or voice capture | A sibling or parent is audible in a take the student exports | Same day | Delete the take, tell the parent, record the event without the audio | Pilot lead | Counsel to confirm |
| Parent complaint about privacy | Wrong notice, consent not honoured, deletion delayed | 2 business days | Acknowledge, open a deletion or correction request | Pilot lead; human owner if unresolved in 14 days | Counsel to confirm |
| App security bug | A take is readable by another app, a backup contains a take, the delete control leaves a file | 24 hours | Stop the pilot on the affected platform, preserve logs, open an engineering ticket | Human owner and engineering | Counsel to confirm |

**Incident log fields:** incident id, date, platform, category, student label
if relevant (no legal name), what happened, immediate action, notification
decision, closure date, and owner. Keep it for 24 months. Do not store the
audio or a screenshot of a child in the incident log.

**Do not promise a notification outcome before counsel decides.** The project
can promise to acknowledge, investigate, and tell the parent what it knows. It
must not promise "we will delete everywhere" when a copy is outside its
control.

### 5.5 Safety rules for the teacher agreement

- No recording without the specific recording consent.
- No export without the specific export consent.
- No public posting, recital, or "student of the month" feature.
- No personal cloud drive, email attachment, or chat for a take.
- No AI transcription, voice cloning, or model training on a take.
- No request for a child's photo, video, address, school schedule, or health
  information.
- No meeting a minor alone outside the parent's knowledge.
- Report any suspected abuse or data incident within 24 hours.
- Delete exports on the §2.5 schedule and confirm it.

---

## 6. School and teacher obligations

### 6.1 Teacher attestation

The teacher signs this before the first student is enrolled. The signed copy
goes in the pilot file.

- [ ] I have read this plan and the parent notice.
- [ ] I will not enroll a minor until a parent/guardian consent record is
      signed, checked, and in the redacted register.
- [ ] I will give the parent the current notice and answer their questions. I
      will not make an optional scope a condition of the lesson.
- [ ] I will keep the consent record and the roster in a locked file or an
      approved encrypted folder, separate from the exported takes.
- [ ] I will use only the student label in the app, the export, and file names.
      I will not put a legal name in a file name or a share message.
- [ ] I will keep exported takes in one approved local folder, not in a
      personal cloud drive, email, or chat.
- [ ] I will delete each export after the review and no later than 30 days,
      with a hard maximum of 90 days, and confirm the deletion.
- [ ] I will not publish, stream, or share a minor's recording.
- [ ] I will not use AI to transcribe, analyze, or train on a minor's audio.
- [ ] I will not ask a minor for photos, video, location, contacts, or health
      information.
- [ ] I will report a suspected data incident or abuse concern to the pilot
      lead within 24 hours.
- [ ] I will complete the pilot training and keep the checklist with my
      records.
- [ ] I understand that a breach of this attestation can end my participation
      and that the project may report a serious concern to the authorities.

**Teacher name:** `________________________`  **Date:** `____________`

**Signature:** `_____________________________`

### 6.2 Student roster minimization

The roster is the teacher's working list. The pilot treats it as a working
list, not an education record; counsel must confirm that treatment, and the
school addendum governs if a school contract makes it an education record.

| Allowed | Not allowed |
|---|---|
| Student label (`stu_7f3a`) | Full legal name in the app or export |
| First name or nickname in the teacher's roster only, if needed to recognize the row (never in the app or export) | Address, phone, email of the child |
| Age band or year of birth | Full date of birth |
| Consent record id and status | A copy of the signed form in the central register |
| Assignment label and start/end dates | Grades, IEP, health, behavior notes |
| Device class (iOS/Android/web) for support | Device serial number or advertising id |

The roster is deleted within 14 days of a student leaving. The redacted
register keeps only the record id, label, age band, scopes, and dates.

### 6.3 Device and shared-iPad rules

The app stores one progress document per install. It has no multi-student
profile switch.

- **Preferred:** one device per student, or the student's own phone.
- **Shared iPad or studio tablet:** not supported for the pilot until the
  project has a tested profile switch or a tested wipe-between-students flow.
  If a teacher must use one, the pilot lead must approve it in writing, and the
  teacher must reset the app and clear site data or app storage between
  students with the next student's guardian aware.
- **Never** leave one student's progress visible to another student.
- **Never** enable device backup on a shared device. If backup cannot be
  disabled, the shared-device option is not approved.
- **Web build:** use a separate browser profile per student, or clear site data
  after each session. A shared browser profile is a shared progress store.
- **Lost or replaced device:** report it under §5.4. The app cannot remote-wipe
  a local device.

The project should add a "shared device" note to the teacher training and the
pilot checklist. A future multi-profile feature is out of scope for T7.3 and
needs its own privacy review.

### 6.4 No recording without consent

- Microphone analysis for an exercise is not a saved recording. It is
  transient and is not kept after the exercise. The parent notice explains
  this.
- A saved take is a recording. It needs the recording consent.
- Sending a take to the teacher is an export. It needs the export consent, and
  it is a separate choice from saving the take.
- A student can practice without saving or exporting. Refusing an optional
  scope must not block the required practice.
- The teacher must not ask for a take "for evidence" or "for the file" when the
  parent declined export. Use the in-app summary instead.

### 6.5 Export handling

| Rule | Why | Evidence |
|---|---|---|
| Export only from the app's share sheet to the teacher's approved local folder | Keeps the teacher copy local and visible | Teacher attestation |
| Do not use email, chat, or a personal cloud drive | Those copies cannot be deleted or audited | Incident if breached |
| Encrypt the folder or device where the platform supports it | A lost device is the main breach risk | Device check |
| Name files with the student label, not a legal name | A leaked file name should not identify a child | Sample file check |
| Delete after the review; 30-day default, 90-day hard maximum | Limits the copies outside the app | Deletion confirmation |
| Confirm deletion to the pilot lead without sending the file | The audit needs a date, not the content | Deletion log |
| A forwarded file is an incident | The project cannot recall it | Incident log |

The T7.2 export must include a plain-language header in the summary: what the
file contains, who it is for, the retention rule, and how to delete it. The
student sees that header before sharing.

### 6.6 Training and checklist

Before a teacher's first student:

- [ ] 45-minute training: this plan, the parent notice, the data map, the
      consent record, the deletion workflow, the incident path, the no-AI and
      no-recital rules, and shared-device rules.
- [ ] Walk through one dummy export and one dummy deletion.
- [ ] Sign the attestation in §6.1.
- [ ] Add the teacher to the pilot register with a training date.
- [ ] Repeat the training annually or after a material change to this plan.

Evidence: training date, trainer role, attendance, signed attestation, and the
dummy deletion result. No training, no student.

### 6.7 School addendum

If a school is the customer, a written agreement is required before any
student data is processed. Counsel must draft or approve it. At minimum:

- the school is the authorized signatory and has the authority to consent on
  parents' behalf, or the school will collect parent consent itself;
- the purpose is limited to the pilot's practice review;
- the school will not send directory information, grades, IEPs, health data,
  or student ids;
- the project will not sell data or use it for advertising;
- the school and project will delete data at the end of the contract;
- the school will notify parents and offer any required opt-out;
- the project will notify the school of a breach within the agreed time;
- the agreement names the student data privacy laws that apply and the
  required contract terms. Counsel to confirm.

A private teacher studio is not a school. Do not use the school path to avoid
individual parent consent unless counsel confirms the school has the legal
authority to consent. Counsel to confirm.

---

## 7. Legal review gate

### 7.1 What counsel must review

Nothing in this table is cleared. The evidence column names what must exist
before a row can move to `Cleared`.

| # | Area | Questions counsel must answer | Evidence required | Owner | Status |
|---:|---|---|---|---|---|
| 1 | COPPA and the FTC COPPA Rule (US) | Does the teacher channel collect personal information from a child under 13? Is the project an operator when the app is local-only and the teacher holds the export? Which verifiable parental consent method is sufficient? Does the school-consent path apply? | Dated memo with the coverage analysis and approved method | Counsel | `Open` |
| 2 | State comprehensive privacy laws (US) | Which pilot states apply? Do minors' opt-in, sale/share, or sensitive-data rules apply? Does a state age-appropriate design code apply and what is its current status? | Memo per pilot state; updated notice | Counsel | `Open` |
| 3 | State student data privacy laws and school contracts | If a school is the customer, which student data law applies and what contract terms are mandatory? Is FERPA's school-official exception relevant? | Memo and approved school addendum | Counsel | `Open` |
| 4 | GDPR Article 8 and member-state ages (EU) | What is the consent age in each pilot member state? Who is the controller for the teacher's copy? Is a DPIA required? Is an EU representative required? | Memo per member state; DPIA or screening note | Counsel | `Open` |
| 5 | UK GDPR and the Age Appropriate Design Code | Does the code apply to the teacher channel? Which of its 15 standards change the design? Is a DPIA required? | Memo and a standard-by-standard gap note | Counsel | `Open` |
| 6 | Canada | What does PIPEDA require for a local-only app? Does Quebec's Law 25 or a provincial law add a rule for the pilot province? | Memo per province | Counsel | `Open` |
| 7 | Other pilot markets | For any market outside the list, what is the age and consent rule? | Memo before that market opens | Counsel | `Open` |
| 8 | Parent notice and consent form | Is the notice clear, complete, and not misleading? Does the form capture valid consent for each scope? | Approved notice and form, versioned | Counsel | `Open` |
| 9 | Teacher agreement and attestation | Does the agreement create the deletion, no-cloud, no-AI, and incident duties the plan needs? Is the teacher a controller, processor, or neither? | Approved agreement | Counsel | `Open` |
| 10 | Privacy policy and terms | Do the public documents describe the teacher path, the local-only model, and the limits honestly? | Approved policy and terms | Counsel | `Open` |
| 11 | Retention and deletion schedule | Are the periods in §2.5 lawful and defensible? Must a consent record be kept longer to answer a claim? | Approved schedule | Counsel | `Open` |
| 12 | DPIA / risk assessment | Is a DPIA required for the pilot? If not, is a documented screening decision enough? | DPIA or screening note | Counsel | `Open` |
| 13 | Breach notification and incident response | What must be notified, to whom, and within what time? Does the 24-hour internal path work? | Approved incident runbook; tabletop record | Counsel and human owner | `Open` |
| 14 | Cross-border transfer and teacher devices | Does a teacher in another country create a transfer issue? Is a local-only export acceptable? | Memo and teacher location list | Counsel | `Open` |
| 15 | App store children and family policies | Do Apple's and Google's policies add a requirement for a teacher-directed app? | Store policy checklist | Engineering | `Open` |
| 16 | Exam-board IP and naming | Can the pilot use generic grade labels without a board license? | Opinion; approved label list | Counsel | `Open` |

Every row is **counsel to confirm** until counsel supplies the named evidence.
Row 16 gates exam packs only; a teacher pilot that uses no exam-board name or
content does not need it. If the pilot later adds an exam pack, row 16 becomes
a blocker.

### 7.2 Evidence package

The pilot file must contain all of the following before a go decision:

- [ ] A dated counsel memo per pilot territory, naming the assumptions and the
      documents reviewed.
- [ ] The approved parent notice and consent form, with version ids.
- [ ] The approved teacher agreement and attestation.
- [ ] The data map in §2.2 and the retention schedule in §2.5.
- [ ] The DPIA or the documented screening decision.
- [ ] The deletion rehearsal record from §4.8 for every device class in scope.
- [ ] The incident tabletop record from §5.4.
- [ ] The redacted consent register template.
- [ ] The pilot roster with age bands and minor flags.
- [ ] The T9.2 decision entry and the T6.3 go/no-go reference.
- [ ] The app build hash, platform list, and the exact consent/notice version
      the build presents or references.

A missing item is a no-go, not a note for later.

### 7.3 Decision procedure

1. The human owner sends counsel this document, the parent notice, the teacher
   agreement, the data map, and the deletion rehearsal.
2. Counsel returns a written memo per territory. Verbal advice is not enough
   for the gate.
3. The human owner accepts, conditions, or rejects each row. A condition is
   written down with an owner and a date.
4. The manager records the decision in Plane `T9.2` and links the PR and this
   document. The manager owns the register; the implementation agent supplies
   the text.
5. `T6.3` records the legal go/no-go for the Phase 1 launch. The teacher
   channel needs its own written clearance because T6.3's scope is the consumer
   launch, not a minors' pilot. If the project wants one combined opinion, the
   T6.3 scope must be amended in writing. Counsel to confirm.
6. No pilot starts while any row is `Open` or `Conditional`. There is no
   residual-risk bypass for a missing counsel memo; the human owner can accept
   a documented residual risk only after counsel has cleared the row, and the
   acceptance is recorded in `T9.2`.

### 7.4 Proposed T9.2 decision entry

> **T7.3 — Teacher channel gated by consent, deletion, moderation, and legal
> review.** The Phase 2 teacher and exam channel stays out of the base case and
> does not ship until: (a) counsel clears
> `docs/COPPA_GUARDIAN_CONSENT_PLAN.md` for each pilot territory; (b) a
> verifiable parent/guardian consent record exists for every minor before the
> first assignment; (c) the deletion and revocation workflow has been rehearsed
> on every device class in scope; (d) the no-recital, no-messaging, no-UGC, and
> no-AI rules are in the teacher agreement; and (e) T6.3 is extended to the
> teacher channel or a separate written go/no-go is recorded. Evidence: the
> plan above, the counsel memo, the deletion rehearsal, and the T7.3 pull
> request. Owner: human owner. Status: open.

### 7.5 Proposed T9.1 risk entry

> **Risk: a minor uses the teacher channel without verifiable consent or a
> working deletion path.** Likelihood: medium while the gate is open. Impact:
> high (regulatory, trust, and child-safety harm). Mitigation: the gate in
> T7.3, the redacted consent register, the monthly audit, the deletion
> rehearsal, and the no-ship base-case rule. Kill criterion: any pilot student
> without a checked consent record, any untested deletion path, or counsel
> advice that the consent method is insufficient. Owner: human owner.

The manager owns both registers. This PR does not edit Plane.

### 7.6 Gate status

| Gate | Current state | What clears it |
|---|---|---|
| Counsel memo for the pilot territory | `Open` | Dated written memo linked in the pilot file |
| Approved parent notice and consent form | `Draft` | Counsel approval; version id |
| Redacted consent register populated for every minor | `Open` | Pilot lead check against the roster |
| Teacher agreement and attestation signed | `Draft` | Signed copies in the pilot file |
| Deletion rehearsal on iOS, Android, and web | `Not run` | Completed checklist in §4.8 with evidence |
| Incident tabletop | `Not run` | Completed tabletop in §5.4 |
| No-recital, no-messaging, no-UGC, no-AI rules in the teacher agreement | `Draft` | Signed agreement |
| T6.3 extension or separate go/no-go | `Open` | Written decision in T9.2 |
| Base-case exclusion confirmed | `Shipped` | Plan §11.3 and this §8 remain unchanged |

---

## 8. Base-case rule

### 8.1 Rule

Teacher and exam revenue stay **out of the base case** until the teacher
channel has a cleared consent plan, a tested deletion path, a moderation rule,
and a written legal go/no-go. Until then, the teacher channel does not ship,
and the consumer app is unaffected.

This is not a temporary marketing position. It is the financial and product
rule in the approved plan:

- Plan §11.3 calculates the base case with **no teacher or exam revenue**.
- Plan §11.3 treats teacher and exam revenue as upside only, after three paid
  teacher pilots pass.
- Plan §3.2 excludes teacher dashboards, accounts, and cloud sync from V1.
- Plan §10.3 puts the teacher pilot in Phase 2, with a COPPA plan and no
  persistent cloud.
- Plan §11.5 requires the consent plan before any under-13 student takes part
  in a paid pilot.

### 8.2 What counts as teacher revenue

Do not book any of these in the base case while the gate is open:

| Revenue line | Status in the base case | Condition to include |
|---|---|---|
| Teacher Studio subscription ($19/month) | Excluded | Three paid pilots pass + every gate in §7 |
| Per-student overage ($0.75/student) | Excluded | Same |
| School or studio contract | Excluded | Same + an approved school addendum |
| Exam pack sold to a teacher or school | Excluded | Same + exam-board IP clearance |
| Referral revenue from a teacher | Excluded | Same |
| A "founding teacher" pre-sale | Excluded | Do not sell before the pilot gate; a refundable deposit still creates expectations |

### 8.3 Gate matrix for shipping

| Question | Answer today | What changes it |
|---|---|---|
| Can a teacher use the app with a minor? | No | Every §7 gate cleared and a signed consent record |
| Can the project sell a Teacher Studio subscription? | No | The same, plus three paid pilots and a written go/no-go |
| Can the project sell an exam pack? | No | The same, plus exam-board IP clearance |
| Can the project post a teacher case study with a student? | No | A separate guardian consent naming the case study and the venue, plus counsel review |
| Can the project claim "COPPA compliant" or "COPPA certified"? | No | Do not make the claim at all without a written legal basis and counsel's approval of the exact wording |
| Can the consumer app ship? | Yes, as the current local-only app | The consumer app is outside this gate |

Any public wording that describes the product's legal status is **counsel to
confirm** before it is used.

### 8.4 If the gate is not ready

- The teacher channel does not ship.
- The consumer app continues. It does not need a teacher account or a child
  account.
- Do not add a "teacher mode" or a "student mode" to the consumer app to work
  around the gate.
- Do not describe the teacher channel as "coming soon" in a way that invites a
  teacher to enroll a minor.
- Do not use the teacher LOIs as evidence that the channel is safe. An LOI is
  demand evidence, not a compliance control.
- If a teacher asks to pilot, the answer is: the project is not taking student
  data until the gate is cleared. Record the interest and wait.

### 8.5 If the gate passes

Only then:

1. Update the base case in [`FINANCIAL_MODEL.md`](FINANCIAL_MODEL.md) with the
   pilot revenue and costs. This is a human-owner and manager change, not an
   engineering change.
2. Record the new assumption in `T9.2` with the counsel memo and pilot
   evidence.
3. Keep the no-cloud, no-account, no-AI, and no-recital rules unless a new
   decision record changes them.
4. Re-run this plan for the next territory, school type, or age group. A
   clearance for one pilot does not clear a different one.

---

## 9. Open questions and non-goals

### 9.1 Open questions

| # | Question | Why it matters | Owner | Needed by | Status |
|---:|---|---|---|---|---|
| 1 | Which territories will the first teacher pilot serve? | The age and consent rule is territory-specific | Human owner | Before T7.1 enrollment | `Open` |
| 2 | Is a teacher's age-band attestation enough, or does the project need a parent-provided age check? | The app has no age gate | Counsel | Before the pilot | `Open` |
| 3 | Is the teacher-held record plus a redacted project register the right custody model, or must the project hold the original? | Determines the data map and the audit | Counsel | Before the pilot | `Open` |
| 4 | Is the local-only app an "operator" collecting data under COPPA? | Determines whether consent is legally required at all | Counsel | Before the pilot | `Open` |
| 5 | Can a school consent on parents' behalf for this use? | Opens or closes the school channel | Counsel | Before a school pilot | `Open` |
| 6 | Are the retention periods in §2.5 lawful and practical? | A shorter period is safer; too short breaks the review | Counsel | Before the pilot | `Open` |
| 7 | Must a consent record be kept after deletion to answer a claim? | Conflicts with data minimization | Counsel | Before the pilot | `Open` |
| 8 | Can a parent see or demand deletion of a teacher's exported copy? | The project does not control the teacher's device | Counsel | Before the pilot | `Open` |
| 9 | What is the breach-notification timeline and who decides? | A late notification is a separate violation | Counsel and human owner | Before the pilot | `Open` |
| 10 | Is a DPIA required for the pilot? | A DPIA changes the evidence package | Counsel | Before an EU/UK pilot | `Open` |
| 11 | Is an EU or UK representative required? | A local-only app may still need one | Counsel | Before an EU/UK pilot | `Open` |
| 12 | Does the app need a child-directed privacy notice even with no accounts? | The store listing and the notice may need to address children | Counsel | Before the pilot | `Open` |
| 13 | Can a teacher use a shared studio iPad? | The app has one progress store per install | Product and pilot lead | Before the pilot | `Open` |
| 14 | What insurance or contract limit does the project need? | A child-data incident can exceed the pilot revenue | Human owner | Before the pilot | `Open` |
| 15 | Does an exam pack need a board license before a teacher pilot? | Naming and content rights are separate from privacy | Counsel | Before an exam pilot | `Open` |

### 9.2 Non-goals

This plan does **not**:

- provide a legal conclusion or a legal opinion;
- certify the app as COPPA compliant or COPPA certified;
- create a child account, a parent account, or a parent dashboard in V1;
- create a teacher dashboard or a cloud roster;
- add a public recital, leaderboard, social feed, direct messages, comments, or
  UGC for minors;
- add AI feedback, transcription, voice cloning, or model training on a
  minor's audio;
- add advertising, tracking, or a data sale;
- add location, contacts, camera, photos, or health data;
- replace the school's own consent, safeguarding, or mandatory-reporting
  duties;
- clear the teacher channel for a territory, school, or age group that counsel
  has not reviewed;
- change the consumer app's privacy model.

### 9.3 Claims the project must not make

| Do not say | Say instead |
|---|---|
| "COPPA compliant" or "COPPA certified" | "The teacher channel is gated by a consent plan that counsel is reviewing" |
| "We delete everything on request" | "We have a documented deletion workflow, and we test it before the pilot" |
| "Recordings are private" without the backup caveat | "Recordings are local by default and excluded from cloud backup when the platform confirms it" |
| "The app is anonymous" | "The app has no account and no name field; an exported take can still identify a player" |
| "Teacher-approved" or "school-ready" before the gate | "The teacher channel is a Phase 2 pilot and is not open" |
| "AI-powered feedback for students" | "No AI feedback on a minor's audio in V1" |
| "Public recital" or "share your performance" for a minor | "No public recital for minors" |
| "Parent dashboard" | "No parent dashboard in V1; the parent receives the notice and the deletion channel" |

Every claim about legal status is **counsel to confirm**. A product decision
that the project will not make a claim is not the same as a legal clearance to
make a different one.

---

## 10. Links, ownership, and change control

### 10.1 Related documents

| Document | Why it matters |
|---|---|
| [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md) §3.2, §9, §10.3, §11.3, §11.5, §11.6, §14 | Scope, privacy model, teacher pilot, base-case exclusion, legal gate, risks |
| [`../AGENTS.md`](../AGENTS.md) hard rule 1 and hard rule 10 | No network/cloud/accounts in the app; Plane is the source of truth |
| [`AI_HANDOFF_PROTOCOL.md`](AI_HANDOFF_PROTOCOL.md) §8 | Human-owned tickets and the rule that an agent cannot claim legal or human evidence |
| [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md) | The local opt-in log, its fields, and its erase path |
| [`decisions/0002-backup-exclusion-no-opt-in.md`](decisions/0002-backup-exclusion-no-opt-in.md) | Recording backup exclusion and the conditional privacy copy |
| [`decisions/0006-local-retention-instrumentation.md`](decisions/0006-local-retention-instrumentation.md) | No remote analytics; local, opt-in, bounded log |
| [`CORPUS_CONSENT.md`](CORPUS_CONSENT.md) | The adult-only corpus consent model and the deletion precedent |
| [`FINANCIAL_MODEL.md`](FINANCIAL_MODEL.md) | The base case that excludes teacher and exam revenue |
| [`PLANE.md`](PLANE.md) | Where the live decision and risk registers live |
| [T6.3 — Complete the legal review and go/no-go](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/8ae3b050-4e45-491c-81b7-e949bbb56d66) | The consumer launch legal gate this plan must be tied to |
| [T7.1 — Interview 10 teachers and secure 3 LOIs](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/6c27abcb-58a0-4990-b408-673424edf0e8) | Demand evidence, not consent evidence |
| [T7.2 — Build the manual export flow](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/b3941675-2fbc-4160-908c-6c7c58d7f41d) | The export and deletion controls this plan requires |
| [T7.5 — Build the teacher dashboard only if LOIs pass](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/99b52551-9412-4c72-b04c-ebc8855dfcdc) | Accounts, rosters, and permissions need a new review |
| [T9.2 — Maintain the decision log](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/5b34fd51-46d1-4121-b029-5560688ff9b7) | The gate decision is recorded here |
| [T9.1 — Maintain the risk register](https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/694298da-0c68-4ae6-a03a-e349cb125176) | The minor-data risk is tracked here |

### 10.2 Sources for the legal review

These are starting points for counsel, not a statement that the law is
current. Counsel must confirm the version in force at the pilot date and in
each territory. The project has not treated any of these as a legal opinion.

| Source | What it covers | Marker |
|---|---|---|
| Children's Online Privacy Protection Act, 15 U.S.C. §§ 6501–6506 | US child privacy statute | Counsel to confirm |
| FTC COPPA Rule, 16 C.F.R. Part 312 | Notice, consent, and data rules for operators | Counsel to confirm |
| FTC children's privacy guidance | The FTC's current guidance and enforcement position | Counsel to confirm |
| EU General Data Protection Regulation, Article 8 (and Articles 17, 30, 33, 34, 35) | Child consent age, erasure, records, breach, DPIA | Counsel to confirm |
| UK GDPR and Data Protection Act 2018, sections 9 and 123 | UK consent age and the statutory code | Counsel to confirm |
| ICO Age Appropriate Design Code | Design standards for services likely to be used by children | Counsel to confirm |
| Canada's PIPEDA and Office of the Privacy Commissioner guidance | Canadian consent and minors | Counsel to confirm |
| Quebec Law 25 | Quebec's rules for younger minors and privacy | Counsel to confirm |
| California Consumer Privacy Act / CPRA, Cal. Civ. Code § 1798.100 et seq. | California minors, opt-in, and deletion | Counsel to confirm |
| California Age-Appropriate Design Code | Design duties; counsel must confirm the current status | Counsel to confirm |
| Apple App Store Review Guidelines and Google Play Families policy | Store-level child and family requirements | Counsel to confirm |

### 10.3 Ownership

| Area | Owner | Backup |
|---|---|---|
| The gate decision and residual risk | Human owner | Manager |
| Counsel engagement and the memo | Human owner | Manager |
| Consent register, audit, and deletion log | Pilot lead | Human owner |
| Teacher agreement and training | Pilot lead | Human owner |
| Export, delete, and privacy copy in the app | Engineering | Manager |
| The base-case exclusion | Human owner | Manager |
| The T9.2 and T9.1 entries | Manager | Human owner |

### 10.4 Review cadence

- Before any teacher pilot.
- After any counsel memo or material legal change.
- After any change to the data map, export format, retention period, or app
  storage.
- After any incident.
- At least once a year while the teacher channel exists.
- Before a new territory, school type, or age group.

### 10.5 Change log

| Version | Date | Change | Author |
|---|---|---|---|
| 0.1 | 2026-11-06 | First draft for counsel review; all gates open; teacher channel out of the base case | T7.3 implementation |

---

*End of draft. This document is not legal advice. Do not start a teacher pilot
with a minor until counsel has reviewed it and every gate in §7 is cleared.*
