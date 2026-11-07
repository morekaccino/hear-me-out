/// Result of clearing the app's exported take copies.
class TakeExportClearResult {
  const TakeExportClearResult({this.deletedCount = 0, this.failure});

  /// Number of files that were deleted. On a partial failure this is the
  /// number removed before the error.
  final int deletedCount;

  /// Null when every file was removed (or there was nothing to remove).
  final TakeExportClearFailure? failure;

  bool get cleared => failure == null;
}

/// Typed failure from clearing the exports folder.
class TakeExportClearFailure {
  const TakeExportClearFailure(this.message, [this.cause]);

  /// Calm, user-facing message. Never a raw platform exception.
  final String message;

  final Object? cause;

  @override
  String toString() => 'TakeExportClearFailure: $message';
}

/// Deletes the app's exported copies without touching stored takes.
///
/// The cleaner owns only the app support `exports/` folder. It never deletes
/// the media store, the recording manifest, progress, or settings. On web the
/// browser owns downloaded files, so [isSupported] is false.
abstract interface class TakeExportCleaner {
  /// True when this platform has an app-owned exports folder to clear.
  bool get isSupported;

  /// Deletes the files directly inside the exports folder.
  ///
  /// Directories and links are left alone. A partial failure returns the count
  /// deleted so far plus a typed message.
  Future<TakeExportClearResult> clearExports();
}
