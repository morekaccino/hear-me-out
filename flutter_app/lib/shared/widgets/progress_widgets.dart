import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';

class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.green,
    this.height = 16,
    this.duration = DuoMotion.slow,
  });

  final double value;
  final Color color;
  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      label: 'Lesson progress',
      value: '${(clamped * 100).round()} percent',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          // The track has to be visible, otherwise the bar reads as a floating
          // green sliver with no start or end.
          color: AppColors.borderStrong.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: AppColors.borderStrong, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: duration,
            curve: DuoMotion.overshoot,
            builder: (context, animated, _) {
              final width = animated.clamp(0.0, 1.0);
              if (width == 0) return const SizedBox.shrink();
              return FractionallySizedBox(
                widthFactor: width,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppColors.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: iconColor ?? resolved),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: resolved,
          ),
        ),
      ],
    );
  }
}

/// Optional streak counter. No border; the number uses the icon color. The
/// counter disappears when the learner has not opted in. There is no currency.
class PathCounters extends StatelessWidget {
  const PathCounters({super.key, this.streak});

  final int? streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (streak != null)
          _Counter(
            icon: Icons.local_fire_department_rounded,
            value: '$streak',
            color: AppColors.orange,
            label: 'Streak $streak',
          ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final String value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DuoSpacing.md),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.background,
        borderRadius: BorderRadius.circular(DuoSpacing.md),
        border: Border.all(color: borderColor ?? AppColors.border, width: 2),
      ),
      child: child,
    );
  }
}
