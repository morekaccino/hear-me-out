import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/progress.dart';
import '../../core/music/curriculum.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../lesson/lesson_screen.dart';

class PathScreen extends ConsumerWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final progress = data.progress;
    final currentLesson = _currentLesson(progress.completedLessons);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageFrame(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _Header(
                streak: progress.effectiveStreak,
                level: progress.level,
                xp: progress.xp,
              ),
              const SizedBox(height: 14),
              _DailyGoalCard(
                xpToday: progress.xpTodayForDisplay,
                goal: progress.settings.dailyGoalXp,
                mastered: progress.masteredCount,
              ),
              const SizedBox(height: 20),
              for (final unit in curriculum) ...[
                _UnitBanner(unit: unit),
                const SizedBox(height: 8),
                _LessonPath(
                  unit: unit,
                  completed: progress.completedLessons,
                  currentLessonId: currentLesson?.id,
                  onLessonTap: (lesson) {
                    if (progress.completedLessons.contains(lesson.id) ||
                        lesson.id == currentLesson?.id) {
                      _openLesson(context, ref, lesson.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Finish the lesson before this one first.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 18),
              ],
              const _FooterNote(),
            ],
          ),
        ),
      ),
    );
  }

  LessonDefinition? _currentLesson(Set<String> completed) {
    for (final lesson in allLessons) {
      if (!completed.contains(lesson.id)) return lesson;
    }
    return null;
  }

  Future<void> _openLesson(
    BuildContext context,
    WidgetRef ref,
    String lessonId,
  ) async {
    final controller = ref.read(appControllerProvider.notifier);
    final settings = ref
        .read(appControllerProvider)
        .requireValue
        .progress
        .settings;
    var micAvailable = false;
    if (settings.answerMode != AnswerMode.name) {
      final source = ref.read(pitchSourceFactoryProvider)();
      try {
        micAvailable = await source.ensurePermission();
      } catch (_) {
        micAvailable = false;
      } finally {
        await source.dispose();
      }
    }
    if (!context.mounted) return;
    if (!micAvailable && settings.answerMode != AnswerMode.name) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone unavailable. This lesson will use note names.',
          ),
        ),
      );
    }
    controller.startLesson(lessonId, micAvailable: micAvailable);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LessonScreen()));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.streak, required this.level, required this.xp});

  final int streak;
  final int level;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Mascot(size: 54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hear Me Out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'Level $level  ·  $xp XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        StatPill(
          icon: Icons.local_fire_department_rounded,
          value: '$streak',
          iconColor: const Color(0xFFFF9600),
        ),
      ],
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.xpToday,
    required this.goal,
    required this.mastered,
  });

  final int xpToday;
  final int goal;
  final int mastered;

  @override
  Widget build(BuildContext context) {
    final ratio = goal == 0 ? 0.0 : (xpToday / goal).clamp(0.0, 1.0);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 20,
                color: AppColors.greenDark,
              ),
              const SizedBox(width: 6),
              const Text(
                'Daily goal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$xpToday / $goal XP',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LessonProgressBar(value: ratio),
          const SizedBox(height: 10),
          Text(
            ratio >= 1
                ? 'Goal complete. Nice work today.'
                : mastered == 0
                ? 'Finish a lesson to start your streak.'
                : '$mastered notes mastered so far.',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({required this.unit});

  final UnitDefinition unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(18),
        border: const Border(
          bottom: BorderSide(color: AppColors.greenDark, width: 5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UNIT ${unit.number}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unit.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unit.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white70,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _LessonPath extends StatelessWidget {
  const _LessonPath({
    required this.unit,
    required this.completed,
    required this.currentLessonId,
    required this.onLessonTap,
  });

  final UnitDefinition unit;
  final Set<String> completed;
  final String? currentLessonId;
  final ValueChanged<LessonDefinition> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const spacing = 118.0;
        const nodeSize = 78.0;
        final height = unit.lessons.length * spacing + 24;
        final centers = <Offset>[];
        for (var index = 0; index < unit.lessons.length; index++) {
          final x =
              width / 2 + math.sin(index * 1.15 + unit.number) * width * 0.23;
          final y = 44.0 + index * spacing;
          centers.add(Offset(x, y));
        }

        return SizedBox(
          height: height,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(
                    points: centers,
                    completedCount: unit.lessons
                        .where((lesson) => completed.contains(lesson.id))
                        .length,
                  ),
                ),
              ),
              for (var index = 0; index < unit.lessons.length; index++)
                Positioned(
                  left: centers[index].dx - nodeSize / 2,
                  top: centers[index].dy - nodeSize / 2,
                  child: _LessonNode(
                    lesson: unit.lessons[index],
                    index: index,
                    completed: completed.contains(unit.lessons[index].id),
                    current: unit.lessons[index].id == currentLessonId,
                    size: nodeSize,
                    onTap: () => onLessonTap(unit.lessons[index]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LessonNode extends StatelessWidget {
  const _LessonNode({
    required this.lesson,
    required this.index,
    required this.completed,
    required this.current,
    required this.size,
    required this.onTap,
  });

  final LessonDefinition lesson;
  final int index;
  final bool completed;
  final bool current;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, border, icon, iconColor) = completed
        ? (
            AppColors.yellow,
            AppColors.yellowDark,
            Icons.check_rounded,
            Colors.white,
          )
        : current
        ? (
            AppColors.green,
            AppColors.greenDark,
            Icons.play_arrow_rounded,
            Colors.white,
          )
        : (
            AppColors.surface,
            AppColors.border,
            Icons.lock_rounded,
            AppColors.textLight,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (current)
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Text(
              'START',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.greenDark,
              ),
            ),
          ),
        Semantics(
          button: true,
          label: 'Lesson ${lesson.title}',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: border.withValues(alpha: 0.35),
                    offset: const Offset(0, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: size * 0.42),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 112,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            lesson.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: current || completed
                  ? AppColors.text
                  : AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.points, required this.completedCount});

  final List<Offset> points;
  final int completedCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    for (var index = 0; index < points.length - 1; index++) {
      final start = points[index];
      final end = points[index + 1];
      final midY = (start.dy + end.dy) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
      if (index < completedCount - 1) {
        canvas.drawPath(
          path,
          Paint()
            ..color = AppColors.green.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.completedCount != completedCount;
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: Text(
        'Every note you master is stored on this device only.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}
