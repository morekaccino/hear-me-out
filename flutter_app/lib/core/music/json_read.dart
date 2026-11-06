/// Strict JSON readers shared by the score domain models.
///
/// Every failure throws a [FormatException] that names the exact field path
/// (for example `phrases[0].events[2].soundingMidi`). Callers never have to
/// guess which part of a document is malformed.
library;

String jsonFieldPath(String path, String key) =>
    path.isEmpty ? key : '$path.$key';

Never jsonReadError(String path, String message) =>
    throw FormatException('$message at $path');

Map<String, dynamic> readJsonObject(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final fieldPath = jsonFieldPath(path, key);
  final value = json[key];
  if (value == null) {
    jsonReadError(fieldPath, 'Missing required field');
  }
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  jsonReadError(fieldPath, 'Expected an object');
}

List<dynamic> readJsonList(Map<String, dynamic> json, String key, String path) {
  final fieldPath = jsonFieldPath(path, key);
  final value = json[key];
  if (value == null) {
    jsonReadError(fieldPath, 'Missing required field');
  }
  if (value is! List) jsonReadError(fieldPath, 'Expected a list');
  return value;
}

String readJsonString(Map<String, dynamic> json, String key, String path) {
  final fieldPath = jsonFieldPath(path, key);
  final value = json[key];
  if (value == null) {
    jsonReadError(fieldPath, 'Missing required field');
  }
  if (value is! String) jsonReadError(fieldPath, 'Expected a string');
  return value;
}

String? readOptionalJsonString(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    jsonReadError(jsonFieldPath(path, key), 'Expected a string');
  }
  return value;
}

int readJsonInt(Map<String, dynamic> json, String key, String path) {
  final fieldPath = jsonFieldPath(path, key);
  final value = json[key];
  if (value == null) {
    jsonReadError(fieldPath, 'Missing required field');
  }
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  jsonReadError(fieldPath, 'Expected an integer');
}

int? readOptionalJsonInt(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  jsonReadError(jsonFieldPath(path, key), 'Expected an integer');
}

double readJsonDouble(Map<String, dynamic> json, String key, String path) {
  final fieldPath = jsonFieldPath(path, key);
  final value = json[key];
  if (value == null) {
    jsonReadError(fieldPath, 'Missing required field');
  }
  if (value is num && value.isFinite) return value.toDouble();
  jsonReadError(fieldPath, 'Expected a finite number');
}

double? readOptionalJsonDouble(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is num && value.isFinite) return value.toDouble();
  jsonReadError(jsonFieldPath(path, key), 'Expected a finite number');
}

bool readOptionalJsonBool(
  Map<String, dynamic> json,
  String key,
  String path, {
  required bool fallback,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! bool) {
    jsonReadError(jsonFieldPath(path, key), 'Expected a boolean');
  }
  return value;
}

List<String> readOptionalJsonStringList(
  Map<String, dynamic> json,
  String key,
  String path, {
  List<String> fallback = const <String>[],
}) {
  final fieldPath = jsonFieldPath(path, key);
  final value = json[key];
  if (value == null) return fallback;
  if (value is! List) jsonReadError(fieldPath, 'Expected a list of strings');
  final result = <String>[];
  for (var index = 0; index < value.length; index++) {
    final item = value[index];
    if (item is! String) {
      jsonReadError('$fieldPath[$index]', 'Expected a string');
    }
    result.add(item);
  }
  return List.unmodifiable(result);
}
