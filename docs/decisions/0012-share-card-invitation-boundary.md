# Decision 0012 — Sharing the before/after card is an invitation, not a referral loop

**Date:** 2026-11-16
**Status:** Accepted
**Owner:** AI delivery manager
**Supersedes:** Nothing
**Related:** T8.6, T4.4, T7.2, T9.2, decisions 0006 and 0011

## Context

T4.4 built a private before/after PNG card, and T7.2 added the
`TakeShareGateway` seam so an explicit export can open the OS share sheet
(decision 0011). T8.6 asks for a shareable card, a referral link or code, and a
measurement of shares to installs.

V1 has no account, server, deep link, store install attribution, or network
path. A referral code would create a number the app cannot measure: the app
never learns whether a recipient installed anything. Inventing a shares-to-
installs figure would violate the "do not fake stats" rule, and adding the
server or attribution SDK needed to measure it would break the local-only
boundary. The ticket's purpose, a card that can be shared without exposing a
score or account, does not depend on a referral loop.

## Decision

1. **No referral code, invite redemption, deep link, store attribution, or
   shares-to-installs metric in V1.** The share payload is the card plus a plain
   invitation line, and the local log records `card_shared`. That event counts
   a successful hand-off from this device; it is not a reach, install, or
   conversion count.
2. **The only payload is the generated PNG.** Audio is never included, and the
   card screen has no audio option. The card carries the piece, phrase, date
   range, and the one honest metric (days apart). It contains no score, grade,
   percentage, rank, streak, leaderboard, or comparison with another learner.
3. **The invitation is one documented constant.** `beforeAfterInviteText` in
   `lib/core/media/before_after_share.dart` is the only shared text. It is a
   plain invitation: no score, percentage, rank, comparison, streak shame, or
   link. A test pins the exact value and rejects those terms.
4. **The share action is explicit and reuses the existing seams.** **SHARE
   CARD** renders the same PNG as **EXPORT CARD**, writes it through
   `RecordingExporter`, and hands that one file plus
   `beforeAfterInviteText` to `TakeShareGateway`. On IO the gateway opens the
   OS share sheet; the app does not upload, sync, or post anything. On web the
   browser downloads the PNG and app code does not import or call `share_plus`.
   The existing export path and the teacher bundle are unchanged.
5. **`card_shared` is recorded once per successful share.** A cancelled,
   unavailable, failed, or download-only result records nothing. The event is
   local and opt-in under decision 0006, with the same pseudonymous fields as
   every other event; it adds no piece, text, or destination.
6. **The card is a share, not a social surface.** There is no public link,
   feed, leaderboard, rank, or score comparison. The user chooses the
   destination in the OS share sheet, and the app cannot see it.

## Consequences

Positive: the card can leave the device without an account, a server, a referral
code, or a fake conversion metric. The recipient sees a plain invitation and a
private card. Tests never open a real share sheet, and the web build keeps its
download-only behavior.

Negative: the team cannot measure shares to installs, because V1 has no
attribution. `card_shared` is a local hand-off count from opted-in installs, not
a population metric, and it does not prove the recipient kept or opened the
card. Some share destinations accept only files or only text, so the invitation
may not appear next to the PNG. The OS share sheet has not been verified on a
physical iOS or Android device in this environment; the tests use a fake
gateway.

A future attribution or referral feature needs a new decision, a privacy review,
and a deep-link/store plan. It is not implied by this record.

## Evidence

- `flutter_app/lib/core/media/before_after_share.dart` — the pinned invitation
  and subject.
- `flutter_app/lib/core/retention/retention_event.dart` — `cardShared`
  (`card_shared`) appended to the wire names.
- `flutter_app/lib/state/recording_controller.dart` —
  `shareBeforeAfterCard` writes no progress, sends one file, and records the
  event only for `TakeShareStatus.shared`.
- `flutter_app/lib/features/before_after/before_after_screen.dart` — the
  explicit **SHARE CARD** action and the unchanged **EXPORT CARD** path.
- `flutter_app/test/share_card_test.dart` — pinned invitation text, one event
  per successful share, no event for cancelled/unavailable/failed/download-only
  results, and no event when the log is opted out.
- `flutter_app/test/before_after_screen_test.dart` — one PNG and the invitation
  reach the fake gateway once; export does not share; the web-style download
  calls no share sheet.
- `flutter analyze`, `flutter test`, and `flutter build web --release` pass on
  this branch. No device share or install attribution is claimed.

## Follow-up

The manager owns the T9.2 index entry. Any referral, deep-link, or install
measurement work needs its own ticket and decision record; this one does not
open it.
