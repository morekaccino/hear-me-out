import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Name of the platform channel handled by `ios/Runner/AppDelegate.swift`.
const String mediaBackupExclusionChannelName =
    'hear_me_out/media_backup_exclusion';

/// Result of asking the platform to keep the media directory out of backup.
enum BackupExclusionStatus {
  /// The platform confirmed the directory is excluded from backup.
  excluded,

  /// The platform handles exclusion without a runtime call (Android rules,
  /// web storage).
  notRequired,

  /// The platform call failed or did not confirm exclusion.
  failed,
}

/// Outcome of one backup exclusion request.
@immutable
class BackupExclusionResult {
  const BackupExclusionResult._(this.status, {this.error});

  /// The platform confirmed the exclusion.
  const BackupExclusionResult.excluded()
    : this._(BackupExclusionStatus.excluded);

  /// The platform does not need an exclusion call.
  const BackupExclusionResult.notRequired([String? reason])
    : this._(BackupExclusionStatus.notRequired, error: reason);

  /// The exclusion failed. [error] explains why.
  const BackupExclusionResult.failed(Object error)
    : this._(BackupExclusionStatus.failed, error: error);

  final BackupExclusionStatus status;

  /// The failure, or the reason no call was needed.
  final Object? error;

  /// True only when the platform confirmed the resource value.
  bool get isExcluded => status == BackupExclusionStatus.excluded;

  @override
  String toString() =>
      'BackupExclusionResult(${status.name}'
      '${error == null ? '' : ', $error'})';
}

/// Keeps the recording directory out of platform cloud backup.
abstract class MediaBackupExclusion {
  /// Asks the platform to exclude [directory] from backup.
  ///
  /// Implementations return a failed result instead of throwing so the caller
  /// can continue without claiming the directory is protected.
  Future<BackupExclusionResult> excludeFromBackup(String directory);
}

/// iOS implementation backed by the `hear_me_out/media_backup_exclusion`
/// method channel.
///
/// `AppDelegate.swift` sets `NSURLIsExcludedFromBackupKey` on [directory] and
/// returns true only after reading the resource value back.
class PlatformMediaBackupExclusion implements MediaBackupExclusion {
  const PlatformMediaBackupExclusion({this.channel});

  /// Method name handled by the iOS side.
  static const String method = 'excludeFromBackup';

  /// Override for tests. Production uses the channel named by
  /// [mediaBackupExclusionChannelName].
  final MethodChannel? channel;

  MethodChannel get _channel =>
      channel ?? const MethodChannel(mediaBackupExclusionChannelName);

  @override
  Future<BackupExclusionResult> excludeFromBackup(String directory) async {
    if (directory.trim().isEmpty) {
      return BackupExclusionResult.failed(
        ArgumentError.value(directory, 'directory', 'must not be empty'),
      );
    }

    try {
      final excluded = await _channel.invokeMethod<bool>(method, {
        'path': directory,
      });
      if (excluded == true) return const BackupExclusionResult.excluded();
      return BackupExclusionResult.failed(
        PlatformException(
          code: 'not_confirmed',
          message: 'The platform did not confirm backup exclusion.',
        ),
      );
    } on PlatformException catch (error) {
      return BackupExclusionResult.failed(error);
    } on MissingPluginException catch (error) {
      return BackupExclusionResult.failed(error);
    }
  }
}

/// No-op implementation for platforms that do not use the iOS resource value.
class NoopMediaBackupExclusion implements MediaBackupExclusion {
  const NoopMediaBackupExclusion();

  @override
  Future<BackupExclusionResult> excludeFromBackup(String directory) async {
    return const BackupExclusionResult.notRequired(
      'This platform excludes recordings with its own backup rules.',
    );
  }
}

/// Returns the backup exclusion implementation for the current platform.
MediaBackupExclusion createMediaBackupExclusion() {
  if (kIsWeb) return const NoopMediaBackupExclusion();
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return const PlatformMediaBackupExclusion();
  }
  return const NoopMediaBackupExclusion();
}
