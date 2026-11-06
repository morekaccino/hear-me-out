import '../../core/music/piece.dart';

/// The two V1 repertoire tiers.
enum LaunchTier {
  foundation('foundation'),
  returner('returner');

  const LaunchTier(this.wireName);

  /// Stable value for content QA and future score metadata.
  final String wireName;
}

/// The stage outcomes from plan section 6.1 that launch pieces support.
///
/// Stage 12 (record a two-minute program) is a separate checkpoint and uses
/// any passed piece, so it has no fixed launch-piece row.
const Map<int, String> v1StageOutcomes = <int, String>{
  1: 'Play a 4-bar monophonic study at 60 BPM',
  2: 'Play an 8-bar folk melody',
  3: 'Play a 12-bar monophonic piece',
  5: 'Play a 12-bar study with two shifts',
  9: 'Read a 4-bar etude at sight at 70 BPM',
  10: 'Perform a 1-minute monophonic piece',
};

/// Metadata for one locked V1 launch piece.
///
/// This is a content spec, not an arrangement. T3.3/T3.4 add the notes and
/// T6.3 owns legal clearance. See `docs/LAUNCH_PIECES.md`.
class LaunchPiece {
  const LaunchPiece({
    required this.piece,
    required this.tier,
    required this.v1Stage,
    required this.phraseCount,
    required this.targetTempoBpm,
    required this.techniqueFocus,
    required this.licenseQuestion,
    required this.rangeAndPosition,
    this.texture = 'monophonic',
    this.imslpId,
  });

  final Piece piece;
  final LaunchTier tier;

  /// One of 1, 2, 3, 5, 9, or 10; see [v1StageOutcomes].
  final int v1Stage;

  /// V1 launch pieces always have four phrases.
  final int phraseCount;

  /// Target performance tempo, inside the V1 50-90 BPM range.
  final int targetTempoBpm;

  /// The main skill the arrangement should exercise.
  final String techniqueFocus;

  /// The question T6.3 must answer before this piece can ship.
  final String licenseQuestion;

  /// Intended position and fret range. Notes are added by T3.3/T3.4.
  final String rangeAndPosition;

  /// V1 is strictly monophonic. Recorded so later content cannot silently
  /// reintroduce a second voice.
  final String texture;

  /// IMSLP page identifier (the part after `/wiki/`), when one exists.
  final String? imslpId;

  /// Reference source for the melody. Mirrors [Piece.sourceUrl] so the two
  /// records cannot drift.
  String? get sourceUrl => piece.sourceUrl;

  /// The stage outcome this piece supports.
  String get stageOutcome => v1StageOutcomes[v1Stage] ?? 'Unknown stage';
}

/// The locked V1 launch list: 5 Foundation and 5 Returner pieces.
///
/// The list is final rather than const because [Tuning.standard] is a final
/// model value. Every entry uses that shared tuning so it cannot drift.
final launchPieces = List<LaunchPiece>.unmodifiable(<LaunchPiece>[
  LaunchPiece(
    piece: _piece(
      id: 'greensleeves',
      title: 'Greensleeves',
      composer: 'Traditional English (16th century)',
      license: 'public-domain',
      timeSignature: const TimeSignature(6, 8),
      key: 'A minor',
      sourceUrl: 'https://en.wikipedia.org/wiki/Greensleeves',
    ),
    tier: LaunchTier.foundation,
    v1Stage: 1,
    phraseCount: 4,
    targetTempoBpm: 60,
    techniqueFocus: 'Open strings, steady pulse, 6/8 lilt',
    rangeAndPosition: 'First position; strings 1-3; frets 0-3',
    licenseQuestion:
        'Confirm the 16th-century melody and the chosen edition are '
        'public domain in the US, UK/EU, and Canada; confirm the edition '
        'is not a copyrighted arrangement.',
  ),
  LaunchPiece(
    piece: _piece(
      id: 'ode-to-joy',
      title: 'Ode to Joy',
      composer: 'Ludwig van Beethoven',
      license: 'public-domain',
      timeSignature: const TimeSignature(4, 4),
      key: 'D major',
      sourceUrl: 'https://imslp.org/wiki/Symphony_No.9,_Op.125_(Beethoven,_Ludwig_van)',
    ),
    tier: LaunchTier.foundation,
    v1Stage: 2,
    phraseCount: 4,
    targetTempoBpm: 72,
    techniqueFocus: 'Stepwise melody, quarter-note pulse, phrase endings',
    rangeAndPosition: 'First position; strings 1-2; frets 0-5',
    imslpId: 'Symphony_No.9,_Op.125_(Beethoven,_Ludwig_van)',
    licenseQuestion:
        'Confirm the 1824 melody and the chosen edition are public '
        'domain in the US, UK/EU, and Canada; confirm the engraving is '
        'public domain or newly made.',
  ),
  LaunchPiece(
    piece: _piece(
      id: 'amazing-grace',
      title: 'Amazing Grace (New Britain)',
      composer:
          'Traditional American (words: John Newton, 1779; tune: New '
          'Britain, 1835)',
      license: 'public-domain',
      timeSignature: const TimeSignature(3, 4),
      key: 'G major',
      sourceUrl: 'https://imslp.org/wiki/Amazing_Grace_(Anonymous)',
    ),
    tier: LaunchTier.foundation,
    v1Stage: 2,
    phraseCount: 4,
    targetTempoBpm: 66,
    techniqueFocus: 'Triple meter, breath-length phrases, legato changes',
    rangeAndPosition: 'First position; strings 1-3; frets 0-3',
    imslpId: 'Amazing_Grace_(Anonymous)',
    licenseQuestion:
        'Confirm the New Britain melody is public domain in the US, '
        'UK/EU, and Canada; confirm the chosen melody edition is public '
        'domain or newly engraved, with no copied harmonization.',
  ),
  LaunchPiece(
    piece: _piece(
      id: 'down-by-the-riverside',
      title: 'Down by the Riverside',
      composer:
          'Traditional African-American spiritual (19th century; author '
          'unknown)',
      license: 'public-domain',
      timeSignature: const TimeSignature(4, 4),
      key: 'G major',
      sourceUrl: 'https://en.wikipedia.org/wiki/Down_by_the_Riverside',
    ),
    tier: LaunchTier.foundation,
    v1Stage: 3,
    phraseCount: 4,
    targetTempoBpm: 76,
    techniqueFocus: 'Middle strings, syncopated eighths, two accidentals',
    rangeAndPosition: 'First position; strings 3-4; frets 0-5',
    licenseQuestion:
        'Confirm the traditional spiritual is public domain in the US, '
        'UK/EU, and Canada; identify the earliest printed source and '
        'confirm the chosen edition is not a copyrighted arrangement.',
  ),
  LaunchPiece(
    piece: _piece(
      id: 'original-study-1',
      title: 'Original Monophonic Study No. 1',
      composer: 'Hear Me Out (original)',
      license: 'original',
      timeSignature: const TimeSignature(4, 4),
      key: 'A minor',
    ),
    tier: LaunchTier.foundation,
    v1Stage: 3,
    phraseCount: 4,
    targetTempoBpm: 60,
    techniqueFocus: 'Lower-string reading, accidentals, 12-bar form',
    rangeAndPosition: 'First position; strings 4-6; frets 0-3',
    licenseQuestion:
        'Confirm the study is an original work with no quoted external '
        'melody, and that authorship and assignment are documented for '
        'all territories.',
  ),
  LaunchPiece(
    piece: _piece(
      id: 'scarborough-fair',
      title: 'Scarborough Fair',
      composer: 'Traditional English ballad (Child Ballad 2)',
      license: 'public-domain',
      timeSignature: const TimeSignature(3, 4),
      key: 'A minor',
      sourceUrl: 'https://en.wikipedia.org/wiki/Scarborough_Fair_(ballad)',
    ),
    tier: LaunchTier.returner,
    v1Stage: 5,
    phraseCount: 4,
    targetTempoBpm: 58,
    techniqueFocus: 'Two position shifts with guide fingers; 3/4 phrasing',
    rangeAndPosition: 'First position with two shifts; strings 1-3; frets 0-5',
    licenseQuestion:
        'Confirm the traditional melody is public domain in the US, '
        'UK/EU, and Canada; confirm the arrangement is original and does '
        'not use the copyrighted Simon & Garfunkel arrangement.',
  ),
  LaunchPiece(
    piece: _piece(
      id: 'londonderry-air',
      title: 'Londonderry Air',
      composer:
          'Traditional Irish (collected 1855; lyrics "Danny Boy" by '
          'Frederic Weatherly, 1913)',
      license: 'public-domain',
      timeSignature: const TimeSignature(4, 4),
      key: 'G major',
      sourceUrl: 'https://en.wikipedia.org/wiki/Londonderry_Air',
    ),
    tier: LaunchTier.returner,
    v1Stage: 5,
    phraseCount: 4,
    targetTempoBpm: 54,
    techniqueFocus: 'Two position shifts, sustained tone, wide leaps',
    rangeAndPosition: 'First position with two shifts; strings 1-3; frets 0-5',
    licenseQuestion:
        'Confirm the traditional melody is public domain in the US, '
        'UK/EU, and Canada; V1 uses the melody only; confirm no '
        'copyrighted lyric or arrangement is used.',
  ),
  LaunchPiece(
    piece: _piece(
      id: 'bach-minuet-in-g',
      title: 'Minuet in G major, BWV Anh. 114',
      composer: 'Christian Petzold (formerly attributed to J.S. Bach)',
      license: 'public-domain',
      timeSignature: const TimeSignature(3, 4),
      key: 'G major',
      sourceUrl: 'https://imslp.org/wiki/Notebook_for_Anna_Magdalena_Bach,_BWV_Anh.113-132_(Bach,_Johann_Sebastian)',
    ),
    tier: LaunchTier.returner,
    v1Stage: 9,
    phraseCount: 4,
    targetTempoBpm: 72,
    techniqueFocus: 'Sight-reading fluency; 3/4 phrasing; single-line reading',
    rangeAndPosition: 'First position; strings 1-3; frets 0-4',
    imslpId: 'Notebook_for_Anna_Magdalena_Bach,_BWV_Anh.113-132_(Bach,_Johann_Sebastian)',
    licenseQuestion:
        'Confirm the 1725 melody is public domain in the US, UK/EU, and '
        'Canada; confirm the attribution to Christian Petzold and that '
        'the single-line edition is newly engraved or public domain.',
  ),
  LaunchPiece(
    piece: _piece(
      id: 'spanish-romance',
      title: 'Spanish Romance (Romance Anónimo)',
      composer:
          'Anonymous (attribution disputed; sometimes attributed to '
          'Antonio Rubira or Fernando Sor)',
      license: 'public-domain',
      timeSignature: const TimeSignature(3, 4),
      key: 'E minor',
      sourceUrl: 'https://en.wikipedia.org/wiki/Romance_(guitar_piece)',
    ),
    tier: LaunchTier.returner,
    v1Stage: 9,
    phraseCount: 4,
    targetTempoBpm: 72,
    techniqueFocus:
        'Sight-reading fluency; melody across strings 1-2; steady pulse',
    rangeAndPosition: 'First position; strings 1-3; frets 0-4',
    licenseQuestion:
        'Confirm the anonymous 19th-century melody is public domain in '
        'the US, UK/EU, and Canada; confirm the chosen edition and the '
        'single-line reduction are original or public domain, with no '
        'copied copyrighted arrangement.',
  ),
  LaunchPiece(
    piece: _piece(
      id: 'original-study-2',
      title: 'Original Monophonic Study No. 2',
      composer: 'Hear Me Out (original)',
      license: 'original',
      timeSignature: const TimeSignature(4, 4),
      key: 'D major',
    ),
    tier: LaunchTier.returner,
    v1Stage: 10,
    phraseCount: 4,
    targetTempoBpm: 66,
    techniqueFocus:
        'Full-piece consolidation, dynamic shaping, 1-minute performance',
    rangeAndPosition: 'First and second position; strings 1-4; frets 0-5',
    licenseQuestion:
        'Confirm the study is an original work with no quoted external '
        'melody, and that authorship and assignment are documented for '
        'all territories.',
  ),
]);

/// Returns the launch piece with [id], or null when no piece matches.
LaunchPiece? launchPieceById(String id) {
  for (final launch in launchPieces) {
    if (launch.piece.id == id) return launch;
  }
  return null;
}

/// Returns the launch pieces in [tier], in plan order.
List<LaunchPiece> launchPiecesForTier(LaunchTier tier) =>
    List<LaunchPiece>.unmodifiable(
      launchPieces.where((launch) => launch.tier == tier),
    );

Piece _piece({
  required String id,
  required String title,
  required String composer,
  required String license,
  required TimeSignature timeSignature,
  required String key,
  String? sourceUrl,
}) {
  return Piece(
    id: id,
    title: title,
    composer: composer,
    license: license,
    tuning: Tuning.standard,
    timeSignature: timeSignature,
    key: key,
    sourceUrl: sourceUrl,
  );
}
