# Foundation piece arrangements (T3.3)

**Status:** Arrangements authored; **not musically reviewed, recorded,
playtested, or legally cleared.**
**Owner:** T3.3. **Musical review and 3-beginner playtest:** T3.8/content QA
(the playtest is human-owned and is not claimed here).
**Reference recordings:** T3.5. **Legal review:** T6.3. **Runtime wiring:**
T2.11/T2.12.

This document describes the five Foundation arrangements from the locked T3.1
list. Each piece is a strictly monophonic, standard-tuning, capo-0 score in the
T3.2 authoring format. Every file has exactly four phrases and every phrase is
two to four bars. The arrangements were written from the traditional melodies
and from an original study; they do not copy a copyrighted edition or
arrangement.

The machine-readable files are:

```text
flutter_app/assets/content/pieces/foundation/greensleeves.json
flutter_app/assets/content/pieces/foundation/ode-to-joy.json
flutter_app/assets/content/pieces/foundation/amazing-grace.json
flutter_app/assets/content/pieces/foundation/down-by-the-riverside.json
flutter_app/assets/content/pieces/foundation/original-study-1.json
```

They are validated by `flutter_app/test/foundation_pieces_test.dart` and by the
T3.2 CLI:

```powershell
cd flutter_app
dart run tool/content/validate_piece.dart assets/content/pieces/foundation/greensleeves.json
```

All five files pass with **0 errors and 0 warnings**. The test parses T3.1's
`rangeAndPosition` and checks every note against it, so a future string or fret
deviation cannot hide behind the per-piece envelope. No runtime loader is added
in this ticket: T2.11/T2.12 wire content into the app, and the assets are not
listed in `pubspec.yaml` yet.

## Summary

| Piece | Key | Meter | Tempo | Bars | Phrase bars | Written range | Strings / frets | Stage |
|---|---|---|---:|---:|---|---|---|---:|
| `greensleeves` | A minor | 6/8 | 60 | 9 | 3 + 2 + 2 + 2 | G4-E5 | 1-3 / 0-3 | 1 |
| `ode-to-joy` | D major | 4/4 | 72 | 8 | 2 + 2 + 2 + 2 | D5-A5 | 1-2 / 0-5 | 2 |
| `amazing-grace` | G major | 3/4 | 66 | 8 | 2 + 2 + 2 + 2 | G4-G5 | 1-3 / 0-3 | 2 |
| `down-by-the-riverside` | G major | 4/4 | 76 | 12 | 4 + 4 + 2 + 2 | D4-C5 | 3-4 / 0-5 | 3 |
| `original-study-1` | A minor | 4/4 | 60 | 12 | 3 + 3 + 3 + 3 | E3-F4 | 4-6 / 0-3 | 3 |

"Written range" is staff pitch; the guitar sounds one octave lower. All notes
are inside the V1 written range E3-E6 and the sounding range E2-E5.

## Stage envelope

T3.1's recorded `rangeAndPosition`, `docs/LAUNCH_PIECES.md`, and the test use the
same envelope. Stages 1-2 use no string 4. Decision 0005 records the octave
choices and the two first-position fret reaches that keep Ode to Joy and Down by
the Riverside inside their recorded string spans.

| Piece | T3.1 strings | T3.1 max fret | Actual strings | Actual max fret | Note |
|---|---|---|---|---|---|
| `greensleeves` | 1-3 | 3 | 1-3 | 3 | E4 in P2 is played as E5. |
| `ode-to-joy` | 1-2 | 5 | 1-2 | 5 | Octave up; A5 is string 1 fret 5. |
| `amazing-grace` | 1-3 | 3 | 1-3 | 3 | Bars 3-4 are played an octave up. |
| `down-by-the-riverside` | 3-4 | 5 | 3-4 | 5 | B4/C5 are string 3 frets 4-5. |
| `original-study-1` | 4-6 | 3 | 4-6 | 3 | Matches T3.1 exactly. |

The three stage-1/2 melodies that would dip below G4 stay on strings 1-3:

- **Greensleeves:** the single low E4 in "to cast me off" is played an octave
  higher as E5 (open high E). Every other note stays at written pitch.
- **Ode to Joy:** the whole theme is written one octave above the first-position
  guitar octave (D5-A5, sounding D4-A4), so it uses strings 1-2 and never string
  4. A5 is string 1 fret 5.
- **Amazing Grace:** the setting starts on G4 (string 3 open). Bars 3-4 are
  played an octave higher (G5-E5-D5) because their written G4-E4-D4 would need
  string 4; the other phrases stay in the lower octave.

## `greensleeves`

- **Source melody:** traditional English tune, registered in 1580. The setting
  follows the public-domain melody as given in the Wikibooks
  `Songbook/Greensleeves` LilyPond transcription (A minor/Dorian); it is a new
  single-line guitar setting, not an edition copy.
- **Key / meter / tempo:** A minor, 6/8, 60 BPM.
- **Phrase map:** P1 bars 1-3 (one-eighth anacrusis plus two full bars);
  P2 bars 4-5; P3 bars 6-7; P4 bars 8-9. Total 9 bars.
- **Position and range:** written G4-E5 (sounding G3-E4); strings 1-3, frets
  0-3. Open G4, B4, and E5 carry the "open strings" focus. The low E4 in P2 is
  played as E5 (open high E).
- **Technique focus:** open strings, steady pulse, 6/8 lilt.
- **Transposition:** none. The tune is written in the guitar's normal octave,
  one octave above sounding pitch. The one low E4 is octave-displaced to E5 so
  stage 1 never leaves strings 1-3.
- **Editorial changes:** the sixteenth-note passing ornaments in the source are
  written as eighths and dotted quarters; the raised seventh G-sharp is kept at
  the cadence. The source is often notated in A Dorian with F-sharp; this
  setting follows the T3.1 key of A minor and omits the F-sharp passing
  ornament.
- **Legal question for T6.3:** confirm the 16th-century melody and the chosen
  edition are public domain in the US, UK/EU, and Canada, and that no
  copyrighted harmonic setting or arrangement is copied.

## `ode-to-joy`

- **Source melody:** the "Ode to Joy" theme from the fourth movement of
  Beethoven's Symphony No. 9 (1824). New single-line guitar reduction.
- **Key / meter / tempo:** D major, 4/4, 72 BPM.
- **Phrase map:** P1 bars 1-2; P2 bars 3-4; P3 bars 5-6; P4 bars 7-8. Total
  8 bars.
- **Position and range:** written D5-A5 (sounding D4-A4); strings 1-2, frets
  0-5. The theme is one octave above the first-position guitar octave, so D5 is
  string 2 fret 3 and the melody never needs string 4. A5 is string 1 fret 5;
  every other note is at fret 0-3.
- **Technique focus:** stepwise melody, quarter-note pulse, phrase endings.
- **Transposition:** octave up from the written D4-A4 version; the key stays D
  major and no note is octave-displaced inside a phrase. The high octave is
  what keeps the stage-2 setting on strings 1-3.
- **Editorial changes:** the theme is complete and unaltered.
- **Legal question for T6.3:** confirm the 1824 melody and the chosen edition
  are public domain in the US, UK/EU, and Canada, and that the engraving is
  public domain or newly made.

## `amazing-grace`

- **Source melody:** New Britain (1835), the tune normally sung to "Amazing
  Grace". New single-line guitar setting after public-domain hymnal melodies.
- **Key / meter / tempo:** G major, 3/4, 66 BPM.
- **Phrase map:** P1 bars 1-2; P2 bars 3-4; P3 bars 5-6; P4 bars 7-8. Total
  8 bars.
- **Position and range:** written G4-G5 (sounding G3-G4); strings 1-3, frets
  0-3. The melody starts on G4 (string 3 open). Bars 3-4 are an octave up
  (G5-E5-D5) because the written G4-E4-D4 would need string 4; bars 1-2 and
  5-8 stay in the lower octave. The final cadence is G4 tied across the bar
  line.
- **Technique focus:** triple meter, breath-length phrases, legato changes, one
  register echo into the upper octave.
- **Excerpt:** the opening four bars and the final four bars of the 16-bar
  tune, without the anacrusis so the piece starts on G4. The middle eight bars,
  including the D5 climax, are omitted so the piece stays an 8-bar stage-2
  reading task and ends on the tonic G.
- **Transposition:** none; the tune stays in G major. The second phrase is
  moved up an octave to avoid string 4.
- **Legal question for T6.3:** confirm the New Britain melody is public domain
  in the US, UK/EU, and Canada; confirm the chosen melody edition is public
  domain or newly engraved; confirm no hymnal harmonization is copied.

## `down-by-the-riverside`

- **Source melody:** traditional African-American spiritual, 19th century,
  author unknown. The pitch sequence follows the public-domain
  Musicaviva/John Chambers ABC setting in D major and is transposed to G; the
  setting is new and monophonic.
- **Key / meter / tempo:** G major, 4/4, 76 BPM.
- **Phrase map:** P1 bars 1-4 (verse, first half); P2 bars 5-8 (verse, second
  half); P3 bars 9-10 (chorus, first half); P4 bars 11-12 (chorus, final
  cadence). Total 12 bars.
- **Position and range:** written D4-C5 (sounding D3-C4); strings 3-4, frets
  0-5. D4-F4 sit on string 4 (frets 0-3); G4-C5 sit on string 3, with B4 and C5
  at frets 4-5 so the upper notes stay inside the T3.1 strings 3-4 envelope.
  The melody never goes below D4, so strings 5-6 are not used.
- **Technique focus:** middle-string reading (string 4 for the lower melody
  notes, string 3 for the upper ones), syncopated eighths, and two chromatic
  notes (A-sharp lower neighbour and F-natural flat seventh). The earlier
  "lower-strings" tag was wrong because most notes sit on strings 3-4; the
  skills name middle strings and string crossing.
- **Transposition:** source ABC in D major, transposed up a perfect fourth to
  G major. The source's C natural becomes F natural (the flat seventh), and
  the E-sharp lower neighbour becomes A-sharp.
- **Editorial changes:** the anacrusis figure is omitted so the 12-bar piece
  keeps four phrases of two to four bars; sixteenth-note pairs are simplified
  to eighths; the repeated chorus bars are reduced to a single statement plus
  the final cadence. The melodic pitches and the verse/chorus contrast are
  preserved.
- **Legal question for T6.3:** confirm the spiritual is public domain in the
  US, UK/EU, and Canada; identify the earliest printed source; confirm the
  chosen edition is not a copyrighted arrangement.

## `original-study-1`

- **Source:** original composition for this project. It quotes no external
  melody.
- **Key / meter / tempo:** A minor, 4/4, 60 BPM.
- **Phrase map:** P1 bars 1-3; P2 bars 4-6; P3 bars 7-9; P4 bars 10-12. Total
  12 bars.
- **Position and range:** written E3-F4 (sounding E2-F3); strings 4-6, frets
  0-3. This matches the T3.1 target exactly.
- **Technique focus:** lower-string reading, accidentals (F-sharp and B-flat as
  chromatic neighbours), 12-bar form.
- **Transposition:** none.
- **Legal question for T6.3:** confirm the study is original, quotes no
  external melody, and that authorship and assignment are documented for all
  territories.

## Not done here

- No human musical review. Every file records
  `"reviewedBy": "Pending musical review"`; the test only requires the field to
  be non-empty so a later review can replace it without weakening the test.
- No 3-beginner playtest. T3.8/content QA owns that human step; T3.3 does not
  claim it.
- No reference recordings. T3.5 owns the human takes.
- No legal clearance. T6.3 owns the territory-by-territory review, and this
  document is not legal advice.
- No runtime asset loading, pubspec entry, UI, storage, learning, or audio
  change. T2.11/T2.12 wire the content into the app.
- No exercises, lessons, or progress rules for the pieces. Those are later
  content and app work.
