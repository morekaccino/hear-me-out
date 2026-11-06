/// The stable names written to the local retention log.
///
/// These names are a wire format: renaming an enum member must not change the
/// string. The log never stores a note name, query text, or free text.
enum RetentionEventName {
  appOpen('app_open'),
  onboardingStart('onboarding_start'),
  onboardingComplete('onboarding_complete'),
  firstNote('first_note'),
  firstPhrase('first_phrase'),
  firstRecording('first_recording'),
  sessionStart('session_start'),
  sessionComplete('session_complete'),
  dailyActive('daily_active');

  const RetentionEventName(this.wireName);

  final String wireName;

  static RetentionEventName? fromWireName(String value) {
    for (final name in values) {
      if (name.wireName == value) return name;
    }
    return null;
  }
}

/// One local, pseudonymous event.
///
/// The only fields are the event name, a UTC timestamp, and the locally
/// generated install id. There is deliberately no room for audio, note names,
/// piece titles, user ids, or device fingerprints.
class RetentionEvent {
  RetentionEvent({
    required this.name,
    required DateTime timestamp,
    required this.installId,
  }) : timestamp = timestamp.toUtc();

  final RetentionEventName name;
  final DateTime timestamp;
  final String installId;

  Map<String, dynamic> toJson() => {
    'name': name.wireName,
    'at': timestamp.toUtc().toIso8601String(),
    'installId': installId,
  };

  /// Parses one event, returning null for anything malformed. A bad event must
  /// never make the whole log unreadable.
  static RetentionEvent? tryFromJson(Object? raw, {String? expectedInstallId}) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final at = raw['at'];
    final installId = raw['installId'];
    if (name is! String || at is! String || installId is! String) return null;
    if (installId.isEmpty) return null;
    if (expectedInstallId != null && installId != expectedInstallId) {
      return null;
    }
    final eventName = RetentionEventName.fromWireName(name);
    final timestamp = DateTime.tryParse(at);
    if (eventName == null || timestamp == null) return null;
    return RetentionEvent(
      name: eventName,
      timestamp: timestamp,
      installId: installId,
    );
  }
}
