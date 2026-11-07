# Manual export for teacher review (T7.2)

**Status:** implemented in T7.2; pending manager review and merge. This is a
local export workflow, not a teacher dashboard and not a sync service.

A student can hand one saved take to a teacher without an account, a server, or
a cloud drive. The app writes three files on the device and opens the operating
system share sheet. The student chooses every destination. Nothing is uploaded
by the app.

## The workflow

1. Open **Practice → Recordings**.
2. Find the take and tap **EXPORT FOR TEACHER**.
3. The app writes three files under the app support `exports/` folder:
   `<take-id>.wav`, `<take-id>.json`, and `<take-id>.pdf`.
4. On mobile and desktop, the OS share sheet opens with the three files. The
   student picks where to send them.
5. On web, the browser downloads the three files. There is no share sheet in
   the web build.
6. The student's stored take, its manifest entry, and the recording counters are
   unchanged. The export is a copy.

The screen shows the caption: “Export for teacher gives you the take, a
one-page summary, and a JSON copy. Nothing is uploaded; your teacher gets a copy
only if you share it.”

## Bundle contents

| File | Content |
|---|---|
| `<take-id>.wav` | The stored take bytes, byte-for-byte. Never re-encoded, rewritten, or deleted. |
| `<take-id>.json` | A versioned summary document (`schemaVersion: 1`). |
| `<take-id>.pdf` | A one-page A4 summary rendered with PDF standard fonts. |

No ZIP or archive is produced. The three files are shared together or
downloaded separately; see [Platform behavior](#platform-behavior-and-limitations).

### JSON summary

The stable top-level shape is:

```json
{
  "schemaVersion": 1,
  "takeId": "take-1",
  "createdAt": "2026-11-06T12:30:00.000Z",
  "durationMs": 42000,
  "capped": false,
  "pieceId": "ode-to-joy",
  "piece": {
    "title": "Ode to Joy",
    "composer": "Ludwig van Beethoven",
    "stage": 2
  },
  "phraseId": "p1",
  "appVersion": "4.0.0",
  "exportedAt": "2026-11-07T09:15:00.000Z",
  "evidence": {
    "label": "Stored practice evidence, not a teacher grade",
    "attempts": 7,
    "bestAccuracy": 0.92,
    "bestTempoBpm": 72,
    "performanceDays": 4,
    "masteryDays": 1,
    "performanceSpanDays": 9,
    "contentVersion": 1,
    "lastPerformedAt": "2026-11-05T18:00:00.000Z"
  }
}
```

- `piece` is null when the launch-piece catalogue does not know the piece id.
- `phraseId` is null for a free take or a whole-piece take.
- `evidence` is null when the take has no phrase id, or when no stored
  `ProgressState.phraseProgress` record exists for that phrase.
- The summary contains no account, name, email, device id, install id, audio
  path, or free text the learner typed. The local retention log's `installId`
  is never included.

### PDF summary

The one-page PDF carries the same facts plus the plain-language header required
by
[`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md) §6.5:

- **What this file contains:** one WAV take, the PDF summary, and the JSON copy.
- **Who it is for:** a teacher or another person the student chooses. The app
  does not send it to anyone.
- **Keeping and deleting it:** the teacher should delete the copy after the
  review and no later than 90 days after receiving it. The student deletes the
  local take from Recordings with **Delete** or **Clear all**.

The evidence section is labelled **Stored practice evidence, not a teacher
grade**. It reports raw counters only. A take with no stored record says “No
stored practice evidence for this take” and never invents a score.

## Consent, privacy, and deletion

- The export is student-initiated and explicit. There is no automatic share,
  upload, sync, or public link.
- The app has no account and no student identity. The bundle carries the take
  metadata and stored evidence only, never a name field.
- **COPPA gate.** The teacher channel is a Phase 2 pilot and remains gated by
  [`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md). No student
  under 18 takes part without a guardian consent record, and no gate in §7 is
  cleared by this ticket. T7.2 builds the export control; it does not open the
  teacher channel, clear a legal gate, or certify the product. Do not describe
  the channel as open, compliant, or approved.
- **Deletion path.** The existing recordings controls are the deletion path: a
  per-take **Delete** and **Clear all** remove the local take and its manifest
  entry. The export copies in the app support `exports/` folder are normal files
  and can be deleted by the student with the platform file manager or the
  browser's downloads list. Deleting a local take does not delete a copy the
  teacher already received; the app cannot reach another device. The teacher
  agreement and the COPPA plan own that duty.
- **Backup caveat.** The `exports/` folder is app support, not the `media/`
  directory covered by the Android backup rules and the iOS exclusion request.
  An exported copy may be included in device backup. The UI must not claim
  otherwise.

## Platform behavior and limitations

- **Share sheet.** `share_plus` hands the three file paths to the OS share sheet.
  It is an operating-system hand-off, not a network service: no account, no
  upload, no sync, no analytics. It is wrapped in `TakeShareGateway` so tests
  never touch a platform channel.
- **Web.** The web build does not compile `share_plus`; a conditional import
  resolves to a download-only fallback. The bundle exporter triggers three
  browser downloads. Browsers can throttle or block several downloads started
  by one tap; if one cannot start, the app shows a typed message and the files
  that did download remain. There is no ZIP.
- **Multiple file types.** Some share destinations accept only one file type
  (audio, JSON, or PDF). The three files are always written to the exports
  folder, so the student can share them individually if a destination refuses
  the set.
- **Verified in this branch.** `flutter analyze`, `flutter test` (1096 tests),
  and `flutter build web --release` pass. The OS share sheet has **not** been
  verified on a physical iOS or Android device in this environment; the tests
  use a fake gateway. Do not claim device share behavior, iPad popover
  anchoring, or Android multi-file acceptance until a device check is recorded.
- **WASM.** The release web build targets JavaScript. `flutter build web` prints
  a WASM dry-run warning from `image`, a transitive dependency of `pdf`; it does
  not fail the JS build. No WASM claim is made.

## What this export does not do

- No teacher dashboard, roster, assignments, comments, student accounts, or
  cloud sync. Those remain T7.5 and are gated.
- No public recital, share link, social feed, or leaderboard.
- No score, grade, mastery certification, or teacher-approved badge. The
  summary carries stored evidence or an explicit “no stored evidence” line.
- No automatic upload or background sync. The student chooses the destination
  in the OS share sheet.
- No AAC/compressed export; V1 is WAV (decision
  [`0009`](decisions/0009-v1-recording-format.md)).
- No ZIP/archive package. The brief asks for three files shared together, and
  `share_plus` accepts multiple files.

## Code map

| Path | Purpose |
|---|---|
| `flutter_app/lib/core/media/take_export_summary.dart` | `TakeExportSummary`, JSON, and the one-page PDF builder |
| `flutter_app/lib/core/media/take_bundle_exporter.dart` | Bundle request/result types and the exporter interface |
| `flutter_app/lib/core/media/take_bundle_exporter_io.dart` | Writes the three files under `exports/` |
| `flutter_app/lib/core/media/take_bundle_exporter_web.dart` | Browser download fallback |
| `flutter_app/lib/core/media/take_share_gateway.dart` | Share seam and typed result |
| `flutter_app/lib/core/media/take_share_gateway_share_plus.dart` | `share_plus` implementation (IO only) |
| `flutter_app/lib/core/media/take_share_gateway_web.dart` | Web unsupported/download message |
| `flutter_app/lib/core/app_metadata.dart` | The single `appVersion` constant, checked against `pubspec.yaml` |
| `flutter_app/lib/state/recording_controller.dart` | `exportTakeBundle`, evidence resolution, share outcome |
| `flutter_app/lib/features/recordings/recordings_screen.dart` | The action button and honest caption |
| `flutter_app/lib/state/providers.dart` | Bundle and share providers |

## Tests

- `flutter_app/test/take_export_summary_test.dart` — JSON shape and version,
  deterministic output apart from the export time, unknown piece/phrase
  fallback, no invented score, PDF header and length, app-version drift.
- `flutter_app/test/take_bundle_exporter_test.dart` — IO writes all three files,
  never touches a source take, rejects traversal names, returns typed failures.
- `flutter_app/test/recordings_screen_test.dart` — the export action calls the
  bundle flow once, a typed failure is shown instead of an exception, a phrase
  take includes real evidence, a missing record says there is no evidence, a
  cancelled share keeps the files, and a web download reports the three files.
- No test touches a real platform channel, a real share sheet, or the network.

## Pilot checklist

Before a teacher pilot, run the deletion rehearsal in
[`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md) §4.8 on each
device class. This document does not claim that rehearsal has been run.
