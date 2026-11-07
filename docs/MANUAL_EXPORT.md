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
3. The pre-export sheet shows the plain-language header: what the bundle
   contains, who it is for, the 90-day teacher retention rule, and how to delete
   the copy. Confirm **EXPORT**.
4. The app writes three files under the app support `exports/` folder:
   `<take-id>.wav`, `<take-id>.json`, and `<take-id>.pdf`.
5. On Android and iOS, the OS share sheet opens with the three files. The
   student picks where to send them. On web, the browser downloads the three
   files; there is no share sheet.
6. The student's stored take, its manifest entry, and the recording counters are
   unchanged. The export is a copy.
7. The exported copies stay in the app's `exports/` folder until the student
   taps **CLEAR EXPORTS** on the Recordings screen (Android/iOS). On web the
   browser's downloads list owns them.

The screen shows the caption: “Export for teacher gives you the take, a
one-page summary, and a JSON copy. Nothing is uploaded by the app; your teacher
gets a copy only if you share it. Exported copies stay in the app until you tap
Clear exports.”

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
  "evidenceStatus": "stored",
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
- `evidenceStatus` is one of:
  - `stored` — a real `ProgressState.phraseProgress` record was read and copied;
    `evidence` is the object above.
  - `none` — the take has no phrase id, or the phrase has no stored record;
    `evidence` is null. This is a positive finding, not an assumption.
  - `unavailable` — the progress aggregate could not be read; `evidence` is null
    and the PDF says the evidence could not be read. The app does not claim
    there is none.
- The summary contains no account, name, email, device id, install id, audio
  path, or free text the learner typed. The local retention log's `installId`
  is never included.

### PDF summary

The one-page PDF carries the same facts plus the plain-language header required
by
[`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md) §6.5. The
same header is shown in the pre-export sheet, so the student sees it before the
share sheet opens:

- **What this file contains:** one WAV take, the PDF summary, and the JSON copy.
- **Who it is for:** a teacher or another person the student chooses. The app
  does not send it to anyone; the student shares it from the device share sheet
  or downloads it in a web browser.
- **Keeping and deleting it:** the teacher should delete the copy after the
  review and no later than 90 days after receiving it. On Android/iOS the
  student deletes the export copies with **CLEAR EXPORTS**; on web, with the
  browser's downloads list. **Delete** and **Clear all** remove the stored take,
  not an export copy.

The evidence section is labelled **Stored practice evidence, not a teacher
grade**. It reports raw counters only. A take with no stored record says “No
stored practice evidence for this take.” A take whose progress could not be read
says “Practice evidence could not be read for this take.” Neither case invents a
score.

The standard PDF fonts cover WinAnsi/Latin-1, so the current launch list
(including “Spanish Romance (Romance Anónimo)”) renders. A future title or
composer outside that range needs a bundled font; no font asset is bundled
today.

## Consent, privacy, and deletion

- The export is student-initiated and explicit. The header sheet is shown before
  the share sheet; there is no automatic share, upload, sync, or public link.
- The app has no account and no student identity. The bundle carries the take
  metadata and stored evidence only, never a name field.
- **COPPA gate.** The teacher channel is a Phase 2 pilot and remains gated by
  [`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md). No student
  under 18 takes part without a guardian consent record, and no gate in §7 is
  cleared by this ticket. T7.2 builds the export and deletion controls; it does
  not open the teacher channel, clear a legal gate, or certify the product. Do
  not describe the channel as open, compliant, or approved.
- **Deletion path for stored takes.** A per-take **Delete** and **Clear all**
  remove the local take and its manifest entry.
- **Deletion path for exported copies.** On Android and iOS, **CLEAR EXPORTS**
  deletes only the files directly inside the app support `exports/` folder
  (WAV, PDF, JSON). It does not touch the media store, the recording manifest,
  progress, or settings. The exports folder is inside the app sandbox and is
  not visible to the system file manager, so this in-app control is the deletion
  path; a file-manager instruction would be false. On web, use the browser's
  downloads list; the app cannot see or delete browser downloads.
- **Teacher copies.** Deleting a local take or the exported copies does not
  delete a copy the teacher already received. The app cannot reach another
  device. The teacher agreement and the COPPA plan own that duty.
- **Backup caveat.** The `exports/` folder is app support, not the `media/`
  directory covered by the Android backup rules and the iOS exclusion request.
  An exported copy may be included in device backup. The UI must not claim
  otherwise.

## Platform behavior and limitations

- **Share sheet (Android/iOS).** `share_plus` hands the three file paths to the
  OS share sheet. It is an operating-system hand-off, not a network service: no
  account, no upload, no sync, no analytics. It is wrapped in `TakeShareGateway`
  so tests never touch a platform channel. The app has no desktop target; a
  desktop share claim is out of scope, and `share_plus` does not support files
  on Linux.
- **Web.** The app does not import or call `share_plus` on web; a conditional
  import resolves to a download-only gateway. `share_plus` declares a web
  plugin, so the generated web plugin registrant may still compile/register it,
  but app code never calls it on web. The bundle exporter triggers three browser
  downloads. Browsers can throttle or block several downloads started by one
  tap; if one cannot start, the app shows a typed message and the files that did
  download remain. There is no ZIP. The app has no in-app clear action for web
  downloads; use the browser's downloads list.
- **Multiple file types.** Some share destinations accept only one file type
  (audio, JSON, or PDF). The three files remain in the app's `exports/` folder
  until **CLEAR EXPORTS**; the app does not provide a per-file share from that
  folder. A destination that refuses the set is a destination limitation, not a
  file-location workaround.
- **Verified in this branch.** `flutter analyze`, `flutter test` (the count is
  recorded in `AGENTS.md`), and `flutter build web --release` pass. The OS share
  sheet has **not** been verified on a physical iOS or Android device in this
  environment; the tests use a fake gateway. Do not claim device share behavior,
  iPad popover anchoring, or Android multi-file acceptance until a device check
  is recorded.
- **WASM.** The release web build targets JavaScript. `flutter build web` prints
  a WASM dry-run warning from `image`, a transitive dependency of `pdf`; it does
  not fail the JS build. No WASM claim is made.

## What this export does not do

- No teacher dashboard, roster, assignments, comments, student accounts, or
  cloud sync. Those remain T7.5 and are gated.
- No public recital, share link, social feed, or leaderboard.
- No score, grade, mastery certification, or teacher-approved badge. The
  summary carries stored evidence, an explicit no-evidence line, or an
  evidence-unavailable line.
- No automatic upload or background sync. The student chooses the destination
  in the OS share sheet.
- No AAC/compressed export; V1 is WAV (decision
  [`0009`](decisions/0009-v1-recording-format.md)).
- No ZIP/archive package. The brief asks for three files shared together, and
  `share_plus` accepts multiple files.

## Code map

| Path | Purpose |
|---|---|
| `flutter_app/lib/core/media/take_export_summary.dart` | `TakeExportSummary`, tri-state evidence, the shared header, JSON, and the one-page PDF builder |
| `flutter_app/lib/core/media/take_bundle_exporter.dart` | Bundle request/result types and the exporter interface |
| `flutter_app/lib/core/media/take_bundle_exporter_io.dart` | Writes the three files under `exports/` |
| `flutter_app/lib/core/media/take_bundle_exporter_web.dart` | Browser download fallback |
| `flutter_app/lib/core/media/take_export_cleaner.dart` | Clear-exports seam and typed result |
| `flutter_app/lib/core/media/take_export_cleaner_io.dart` | Deletes only direct files under `exports/` |
| `flutter_app/lib/core/media/take_export_cleaner_web.dart` | Reports that the browser owns downloads |
| `flutter_app/lib/core/media/take_share_gateway.dart` | Share seam and typed result |
| `flutter_app/lib/core/media/take_share_gateway_share_plus.dart` | `share_plus` implementation (IO only) |
| `flutter_app/lib/core/media/take_share_gateway_web.dart` | Web unsupported/download message |
| `flutter_app/lib/core/app_metadata.dart` | The single `appVersion` constant, checked against `pubspec.yaml` |
| `flutter_app/lib/state/recording_controller.dart` | `exportTakeBundle`, tri-state evidence, `clearExports`, share outcome |
| `flutter_app/lib/features/recordings/recordings_screen.dart` | The header sheet, action button, caption, clear-exports action, neutral notice |
| `flutter_app/lib/state/providers.dart` | Bundle, cleaner, and share providers |

## Tests

- `flutter_app/test/take_export_summary_test.dart` — JSON shape and version,
  deterministic output apart from the export time, unknown piece/phrase
  fallback, no invented score, tri-state evidence, the shared header content,
  PDF signature and non-trivial length, a non-ASCII launch-piece title, and
  app-version drift.
- `flutter_app/test/take_bundle_exporter_test.dart` — IO writes all three files,
  never touches a source take, rejects traversal names, returns typed failures.
- `flutter_app/test/take_export_cleaner_test.dart` — deletes only direct files
  under `exports/`, leaves nested directories and the media store alone, handles
  an absent folder, and returns a typed failure for a broken exports path.
- `flutter_app/test/recordings_screen_test.dart` — the export header is shown
  before the share sheet, the export action is disabled in flight, a typed
  failure is shown instead of an exception, a phrase take includes real
  evidence, a missing record says there is no evidence, an unread progress
  record says the evidence is unavailable, a cancelled share uses a neutral
  notice and keeps the files, a web download reports the three files, and clear
  exports succeeds, fails typed, and is hidden when the platform has no app
  folder.
- No test touches a real platform channel, a real share sheet, or the network.

## Pilot checklist

Before a teacher pilot, run the deletion rehearsal in
[`COPPA_GUARDIAN_CONSENT_PLAN.md`](COPPA_GUARDIAN_CONSENT_PLAN.md) §4.8 on each
device class. This document does not claim that rehearsal has been run.
