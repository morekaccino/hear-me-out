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
   sync, and no tracking. It is wrapped in `TakeShareGateway` so tests and the
   web build never touch a platform channel. The share action is explicit: one
   tap, one destination chosen by the student. There is no automatic share.
2. **The bundle is three files, not one archive.** One selected take produces
   the existing WAV bytes, a one-page PDF summary, and a versioned JSON summary.
   The files are shared together. No ZIP/archive package is added; `share_plus`
   already accepts multiple files. `archive` appears in the lockfile only as a
   transitive dependency of `pdf` and is not used for packaging.
3. **`pdf` renders the summary.** The package is pure Dart, so `lib/core/` stays
   free of native plugins and the web build needs no platform PDF engine.
   `printing` and native PDF plugins are not added. The PDF uses PDF standard
   fonts (Helvetica), not a bundled font asset; a font asset is not worth the
   size for one page.
4. **The stored take is unchanged.** The bundle exporter copies the stored WAV
   bytes; it never re-encodes, deletes, or rewrites the take or its manifest
   entry. IO writes into the existing app support `exports/` folder. Web uses
   the existing browser-download technique through a conditional import; the
   web build does not compile `share_plus`.
5. **The summary carries evidence or says it has none.** Stored phrase evidence
   is included only when the take has a phrase id and a real
   `ProgressState.phraseProgress` record exists. The block is labelled “Stored
   practice evidence, not a teacher grade.” A take without evidence says so in
   the JSON and the PDF. No score, grade, or mastery claim is invented.
6. **The deletion path is the existing recordings controls.** A per-take
   **Delete** or **Clear all** removes the local take and its manifest entry.
   The export copies are normal files in `exports/` and are outside the media
   backup exclusion; the UI does not claim they are excluded. The app cannot
   delete a copy a teacher already received; the teacher agreement and the
   COPPA plan own that duty.
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

The pubspec declares `pdf: ^3.11.3` and `share_plus: ^13.3.1`; the lockfile
pins `pdf 3.11.3`. A future ticket may raise `pdf` and `xml` together after
proving the image/archive pair on every target.

## Consequences

Positive: the teacher workflow exists without a server, account, or sync. The
bundle is self-describing, carries real evidence or says it has none, and leaves
the stored take untouched. The share seam is injectable, so CI never opens a
share sheet, and the web build remains a pure download because the platform
share path is conditionally excluded.

Negative: the OS share sheet is not verified on a physical iOS or Android device
in this environment, so no device share claim is made. Some destinations accept
only one file type, so the student may need to share the three files
individually. Web browsers can throttle several downloads from one tap. The
`exports/` folder sits outside the media backup exclusion, so an exported copy
may be included in device backup; the copy is the student's responsibility.
The teacher channel remains gated by the COPPA plan, and this decision does not
clear any legal gate.
