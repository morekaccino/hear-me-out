# Decision 0005 - Foundation stage-1/2 melodies stay on strings 1-3

**Date:** 2026-11-06
**Status:** Accepted
**Owner:** AI delivery manager
**Related:** T3.1, T3.3, T3.8, T3.10, T9.2

## Context

T3.1 locked the 10-piece launch list with a nominal string/fret target per
stage: stages 1-2 on strings 1-3, stage 3 on strings 4-6, and so on. T3.3 first
arranged the Foundation pieces in their lowest first-position octave. That
reading needs string 4 for Greensleeves (one E4), Ode to Joy (D4/E4/F#4), and
Amazing Grace (D4/E4). String 4 is not taught until stage 3, so those
arrangements introduced untaught left-hand technique into stage-1/2 content.
The review rejected the "record the deviation" approach for that reason.

## Decision

Stage-1/2 arrangements must not use string 4. The melodies stay on strings 1-3
through octave choices, not through a string-4 exception:

- **Greensleeves:** the single low E4 in "to cast me off" is played as E5
  (open high E). Every other note stays at written pitch.
- **Ode to Joy:** the theme is written one octave up (D5-A5, sounding D4-A4).
  It uses strings 1-2; A5 is string 1 fret 5 and every other note is at fret
  0-3.
- **Amazing Grace:** the setting starts on G4 (string 3 open). Bars 3-4 are an
  octave up (G5-E5-D5) because the written G4-E4-D4 would need string 4; the
  other phrases stay in the lower octave.

The remaining stage-3 piece keeps its upper notes inside the planned string
span by using string 3 frets 4-5: Down by the Riverside's B4/C5 sit there
instead of on string 2, and D4-F4 stay on string 4. T3.1 therefore records
these first-position envelopes:

| Piece | `rangeAndPosition` |
|---|---|
| `greensleeves` | First position; strings 1-3; frets 0-3 |
| `ode-to-joy` | First position; strings 1-2; frets 0-5 |
| `amazing-grace` | First position; strings 1-3; frets 0-3 |
| `down-by-the-riverside` | First position; strings 3-4; frets 0-5 |
| `original-study-1` | First position; strings 4-6; frets 0-3 |

The monophonic, no-shift, and no-chord rules are unchanged. Frets 4-5 are
first-position reaches, not position shifts; no arrangement uses an untaught
string or a second position. The Foundation test parses
`rangeAndPosition` and rejects any note outside the recorded string span or
fret ceiling.

## Consequences

Positive: stages 1-2 stay on the taught treble strings, the arrangements remain
first position, and the T3.1 map and the scores cannot drift apart silently.

Negative: Ode to Joy uses a ledger-line A5, Amazing Grace has an octave-up echo
phrase, and Down by the Riverside reaches fret 5 on string 3. The arrangement
notes and the record above make those choices explicit. T3.8/content QA still
owns the musical review and the 3-beginner playtest; T3.3 does not claim either.
