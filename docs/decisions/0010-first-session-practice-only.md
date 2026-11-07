# Decision 0010 — Unscored practice-only phrase feedback may precede T1.7

**Date:** 2026-11-07
**Status:** Accepted
**Owner:** AI delivery manager
**Supersedes:** Nothing
**Related:** T5.2, T1.7, T2.5, T9.2, decision 0001

## Context

T5.2 needs a first session that lets a new learner hear four notes, play them
back, see one correction, and record ten seconds. The only existing phrase
feedback surface is `PhrasePlayerScreen`, which is written for the scored phrase
loop. Decision 0001 keeps the scored phrase loop and any content that depends on
validated phrase scoring unreachable from main navigation until T1.7 passes.

The first session does not need a score. It needs one honest correction from the
same verifier the scored flow will use, with no FSRS, mastery, XP, quest, or
streak write. Gating every use of the phrase player would leave the first
session without a real correction; duplicating the verifier would create a second
audio path to maintain.

## Decision

1. The first-session flow may construct `PhrasePlayerScreen` directly with
   `practiceOnly: true` and `recordProgress: false` before T1.7. It is not
   reachable from Learn, Today, or Practice.
2. A practice-only player take writes no progress, no mastery, no XP, no quest
   counter, no streak, and no recording unless the learner uses the separate
   recording step. It never claims validated microphone accuracy.
3. The scored phrase loop, scored content, and any main-navigation entry remain
   behind `phraseLoopEnabled` exactly as decision 0001 requires. No production
   path turns that switch on before T1.7.
4. The first-session recording is the only saved artifact. The local funnel
   events (`first_note`, `first_phrase`, `first_recording`) are instrumentation,
   not mastery.
5. `PhrasePlayerScreen.onVerification` exists only to hand the single correction
   to the first-session flow. It does not save progress.

## Consequences

Positive: a new learner can play something real and hear one honest correction
on day one without shipping the scored phrase loop or creating a second verifier.

Negative: the phrase player has a second, non-scored entry point. Its doc comment
and tests must make the distinction explicit, and a future refactor must not
accidentally save a practice-only take. T1.7 still owns the scored loop and any
accuracy claim.

## Evidence

- `features/first_session/first_session_screen.dart` uses `practiceOnly: true`,
  `recordProgress: false`, and `onVerification` only for the correction.
- The first-session widget test proves the funnel hooks fire and the phrase take
  writes no progress.
- `flutter analyze`, the full CI suite, and `flutter build web --release` pass.
- No microphone accuracy or device evidence is claimed.

## Follow-up

T1.7 remains open. When it passes, the scored phrase loop can be enabled behind
the existing switch and this practice-only path can stay as the first-session
onboarding experience.
