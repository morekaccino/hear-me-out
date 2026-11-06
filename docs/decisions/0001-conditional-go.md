# Decision 0001 — Conditional go for Phase 1 engineering while the assessment corpus is open

**Date:** 2026-11-05
**Status:** Accepted
**Owner:** AI delivery manager
**Supersedes:** Nothing
**Related:** T1.1, T1.2, T1.3, T1.4, T1.5, T1.6, T1.7, T2.1, T9.2

## Context

`T1.7` is the plan's hard gate: no Phase 1 product work until a corpus of at
least 240 real takes shows phrase-level false pass <= 5%, false fail <= 10%,
per-note recall >= 99%, and the other validity gates in the assessment
contract. The gate exists for a good reason: a mic-first phrase loop that
scores beginners dishonestly is worse than no phrase loop.

The gate has two different risks inside it:

1. **Engineering risk** — sample-rate handling, onset detection, alignment,
   tri-state scoring, deterministic timing, and the device test rig. This can
   be reduced now with synthetic signals, known-ground-truth fixtures, and
   recorded hardware runs.
2. **Evidence risk** — recruiting 6–10 players across four devices and three
   conditions, recording 240 takes, and labelling them. This needs people and
   hardware. An autonomous agent team cannot honestly manufacture it.

Blocking every line of Phase 1 code on the second risk would idle the
engineering work for weeks and make the eventual spike slower. Shipping the
phrase loop without the second risk would violate the plan.

## Decision

Proceed with Phase 1 **engineering** in parallel with the open corpus gate,
under these conditions:

- `T1.3`, `T1.4`, `T1.5`, `T1.6`, `T2.1`–`T2.5`, `T3.2`, and later engineering
  tickets may start before `T1.7`.
- The phrase loop and any content that depends on validated phrase scoring stay
  unreachable from the main navigation, behind a single feature switch that the
  implementing ticket adds, until `T1.7` passes. The Reading Lab and single-note
  features remain available. The switch has no production "on" path before the
  gate.
- No document, ticket, or UI may claim that mic accuracy is validated. `T1.6`
  and `T1.7` stay open until real corpus evidence exists.
- The assessment contract in `D0.5` is the interface. Code that cannot satisfy
  it is a bug, not a reason to weaken the contract.
- If `T1.7` fails, the phrase loop is disabled and the app falls back to
  call-and-response, single-bar assessment, or the notation trainer. The
  domain models and audio fixes remain useful in every branch.
- A human still owns `T1.1` (recruit players), the hardware runs in `T1.4`,
  the corpus in `T1.6`, and the `T1.7` decision. Those tickets are not marked
  Done by an agent.

## Consequences

Positive: the highest-risk code is written and tested while the human evidence
is collected; the spike can use a working engine instead of starting from
scratch; domain work is not serialized behind a four-week recruitment window.

Negative: some UI or content work may be reworked if the spike fails. The
feature flag and the "no validated-accuracy claims" rule bound that cost. The
team must resist treating a passing synthetic suite as a passing spike.

## Evidence for the decision

- The current audio pipeline hard-codes 44.1 kHz mono and `DateTime.now()`;
  both are correctness bugs independent of the spike.
- The plan already requires those fixes before the corpus (`D0.5` section 4.6).
- Synthetic fixtures can prove determinism, resampling, onset detection,
  alignment, and tri-state behavior. They cannot prove real-world accuracy;
  that remains the gate.
