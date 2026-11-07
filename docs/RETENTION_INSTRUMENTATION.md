# Local retention instrumentation

This document describes the local-only, opt-in beta usage log added in T5.4.
It exists so the team can measure the onboarding and practice funnel without
turning the app into a tracking product. The decision is recorded in
[`decisions/0006-local-retention-instrumentation.md`](decisions/0006-local-retention-instrumentation.md).

## Boundaries

- The app has no network code, no accounts, no cloud sync, no analytics SDK, and
  no third-party tracking package. This log does not change that.
- The log lives in `shared_preferences` under its own key. It is separate from
  `ProgressState`; restoring a progress backup does not import or export it.
- Nothing is uploaded. The only way the log leaves the device is when the user
  taps **Copy usage log** in Profile and chooses what to do with the clipboard
  text.
- The log contains no audio, no note names, no piece titles, no free text, no
  user id, no email, and no hardware or advertising identifier.

## Opt-in

- Logging is **off by default**.
- The switch appears on the **first onboarding screen** and in
  **Profile → Privacy → Beta usage log**.
- Enabling the switch creates the first `app_open` event, pins `installAt`, and
  records `onboarding_start`. The first onboarding screen is therefore the
  point where a new install can enter the funnel.
- Disabling the switch stops new events immediately. Existing events stay
  until the user taps **Erase log**.
- A user who leaves the switch off has no onboarding events. A user who turns
  it on and later turns it off keeps the events recorded while it was on.

## Events

The wire names are stable. Do not rename them without a schema change.

| Wire name | Enum | Emitted when | Repeat rule |
|---|---|---|---|
| `app_open` | `appOpen` | The app starts, resumes, or the user opts in | At most once per local day |
| `onboarding_start` | `onboardingStart` | The first onboarding screen initializes or its consent switch is enabled | Once per install |
| `onboarding_complete` | `onboardingComplete` | Onboarding is finished while opted in | Once per install |
| `first_note` | `firstNote` | The first scored `NotePrompt` answer | Once per install |
| `first_phrase` | `firstPhrase` | Reserved for the real phrase path (T2.5) | Once per install |
| `first_recording` | `firstRecording` | Reserved for the real recording path (T4.2) | Once per install |
| `session_start` | `sessionStart` | A lesson, practice, or jump test starts | Every session |
| `session_complete` | `sessionComplete` | A session finishes, passed or failed | Every session |
| `daily_active` | `dailyActive` | A session completes | At most once per local day |
| `reminder_opt_in` | `reminderOptIn` | The learner enables the local practice reminder | Once per install; no copy, piece, or time is stored |

`first_phrase` and `first_recording` have no caller in this ticket. T2.5 and
T4.2 must call `RetentionController.recordFirstPhrase()` and
`recordFirstRecording()` from the real feature paths. Do not fake them from a
lesson.

## Fields

Each event has exactly three fields:

```json
{
  "name": "first_note",
  "at": "2026-11-06T09:15:00.000Z",
  "installId": "6f1c...32 hex characters"
}
```

- `name` — one of the wire names above.
- `at` — UTC ISO-8601 timestamp.
- `installId` — a locally generated pseudonymous id. It is 16 random bytes from
  `Random.secure()`, written as hex. It is not derived from hardware, an
  account, or an advertising id. It stays stable for the life of the local log
  and is kept when the log is erased.

## Storage

- Key: `hear_me_out_retention_v1`
- Schema version: `1`
- Document shape:

```json
{
  "schemaVersion": 1,
  "optIn": false,
  "installId": "6f1c...",
  "installAt": "2026-11-06T09:00:00.000Z",
  "events": []
}
```

- `installAt` pins the install day at the first consent/`app_open`. It is kept
  outside the event list so trimming cannot move D1/D7/D30. Older documents
  without it fall back to the first `app_open`.
- Corrupt JSON, wrong field types, and unknown event names are ignored. A bad
  event is dropped without making the rest of the log unreadable.
- A document with `schemaVersion` greater than `1` is rejected as a whole and
  is not rewritten by a plain load. A later explicit save replaces it.
- The log keeps at most **500 events**. The oldest events are dropped first.
  This is the retention window: there is no time-based purge. `installAt`
  survives trimming.
- `ProgressState` is unchanged. The log is not part of the progress backup.

## Export

**Copy usage log** puts a JSON document on the clipboard:

```json
{
  "schemaVersion": 1,
  "installId": "6f1c...",
  "installAt": "2026-11-06T09:00:00.000Z",
  "events": [
    {"name": "app_open", "at": "2026-11-06T09:00:00.000Z", "installId": "6f1c..."}
  ]
}
```

Every event keeps only `name`, `at`, and `installId`. The export adds the
document's `installAt` so D1/D7/D30 survive trimming; it has no `exportedAt`,
device, app version, or free-text field. Uploading or sharing the export is a
manual user or researcher action outside the app.

## Erase

**Erase log** asks for confirmation, then deletes every stored event and writes
an empty log with the same pseudonymous install id, install day, and opt-in
choice. It does not remove the key and does not turn logging off. A subsequent
event starts a fresh log with the same install id; turn the switch off as well
if you want both. The action cannot be undone.

## Bias caveat

Opt-in instrumentation is **not an unbiased baseline**. People who turn on a
beta log differ from people who ignore it, and they know they are being
observed. Use this log to debug the funnel and to form hypotheses. For the
pilot, use the hand-recruited beta cohort and report its results separately.
Do not present opt-in D1/D7/D30 as the product's retention rate.

## Reminder-copy experiment

T5.6 uses this log for a local, pre-registered reminder-copy experiment: a
specific-task reminder versus `Time to practice!`. The protocol, assignment
rule, metrics, sample-size caveat, and decision rule are in
[`REMINDER_EXPERIMENT.md`](REMINDER_EXPERIMENT.md). The experiment is
**prepared, not measured**; it adds no upload, no event name, and no storage
key. The analysis helper is `returnMetricsFromLog` in
`lib/core/retention/return_metrics.dart`.

## API

Pure domain (`lib/core/retention/`):

- `RetentionEventName` — stable wire names.
- `RetentionEvent` — name, UTC timestamp, install id.
- `RetentionLog` — `record`, `funnel`, `activeDays`, `retainedOnDay`,
  `d1Retained`, `d7Retained`, `d30Retained`, `exportJson`.
- `ReturnMetrics` / `returnMetricsFromLog` — session-2 within 48 elapsed hours
  and D7 activity for the reminder experiment; see
  [`REMINDER_EXPERIMENT.md`](REMINDER_EXPERIMENT.md).

Storage (`lib/core/storage/retention_store.dart`):

- `RetentionStore.load` — returns an opted-out document on corrupt or future
  data; it never throws.
- `RetentionStore.save`
- `RetentionStore.clear` — removes the whole key. The Profile erase action does
  not call this; it saves an empty log so the install id, install day, and
  choice survive.

State (`lib/state/retention_controller.dart`):

- `retentionStoreProvider` — overridden in tests.
- `retentionControllerProvider` — UI state and the record methods.
- All writes are best-effort: a storage failure never breaks a lesson or
  onboarding.

## Tests

- `test/retention_test.dart` — event names, bound, timestamp-ordered funnel,
  D1/D7/D30, pinned install day, export fields, and the pure-domain import rule.
- `test/return_metrics_test.dart` — session-2 at 47/48/49 hours, same-day
  sessions, D7 boundaries, future timestamps, and foreign install ids.
- `test/retention_store_test.dart` — default opt-out, round trip, corrupt and
  future data, bad event entries, bound on load, install-day persistence.
- `test/retention_controller_test.dart` — opt-in gating, persistence, erase,
  onboarding dedupe, first-event dedupe, and the `AppController` session hooks.
- `test/retention_profile_test.dart` — default-off switch, toggle, copy, erase,
  and 390×844 / 1200 px layouts.
- `test/onboarding_test.dart` — first-screen consent, reachable onboarding
  funnel, and no events when the switch stays off.
