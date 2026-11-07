import 'package:flutter/material.dart';

import '../../core/media/before_after.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/progress_widgets.dart';

/// A private progress card built from two real takes.
///
/// It shows one honest metric (days apart), never a score, grade, or public
/// rank. The card stays on the device unless the learner explicitly exports it.
class BeforeAfterCard extends StatelessWidget {
  const BeforeAfterCard({
    super.key,
    required this.data,
    this.onPlayLatest,
  });

  final BeforeAfterCardData data;
  final VoidCallback? onPlayLatest;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      color: AppColors.greenSoft,
      borderColor: AppColors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Before / after',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
              Text(
                _formatDate(data.last.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.pieceTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.phraseLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green, width: 2),
            ),
            child: Text(
              data.metricLabel,
              key: const ValueKey('before-after-metric'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.greenDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You kept ${data.takeCount} takes. Listen to how the phrase '
            'changed. No score, no ranking.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          if (onPlayLatest != null) ...[
            const SizedBox(height: 12),
            DuoButton(
              key: const ValueKey('before-after-play-latest'),
              label: 'PLAY LATEST TAKE',
              icon: Icons.play_arrow_rounded,
              height: 48,
              fontSize: 14,
              onPressed: onPlayLatest,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Private. Stays on this device unless you export it.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
