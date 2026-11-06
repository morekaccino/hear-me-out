import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/media/backup_exclusion.dart';
import '../../shared/theme/app_theme.dart';

const String _privacyBase =
    'No account. No cloud. Your progress, practice history, and settings stay on this '
    'device. Audio is analyzed on this device.';

/// Copy for the profile privacy card.
///
/// The recording sentence is conditional on [backup]: the app claims
/// exclusion only when the platform confirmed it. Loading and error states
/// avoid making either claim.
String mediaPrivacyNote(AsyncValue<BackupExclusionResult> backup) {
  final status = backup.asData?.value;
  if (status == null && !backup.hasError) {
    return '$_privacyBase When you record a take, the app is checking whether '
        'it can be excluded from device backup.';
  }
  if (status?.isConfirmed ?? false) {
    return '$_privacyBase When you record a take, it stays here too and is '
        'excluded from cloud backup by default.';
  }
  return '$_privacyBase When you record a take, the app could not confirm it '
      'is excluded from device backup, so it may be included in device backup.';
}

/// The profile privacy card. Kept separate from the screen so the confirmed and
/// unconfirmed copies are directly testable.
class MediaPrivacyCard extends StatelessWidget {
  const MediaPrivacyCard({super.key, required this.backup});

  final AsyncValue<BackupExclusionResult> backup;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.blueDark,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mediaPrivacyNote(backup),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.45,
                color: AppColors.blueDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
