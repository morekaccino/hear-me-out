/// What happened when the OS share sheet was asked to share exported files.
enum TakeShareStatus {
  /// The user picked a share action. The platform cannot always prove the
  /// receiving app finished with the files.
  shared,

  /// The user dismissed the share sheet without choosing an action.
  cancelled,

  /// This platform or build has no share sheet. The files are still on disk
  /// (or in the browser's download folder).
  unavailable,

  /// The share sheet could not open. The exported files are unaffected.
  failed,
}

/// Typed result of a share request.
class TakeShareResult {
  const TakeShareResult(this.status, {this.message});

  final TakeShareStatus status;

  /// Calm, user-facing detail. Never a raw platform exception.
  final String? message;

  bool get shared => status == TakeShareStatus.shared;
}

/// Opens the OS share sheet for already-written files.
///
/// The gateway is a local OS hand-off, not a network service. It never
/// uploads, syncs, or posts anything by itself; the user chooses a
/// destination in the platform sheet.
abstract interface class TakeShareGateway {
  /// Shares [paths] together, with an optional subject line.
  ///
  /// Returns a typed result instead of throwing so the UI can keep the
  /// exported files available when sharing is unavailable.
  Future<TakeShareResult> shareFiles(
    List<String> paths, {
    String? subject,
  });
}

/// A gateway for builds with no share sheet (web and tests).
class UnsupportedTakeShareGateway implements TakeShareGateway {
  const UnsupportedTakeShareGateway({
    this.message = 'Sharing is not available in this build.',
  });

  final String message;

  @override
  Future<TakeShareResult> shareFiles(
    List<String> paths, {
    String? subject,
  }) async => TakeShareResult(TakeShareStatus.unavailable, message: message);
}
