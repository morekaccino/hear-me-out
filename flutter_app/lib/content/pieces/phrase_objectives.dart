import '../../core/learning/objective.dart';
import '../../core/learning/phrase_objective.dart';
import '../../core/learning/prompt.dart';
import '../../core/music/phrase.dart';
import '../../core/music/piece.dart';
import '../../core/music/score.dart';

/// One phrase registered for practice, plus the piece metadata it belongs to.
class PhraseContentRecord {
  const PhraseContentRecord({
    required this.piece,
    required this.phrase,
    required this.contentVersion,
    required this.stage,
  });

  final Piece piece;
  final Phrase phrase;

  /// Revision of [phrase]'s musical content.
  final int contentVersion;

  /// V1 stage or phrase difficulty used for display and ordering.
  final int stage;

  String get objectiveId =>
      phraseObjectiveId(pieceId: piece.id, phraseId: phrase.id);
}

/// A runtime registry of phrase content.
///
/// The app does not read authoring JSON at startup yet. A future content loader
/// calls [registerScore] (or [registerPhrase]) with the scores it parsed. Tests
/// use a local registry; the app uses [phraseObjectiveRegistry].
///
/// Phrase ids are globally unique. Re-registering the same phrase id for the
/// same piece with a new [Phrase.contentVersion] is the content-edit path: the
/// record is replaced, the stable phrase id and objective id stay the same, and
/// stored `PhraseProgress` is untouched. Registering an existing phrase id for
/// a different piece throws instead of silently overwriting the other piece's
/// objective.
class PhraseObjectiveRegistry implements PhraseObjectiveResolver {
  PhraseObjectiveRegistry();

  final Map<String, PhraseContentRecord> _records =
      <String, PhraseContentRecord>{};
  final Map<String, Piece> _pieces = <String, Piece>{};
  final Map<String, Set<String>> _piecePhraseIds = <String, Set<String>>{};

  /// Registers every phrase in [score].
  ///
  /// [contentVersion] overrides the phrase's own version, which is useful for
  /// imported or generated content. [stage] overrides the display stage.
  ///
  /// Re-registering a piece drops phrases it no longer contains. Their stored
  /// `PhraseProgress` stays in the progress document, but they no longer
  /// resolve until the phrase returns.
  void registerScore(Score score, {int? contentVersion, int? stage}) {
    final previous = _piecePhraseIds[score.piece.id] ?? const <String>{};
    final current = <String>{for (final phrase in score.phrases) phrase.id};
    for (final phraseId in previous.difference(current)) {
      _records.remove(phraseId);
    }
    _piecePhraseIds[score.piece.id] = current;
    _pieces[score.piece.id] = score.piece;
    for (final phrase in score.phrases) {
      registerPhrase(
        piece: score.piece,
        phrase: phrase,
        contentVersion: contentVersion ?? phrase.contentVersion,
        stage: stage ?? phrase.difficulty,
      );
    }
  }

  /// Registers one phrase. The phrase id must already be stable.
  void registerPhrase({
    required Piece piece,
    required Phrase phrase,
    int? contentVersion,
    int? stage,
  }) {
    final version = contentVersion ?? phrase.contentVersion;
    if (version < 1) {
      throw ArgumentError.value(
        version,
        'contentVersion',
        'Phrase content version must be at least 1',
      );
    }
    final existing = _records[phrase.id];
    if (existing != null && existing.piece.id != piece.id) {
      throw ArgumentError.value(
        phrase.id,
        'phraseId',
        'Phrase id "${phrase.id}" is already registered for piece '
            '"${existing.piece.id}"; phrase ids must be unique across pieces',
      );
    }
    _pieces[piece.id] = piece;
    _piecePhraseIds.putIfAbsent(piece.id, () => <String>{}).add(phrase.id);
    _records[phrase.id] = PhraseContentRecord(
      piece: piece,
      phrase: phrase,
      contentVersion: version,
      stage: stage ?? phrase.difficulty,
    );
  }

  /// Removes every registered phrase and piece. Tests call this between cases.
  void clear() {
    _records.clear();
    _pieces.clear();
    _piecePhraseIds.clear();
  }

  /// The registered record for [phraseId], or null.
  PhraseContentRecord? recordFor(String phraseId) => _recordFor(phraseId);

  @override
  ObjectiveRef? resolvePhrase(String phraseId, {int? contentVersion}) {
    final record = _recordFor(phraseId);
    if (record == null) return null;

    // The learner has practiced content this build does not contain. Do not
    // substitute an older arrangement and pretend it is the same notes.
    if (contentVersion != null && contentVersion > record.contentVersion) {
      return null;
    }

    return _objectiveFor(
      record,
      practicedVersion: contentVersion ?? record.contentVersion,
    );
  }

  PhraseContentRecord? _recordFor(String phraseId) {
    final direct = _records[phraseId];
    if (direct != null) return direct;

    var value = phraseId;
    if (value.startsWith(phraseObjectivePrefix)) {
      value = value.substring(phraseObjectivePrefix.length);
    }
    final bare = _records[value];
    if (bare != null) return bare;

    final separator = value.lastIndexOf(':');
    if (separator < 0) return null;
    return _records[value.substring(separator + 1)];
  }

  ObjectiveRef _objectiveFor(
    PhraseContentRecord record, {
    required int practicedVersion,
  }) {
    final phrase = record.phrase;
    final title = phrase.title ?? phrase.id;
    final options = _pieceOptions(record.piece);

    return ObjectiveRef(
      record.objectiveId,
      family: SkillFamily.repertoire,
      stage: record.stage,
      data: <String, Object?>{
        PhraseObjectiveData.pieceId: record.piece.id,
        PhraseObjectiveData.phraseId: phrase.id,
        PhraseObjectiveData.contentVersion: record.contentVersion,
        PhraseObjectiveData.practicedContentVersion: practicedVersion,
        PhraseObjectiveData.needsRetest:
            practicedVersion < record.contentVersion,
        PhraseObjectiveData.stage: record.stage,
        PhraseObjectiveData.difficulty: phrase.difficulty,
        PhraseObjectiveData.title: title,
        PhraseObjectiveData.pieceTitle: record.piece.title,
        'question': 'Which piece does "$title" belong to?',
        'options': options,
        'correctId': record.piece.id,
        'hint': '${record.piece.title} · $title',
      },
    );
  }

  List<ChoiceOption> _pieceOptions(Piece correct) {
    final pieces = <String, Piece>{..._pieces, correct.id: correct};
    final ordered = pieces.values.toList()
      ..sort((a, b) {
        final byTitle = a.title.compareTo(b.title);
        return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
      });
    // Keep the recognition surface small even when a full catalogue is
    // registered. The correct piece is always present.
    final selected =
        <Piece>[
          correct,
          ...ordered.where((piece) => piece.id != correct.id).take(3),
        ]..sort((a, b) {
          final byTitle = a.title.compareTo(b.title);
          return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
        });
    return <ChoiceOption>[
      for (final piece in selected) ChoiceOption(piece.id, piece.title),
    ];
  }
}

/// The app-wide phrase registry.
///
/// It is empty until a content loader registers parsed scores. An empty
/// registry makes every phrase id unknown, so practice safely ignores it.
final PhraseObjectiveRegistry phraseObjectiveRegistry =
    PhraseObjectiveRegistry();

/// Read-only view of [phraseObjectiveRegistry] for the session factory.
final PhraseObjectiveResolver phraseObjectiveResolver = phraseObjectiveRegistry;
