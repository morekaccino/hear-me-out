import 'package:flutter/material.dart';

import '../../core/learning/progress.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';

/// Right column on the learn page. Quest progress only — no leagues or ads.
class LearnRail extends StatelessWidget {
  const LearnRail({
    super.key,
    required this.progress,
    this.onOpenQuests,
  });

  final ProgressState progress;
  final VoidCallback? onOpenQuests;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final goal = progress.settings.weeklyGoalMinutes;
    final minutes = progress.weeklyPracticeMinutes(now);
    final remaining = progress.weeklyPracticeGoalRemaining(now);
    final ratio = goal == 0 ? 0.0 : (minutes / goal).clamp(0.0, 1.0);

    return Padding(
      key: const ValueKey('learn-rail'),
      padding: const EdgeInsets.fromLTRB(
        DuoSpacing.md,
        DuoSpacing.md,
        DuoSpacing.lg,
        DuoSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            PathCounters(
              streak: progress.settings.streakEnabled
                  ? progress.effectiveStreak
                  : null,
              gems: progress.gems,
            ),
            const SizedBox(height: DuoSpacing.lg),
            _RailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Daily Quests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (onOpenQuests != null)
                        DuoTappable(
                          onTap: onOpenQuests!,
                          pressedScale: 0.94,
                          child: const Text(
                            'VIEW ALL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DuoSpacing.md),
                  for (
                    var index = 0;
                    index < dailyQuestDefinitions.length;
                    index++
                  ) ...[
                    _QuestRow(
                      quest: dailyQuestDefinitions[index],
                      value: progress.questProgress(
                        dailyQuestDefinitions[index],
                      ),
                    ),
                    if (index < dailyQuestDefinitions.length - 1)
                      const SizedBox(height: DuoSpacing.md),
                  ],
                ],
              ),
            ),
            const SizedBox(height: DuoSpacing.lg),
            _RailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly goal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: DuoSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        size: 22,
                        color: AppColors.greenDark,
                      ),
                      const SizedBox(width: DuoSpacing.xs),
                      Expanded(
                        child: _QuestProgress(
                          value: ratio,
                          label: '$minutes / $goal min',
                          color: AppColors.green,
                          duration: const Duration(milliseconds: 600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DuoSpacing.xs),
                  Text(
                    ratio >= 1
                        ? 'Weekly goal complete. Nice work.'
                        : minutes == 0
                        ? 'A few minutes this week is a good start.'
                        : '$remaining min to this week’s goal.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DuoSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: child,
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest, required this.value});

  final QuestDefinition quest;
  final int value;

  @override
  Widget build(BuildContext context) {
    final ratio = quest.target == 0
        ? 0.0
        : (value / quest.target).clamp(0.0, 1.0);
    final (icon, color) = switch (quest.kind) {
      'lessons' => (Icons.school_rounded, AppColors.green),
      'combo' => (Icons.local_fire_department_rounded, AppColors.orange),
      _ => (Icons.music_note_rounded, AppColors.blue),
    };

    return Row(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(width: DuoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quest.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DuoSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _QuestProgress(
                      value: ratio,
                      label: '$value / ${quest.target}',
                    ),
                  ),
                  const SizedBox(width: DuoSpacing.xs),
                  const Icon(
                    Icons.inventory_2_rounded,
                    size: 22,
                    color: AppColors.yellowDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestProgress extends StatelessWidget {
  const _QuestProgress({
    required this.value,
    required this.label,
    this.color = AppColors.green,
    this.duration = const Duration(milliseconds: 600),
  });

  final double value;
  final String label;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      height: 1,
    );
    return SizedBox(
      height: 16,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LessonProgressBar(
            value: value,
            height: 16,
            color: color,
            duration: duration,
          ),
          Center(
            child: Text(
              label,
              style: style.copyWith(color: AppColors.textMuted),
            ),
          ),
          ClipRect(
            clipper: _ProgressClipper(value),
            child: Center(
              child: Text(
                label,
                style: style.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressClipper extends CustomClipper<Rect> {
  const _ProgressClipper(this.value);

  final double value;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
    0,
    0,
    size.width * value.clamp(0.0, 1.0),
    size.height,
  );

  @override
  bool shouldReclip(covariant _ProgressClipper oldClipper) =>
      oldClipper.value != value;
}
