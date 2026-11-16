# 20-user beta runbook (T5.7)

**Status:** Kit only. The beta has not run. No participant has been recruited,
no log has been exported, and no metric exists.
**Ticket:** T5.7 — Run the 20-user beta and fix the top 5 activation/retention
blockers.
**Owner:** The beta lead is human-owned. An agent can prepare the kit, the
build, and the analysis definitions; it cannot recruit, run sessions, or report
user evidence.
**Source of truth:** Plane. This runbook is the operator script for the ticket;
it does not replace the ticket, and it does not add a product decision.

---

## 1. What this beta is

The beta is 20 hand-recruited adult returners and early-intermediate players,
with room for a smaller number of motivated adult beginners, using one frozen
local build for four weeks. The purpose is to find out whether a new user
reaches the first real practice loop and comes back, and to fix the five
blockers that stop the most people.

The beta measures these surfaces:

- the guided first session after onboarding, which is practice-only;
- the placement check;
- Reading Lab and the notation lessons;
- local recordings and the private before/after card;
- quests and the weekly minutes goal;
- the optional local practice reminder, on Android only.

The beta exercises these surfaces with real participants. Only the events named
in [`BETA_METRICS.md`](BETA_METRICS.md) become quantitative metrics. Placement,
Reading Lab, quests, and weekly minutes are qualitative in this beta because the
local log has no events for them.

The scored phrase loop is **not** part of this beta. `phraseLoopEnabled` is
false, decision [0001](decisions/0001-conditional-go.md) forbids a production
"on" path before T1.7, and decision
[0010](decisions/0010-first-session-practice-only.md) permits only unscored
practice feedback with no progress write. The first session can show one
practice correction, but that correction is not a score and not accuracy
evidence. Do not tell a participant that the beta scores phrase playing; it
does not. The app does score lessons, but the first session's phrase correction
is practice-only. Do not report a phrase accuracy number from this beta.

The app stays local-only. There is no account, no network call from the app, no
analytics SDK, no crash reporting, no cloud sync, and no store upload. The only
usage log is local, off by default, bounded at 500 events, eraseable, and copied
by the participant. See
[`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md).

The run is human-owned. This kit makes it cheap and repeatable; it does not
claim that the run happened.

## 2. Who to recruit

### Include

- 20 adults, 18 or older, primarily adult returners and early-intermediate
  players. A returner played before, stopped for a long time, and is starting
  again. An early-intermediate player can play a few open chords or simple
  melodies but is not advanced. Adult beginners who want notation from the start
  can be a smaller part of the cohort, not the whole cohort.
- People who own or can borrow a playable guitar and can use it during the
  beta.
- People who can run one of the supported clients for four weeks:
  - a laptop or desktop with current Chrome or Edge on the same local network
    as the beta server; or
  - an Android phone, Android 6.0 or newer (`minSdk 23`), that can install an
    APK.
- People who will turn on the optional local usage log, copy it at the end, and
  send it back through the private channel.
- People who agree to about 10 to 15 minutes of practice, three times a week,
  plus a short check-in in weeks 1 and 2 and a 10-minute interview in week 4.
- People who understand that this is an early build and that some parts will be
  rough or missing.

### Exclude

- Anyone under 18. The guardian-consent path in
  [`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md) is not
  cleared for a beta, so a minor cannot be included even with a parent present.
- Anyone who cannot or will not run the app on a supported client.
- Anyone who cannot read the English interface. This build has no localization,
  and the consent and check-ins are in English.
- Experienced players, teachers, and advanced students. Their feedback is still
  useful, but they are not the target user and they would distort activation.
- Anyone who declines the local usage log. Their sessions can still be observed
  qualitatively, but they cannot enter the quantitative denominator. Keep them
  in a separate qualitative list and say so in the report.
- Anyone who is testing another build, has a second install of the same app, or
  is helping develop it. Their data is not a clean new-user install.
- Anyone who cannot keep the same browser profile or the same Android install
  for four weeks. Clearing site data, using incognito, or uninstalling the APK
  loses the local log and creates a new install identity.
- Anyone who cannot use a microphone and is not willing to use the name-only
  fallback. The app should still work, but the first-session experience is
  weaker and should be recorded as a blocker.

### Cohort shape

Aim for a mix of web and Android users, but record the real split instead of
forcing a quota. The reminder experiment only runs on Android because the web
build has no local notification scheduler. If the reminder is in scope for this
cohort, recruit enough Android participants to make the split visible, and
record each participant's reminder permission and exposure answer. Do not
assign a reminder arm yourself; the app assigns it from the install id.

The cohort is hand-recruited, not random. Every result is reported for this
cohort only, with its denominator. Do not present it as the product's retention
rate.

## 3. Recruitment script and consent

### Short script

Use this in a message or a short call. Change the names and the contact line,
not the claims.

> I am testing an early guitar practice app for adult returners and
> early-intermediate players, plus some people who are just starting. It teaches
> a little music reading and short phrases, and it can listen to your guitar when
> the microphone works. I am looking for 20 people, not advanced players.
>
> It takes about 10 to 15 minutes, three times a week, for four weeks. You need
> a guitar and either a laptop with Chrome or Edge or an Android phone. There is
> no account and no cost. The app is early, so some parts will be rough, and the
> microphone may not work on every device; you can still use it with note names.
>
> Would you be willing to try it and give me a short check-in each week? I will
> explain the optional local usage log before you start. You can say no, stop at
> any time, and ask me to delete your data.

Do not promise that the app will improve their playing, that the microphone is
accurate, or that the beta will become a finished product. Do not describe the
scored phrase loop, because it is not in this build.

### Plain-language consent paragraph

Read this before install, give the participant a copy, and keep the signed or
written reply separate from the app log.

> I am inviting you to take part in a four-week test of Hear Me Out, an early
> guitar practice app. The app runs on your own device. It has no account, no
> ads, and no analytics service. On web it is served from a computer on the
> local network; the app does not upload your practice data.
>
> If you agree, I will ask you to open the app from a private link or install an
> APK file, practice about 10 to 15 minutes three times a week for four weeks,
> answer a short check-in in weeks 1 and 2, and do a 10-minute interview in week
> 4. I will also ask you to turn on the optional local usage log on the first
> screen, and at the end copy that log and send it to me.
>
> The optional log is off unless you turn it on. Each event records only an
> event name, a UTC time, and a random install id. The file also keeps the
> install time. It does not record audio, note names, piece titles, your name,
> your email, your device id, or free text. The app does not upload it. It
> leaves your device only when you copy it and send it to me. You can turn it
> off or erase it at any time in Profile > Privacy. If you erase it, I cannot
> use that log.
>
> The app may ask for microphone permission to hear your guitar. The microphone
> is active only while you practice, tune, or record. You can deny it and still
> use the app with note names. Any recording you make stays on your device
> unless you choose to export it. I will not ask you to send me a recording.
>
> Taking part is voluntary. You can stop at any time, ask me to delete your log
> export, and withdraw. If I have already combined your log into pseudonymous
> counts, I cannot remove it from the combined result, but no name or contact
> detail is in that result. You must be 18 or older. This is an early build, so
> some things will be rough or missing. I am testing the app, not you.
>
> Contact: <name and email>. I will keep your consent form and contact details
> separately from the app log and delete them <date or trigger>.

If the participant asks what the log contains, show them
[`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md) or read the
fields section aloud. Do not describe it as anonymous; it is pseudonymous, and
the participant could be identified if they tell you which install is theirs.

## 4. Install paths

Build the app once, before the first participant, and freeze that build for the
cohort. Record the git commit, the build time, the artifact paths, and which
participants received the web build or the APK. A rebuild during the beta
splits the cohort across versions; if a blocker fix needs a new build, record
the date, the commit, and who received it, and treat the two builds separately
in the report.

From `flutter_app/`:

```powershell
git rev-parse HEAD
.\tool\beta\build_beta.ps1
```

`build_beta.ps1` builds the release web bundle and, when the Android toolchain
is present, the release APK. It prints the artifact paths. If the Android
toolchain is missing, it fails with a clear message instead of quietly
producing a web-only build. Use `-WebOnly` only when the cohort is web-only:

```powershell
.\tool\beta\build_beta.ps1 -WebOnly
```

If Flutter is not on `PATH`, pass the SDK path:

```powershell
.\tool\beta\build_beta.ps1 -FlutterPath 'C:\Users\<you>\flutter\bin\flutter.bat'
```

If PowerShell blocks the script with "running scripts is disabled on this
system", read the script and run that one process with a temporary policy:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\beta\build_beta.ps1 -WebOnly
```

The script does not upload anything and does not call a product analytics
service. Flutter's toolchain check and dependency resolution may use the network
on a machine that has not built the app. The APK uses the repository's debug
signing key; it is a sideloaded beta artifact, not a Play Store build, and it
has no signing secret.

### Web over the LAN

The full LAN notes are in
[`DEVELOPMENT.md`](DEVELOPMENT.md#serve-the-release-build-over-the-lan). The
short path:

From `flutter_app/`:

```powershell
.\tool\beta\build_beta.ps1 -WebOnly
python -m http.server 8080 --bind 0.0.0.0 --directory build\web
ipconfig
```

Open `http://<this-machine-IPv4>:8080/` on the participant's computer. Allow
inbound TCP 8080 for the private network when Windows asks, or add the
subnet-scoped rule from [`DEVELOPMENT.md`](DEVELOPMENT.md). The DHCP address can
change after a router restart; re-check it before each install day. After a
rebuild, hard-refresh the page or close all tabs so the service worker picks up
the new files.

Browsers require HTTPS or `localhost` for microphone and clipboard access. On
plain HTTP over the LAN, Chrome and Edge treat the page as insecure. On a
trusted client, set **Insecure origins treated as secure** in
`chrome://flags/` or `edge://flags/` to the exact LAN URL, then relaunch. That
usually restores both the microphone and the clipboard. If the participant or
their device cannot use that flag, install the Android APK instead, or accept
name-only practice and plan to collect the log another way. Practice still
works name-only.

Do not expose the Python server to the public internet, do not put it behind a
public reverse proxy, and do not ask a participant to disable browser security
wholesale. The beta is a local-network test.

### Android APK

`build_beta.ps1` writes the APK to
`flutter_app\build\app\outputs\flutter-apk\app-release.apk` from the repository
root.

Install it in one of two ways. From `flutter_app/` with a connected device:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

or send the APK file to the participant, open it on the phone, and allow
**Install unknown apps** for the file manager or browser that opens it. The app
requires Android 6.0 or newer (`minSdk 23`). The microphone permission is
declared in the manifest; the participant can deny it and use note names.

The APK is debug-signed. Installing a new build over it keeps local data only
when the package name and signing key match. Uninstalling or clearing app data
deletes progress, recordings, and the local log. Tell participants not to
uninstall during the beta. If they must, ask them to copy the usage log and
export anything they want to keep first.

This kit was written on 2026-11-16 on a machine without the Android SDK. The APK
path above is documented but **not verified on this machine**; only the script's
missing-toolchain failure path was verified. Build the APK on a machine with the
Android SDK before the cohort starts.

### When a device cannot open the microphone

Work through this list and record the answer:

1. Is the page on `localhost` or HTTPS, or is the LAN origin exempted in the
   browser flags? Plain HTTP blocks `getUserMedia`.
2. Did the participant grant the browser or Android microphone permission? A
   denied permission is a valid outcome; the app falls back to note names.
3. Is another app or tab holding the microphone? Close it and reload.
4. Is the input device selected and working in the operating system? Test it in
   another app.
5. On Android, is the app's microphone permission allowed in system settings?
6. Does the device need a restart after a permission change?
7. Does the same device work with the APK instead of the web build?

If the microphone still does not open, continue with name-only practice. Record
the device, browser or Android version, the exact step, and the error or
behavior in the blocker log. Do not mark a session as microphone-verified, and
do not fill a missing answer with an assumption.

## 5. Four-week schedule

The schedule is a guide for the facilitator. The participant's practice days
are their own; do not require a daily streak. The app's weekly goal defaults to
30 minutes and sums real measured session seconds. The local log does not store
minutes, so weekly minutes are interview evidence, not a log metric.

| When | Ask | What the facilitator records |
|---|---|---|
| Week 0, day 0 | Consent, participant code, baseline form, install, open the app, turn on the optional beta usage log on the first screen, finish onboarding, do the first 3-minute session. | Consent, code, install date and time, timezone, device and browser/OS, microphone works yes/no, reminder permission yes/no, reminder enabled yes/no, first piece or phrase for the before/after prompt. |
| Week 1, day 7 | 5-minute check-in: how many sessions, which screens, what was confusing or broken, does the microphone still work, is the reminder on and did it arrive. | Self-reported session count as context only (the metric uses `session_complete`), blockers, mic status, reminder status, any support given. |
| Week 2, day 14 | Before/after prompt: record a take of the same short piece or phrase chosen at week 0. If the app shows the private before/after card, ask for one sentence on whether the difference is audible. | Whether a take was saved, whether two takes of the same piece exist, the participant's one-sentence reaction, blockers. |
| Week 4, day 28 | Exit interview, then copy the usage log and send it. | Interview notes, blockers, the exported JSON file. |
| Day 30 or later | One short request for a final copy of the usage log so the day-30 window can be read. | The final JSON file, or "declined" or "no response". |

### Week 0 details

1. Give the participant the consent paragraph and get a written yes. Assign a
   participant code such as `P01`. Keep the code-to-contact mapping in a
   separate private file.
2. Record the baseline: guitar experience, what they want to learn, device,
   browser or Android version, timezone, and whether they have used a
   metronome or a music app before.
3. Install the frozen build. On the first onboarding screen, turn on
   **Optional beta usage log** before finishing onboarding. If the participant
   wants the practice reminder, enable it **after** the log is on. The reminder
   copy arm is assigned from the install id in the log; enabling the reminder
   before opting in can change the arm when the reminder is next scheduled.
4. Finish onboarding and the first session. The first session is practice-only:
   hear four notes, play them back, see one correction, record ten seconds if
   they want, and finish. Tell them it is not a test and nothing is scored.
   **The guided first session is only pushed once after onboarding in this
   build and cannot be reopened after SKIP FOR NOW.** If they skip it, record
   the skip, ask them to do a normal lesson instead, and log the missing re-entry
   as a blocker. A session on a later day is a return, not day-0 activation.
5. Ask them not to clear site data, use incognito, switch browsers, or
   uninstall the APK during the beta. A new browser profile or a reinstall is a
   new install id.
6. Record the piece used for the first take and the week-2 before/after prompt.
   If the participant recorded the guided first session, that take is Ode to
   Joy; use Ode to Joy for the week-2 take so the app can pair them. If they
   skipped the first take, choose one piece now and record a first take before
   week 2. If they do not choose, use the first piece the app offers and write
   it down.

### Week 1 details

Ask the questions in the same order for every participant so the answers can be
compared. Do not coach them to practice more during the check-in. If they ask
for help, give the minimum help needed and record it as a support event and a
possible blocker.

Questions:

- How many times did you open the app this week? How many of those were real
  practice sessions?
- Which screens did you use? Learn/Today, placement, Reading Lab, Practice,
  recordings, Quests, Profile?
- What was confusing, broken, or annoying?
- Did the microphone work? If not, what happened?
- Is the reminder on? Did it arrive? Did it change what you did?
- Is the beta usage log still on? If it is off, why?

### Week 2 details

The before/after prompt is qualitative in this beta. The local log records only
the first saved recording (`first_recording`), not every take. The recordings
manifest is not exported by the app, so the facilitator cannot count two takes
of the same piece from the log. Ask the participant to show the before/after
card if they have two takes, and record their reaction. If they have only one
take, record that and do not invent a comparison.

Questions:

- Did you record a take of the piece or phrase from week 0? How many takes?
- If the app showed the before/after card, what did you hear? Was the
  difference audible to you?
- What stopped you from recording, if anything?
- Same check-in questions as week 1.

### Week 4 exit interview

Keep it to 10 to 15 minutes. Ask open questions first, then the scale question.

- Walk me through the last four weeks. When did you open the app, and what made
  you open it?
- What did you use most? What did you never use?
- What was confusing or broken? Show me the screen if you can.
- Did the first session make sense? Did the one correction help? (Do not ask
  for a score.)
- Did the weekly goal or the quests change what you did, or did they feel like a
  chore?
- Did the reminder arrive? At a useful time? Did it change what you did?
- Would you keep using it? What would you change first?
- Would you recommend it to a friend who is starting guitar? Why or why not?
- May I quote you pseudonymously in the report, using your participant code?

Then ask them to export the log. If they want to stop or erase, honor it before
the export. Do not re-enable the log for them.

## 6. Exporting the local retention log

The app never uploads the log. The participant copies it and chooses where it
goes.

1. Open **Profile**.
2. Open the **Privacy** section.
3. Find **Beta usage log**.
4. Tap **Copy usage log**. The app puts a JSON document on the clipboard and
   shows "Usage log copied to clipboard."
5. Paste into a new plain-text file. Name it `<participant-code>-<YYYY-MM-DD>.json`,
   for example `P07-2026-12-05.json`.
6. Send the file through the private channel agreed at consent. Do not post it
   in a public chat, a public issue, or the repository.
7. Keep the original file unchanged. Do not reformat, sort, trim, or hand-edit
   the JSON.

The document has this shape:

```json
{
  "schemaVersion": 1,
  "installId": "6f1c...32 hex characters",
  "installAt": "2026-11-06T09:00:00.000Z",
  "events": [
    {"name": "app_open", "at": "2026-11-06T09:00:00.000Z", "installId": "6f1c..."}
  ]
}
```

Every event has only `name`, `at`, and `installId`. There is no audio, note
name, piece title, free text, account, email, device id, or app version in the
export.

If **Copy usage log** fails, the app shows "Could not copy the usage log to the
clipboard." Do not ask the participant to transcribe the log by hand and do not
treat a screenshot as data. Try the secure-origin flag or the Android APK. If
the log cannot be copied on that device, record the failure as a blocker and
mark the participant as missing an export; do not reconstruct the events from
memory.

If the log is off, empty, or was erased, record that. Do not turn it back on
without the participant's agreement, and do not fill the gap with another
participant's data.

### Withdrawal and erase

A participant can turn the log off, erase it, or withdraw at any time. If they
withdraw before the analysis, delete their export and their consent record when
they ask. If their data is already combined into pseudonymous counts, explain
that the counts cannot be reversed; the consent paragraph says this before they
start. Never pressure a participant to keep logging.

## 7. Aggregating the metrics

The definitions, field rules, and limits are in
[`BETA_METRICS.md`](BETA_METRICS.md). Do not invent a second definition in the
spreadsheet.

In one line each:

- **Activation:** `onboarding_complete` plus a `session_complete` on the install
  local day.
- **D1, D7, D30:** at least one event on local day 1, 7, or 30 after the install
  day, with that day's window closed.
- **First recording by day 7:** a `first_recording` event on local day 0 through
  the end of local day 7.
- **Session-2 within 48 hours (KC-03):** the next `session_start` within 48
  elapsed hours of session 1's `session_start`, at least 60 minutes after
  session 1's `session_complete`; the denominator is installs with a completed
  first session, and dropouts stay in it.

The headline session-2 number is KC-03, computed from `session_start` and
`session_complete`. Do not use `returnMetricsFromLog` for it: that helper is
diagnostic only, anchors on `session_complete`, and has no 60-minute sitting
boundary. See [decision 0013](decisions/0013-session-two-definition.md).

The short procedure:

1. Freeze the participant list and the data date before opening any export.
2. Validate every file: `schemaVersion` is 1, `installId` is present, and
   `installAt` is present or can be recovered from the first `app_open`. Reject
   an unknown schema version; do not guess.
3. Record the participant's timezone from week 0. Convert every `at` from UTC
   to that local timezone before assigning local day keys. If the timezone is
   unknown, mark the day metrics unavailable for that install.
4. Compute one row per primary install: activation, D1, D7, D30, first
   recording by day 7, session-2 within 48 hours, and completed sessions per
   install-anchored week. Use
   [`BETA_METRICS.md`](BETA_METRICS.md) for the exact rules.
5. Sum the flags, report the numerator and denominator for every percentage,
   and add a 95% Wilson interval. Do not average per-participant percentages.
   Do not pool this cohort with opt-in users from outside the beta.
6. Report `INSUFFICIENT DATA` when a window has not closed or the denominator
   is zero. Do not estimate a missing value.
7. Keep the raw exports and the calculation sheet in a private folder on the
   facilitator's machine. Do not commit them, attach them to a ticket, or put
   them in a public link.

A simple sheet has one row per participant and these columns:

| Column | Value |
|---|---|
| `participant` | `P01` to `P20`, never a name |
| `installId` | The id from the export |
| `installAt` | UTC from the export |
| `timezone` | The participant's local timezone at install |
| `client` | `web` or `android` |
| `buildCommit` | The commit recorded at install |
| `onboardingComplete` | First `onboarding_complete` present |
| `activated` | `onboarding_complete` and a `session_complete` on the install local day |
| `d1`, `d7`, `d30` | `yes`, `no`, or `window open` |
| `firstRecordingByDay7` | `yes`, `no`, or `window open` |
| `session2Within48h` | `yes`, `no`, or `no session 1` |
| `sessionsWeek0` to `sessionsWeek3` | Count of `session_complete` in each install-anchored week |
| `exportFile` | The private file name |
| `notes` | Data-quality flags, not opinions |

The reminder experiment is not analyzed here. It has its own pre-registered
protocol, decision rule, and report tool in
[`REMINDER_EXPERIMENT.md`](REMINDER_EXPERIMENT.md). This runbook only records
the participant's reminder permission and exposure answer at week 0 and week 1.
Do not compute per-arm reminder results in this sheet unless the manager asks
for them separately.

## 8. Recording and ranking blockers

Every reported problem goes in the blocker log, including problems that were
fixed during the session. The log is the evidence for the top-five tickets.

### Blocker record

| Field | What to write |
|---|---|
| `id` | `B01`, `B02`, ... |
| `date` | Local date the participant hit it |
| `participant` | Participant code, or `facilitator` for a setup problem |
| `build` | Git commit and `web` or `android` |
| `surface` | Install, onboarding, first session, placement, Reading Lab, practice, recordings, quests, weekly goal, reminder, profile, settings |
| `device` | Browser and OS, or Android model and version |
| `expected` | What should have happened, in one sentence |
| `actual` | What happened, including the exact message if there is one |
| `severity` | `S1`, `S2`, `S3`, or `S4` |
| `frequency` | How many participants hit it, and how many reached that surface |
| `workaround` | What the participant did instead, or `none` |
| `evidence` | Screenshot, quote, or steps. No audio, no personal data |
| `owner` | Who will investigate |
| `followUp` | Ticket id, or `none` |

### Severity

- **S1:** blocks install, onboarding, or the first session. The participant
  cannot reach the product.
- **S2:** blocks a core beta surface (placement, Reading Lab, practice,
  recordings, quests, weekly goal, reminder) for at least one participant and
  there is no workaround.
- **S3:** friction or confusion with a workaround. It costs time or causes a
  wrong turn but does not block the surface.
- **S4:** cosmetic or copy problem.

Frequency is a fraction, not a count. "Three participants" means little without
"of the five who reached that screen." Record both.

### Ranking the top five

Rank in this order:

1. S1 blockers, by the number of participants who could not start.
2. S2 blockers, by the number of participants affected divided by the number
   who reached the surface.
3. S3 blockers that appear in both the web and Android cohorts, or that explain
   a return drop.
4. S3 blockers with high frequency and a small fix.
5. S4 blockers only after the higher severities are exhausted.

Tie-break with the surface closest to the first session and the return loop. Do
not rank by the loudest complaint, by the easiest fix, or by a hypothesis that
is not in the log.

### From blocker to follow-up ticket

The facilitator writes one draft per top-five blocker. The manager files it in
Plane; an implementation agent does not edit Plane for this ticket.

```text
Title: Fix <blocker> for the beta cohort
Evidence: <participant codes, dates, build, device>
Frequency: <n> of <m> participants who reached <surface>
Severity: <S1-S4>
Observed: <what happened>
Expected: <what should happen>
Workaround: <what participants did>
Acceptance: <observable behavior>; a regression test; no new network, account, or
  cloud path; docs updated if a rule or setting changes
Owner: <role>
Blocked by: <ticket, or none>
```

Do not fold a blocker fix into the T5.7 kit silently. The kit is the preparation;
the run and the fixes are separate work. T5.7 stays open until the run and the
fixes have real evidence.

If a new build ships during the cohort, record the date, the commit, and which
participants received it. Do not compare retention across the two builds as if
they were one cohort.

## 9. Exit criteria

The run is complete only when all of these are true:

1. 20 participants consented and installed the frozen build. If fewer were
   enrolled, the run is incomplete; the report must say how many and why, and
   T5.7 stays open.
2. Four weeks have elapsed since each participant's install, and every
   participant has a disposition: completed, withdrew, lost contact, or invalid
   install.
3. Every participant counted in a quantitative metric has a valid schema-1
   export with an install day; the report states how many did not.
4. The day-7 window has closed for every install in the D7 denominator. The
   day-30 window has closed for every install in the D30 denominator, or D30 is
   reported as `INSUFFICIENT DATA`.
5. The blocker log has an entry for every reported problem, with severity,
   frequency, and evidence. The top five are ranked and drafted as follow-up
   tickets.
6. The report has the raw numerators and denominators, a 95% Wilson interval
   for every proportion, the build commit or commits, the cohort window, the
   data-freeze date, and the limitations in section 10.
7. The report makes no claim about store installs, share-to-install,
   microphone accuracy, scored phrase accuracy, revenue, or the product's
   overall retention rate.

If an item is missing, the run is incomplete and T5.7 stays open. Do not fill a
gap with an estimate. A smaller denominator is honest; an invented one is not.

## 10. What this beta cannot measure

The local log is deliberately small. It cannot tell you about store installs or
store conversion, share-to-install or invite attribution, or another
participant's device. It also has no app version, device, OS, or timezone; no
note names or per-note results, so it cannot supply microphone or phrase
accuracy; no session seconds, so it cannot supply weekly minutes or weekly-goal
completion, and it cannot supply P1.5's first-note <60 s or first-phrase <3 min
latency targets because it has no reliable start-to-event timer. It has no
placement, Reading Lab, or quest events; only the first recording, not every
take or a same-piece pair; and no notification permission, crash, uninstall, or
revenue event. KC-04's primary evidence is the cohort recording manifest and
before/after pair; the opt-in log's `first_recording` is diagnostic. The cohort
is 20 hand-recruited volunteers, so a result is directional for this cohort,
not the product's retention rate or a causal effect.

[`BETA_METRICS.md`](BETA_METRICS.md) has the field-by-field list in section 4.
The short rule is: if the field is not `name`, `at`, `installId`, or
`installAt`, the export cannot answer the question.

### Source conflicts and caveats to resolve before the report

These are recorded here so the manager can correct the source, not silently
worked around:

1. **Session-2 is settled.** [Decision
   0013](decisions/0013-session-two-definition.md) makes KC-03 the only
   session-2 definition for a gate or beta report. `returnMetricsFromLog` is
   diagnostic only and must not supply the headline number. The beta kit uses
   KC-03: anchor on `session_start`, require the next `session_start` within 48
   hours of session 1's `session_start` and at least 60 minutes after session 1's
   `session_complete`, and keep dropouts in the denominator.
2. [`PHASE_GATES.md`](PHASE_GATES.md) P1.3 lists T5.7 as a source for phrase
   false-fail and false-pass. This beta cannot supply that: the scored loop is
   off and the log has no note-level data. Phrase accuracy stays with T1.6 and
   T1.7. Correct the P1.3 source line before the Phase 1 gate.
3. **KC-04's primary source is not the log.** The dashboard makes the cohort
   recording manifest and before/after evidence primary; the opt-in log's
   `first_recording` is diagnostic. This beta cannot read the manifest, so
   `first_recording` by day 7 is a diagnostic signal, not the KC-04 gate number.
4. [`KILL_CRITERIA_DASHBOARD.md`](KILL_CRITERIA_DASHBOARD.md) KC-12 says T5.7
   must add a researcher-readable recordings manifest export before KC-12 can be
   measured. This ticket's deliverables do not add that export, and this kit
   does not change app code. The beta can measure `first_recording` by day 7,
   but it cannot count two takes of the same piece. If KC-12 is expected from
   this beta, that export needs its own ticket before the run.

Event meanings are canonical. `first_note` is the first determinate scored
note-prompt answer (naming, placing, or hearing), correct or incorrect. It is
not pitch-verified and is not accuracy evidence. `first_phrase` is the first
completed practice-only first-session phrase verification. It is not a scored
phrase and is not accuracy evidence. One call-site mismatch remains: the current
first-session flow also calls `recordFirstNote()` after a practice-only
verification. That call is an implementation defect against the `first_note`
meaning; until it is removed, a `first_note` event does not prove a scored note
prompt. Do not infer pitch verification, correctness, or accuracy from it.

## 11. Data handling and roles

- **Facilitator:** recruits, consents, installs, runs check-ins and the exit
  interview, records blockers, and stores the exports.
- **Analyst:** validates the exports, computes the metrics with the definitions
  in [`BETA_METRICS.md`](BETA_METRICS.md), and writes the report.
- **Manager or human owner:** owns the ticket, the cohort decision, the
  follow-up tickets, and the merge/release decision.
- **Participant:** owns the device and the log. They choose whether to copy it,
  whether to send it, and whether to erase it.

Keep the consent forms, the code-to-contact mapping, and the exports in a
private folder that is not the repository, not a public cloud link, and not a
shared chat. Do not put a participant's name, email, or exact address in the
blocker log or the report. Use the code. Delete the mapping and the consent
records at the date stated in the consent paragraph, or earlier on request.

The app's local progress backup is separate from the usage log. Restoring a
progress backup does not import or export the log. Do not use a progress backup
as a substitute for the log export.

## 12. Facilitator checklists

### Before the first participant

- [ ] Read the ticket, this runbook, [`BETA_METRICS.md`](BETA_METRICS.md),
  [`RETENTION_INSTRUMENTATION.md`](RETENTION_INSTRUMENTATION.md), and
  [`REMINDER_EXPERIMENT.md`](REMINDER_EXPERIMENT.md).
- [ ] Build one frozen web bundle and, if needed, one frozen APK. Record the git
  commit and build time.
- [ ] Test the build on your own device: onboarding, log opt-in, first session,
  one lesson, one recording, one log copy.
- [ ] Confirm the web server is reachable from a second device on the LAN.
- [ ] Prepare the consent form, baseline form, participant codes, blocker log,
  and private export folder.
- [ ] Decide who will answer participant questions and who will analyze the
  exports. Do not let the analyst coach practice during the cohort.

### Each install

- [ ] Consent signed or written.
- [ ] Participant code assigned; contact mapping stored separately.
- [ ] Build commit and client recorded.
- [ ] Timezone, device, browser/OS, and microphone result recorded.
- [ ] Log opted in before onboarding finished.
- [ ] Reminder permission and enabled answer recorded after the log opt-in.
- [ ] First session done or explicitly skipped; the skip is recorded.
- [ ] Participant told not to clear site data, use incognito, or uninstall.

### Each check-in

- [ ] Sessions and surfaces asked in the same order.
- [ ] Blockers written in the participant's words, with steps.
- [ ] Microphone and reminder status recorded.
- [ ] Log status recorded; no pressure to re-enable.
- [ ] Support given is recorded as a support event, not counted as product
  success.

### Exit

- [ ] Interview completed or the reason recorded.
- [ ] Usage log copied, named, and stored privately.
- [ ] Day-30 follow-up requested.
- [ ] Participant told how to erase the log and how to withdraw.
- [ ] Blocker log complete; top five ranked; follow-up drafts written.
- [ ] Data freeze date and cohort window written in the report.

## 13. Report template

Use this shape for the beta report. Fill only what the exports and interviews
support.

```text
T5.7 beta report
Cohort window:
Data freeze:
Build commit(s):
Participants enrolled:
Participants with a valid export:
Participants in each denominator:
Client split (web/android):
Recruitment method:
Consent and data handling:

Activation: <n>/<d> (<pct>, 95% Wilson <low> to <high>)
D1: <n>/<d> ...
D7: <n>/<d> ...
D30: <n>/<d> ... or INSUFFICIENT DATA
First recording by day 7: <n>/<d> ...
Session-2 within 48 hours (KC-03): <n>/<d> ...
Completed sessions per install-anchored week: <counts>

Top five blockers:
1. <blocker>, <severity>, <n>/<m>, <ticket>
...

What the data cannot say:
<copy the relevant limits from section 10>

Qualitative themes:
<short, pseudonymous quotes with participant codes>

Follow-up tickets:
<links>
```

Do not put an unlabeled percentage in the report. Every percentage gets its
numerator and denominator. Do not write "retention improved" or "users loved
it" without the evidence that says so.
