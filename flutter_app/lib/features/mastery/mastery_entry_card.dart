import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/progress_widgets.dart';

/// Profile entry to the mastery map.
///
/// The count is real phrase evidence only. It is zero until the phrase loop
/// ships and a learner earns mastery; the card never substitutes lesson
/// completion.
class MasteryEntryCard extends StatelessWidget {
  const MasteryEntryCard({
    super.key,
    required this.canPlayCount,
    required this.onOpen,
  });

  final int canPlayCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('mastery-map-card'),
      color: AppColors.greenSoft,
      borderColor: AppColors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.greenDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: DuoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Can play',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Performance mastery, earned at tempo on separate days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DuoSpacing.xs),
              Text(
                '$canPlayCount',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.sm),
          OutlineDuoButton(
            label: 'OPEN MASTERY MAP',
            icon: Icons.arrow_forward_rounded,
            onPressed: onOpen,
            color: AppColors.greenDark,
          ),
        ],
      ),
    );
  }
}
