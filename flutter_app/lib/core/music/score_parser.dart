import 'json_read.dart';
import 'phrase.dart';
import 'piece.dart';
import 'score.dart';

/// Version of the canonical score document produced by [scoreToJson].
const int scoreSchemaVersion = 1;

/// Parses the canonical score document.
///
/// Unknown fields are ignored for forward compatibility. A missing or future
/// [scoreSchemaVersion] is rejected instead of guessed. Structural problems
/// throw a [FormatException] naming the exact field path.
///
/// This is the domain parser, not the authoring format. T3.2 builds the
/// content-authoring layer and validator CLI on top of it.
Score parseScore(Map<String, dynamic> json) {
  final rawVersion = json['schemaVersion'];
  if (rawVersion == null) {
    throw FormatException('Missing required field at schemaVersion');
  }
  if (rawVersion is! num ||
      !rawVersion.isFinite ||
      rawVersion != rawVersion.roundToDouble()) {
    throw FormatException('Expected an integer at schemaVersion');
  }
  final version = rawVersion.toInt();
  if (version != scoreSchemaVersion) {
    throw FormatException(
      'Unsupported score schemaVersion $version at schemaVersion; '
      'this build supports $scoreSchemaVersion.',
    );
  }

  final piece = Piece.fromJsonAt(
    readJsonObject(json, 'piece', ''),
    path: 'piece',
  );
  final phraseList = readJsonList(json, 'phrases', '');
  final phrases = <Phrase>[];
  for (var index = 0; index < phraseList.length; index++) {
    final path = 'phrases[$index]';
    final value = phraseList[index];
    if (value is! Map) {
      jsonReadError(path, 'Expected an object');
    }
    final phraseJson = value is Map<String, dynamic>
        ? value
        : Map<String, dynamic>.from(value);
    phrases.add(Phrase.fromJsonAt(phraseJson, path: path));
  }

  return Score(piece: piece, phrases: List<Phrase>.unmodifiable(phrases));
}

/// Serializes a score in the canonical, schema-versioned document shape.
Map<String, dynamic> scoreToJson(Score score) {
  return <String, dynamic>{
    'schemaVersion': scoreSchemaVersion,
    'piece': score.piece.toJson(),
    'phrases': <Map<String, dynamic>>[
      for (final phrase in score.phrases) phrase.toJson(),
    ],
  };
}
