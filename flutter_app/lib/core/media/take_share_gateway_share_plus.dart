import 'package:share_plus/share_plus.dart';

import 'take_share_gateway.dart';

/// Builds the mobile/desktop share gateway backed by the OS share sheet.
TakeShareGateway createTakeShareGateway() => const SharePlusTakeShareGateway();

/// Shares exported files through the platform share sheet.
///
/// `share_plus` is local-only: it hands file paths to the OS sheet and never
/// uploads, syncs, or creates an account. The result is mapped to a typed
/// [TakeShareResult]; a platform error is reported, not thrown into the UI.
class SharePlusTakeShareGateway implements TakeShareGateway {
  const SharePlusTakeShareGateway();

  @override
  Future<TakeShareResult> shareFiles(
    List<String> paths, {
    String? subject,
  }) async {
    if (paths.isEmpty) {
      return const TakeShareResult(
        TakeShareStatus.unavailable,
        message: 'The export produced no files to share.',
      );
    }
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[for (final path in paths) XFile(path)],
          subject: subject,
        ),
      );
      return switch (result.status) {
        ShareResultStatus.success => const TakeShareResult(
          TakeShareStatus.shared,
        ),
        ShareResultStatus.dismissed => const TakeShareResult(
          TakeShareStatus.cancelled,
        ),
        ShareResultStatus.unavailable => const TakeShareResult(
          TakeShareStatus.unavailable,
          message:
              'The share sheet could not confirm a result. The exported '
              'files are still in the exports folder.',
        ),
      };
    } catch (_) {
      return const TakeShareResult(
        TakeShareStatus.failed,
        message:
            'The share sheet could not open. The exported files are still in '
            'the exports folder.',
      );
    }
  }
}
