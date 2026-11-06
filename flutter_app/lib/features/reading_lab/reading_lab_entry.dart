import 'package:flutter/material.dart';

import '../../core/music/curriculum.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';
import '../today/today_gate.dart';

/// The optional 240-lesson notation and theory course. It is the original
/// course, kept as a bridge for current learners, not the core Today loop.
///
/// The Today-loop sentence appears only where that loop actually exists. With
/// decision 0001's gate closed, the copy does not promise an unreachable
/// surface.
String readingLabCopy({bool todayLoopAvailable = todayEnabled}) =>
    todayLoopAvailable
    ? 'The original 240-lesson notation and theory course. It complements the '
          '5-minute Today loop.'
    : 'The original 240-lesson notation and theory course. Optional, '
          'self-paced reading practice.';

/// Full entry shown in Profile. It explains the course and opens the existing
/// path under a Reading Lab header.
class ReadingLabCard extends StatelessWidget {
  const ReadingLabCard({
    super.key,
    required this.completedLessons,
    required this.onOpen,
    this.todayLoopAvailable = todayEnabled,
  });

  final int completedLessons;
  final VoidCallback onOpen;
  final bool todayLoopAvailable;

  @override
  Widget build(BuildContext context) {
    final total = allLessons.length;
    final done = completedLessons.clamp(0, total);
    return SectionCard(
      key: const ValueKey('reading-lab-card'),
      color: AppColors.blueSoft,
      borderColor: AppColors.blue,
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
                  Icons.menu_book_rounded,
                  color: AppColors.blueDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: DuoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Lab',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Structured reading practice, optional',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DuoSpacing.xs),
              Text(
                '$done of $total lessons',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.sm),
          Text(
            readingLabCopy(todayLoopAvailable: todayLoopAvailable),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: DuoSpacing.sm),
          OutlineDuoButton(
            label: 'OPEN READING LAB',
            icon: Icons.arrow_forward_rounded,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

/// Compact entry shown on the Today surface. It stays secondary to the Today
/// session; it never gates or spends anything.
class ReadingLabEntry extends StatelessWidget {
  const ReadingLabEntry({
    super.key,
    required this.completedLessons,
    required this.onOpen,
  });

  final int completedLessons;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final total = allLessons.length;
    final done = completedLessons.clamp(0, total);
    return Semantics(
      button: true,
      label: 'Open the Reading Lab, optional structured reading practice',
      child: DuoTappable(
        onTap: onOpen,
        pressedScale: 0.98,
        child: Container(
          key: const ValueKey('reading-lab-entry'),
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: DuoSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.blue, width: 2),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: AppColors.blueDark,
                size: 24,
              ),
              const SizedBox(width: DuoSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Lab',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Structured reading practice, optional',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DuoSpacing.xs),
              Text(
                '$done/$total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
