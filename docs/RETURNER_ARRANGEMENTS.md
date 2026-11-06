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
  pieces. Three authentic melodies need string 4 for a few low melody notes:
  Londonderry Air, Spanish Romance, and the Bach Minuet use string 4 for E4
  and/or F#4. These are melody notes, not added bass or accompaniment. The
  deviations are recorded per piece below and in the `authoring.notes` field.
- The reference editions were used to confirm the traditional melody; no
  engraving, fingering, or recording was copied. Several reference collections
  carry Creative Commons terms: the Spanish Romance edition is CC BY-SA 2.5 and
  the Londonderry tunebook is CC BY-NC-SA. Those terms are recorded per piece
  and must be resolved by T6.3. The `license` field alone is not clearance.

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
  used; confirm the chosen reference transcription is public domain, newly
  engraved, or used only as a melodic reference with any applicable attribution
  terms satisfied.

## 2. Londonderry Air

- **File:** `londonderry-air.json`.
- **Source melody:** Traditional Irish air, collected in 1855. The melodic
  reference is the C major "Danny Boy" setting in Paul Hardy's Songs Tunebook
  (tune 0006), transposed up a perfect fifth to G and reduced to the vocal line.
  The tunebook is CC BY-NC-SA. Weatherly's 1913 lyric is not used. The ABC
  transcription is a pitch reference only; our arrangement is a new melody-only
  setting, not a copy of the transcription.
- **Key / time / tempo:** G major, 4/4, 54 BPM.
- **Phrase map:** p1 bars 1-4 (two-beat pickup), p2 bars 5-8, p3 bars 9-10,
  p4 bars 11-13; 13 bars total.
- **Position and range:** p1 and p2 in first position; p3 moves to second
  position; p4 returns to first position. Strings 1-4, frets 0-5. Written range
  E4-G5. The low E4 and F#4 are melody notes on string 4 fret 2 and fret 4,
  not a bass voice.
- **Technique focus:** two hand shifts, sustained tone, and wide leaps. The
  shift up is the B-section lift in p3 (E5 on string 2 fret 5); the shift down
  is the return to the open first string in p4.
- **Pickup rhythm:** the pickup figures keep the source's rest plus three
  eighth notes in p1, p2, and p3.
- **Transposition:** up a perfect fifth from the C major reference to match the
  T3.1 G major metadata. No phrase is transposed by an octave.
- **T6.3 question:** Confirm the traditional melody is public domain in the
  US, UK, EU, and Canada; confirm V1 uses the melody only; confirm no
  copyrighted lyric (including "Danny Boy") is used. The cited Paul Hardy
  tunebook is CC BY-NC-SA, so confirm that our independent melody-only
  arrangement does not copy the transcription and that any attribution,
  non-commercial, and share-alike obligations are satisfied.

## 3. Minuet in G major, BWV Anh. 114

- **File:** `bach-minuet-in-g.json`.
- **Source melody:** Christian Petzold (formerly attributed to J.S. Bach),
  BWV Anh. 114. The melodic reference is the public-domain Mutopia guitar
  edition (`Mutopia-2013/01/06-695`). Only the upper line is used; the
  left-hand bass and any second voice are omitted.
- **Key / time / tempo:** G major, 3/4, 72 BPM.
- **Phrase map:** p1 bars 1-4, p2 bars 5-8, p3 bars 9-12, p4 bars 13-16;
  16 bars total. This is the first 16-bar section of the Minuet.
- **Position and range:** first position, strings 1-4, frets 0-4. Written
  range F#4-G5. String 4 carries F#4 (fret 4); every other note is on strings
  1-3.
- **Technique focus:** sight-reading fluency, 3/4 phrasing, single-line
  reading, and register contrast between the higher opening phrase (G4-G5) and
  the lower answering phrase (F#4-D5).
- **Transposition:** none. The arrangement uses the guitar edition's written
  octave, so the opening falling fifth (D5-G4) and the G5-G4-G5 cadence are
  preserved. The key remains G major.
- **T3.1 metadata note:** the locked planning note says "strings 1-3; frets
  0-4". F#4 is the only note that needs string 4; it uses fret 4. Everything
  else is on strings 1-3 and frets 0-4. The T3.1 file itself is unchanged.
- **T6.3 question:** Confirm the 1725 melody is public domain in the US, UK,
  EU, and Canada; confirm the Petzold attribution; confirm the single-line
  edition is newly engraved or public domain; confirm no copyrighted edition,
  bass line, or second voice is copied.

## 4. Spanish Romance (Romance Anónimo)

- **File:** `spanish-romance.json`.
- **Source melody:** Anonymous, late 19th-century. The melodic reference is the
  upper line of the Mutopia edition (`Mutopia-2006/08/03-795`), which is
  Creative Commons Attribution-ShareAlike 2.5. The arpeggio accompaniment and
  bass line are deliberately omitted; every event is one melody note.
- **Key / time / tempo:** E minor, 3/4, 72 BPM.
- **Phrase map:** p1 bars 1-4, p2 bars 5-8, p3 bars 9-12, p4 bars 13-16;
  16 bars total. This is the 16-bar E-minor A section.
- **Position and range:** first position, strings 1-4, frets 0-4. Written range
  E4-E5. String 4 carries the low E4 (fret 2) and F#4 (fret 4) melody notes;
  there is no bass voice.
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
  (Rubira, Sor, and others); confirm our single-line reduction is original. The
  cited Mutopia edition is CC BY-SA 2.5, so confirm that our independent
  reduction does not copy the transcription and that any attribution and
  share-alike obligations are satisfied. Confirm no copyrighted arrangement or
  recording is copied.

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
3. T6.3 answers the legal questions above, including the CC BY-SA 2.5 and
   CC BY-NC-SA reference-edition obligations. The `license` field alone is not
   clearance.
4. Re-run `dart run tool/content/validate_piece.dart <file> --strict` and
   `flutter test test/returner_pieces_test.dart` after any note change.
