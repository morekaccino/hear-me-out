import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/progress.dart';
import '../../core/music/curriculum.dart';
import '../../core/music/guitar.dart';
import '../../core/music/note.dart';
import '../../shared/audio/sound_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../lesson/lesson_screen.dart';
import 'path_layout.dart';

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
              const SizedBox(height: 8),
              _DailyGoalStrip(
                xpToday: progress.xpTodayForDisplay,
                goal: progress.settings.dailyGoalXp,
                mastered: progress.masteredCount,
              ),
              const SizedBox(height: 10),
              for (final section in sections) ...[
                _SectionHeader(
                  section: section,
                  completed: progress.completedLessons,
                  currentLessonId: currentLesson?.id,
                ),
                const SizedBox(height: 6),
                for (final unit in section.units) ...[
                  _UnitHeader(
                    unit: unit,
                    completed: progress.completedLessons,
                    currentLessonId: currentLesson?.id,
                    onGuidebook: () => _showGuidebook(context, ref, unit),
                  ),
                  const SizedBox(height: 20),
                  _LessonPath(
                    unit: unit,
                    startOffset: _unitStartOffset(section, unit),
                    completed: progress.completedLessons,
                    currentLessonId: currentLesson?.id,
                    onLessonTap: (lesson) {
                      final unlocked =
                          progress.completedLessons.contains(lesson.id) ||
                          lesson.id == currentLesson?.id;
                      if (unlocked) {
                        unawaited(
                          ref
                              .read(soundServiceProvider)
                              .play(Sfx.lessonStart),
                        );
                        _openLesson(context, ref, lesson.id);
                      } else {
                        unawaited(
                          ref.read(soundServiceProvider).play(Sfx.uiLocked),
                        );
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
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 6),
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

  Future<void> _showGuidebook(
    BuildContext context,
    WidgetRef ref,
    UnitDefinition unit,
  ) async {
    unawaited(ref.read(soundServiceProvider).play(Sfx.uiSelect));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuidebookSheet(unit: unit),
    );
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
    if (!context.mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
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

class _DailyGoalStrip extends StatelessWidget {
  const _DailyGoalStrip({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 17,
                color: AppColors.greenDark,
              ),
              const SizedBox(width: 5),
              const Text(
                'Daily goal',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$xpToday / $goal XP',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LessonProgressBar(value: ratio, height: 7),
          const SizedBox(height: 4),
          Text(
            ratio >= 1
                ? 'Goal complete. Nice work today.'
                : xpToday == 0
                ? (mastered == 0
                      ? 'Finish a lesson to start your streak.'
                      : '$mastered notes mastered so far.')
                : '${goal - xpToday} XP to your daily goal.',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

Color _sectionColor(int number) => switch (number) {
  2 => AppColors.purple,
  3 => AppColors.blue,
  _ => AppColors.green,
};

Color _sectionDark(int number) => switch (number) {
  2 => AppColors.purpleDark,
  3 => AppColors.blueDark,
  _ => AppColors.greenDark,
};

SectionDefinition _sectionForUnit(UnitDefinition unit) => sections.firstWhere(
  (section) => section.units.any((candidate) => candidate.id == unit.id),
);

int _unitStartOffset(SectionDefinition section, UnitDefinition unit) {
  var count = 0;
  for (final candidate in section.units) {
    if (identical(candidate, unit)) return count;
    count += candidate.lessons.length;
  }
  return count;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.section,
    required this.completed,
    required this.currentLessonId,
  });

  final SectionDefinition section;
  final Set<String> completed;
  final String? currentLessonId;

  @override
  Widget build(BuildContext context) {
    final lessons = [for (final unit in section.units) ...unit.lessons];
    final done = lessons.where((lesson) => completed.contains(lesson.id)).length;
    final current = lessons.any((lesson) => lesson.id == currentLessonId);
    final complete = done == lessons.length;
    final sectionColor = _sectionColor(section.number);
    final sectionDark = _sectionDark(section.number);
    final accent = current
        ? sectionDark
        : complete
        ? AppColors.greenDark
        : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: current
                  ? sectionColor
                  : complete
                  ? AppColors.green
                  : AppColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECTION ${section.number}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  section.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$done/${lessons.length}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({
    required this.unit,
    required this.completed,
    required this.currentLessonId,
    required this.onGuidebook,
  });

  final UnitDefinition unit;
  final Set<String> completed;
  final String? currentLessonId;
  final VoidCallback onGuidebook;

  @override
  Widget build(BuildContext context) {
    final done = unit.lessons
        .where((lesson) => completed.contains(lesson.id))
        .length;
    final current = unit.lessons.any(
      (lesson) => lesson.id == currentLessonId,
    );
    final complete = done == unit.lessons.length;
    final section = _sectionForUnit(unit);
    final sectionColor = _sectionColor(section.number);
    final sectionDark = _sectionDark(section.number);
    final background = current
        ? sectionColor
        : complete
        ? AppColors.yellow
        : AppColors.surface;
    final foreground = current ? Colors.white : AppColors.text;
    final muted = current
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textMuted;
    final border = current
        ? sectionDark
        : complete
        ? AppColors.yellowDark
        : AppColors.border;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: current ? 0.3 : 0.16),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: current
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UNIT ${unit.number}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: current ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unit.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ),
              if (complete)
                Icon(
                  Icons.emoji_events_rounded,
                  color: current ? Colors.white : AppColors.yellowDark,
                  size: 22,
                ),
              IconButton(
                onPressed: onGuidebook,
                tooltip: 'Unit guidebook',
                icon: Icon(
                  Icons.menu_book_rounded,
                  size: 21,
                  color: current ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
          Text(
            unit.focus,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: muted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '$done/${unit.lessons.length} lessons',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: unit.lessons.isEmpty
                        ? 0
                        : done / unit.lessons.length,
                    minHeight: 5,
                    backgroundColor: current
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      current
                          ? Colors.white
                          : complete
                          ? AppColors.yellowDark
                          : sectionColor,
                    ),
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

class _LessonPath extends StatelessWidget {
  const _LessonPath({
    required this.unit,
    required this.startOffset,
    required this.completed,
    required this.currentLessonId,
    required this.onLessonTap,
  });

  final UnitDefinition unit;
  final int startOffset;
  final Set<String> completed;
  final String? currentLessonId;
  final ValueChanged<LessonDefinition> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = PathLayout(
          unit: unit,
          width: constraints.maxWidth,
          startOffset: startOffset,
        );
        return SizedBox(
          height: layout.height,
          width: constraints.maxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(
                    nodes: layout.nodes,
                    completed: completed,
                    currentLessonId: currentLessonId,
                  ),
                ),
              ),
              for (final node in layout.nodes)
                Positioned(
                  left: node.position.dx - PathLayout.nodeSize / 2,
                  top: node.position.dy - PathLayout.nodeSize / 2,
                  child: _LessonNode(
                    lesson: node.lesson,
                    completed: completed.contains(node.lesson.id),
                    current: node.lesson.id == currentLessonId,
                    size: PathLayout.nodeSize,
                    onTap: () => onLessonTap(node.lesson),
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
    required this.completed,
    required this.current,
    required this.size,
    required this.onTap,
  });

  final LessonDefinition lesson;
  final bool completed;
  final bool current;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isReview = lesson.isReview;
    final (background, border, icon, iconColor) = completed
        ? (
            AppColors.yellow,
            AppColors.yellowDark,
            isReview ? Icons.emoji_events_rounded : Icons.check_rounded,
            Colors.white,
          )
        : current
        ? (
            AppColors.green,
            AppColors.greenDark,
            isReview ? Icons.emoji_events_rounded : Icons.play_arrow_rounded,
            Colors.white,
          )
        : (
            AppColors.surface,
            AppColors.border,
            isReview ? Icons.emoji_events_rounded : Icons.lock_rounded,
            AppColors.textLight,
          );
    final content = current && !isReview
        ? Container(
            width: size * 0.68,
            height: size * 0.68,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Mascot(size: size * 0.5),
          )
        : Icon(icon, color: iconColor, size: size * 0.4);

    final node = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (current)
            Positioned(
              top: -34,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
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
                      const CustomPaint(
                        size: Size(12, 6),
                        painter: _StartTailPainter(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Semantics(
            button: true,
            label: isReview
                ? 'Unit checkpoint: ${lesson.title}'
                : 'Lesson: ${lesson.title}',
            excludeSemantics: true,
            child: GestureDetector(
              key: current
                  ? const ValueKey('current-lesson-node')
                  : null,
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: border.withValues(alpha: 0.35),
                      offset: const Offset(0, 6),
                      blurRadius: 0,
                    ),
                    if (current)
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.22),
                        spreadRadius: 6,
                        blurRadius: 0,
                      ),
                  ],
                ),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
    return current ? _Bobbing(child: node) : node;
  }
}

class _Bobbing extends StatefulWidget {
  const _Bobbing({required this.child});

  final Widget child;

  @override
  State<_Bobbing> createState() => _BobbingState();
}

class _BobbingState extends State<_Bobbing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true, count: 2);
  late final Animation<double> _bob = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -3 * _bob.value),
        child: child,
      ),
    );
  }
}

class _StartTailPainter extends CustomPainter {
  const _StartTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = AppColors.background,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _StartTailPainter oldDelegate) => false;
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.nodes,
    required this.completed,
    required this.currentLessonId,
  });

  final List<PathNodeLayout> nodes;
  final Set<String> completed;
  final String? currentLessonId;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) return;
    final base = Paint()
      ..color = AppColors.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final progress = Paint()
      ..color = AppColors.green.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < nodes.length - 1; index++) {
      final start = nodes[index].position;
      final end = nodes[index + 1].position;
      final midY = (start.dy + end.dy) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);
      canvas.drawPath(path, base);
      final reached =
          completed.contains(nodes[index].lesson.id) &&
          (completed.contains(nodes[index + 1].lesson.id) ||
              nodes[index + 1].lesson.id == currentLessonId);
      if (reached) canvas.drawPath(path, progress);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.nodes != nodes ||
      oldDelegate.completed.length != completed.length ||
      oldDelegate.currentLessonId != currentLessonId;
}

class _GuidebookSheet extends StatelessWidget {
  const _GuidebookSheet({required this.unit});

  final UnitDefinition unit;

  @override
  Widget build(BuildContext context) {
    final notes = <Note>[];
    final seen = <String>{};
    for (final lesson in unit.lessons) {
      for (final note in [...lesson.newNotes, ...lesson.reviewNotes]) {
        if (seen.add(note.id)) notes.add(note);
      }
    }
    final newIds = unit.newNotes.map((note) => note.id).toSet();

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'UNIT ${unit.number} GUIDEBOOK',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.greenDark,
              ),
            ),
            Text(
              unit.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unit.focus,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final note = notes[index];
                  final position = Guitar.bestPosition(note);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: newIds.contains(note.id)
                          ? AppColors.greenSoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 54,
                          child: Text(
                            note.display,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (newIds.contains(note.id))
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            position?.label ?? 'First-position note',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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
