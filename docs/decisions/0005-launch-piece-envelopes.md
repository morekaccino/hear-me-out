# Decision 0005 - Launch-piece string envelopes are recorded from the arrangement

**Date:** 2026-11-06
**Status:** Accepted
**Owner:** AI delivery manager
**Related:** T3.1, T3.3, T3.8, T3.10, T9.2

## Context

T3.1 locked the 10-piece launch list with a nominal string/fret target per
stage: stages 1-2 on strings 1-3, stage 3 on strings 3-6, and so on. T3.3
arranged the five Foundation pieces. Four of the five need a string outside
that nominal set to keep the traditional melody in first position:

- Greensleeves dips to written E4 (string 4 fret 2) once.
- Ode to Joy's natural first-position octave uses strings 3-4, frets 0-4.
- Amazing Grace starts on D4/E4 and uses strings 2-4, frets 0-2.
- Down by the Riverside uses strings 2-4, frets 0-3.

Forcing the nominal string set would require octave shifts that change the
melody's register (and read worse for a stage-1/2 learner). The adjacent string
is the smaller change.

## Decision

The stage string label describes the **primary teaching focus**, not a hard
technical restriction. A launch piece may use an adjacent string when the
melody requires it, provided:

- it stays in first position (frets 0-4) and introduces no shift, chord, or
  untaught technique;
- T3.1's `rangeAndPosition`, `docs/LAUNCH_PIECES.md`, and the arrangement notes
  record the actual envelope;
- T3.8's content QA checks the recorded envelope and the 3-beginner playtest.

The monophonic and first-position rules are unchanged. This decision does not
relax the V1 no-chords, no-shift, or one-note-at-a-time constraints.

## Consequences

Positive: the traditional melodies stay recognizable and readable; the content
does not force unnatural octaves to satisfy a planning label.

Negative: the stage label and the actual string set can differ, so every
downstream surface (mastery map, practice hints) must read `rangeAndPosition`
rather than infer the strings from the stage. T3.10 must publish the recorded
map. If a future stage needs a strict string set, that is a new curriculum
decision, not a silent content edit.
