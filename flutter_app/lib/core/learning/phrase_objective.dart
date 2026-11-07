import 'objective.dart';

/// Prefix for every phrase-objective id.
const String phraseObjectivePrefix = 'phrase:';

/// Canonical objective id for one phrase.
///
/// Phrase ids are unique across the shipped content, but the piece id is kept
/// in the objective id so two pieces cannot silently collide and so a stored
/// skill can be traced back to its arrangement.
String phraseObjectiveId({required String pieceId, required String phraseId}) =>
    '$phraseObjectivePrefix$pieceId:$phraseId';

/// The bare phrase id inside a stored phrase-objective id.
///
/// Both the canonical `phrase:<pieceId>:<phraseId>` form and the legacy
/// `phrase:<phraseId>` form are accepted. Phrase ids are kebab-case and must
/// not contain a colon.
String? phraseIdFromObjectiveId(String objectiveId) {
  if (!objectiveId.startsWith(phraseObjectivePrefix)) return null;
  final rest = objectiveId.substring(phraseObjectivePrefix.length);
  if (rest.isEmpty) return null;
  final separator = rest.lastIndexOf(':');
  return separator < 0 ? rest : rest.substring(separator + 1);
}

/// Data keys a phrase objective carries for the session composer.
abstract final class PhraseObjectiveData {
  static const String pieceId = 'pieceId';
  static const String phraseId = 'phraseId';

  /// The version of the phrase content this build knows.
  static const String contentVersion = 'contentVersion';

  /// The version the learner's stored evidence was earned against.
  static const String practicedContentVersion = 'practicedContentVersion';

  /// True when the content changed since the learner last practiced it.
  static const String needsRetest = 'needsRetest';

  /// The content stage (V1 stage or phrase difficulty) for display.
  static const String stage = 'stage';

  static const String difficulty = 'difficulty';
  static const String title = 'title';
  static const String pieceTitle = 'pieceTitle';
}

/// Read-only phrase metadata a progress surface needs.
///
/// This lives in `core/learning` so a mastery model can read phrase content
/// without importing `lib/content`. `PhraseObjectiveRegistry` implements it.
abstract interface class PhraseContentSummary {
  String get pieceId;
  String get pieceTitle;
  String get phraseId;
  String get phraseTitle;
  int get targetTempoBpm;
  int get contentVersion;
  int get stage;
}

/// The set of phrase records this build contains.
abstract interface class PhraseContentCatalog {
  Iterable<PhraseContentSummary> get allRecords;
}

/// Resolves a stable phrase id to an objective the session composer can use.
///
/// Implementations live in `lib/content/`; `lib/core/` never imports content.
/// An unknown id returns null. Callers must skip a null result instead of
/// failing the whole session.
abstract interface class PhraseObjectiveResolver {
  /// Returns the objective for [phraseId], or null when this build has no
  /// registered content for it.
  ///
  /// [contentVersion] is the version the learner's evidence was earned
  /// against. When it is newer than the registered content the resolver
  /// returns null, because this build cannot show the content the learner
  /// practiced. When it is older, the resolver still returns the stable
  /// objective and marks it as needing a re-test.
  ObjectiveRef? resolvePhrase(String phraseId, {int? contentVersion});
}
