# Returner arrangements (T3.4)

**Status:** Arrangements authored and machine-validated. **Not** musically
reviewed, **not** recorded, and **not** legally cleared.

- **Owner:** T3.4.
- **Musical review:** pending.
- **Human reference recordings:** T3.5.
- **Legal review:** T6.3.
- **Metadata and stage map:** [`LAUNCH_PIECES.md`](LAUNCH_PIECES.md) (T3.1).
- **Authoring format:** [`CONTENT_AUTHORING.md`](CONTENT_AUTHORING.md) (T3.2).

These are **arrangements pending musical review and human reference
recordings**. The `public-domain` and `original` values in the JSON are
planning labels from T3.1, not legal conclusions. Do not describe any piece as
cleared for launch until T6.3 has reviewed it and T3.5 has recorded the human
reference takes.

The five files live in
`flutter_app/assets/content/pieces/returner/` and are checked by
`flutter_app/test/returner_pieces_test.dart`. Every file passes the T3.2
authoring validator with zero errors and zero warnings.

## Shared decisions

- All five pieces are strictly monophonic. There are no chords, double stops,
  overlapping notes, bass lines, or arpeggio voices.
- Every note has an explicit written pitch, sounding MIDI value, string, and
  fret. `soundingMidi` is always written MIDI minus 12.
- Standard tuning, capo 0. Tempos stay inside the V1 50-90 BPM range.
- Each piece has four phrases of two to four bars. The phrase ids are
  `<piece-id>-p1` through `-p4`.
- The written range stays inside E3-E6. No arrangement uses a fret above 5.
- The T3.1 planning note says "strings 1-3" for the stage-5 and stage-9
  pieces. Two authentic melodies need a lower string for a few melody notes:
  Londonderry Air and Spanish Romance use string 4 for E4/F#4, and the Bach
  Minuet needs strings 2-5 because its two phrases sit in different registers.
  These are melody notes, not added bass or accompaniment. The deviations are
  recorded per piece below and in the `authoring.notes` field.
- No arrangement copies a copyrighted edition, engraving, fingering, or
  recording. Source editions were used only to confirm the traditional melody.

## 1. Scarborough Fair

- **File:** `scarborough-fair.json`.
- **Source melody:** Traditional English ballad, Child Ballad 2. The melodic
  reference is the traditional E dorian setting in The Session ABC collection
  (`https://thesession.org/tunes/7522`), transposed up a perfect fourth to A
  and reduced to one line. No Simon & Garfunkel countermelody or arrangement is
  used.
- **Key / time / tempo:** A minor (with the dorian F# inflection), 3/4, 58 BPM.
- **Phrase map:** p1 bars 1-4, p2 bars 5-8, p3 bars 9-10, p4 bars 11-12;
  12 bars total.
- **Position and range:** p1 and p4 in first position; p2 and p3 in second
  position. Strings 1-3, frets 0-5. Written range A4-A5.
- **Technique focus:** two hand shifts with guide fingers and 3/4 phrasing.
  The shift up is at the start of p2 (A4 to E5 on string 2 fret 5); the shift
  down is at the start of p4 (A5 back to the open first string).
- **Transposition:** up a perfect fourth from the E dorian reference. The
  raised sixth (F#) is written as an accidental and is the traditional dorian
  colour, not a key change.
- **T6.3 question:** Confirm the traditional melody is public domain in the
  US, UK, EU, and Canada; confirm our single-line arrangement is original;
  confirm no copyrighted Simon & Garfunkel arrangement or countermelody is
  used; confirm the chosen reference edition/transcription is public domain or
  newly engraved.

## 2. Londonderry Air

- **File:** `londonderry-air.json`.
- **Source melody:** Traditional Irish air, collected in 1855. The melodic
  reference is the F major "Danny Boy" setting in Paul Hardy's Songs Tunebook,
  transposed up a whole tone to G and reduced to the vocal line. Weatherly's
  1913 lyric is not used. The ABC file is a pitch reference only; no
  copyrighted arrangement or lyric is copied.
- **Key / time / tempo:** G major, 4/4, 54 BPM.
- **Phrase map:** p1 bars 1-4 (two-beat pickup), p2 bars 5-8, p3 bars 9-10,
  p4 bars 11-13; 13 bars total.
- **Position and range:** p1 and p2 in first position; p3 moves to second
  position; p4 returns to first position. Strings 1-4, frets 0-5. Written range
  E4-G5. The low E4 and F#4 are melody notes on string 4 (open and fret 4),
  not a bass voice.
- **Technique focus:** two hand shifts, sustained tone, and wide leaps. The
  shift up is the B-section lift in p3 (E5 on string 2 fret 5); the shift down
  is the return to the open first string in p4.
- **Transposition:** up a whole tone from the F major reference to match the
  T3.1 G major metadata. No phrase is transposed by an octave.
- **T6.3 question:** Confirm the traditional melody is public domain in the
  US, UK, EU, and Canada; confirm V1 uses the melody only; confirm no
  copyrighted lyric (including "Danny Boy") or copyrighted arrangement is
  used; confirm the chosen reference edition is public domain or newly
  engraved.

## 3. Minuet in G major, BWV Anh. 114

- **File:** `bach-minuet-in-g.json`.
- **Source melody:** Christian Petzold (formerly attributed to J.S. Bach),
  BWV Anh. 114. The melodic reference is the public-domain Mutopia guitar
  edition (`Mutopia-2013/01/06-695`). Only the upper line is used; the
  left-hand bass and any second voice are omitted.
- **Key / time / tempo:** G major, 3/4, 72 BPM.
- **Phrase map:** p1 bars 1-4, p2 bars 5-8, p3 bars 9-12, p4 bars 13-16;
  16 bars total. This is the first 16-bar section of the Minuet.
- **Position and range:** first position, strings 2-5, frets 0-4. Written
  range C4-D5.
- **Technique focus:** sight-reading fluency, 3/4 phrasing, single-line
  reading, and register contrast between the opening and answering phrases.
- **Transposition:** the opening phrase (bars 1-4 and its repeat) is transposed
  down one octave because its written B5/C6 notes lie above the V1
  first-position range. The answering phrase (bars 5-8 and its repeat) already
  fits and stays at its written octave. The key remains G major.
- **T3.1 metadata note:** the locked planning note says "strings 1-3; frets
  0-4". The authentic two-register melody cannot be played entirely on strings
  1-3 in first position without changing key. This arrangement keeps the key
  and the first-position requirement, and uses strings 2-5 for the melody.
  T6.3 and the musical reviewer should confirm this is the preferred
  resolution; the T3.1 file itself is unchanged.
- **T6.3 question:** Confirm the 1725 melody is public domain in the US, UK,
  EU, and Canada; confirm the Petzold attribution; confirm the single-line
  edition is newly engraved or public domain; confirm no copyrighted edition,
  bass line, or second voice is copied.

## 4. Spanish Romance (Romance Anónimo)

- **File:** `spanish-romance.json`.
- **Source melody:** Anonymous, late 19th-century. The melodic reference is the
  upper line of the Mutopia edition (`Mutopia-2006/08/03-795`). The arpeggio
  accompaniment and bass line are deliberately omitted; every event is one
  melody note.
- **Key / time / tempo:** E minor, 3/4, 72 BPM.
- **Phrase map:** p1 bars 1-4, p2 bars 5-8, p3 bars 9-12, p4 bars 13-16;
  16 bars total. This is the 16-bar E-minor A section.
- **Position and range:** first position, strings 1-4, frets 0-4. Written range
  E4-E5. String 4 carries the low E4 and F#4 melody notes; there is no bass
  voice.
- **Technique focus:** melody across strings 1-2, steady pulse, first-position
  reading, and a single-line reduction of a texture that is normally
  accompanied by arpeggios.
- **Transposition:** down one octave from the engraved guitar octave so the
  upper line sits in first position. The key remains E minor.
- **T3.1 metadata note:** the planning note says "strings 1-3". E4 and F#4 are
  below the open third string, so those melody notes use string 4. Frets stay
  within 0-4.
- **T6.3 question:** Confirm the anonymous 19th-century melody is public
  domain in the US, UK, EU, and Canada; address the disputed authorship
  (Rubira, Sor, and others); confirm our single-line reduction is original;
  confirm no copyrighted edition, arrangement, or recording is copied.

## 5. Original Monophonic Study No. 2

- **File:** `original-study-2.json`.
- **Source:** Original work written for the V1 Returner stage-10 slot. No
  external melody is quoted.
- **Key / time / tempo:** D major, 4/4, 66 BPM.
- **Phrase map:** p1 bars 1-4, p2 bars 5-8, p3 bars 9-12, p4 bars 13-16;
  16 bars total. At 66 BPM the study lasts about one minute, matching the
  stage-10 performance target.
- **Position and range:** p1 in first position; p2 and p3 in second position;
  p4 returns to first position. Strings 1-4, frets 0-5. Written range D4-G5.
- **Technique focus:** full-piece consolidation, dynamic shaping, a clear
  first-to-second-position shift, and a one-minute monophonic performance.
  The shift up uses E5 on string 2 fret 5; the shift down returns to the open
  first string and first-position shapes.
- **Transposition:** none. This is an original study, not an arrangement.
- **T6.3 question:** Confirm the study is an original work with no quoted
  external melody, and that authorship and assignment are documented for all
  territories.

## Review checklist

Before this content ships:

1. A musical reviewer plays each file from the JSON or an engraving and signs
   off the melody, rhythm, fingering, and position plan. Record the reviewer
   and date in `authoring.reviewedBy`.
2. T3.5 records the human reference takes at target and slow tempo.
3. T6.3 answers the legal questions above. The `license` field alone is not
   clearance.
4. Re-run `dart run tool/content/validate_piece.dart <file> --strict` and
   `flutter test test/returner_pieces_test.dart` after any note change.
