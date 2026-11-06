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

All five files pass with **0 errors and 0 warnings**. The test also parses
T3.1's `rangeAndPosition` and checks every note against it, so a future string
deviation cannot hide behind the per-piece envelope. No runtime loader is added
in this ticket: T2.11/T2.12 wire content into the app, and the assets are not
listed in `pubspec.yaml` yet.

## Summary

| Piece | Key | Meter | Tempo | Bars | Phrase bars | Written range | Strings / frets | Stage |
|---|---|---|---:|---:|---|---|---|---:|
| `greensleeves` | A minor | 6/8 | 60 | 9 | 3 + 2 + 2 + 2 | E4-E5 | 1-4 / 0-3 | 1 |
| `ode-to-joy` | D major | 4/4 | 72 | 8 | 2 + 2 + 2 + 2 | D4-A4 | 3-4 / 0-4 | 2 |
| `amazing-grace` | G major | 3/4 | 66 | 9 | 3 + 2 + 2 + 2 | D4-B4 | 2-4 / 0-2 | 2 |
| `down-by-the-riverside` | G major | 4/4 | 76 | 12 | 4 + 4 + 2 + 2 | D4-C5 | 2-4 / 0-3 | 3 |
| `original-study-1` | A minor | 4/4 | 60 | 12 | 3 + 3 + 3 + 3 | E3-F4 | 4-6 / 0-3 | 3 |

"Written range" is staff pitch; the guitar sounds one octave lower. All notes
are inside the V1 written range E3-E6 and the sounding range E2-E5.

## Stage envelope

Decision 0005 records the actual first-position envelope for each piece and
keeps T3.1's `rangeAndPosition`, `docs/LAUNCH_PIECES.md`, and the tests in
sync. Stage labels describe the primary teaching focus; they are not a hard
string restriction. The monophonic and first-position rules are unchanged.

| Piece | T3.1 original span | Recorded strings | T3.1 original frets | Recorded max fret | Reason |
|---|---|---|---|---|---|
| `greensleeves` | 1-3 | 1-4 | 0-3 | 3 | E4 in P2 is string 4 fret 2. |
| `ode-to-joy` | 1-3 | 3-4 | 0-3 | 4 | D4/E4 need string 4; F#4 needs fret 4. |
| `amazing-grace` | 1-3 | 2-4 | 0-3 | 2 | The melody starts on D4/E4, which need string 4. |
| `down-by-the-riverside` | 3-6 | 2-4 | 0-3 | 3 | B4/C5 need string 2; strings 5-6 are not used. |
| `original-study-1` | 4-6 | 4-6 | 0-3 | 3 | Matches T3.1 exactly. |

## `greensleeves`

- **Source melody:** traditional English tune, registered in 1580. The setting
  follows the public-domain melody as given in the Wikibooks
  `Songbook/Greensleeves` LilyPond transcription (A minor/Dorian); it is a new
  single-line guitar setting, not an edition copy.
- **Key / meter / tempo:** A minor, 6/8, 60 BPM.
- **Phrase map:** P1 bars 1-3 (one-eighth anacrusis plus two full bars);
  P2 bars 4-5; P3 bars 6-7; P4 bars 8-9. Total 9 bars.
- **Position and range:** written E4-E5 (sounding E3-E4); strings 1-4, frets
  0-3. Open G4, B4, and E5 carry the "open strings" focus; the low E4 in P2 is
  string 4 fret 2 (Decision 0005).
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
  0-4. D4 and E4 sit on string 4; F#4 needs fret 4. The melody stays in the
  guitar's natural first-position octave.
- **Technique focus:** stepwise melody, quarter-note pulse, phrase endings.
- **Transposition:** none; the theme is in D major at the written first-position
  octave. Decision 0005 records the string-4 use.
- **Editorial changes:** the theme is complete and unaltered.
- **Legal question for T6.3:** confirm the 1824 melody and the chosen edition
  are public domain in the US, UK/EU, and Canada, and that the engraving is
  public domain or newly made.

## `amazing-grace`

- **Source melody:** New Britain (1835), the tune normally sung to "Amazing
  Grace". New single-line guitar setting after public-domain hymnal melodies.
- **Key / meter / tempo:** G major, 3/4, 66 BPM.
- **Phrase map:** P1 bars 1-3 (one-bar anacrusis plus two bars); P2 bars 4-5;
  P3 bars 6-7; P4 bars 8-9. Total 9 bars.
- **Position and range:** written D4-B4 (sounding D3-B3); strings 2-4, frets
  0-2. D4/E4 sit on string 4; G4-A4 on string 3; B4 on string 2. The melody
  stays in the natural first-position octave.
- **Technique focus:** triple meter, breath-length phrases, legato changes.
- **Excerpt:** the opening four bars and the final four bars of the 16-bar
  tune, with the one-bar anacrusis; it reads as an 8-bar melody plus pickup.
- **Transposition:** none; the tune stays in G major. Decision 0005 records the
  string-4 use for D4/E4.
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
  0-3. D4-F4 sit on string 4 (frets 0-3); G4-B4 on string 3; C5 is string 2
  fret 1. The melody never goes below D4, so strings 5-6 are not used.
- **Technique focus:** middle-string reading (string 4 for the lower melody
  notes, strings 2-3 for the upper ones), syncopated eighths, and two chromatic
  notes (A-sharp lower neighbour and F-natural flat seventh). The earlier
  "lower-strings" tag was wrong because most notes sit on strings 2-3; the
  arrangement stays on strings 2-4 and the skills name middle strings and
  string crossing.
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
