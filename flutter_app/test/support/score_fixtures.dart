import 'dart:convert';
import 'dart:io';

/// Loads one canonical score fixture from `test/fixtures/score/`.
Map<String, dynamic> loadScoreFixture(String name) {
  final file = File('test/fixtures/score/$name.json');
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Fixture $name is not a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}
