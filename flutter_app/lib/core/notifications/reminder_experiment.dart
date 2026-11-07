import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../learning/progress.dart';
import 'reminder_copy.dart';

/// Which body copy an install receives for the local practice reminder.
///
/// The assignment is a pure function of the locally generated install id. It
/// never uses a random number, the clock, or the platform, so a re-scheduled
/// reminder keeps the same copy for the life of the install.
enum ReminderCopyVariant {
  /// Names the real next musical task, for example
  /// `Today: 5 min — 3 notes are due.`
  specificTask,

  /// The plain body `Time to practice!`.
  generic,
}

/// The exact generic body. The notification title stays
/// [reminderNotificationTitle] for both variants, so the body is the only
/// experimental difference.
const String genericReminderBody = 'Time to practice!';

/// How many leading hex characters of the SHA-256 digest choose the variant.
///
/// Eight characters are 32 bits, enough to split a real install id evenly. The
/// exact width is part of the assignment rule: changing it reassigns users.
const int reminderAssignmentHexLength = 8;

/// The minimum number of hex characters accepted as a well-formed install id.
///
/// The real id is 32 lowercase hex characters from `Random.secure()`. A value
/// that is empty, shorter, or not hex is malformed and gets the safe default.
const int reminderInstallIdMinHexLength = 8;

final RegExp _hexInstallId = RegExp(r'^[0-9a-f]+$');

/// Returns the stable copy variant for [installId].
///
/// The id is trimmed and lowercased, then SHA-256 hashed. The first
/// [reminderAssignmentHexLength] hex characters are read as an unsigned
/// integer; an odd value gets [ReminderCopyVariant.generic] and an even value
/// gets [ReminderCopyVariant.specificTask]. A cryptographic hash is uniform, so
/// this splits well-formed ids roughly 50/50.
///
/// Empty and malformed ids get [ReminderCopyVariant.specificTask]. That is the
/// current copy, so a broken or missing id never changes the reminder.
ReminderCopyVariant reminderVariantForInstall(String installId) {
  final normalized = installId.trim().toLowerCase();
  if (normalized.length < reminderInstallIdMinHexLength ||
      !_hexInstallId.hasMatch(normalized)) {
    return ReminderCopyVariant.specificTask;
  }
  final digest = sha256.convert(utf8.encode(normalized)).toString();
  final bucket = int.parse(
    digest.substring(0, reminderAssignmentHexLength),
    radix: 16,
  );
  return bucket.isOdd
      ? ReminderCopyVariant.generic
      : ReminderCopyVariant.specificTask;
}

/// The reminder body for [variant], built from real progress only.
///
/// [ReminderCopyVariant.specificTask] delegates to [reminderTaskBody], so a
/// caller that does not pass a variant keeps the existing copy and fallback
/// order: a real phrase title and bar count when the caller supplies them, then
/// the real due-note count, then the real weekly-goal remainder, then
/// `Today: 5 min of guitar.`
///
/// [ReminderCopyVariant.generic] always returns [genericReminderBody]. It never
/// reads progress, so it cannot invent a task, a deadline, or a streak claim.
String reminderBodyForVariant(
  ProgressState progress,
  DateTime now, {
  ReminderCopyVariant variant = ReminderCopyVariant.specificTask,
  bool phraseLoopEnabled = false,
  String? phraseTitle,
  int? phraseBars,
}) {
  return switch (variant) {
    ReminderCopyVariant.generic => genericReminderBody,
    ReminderCopyVariant.specificTask => reminderTaskBody(
      progress,
      now,
      phraseLoopEnabled: phraseLoopEnabled,
      phraseTitle: phraseTitle,
      phraseBars: phraseBars,
    ),
  };
}
