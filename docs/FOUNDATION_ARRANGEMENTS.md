# Foundation piece arrangements (T3.3)

**Status:** Arrangements authored; **not musically reviewed, not recorded, and
not legally cleared.**
**Owner:** T3.3. **Musical review:** pending. **Reference recordings:** T3.5.
**Legal review:** T6.3. **Runtime wiring:** T2.11/T2.12.

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

All five files pass with **0 errors and 0 warnings**. No runtime loader is added
in this ticket: T2.11/T2.12 wire content into the app, and the assets are not
listed in `pubspec.yaml` yet.

## Summary

| Piece | Key | Meter | Tempo | Bars | Phrase bars | Written range | Strings / frets | Stage |
|---|---|---|---:|---:|---|---|---|---:|
| `greensleeves` | A minor | 6/8 | 60 | 9 | 3 + 2 + 2 + 2 | A4-E5 | 1-3 / 0-3 | 1 |
| `ode-to-joy` | D major | 4/4 | 72 | 8 | 2 + 2 + 2 + 2 | D5-A5 | 1-2 / 0-5 | 2 |
| `amazing-grace` | G major | 3/4 | 66 | 9 | 3 + 2 + 2 + 2 | G4-G5 | 1-3 / 0-3 | 2 |
| `down-by-the-riverside` | G major | 4/4 | 76 | 12 | 4 + 4 + 2 + 2 | E4-G4 | 3-4 / 0-5 | 3 |
| `original-study-1` | A minor | 4/4 | 60 | 12 | 3 + 3 + 3 + 3 | E3-F4 | 4-6 / 0-3 | 3 |

"Written range" is staff pitch; the guitar sounds one octave lower. All notes
are inside the V1 written range E3-E6 and the sounding range E2-E5.

## Recorded ranges and Decision 0005

The original T3.1 string targets were planning labels. Four melodies cannot be
played literally inside their stated string/fret envelope without changing the
tune or forcing an unnatural octave. Decision 0005 records the actual
first-position envelope for each launch piece and keeps T3.1's
`rangeAndPosition` metadata, `docs/LAUNCH_PIECES.md`, and this table in sync.
Stage labels still describe the primary teaching focus; they are not a hard
string restriction, and no arrangement adds a shift, chord, or untaught
technique.

| Piece | Original T3.1 target | Recorded envelope | Reason |
|---|---|---|---|
| `greensleeves` | strings 1-3, frets 0-3 | strings 1-3, frets 0-3 | No deviation after the phrase is read an octave up; the melody is A4-E5. |
| `ode-to-joy` | strings 1-3, frets 0-3 | strings 1-2, frets 0-5 | The theme is read an octave up (D5-A5) so it stays on strings 1-2; A5 needs fret 5 on string 1. |
| `amazing-grace` | strings 1-3, frets 0-3 | strings 1-3, frets 0-3 | No deviation after the G-major melody is read an octave up (G4-G5). |
| `down-by-the-riverside` | strings 3-6, frets 0-3 | strings 3-4, frets 0-5 | B4 and C5 are on string 3 frets 4-5, so the piece stays on strings 3-4 and does not need the lower strings. |
| `original-study-1` | strings 4-6, frets 0-3 | strings 4-6, frets 0-3 | No deviation. |

Two T3.1 labels are also narrower than the actual tune: `down-by-the-riverside`
says "one accidental", but the melody has an A-sharp lower neighbour and an
F-natural flat seventh; and the stage-2 target is an "8-bar folk melody", while
the complete New Britain tune is 16 bars. `amazing-grace` uses a 9-bar excerpt
(one-bar anacrusis plus eight bars) so it still reads as an 8-bar melody.

## `greensleeves`

- **Source melody:** traditional English tune, registered in 1580. The setting
  follows the public-domain melody as given in the Wikibooks
  `Songbook/Greensleeves` LilyPond transcription (A minor/Dorian); it is a new
  single-line guitar setting, not an edition copy.
- **Key / meter / tempo:** A minor, 6/8, 60 BPM.
- **Phrase map:** P1 bars 1-3 (one-eighth anacrusis plus two full bars);
  P2 bars 4-5; P3 bars 6-7; P4 bars 8-9. Total 9 bars.
- **Position and range:** written E4-E5 (sounding E3-E4); strings 1-4, frets
  0-3. The single E4 in P2 is string 4 fret 2. Open G4, B4, and E5 carry the
  "open strings" focus.
- **Technique focus:** open strings, steady pulse, 6/8 lilt.
- **Transposition:** none. The tune is written in the guitar's normal octave,
  one octave above sounding pitch.
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
- **Position and range:** written D4-A4 (sounding D3-A3); strings 3-4, frets
  0-4. D4 and E4 are string 4 open and fret 2; F-sharp4 is string 4 fret 4;
  G4 and A4 are string 3 open and fret 2. Every note is on the staff.
- **Technique focus:** stepwise melody, quarter-note pulse, phrase endings.
- **Transposition:** the theme is written in the guitar's first-position octave
  (sounding D3-A3). It is not transposed to another key and no note is
  octave-displaced.
- **Editorial changes:** the theme is complete and unaltered; the two A4 notes
  use the only available fingering.
- **Legal question for T6.3:** confirm the 1824 melody and the chosen edition
  are public domain in the US, UK/EU, and Canada, and that the engraving is
  public domain or newly made.

## `amazing-grace`

- **Source melody:** New Britain (1835), the tune normally sung to "Amazing
  Grace". New single-line guitar setting after public-domain hymnal melodies.
- **Key / meter / tempo:** G major, 3/4, 66 BPM.
- **Phrase map:** P1 bars 1-3 (one-beat anacrusis plus two full bars); P2 bars
  4-5; P3 bars 6-7; P4 bars 8-9. Total 9 bars.
- **Position and range:** written D4-B4 (sounding D3-B3); strings 2-4, frets
  0-3.
- **Technique focus:** triple meter, breath-length phrases, legato changes.
- **Excerpt:** the one-beat anacrusis, the opening four bars, and the final
  four bars of the 16-bar tune. The middle eight bars, including the D5
  climax, are omitted so the piece stays an 8-bar stage-2 reading task and ends
  on the tonic G. The cut is deliberate; the full tune can be restored in a
  later returner arrangement.
- **Transposition:** none. The tune is in the guitar's written octave
  (sounding one octave lower).
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
- **Position and range:** written D4-C5 (sounding D3-C4); strings 2-4, frets
  0-3. D4-F4 sit on string 4, G4-A4 on string 3, and B4-C5 on string 2.
- **Technique focus:** lower-string reading, syncopated eighths, one flat
  seventh plus a chromatic lower neighbour.
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
  `"reviewedBy": "Pending musical review"`.
- No 3-beginner playtest. Decision 0004 carries that human content-QA step
  into T3.8.
- No reference recordings. T3.5 owns the human takes.
- No legal clearance. T6.3 owns the territory-by-territory review, and this
  document is not legal advice.
- No runtime asset loading, pubspec entry, UI, storage, learning, or audio
  change. T2.11/T2.12 wire the content into the app.
- No exercises, lessons, or progress rules for the pieces. Those are later
  content and app work.
