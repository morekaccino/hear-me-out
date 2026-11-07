# Decision 0011 — Manual teacher export uses an OS share sheet and a three-file bundle

**Date:** 2026-11-07
**Status:** Accepted
**Owner:** Engineering
**Supersedes:** Nothing
**Related:** T7.2, T4.2, T4.4, T7.3, T7.5, T9.2, plan section 10.3

## Context

The recording pipeline deliberately shipped without a share package. Its
comment said: “There is deliberately no share or cloud package.” The only way
to get a take out of the app was a single-WAV export to `<app support>/exports/`
on IO or a browser download on web.

T7.2 requires a manual teacher workflow: a student selects one take and exports
the audio plus a one-page summary, without an account or a cloud service. The
teacher reviews a copy; there is no persistent sync. This decision is required
because it changes the earlier no-share-package rule for this one workflow.

The COPPA and guardian consent plan (`docs/COPPA_GUARDIAN_CONSENT_PLAN.md`)
requires the export to be student-initiated, to carry the minimum data, and to
include a plain-language header saying what the file contains, who it is for,
how long the teacher may keep it, and how to delete it. The teacher channel
itself remains gated and is not opened by this decision.

## Decision

1. **The OS share sheet is the delivery seam.** `share_plus` is added because it
   is a local operating-system hand-off: no network, no account, no cloud, no
   sync, and no tracking. It is wrapped in `TakeShareGateway` so tests and app
   code never touch a platform channel. On web the app does not import or call
   `share_plus`; it uses a download-only gateway. `share_plus` declares a web
   plugin, so the generated web plugin registrant may still compile/register
   it, but app code never calls it on web. The share action is explicit: the
   student sees the header sheet, confirms, and chooses one destination. There
   is no automatic share.
2. **The bundle is three files, not one archive.** One selected take produces
   the existing WAV bytes, a one-page PDF summary, and a versioned JSON summary.
   The files are shared together. No ZIP/archive package is added; `share_plus`
   already accepts multiple files. `archive` appears in the lockfile only as a
   transitive dependency of `pdf` and of the dev-only `flutter_launcher_icons` →
   `image` chain; it is not used for packaging.
3. **`pdf` renders the summary.** The package is pure Dart, so `lib/core/` stays
   free of native plugins and the web build needs no platform PDF engine.
   `printing` and native PDF plugins are not added. The PDF uses PDF standard
   fonts (Helvetica), not a bundled font asset; a font asset is not worth the
   size for one page. Standard fonts cover WinAnsi/Latin-1; a future non-Latin
   title needs a bundled font.
4. **The stored take is unchanged.** The bundle exporter copies the stored WAV
   bytes; it never re-encodes, deletes, or rewrites the take or its manifest
   entry. IO writes into the existing app support `exports/` folder. Web uses
   the existing browser-download technique through a conditional import.
5. **The summary carries a tri-state evidence field.** Stored phrase evidence is
   included only when the take has a phrase id and a real
   `ProgressState.phraseProgress` record exists (`evidenceStatus: stored`). A
   missing phrase record is `none`; a failed progress read is `unavailable`, so
   the summary never claims there is no evidence when it could not look. The
   stored block is labelled “Stored practice evidence, not a teacher grade.” No
   score, grade, or mastery claim is invented.
6. **Deletion has two explicit paths.** A per-take **Delete** or **Clear all**
   removes the local take and its manifest entry. A new **Clear exports**
   control deletes only the files directly inside the app support `exports/`
   folder; it cannot reach the media store, manifest, progress, or settings.
   Android/iOS do not expose that sandbox folder to the system file manager, so
   the in-app control is the real deletion path; web downloads use the
   browser's downloads list. The export copies are outside the media backup
   exclusion and the UI does not claim they are excluded. The app cannot delete
   a copy a teacher already received; the teacher agreement and the COPPA plan
   own that duty.
7. **No teacher account, dashboard, roster, upload, or sync is added.** The
   teacher receives a copy only if the student sends it. T7.5 remains gated by
   the COPPA plan and a separate decision.

## Version constraint

`pdf` is held at the 3.11.x line by the existing `xml ^6.6.1` dev dependency.
The resolution details are a constraint, not a preference:

- `pdf 3.13.x` requires `xml >=7.0.1`, which would upgrade an unrelated dev
  dependency. T7.2 does not do that.
- `pdf 3.12.0` supports `xml 6.x`, but it caps `archive` at `<4.1.0` while the
  `image` versions it permits (`4.11+`) call an `archive` API that is absent
  from the highest allowed `archive` (`4.0.9`). That pair does not compile.
- `pdf 3.11.3` caps `image` at `<4.6.0`, which resolves to `image 4.5.4` and
  `archive 4.0.9`, a working pair with `xml 6.6.1`.

The pubspec declares `pdf: '>=3.11.3 <3.12.0'` and `share_plus: ^13.3.1`; the
upper bound prevents a lockfile refresh from resolving the non-compiling
`pdf 3.12`/`image`/`archive` pair. The lockfile pins `pdf 3.11.3`. A future
ticket may raise `pdf` and `xml` together after proving the image/archive pair
on every target.

## Consequences

Positive: the teacher workflow exists without a server, account, or sync. The
bundle is self-describing, carries tri-state evidence rather than a guess, shows
the header before the share sheet, and leaves the stored take untouched. The
share seam is injectable, so CI never opens a share sheet. App code on web never
imports or calls `share_plus`; it uses the download-only gateway, though the
generated plugin registrant may still compile/register the plugin. The in-app
Clear exports control closes the Android/iOS copy-deletion gap.

Negative: the OS share sheet is not verified on a physical iOS or Android device
in this environment, so no device share claim is made. Some destinations accept
only one file type, and the app does not provide a per-file share from the
exports folder. Web browsers can throttle several downloads from one tap. The
`exports/` folder sits outside the media backup exclusion, so an exported copy
may be included in device backup; the copy is the student's responsibility.
The teacher channel remains gated by the COPPA plan, and this decision does not
clear any legal gate.
