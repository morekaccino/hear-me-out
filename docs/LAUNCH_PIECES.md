# Launch pieces (T3.1)

**Status:** Metadata locked; Foundation (T3.3) and Returner (T3.4) arrangements complete; not recorded, musically reviewed, or legally cleared.
**Owner:** T3.1. **Legal review:** T6.3. **Notes:** T3.3/T3.4.
**Reference recordings:** T3.5.
**Source of truth:** [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md)
section 6.2, with stage outcomes from section 6.1.

This is the content spec for the 10 V1 launch pieces. It records the approved
list and maps each piece to the stage it supports. It is **not** evidence of
legal clearance: no arrangement, reference recording, or territory-by-territory
license review exists yet.

## Decision

V1 ships 10 strictly monophonic pieces, four phrases each, in standard tuning
with capo 0:

- **Foundation (stages 1-3):** five pieces for learners starting in first
  position.
- **Returner (stages 5, 9-10):** five pieces for learners who can already read
  first position and need shifts, fluency, and a full performance.

Every piece uses a single melody line. There are no bass lines, chords, double
stops, or second voices. Tempos stay in the V1 50-90 BPM range.

## The 10 pieces

| ID | Piece | Composer / source | Tier | Stage | Tempo (BPM) | Phrases | Range and position | Technique focus | Intended license | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| `greensleeves` | Greensleeves | Traditional English (16th century) | Foundation | 1 | 60 | 4 | First position; strings 1-3; frets 0-3 | Open strings, steady pulse, 6/8 lilt | public-domain | [Wikipedia](<https://en.wikipedia.org/wiki/Greensleeves>) |
| `ode-to-joy` | Ode to Joy | Ludwig van Beethoven | Foundation | 2 | 72 | 4 | First position; strings 1-2; frets 0-5 | Stepwise melody, quarter-note pulse, phrase endings | public-domain | [IMSLP](<https://imslp.org/wiki/Symphony_No.9,_Op.125_(Beethoven,_Ludwig_van)>) |
| `amazing-grace` | Amazing Grace (New Britain) | Traditional American (words: John Newton, 1779; tune: New Britain, 1835) | Foundation | 2 | 66 | 4 | First position; strings 1-3; frets 0-3 | Triple meter, breath-length phrases, legato changes | public-domain | [IMSLP](<https://imslp.org/wiki/Amazing_Grace_(Anonymous)>) |
| `down-by-the-riverside` | Down by the Riverside | Traditional African-American spiritual (19th century; author unknown) | Foundation | 3 | 76 | 4 | First position; strings 3-4; frets 0-5 | Middle strings, syncopated eighths, two accidentals | public-domain | [Wikipedia](<https://en.wikipedia.org/wiki/Down_by_the_Riverside>) |
| `original-study-1` | Original Monophonic Study No. 1 | Hear Me Out (original) | Foundation | 3 | 60 | 4 | First position; strings 4-6; frets 0-3 | Lower-string reading, accidentals, 12-bar form | original | Original work |
| `scarborough-fair` | Scarborough Fair | Traditional English ballad (Child Ballad 2) | Returner | 5 | 58 | 4 | First position with two shifts; strings 1-3; frets 0-5 | Two position shifts with guide fingers; 3/4 phrasing | public-domain | [Wikipedia](<https://en.wikipedia.org/wiki/Scarborough_Fair_(ballad)>) |
| `londonderry-air` | Londonderry Air | Traditional Irish (collected 1855; lyrics "Danny Boy" by Frederic Weatherly, 1913) | Returner | 5 | 54 | 4 | First position with two shifts; strings 1-3; frets 0-5 | Two position shifts, sustained tone, wide leaps | public-domain | [Wikipedia](<https://en.wikipedia.org/wiki/Londonderry_Air>) |
| `bach-minuet-in-g` | Minuet in G major, BWV Anh. 114 | Christian Petzold (formerly attributed to J.S. Bach) | Returner | 9 | 72 | 4 | First position; strings 1-3; frets 0-4 | Sight-reading fluency; 3/4 phrasing; single-line reading | public-domain | [IMSLP](<https://imslp.org/wiki/Notebook_for_Anna_Magdalena_Bach,_BWV_Anh.113-132_(Bach,_Johann_Sebastian)>) |
| `spanish-romance` | Spanish Romance (Romance Anónimo) | Anonymous (attribution disputed; sometimes attributed to Antonio Rubira or Fernando Sor) | Returner | 9 | 72 | 4 | First position; strings 1-3; frets 0-4 | Sight-reading fluency; melody across strings 1-2; steady pulse | public-domain | [Wikipedia](<https://en.wikipedia.org/wiki/Romance_(guitar_piece)>) |
| `original-study-2` | Original Monophonic Study No. 2 | Hear Me Out (original) | Returner | 10 | 66 | 4 | First and second position; strings 1-4; frets 0-5 | Full-piece consolidation, dynamic shaping, 1-minute performance | original | Original work |

Notes:

- The plan calls the eighth piece "Bach Minuet in G". The work is now generally
  attributed to Christian Petzold, so the metadata records that attribution
  while keeping the familiar title.
- "Londonderry Air" is the melody. "Danny Boy" is the later lyric; V1 does not
  use the lyric.
- The intended license values are the T2.1 wire values: `public-domain` and
  `original`. They are not a legal conclusion.
- IMSLP page identifiers are stored in the Dart metadata for the three
  IMSLP-backed sources: `Symphony_No.9,_Op.125_(Beethoven,_Ludwig_van)`,
  `Amazing_Grace_(Anonymous)`, and
  `Notebook_for_Anna_Magdalena_Bach,_BWV_Anh.113-132_(Bach,_Johann_Sebastian)`.
  The other public-domain pieces link to reference pages; their engraving
  source is still to be selected.

## Stage outcomes

The outcomes come from plan section 6.1. They describe what the stage trains,
not a claim that these arrangements already pass an assessment.

| Stage | Plan 6.1 outcome | Pieces |
|---|---|---|
| 1 | Play a 4-bar monophonic study at 60 BPM | `greensleeves` |
| 2 | Play an 8-bar folk melody | `ode-to-joy`, `amazing-grace` |
| 3 | Play a 12-bar monophonic piece | `down-by-the-riverside`, `original-study-1` |
| 5 | Play a 12-bar study with two shifts | `scarborough-fair`, `londonderry-air` |
| 9 | Read a 4-bar etude at sight at 70 BPM | `bach-minuet-in-g`, `spanish-romance` |
| 10 | Perform a 1-minute monophonic piece | `original-study-2` |

Stage 12 is a separate performance/recording checkpoint that uses any passed
piece. Stages 4, 6, 7, and 8 are Phase 2 or self/teacher-reviewed and are not
placement targets for these pieces.

## Why each piece is monophonic-safe

"Monophonic-safe" means the V1 reduction is one sounding note at a time. It
does not mean the historical source had no accompaniment; the arranger must
leave the accompaniment out.

| Piece | Why the V1 reduction is monophonic-safe |
|---|---|
| Greensleeves | Melody only. The lute ground, bass, and any chordal accompaniment are not transcribed. |
| Ode to Joy | Theme line from the fourth movement only. No orchestral accompaniment. |
| Amazing Grace | New Britain melody only. No three-part chorus or keyboard harmony. |
| Down by the Riverside | Single vocal line. No choir response, piano, or rhythm section. |
| Original study 1 | Composed as one line. No accompaniment exists. |
| Scarborough Fair | Single ballad melody. No drone, countermelody, or Simon & Garfunkel countermelody. |
| Londonderry Air | Single melody. No piano part or vocal harmony. |
| Bach Minuet | Top line only. No left-hand bass, chords, or second voice. |
| Spanish Romance | Melody line only. The original arpeggio accompaniment is not transcribed. |
| Original study 2 | Composed as one line. No accompaniment exists. |

The score validator still enforces one sounding note at a time, no overlapping
durations, and no chords or double stops. Metadata alone is not enough.

## Legal review questions (T6.3)

Territories assessed in V1: **United States, United Kingdom, European Union,
Canada**. Other territories are out of scope until T6.3 extends the review.
"Intended status" is a content-planning label, not legal clearance.

| ID | Intended status | Territories to confirm | What is original in our version | What T6.3 must confirm |
|---|---|---|---|---|
| `greensleeves` | public-domain (melody) | US, UK, EU, Canada | New single-line melody setting and engraving | That the 16th-century melody is public domain in each territory; that the chosen source edition is public domain or newly engraved; that no copyrighted harmonic setting or arrangement is copied. |
| `ode-to-joy` | public-domain | US, UK, EU, Canada | New single-line reduction and engraving | That Beethoven's 1824 melody is public domain in each territory; that the chosen edition is public domain or newly engraved. |
| `amazing-grace` | public-domain (New Britain melody) | US, UK, EU, Canada | New single-line melody edition; Newton's text is not used | That the New Britain melody is public domain in each territory; that the chosen melody edition is public domain or newly engraved; that no hymnal harmonization is copied. |
| `down-by-the-riverside` | public-domain (traditional spiritual) | US, UK, EU, Canada | New single-line transcription | That the spiritual is public domain in each territory; the earliest printed source; that the chosen edition is not a copyrighted arrangement. |
| `original-study-1` | original | All territories | Entire work | That the study is original, quotes no external melody, and that authorship and assignment are documented. |
| `scarborough-fair` | public-domain (traditional melody) | US, UK, EU, Canada | New single-line arrangement | That the traditional melody is public domain in each territory; that our arrangement is original; that the Simon & Garfunkel arrangement and its countermelody are not used. |
| `londonderry-air` | public-domain (melody only) | US, UK, EU, Canada | New single-line arrangement; Weatherly's lyric is not used | That the traditional melody is public domain in each territory; that only the melody is used; that no copyrighted lyric or arrangement is copied. |
| `bach-minuet-in-g` | public-domain | US, UK, EU, Canada | New single-line extraction and engraving | That the 1725 melody is public domain in each territory; the Petzold attribution; that no copyrighted edition or bass line is copied. |
| `spanish-romance` | public-domain (anonymous melody) | US, UK, EU, Canada | New single-line melody reduction | That the anonymous 19th-century melody is public domain in each territory; the authorship dispute; that our reduction is original; that no copyrighted edition, arrangement, or recording is copied. |
| `original-study-2` | original | All territories | Entire work | That the study is original, quotes no external melody, and that authorship and assignment are documented. |

Open legal questions that apply to the whole list:

- Which source edition or manuscript will be engraved for each public-domain
  piece?
- Is the reduction original enough to claim a new arrangement, or does it copy
  a protected edition's editorial choices such as fingerings, dynamics, or
  cadenzas?
- Do any moral-rights or performers'-rights rules apply in a target territory?
- Do the two original studies need a contributor agreement before launch?

## Out of scope

- Sor, Giuliani, and Carcassi two-voice studies. Two-voice texture is Phase 2.
- Pop songs and copyrighted arrangements, including the Simon & Garfunkel
  arrangement of Scarborough Fair.
- Exam-board names, syllabi, or grade lists. The V1 stages are internal and are
  not exam grades.
- Chords, bass lines, double stops, and any second voice.
- Audio assets and human reference takes. T3.3/T3.4 arranged the pieces.
  T3.5 records the 20 human reference takes (target and slow tempo). T6.4 is
  the paywall and day-7 recap, not the recording owner.
- Legal clearance. T6.3 owns it.
- More than 10 pieces. The monthly content calendar is separate from this
  launch decision.

## Not yet validated

- The Foundation and Returner JSON arrangements exist and pass the T3.2 validator; the human musical review and 3-beginner playtest are T3.8.
- No reference recordings exist at target or slow tempo. T3.5 owns the 20
  human reference takes (target and slow tempo) and must not use copyrighted
  recordings.
- No legal clearance exists. T6.3 must answer the questions above.
- The tempos, ranges, and shift counts are planning targets, not
  human-validated arrangements.
- The mic has not been tested on these pieces. The assessment spike remains the
  gate for the phrase loop.
- The stage map is a placement intention, not evidence that a learner who plays
  the piece has met the stage outcome.

## Machine-readable metadata

- Code: `flutter_app/lib/content/pieces/launch_pieces.dart`
- Tests: `flutter_app/test/launch_pieces_test.dart`
- The list exposes `launchPieces`, `launchPieceById(String id)`,
  `launchPiecesForTier(LaunchTier tier)`, and the `v1StageOutcomes` map.
- Each entry uses the T2.1 `Piece` model with standard tuning, capo 0, and a
  `public-domain` or `original` license. The note arrangements live under
  `flutter_app/assets/content/pieces/foundation/` and
  `flutter_app/assets/content/pieces/returner/`.

## References

- [`TRANSFORMATION_PLAN_FINAL.md`](TRANSFORMATION_PLAN_FINAL.md), sections 6.1
  and 6.2.
- [`ARCHITECTURE.md`](ARCHITECTURE.md), "Score and media models (Phase 1)".
- `flutter_app/lib/core/music/piece.dart` for the `Piece`, `Tuning`,
  `TimeSignature`, and `LicenseStatus` models.
