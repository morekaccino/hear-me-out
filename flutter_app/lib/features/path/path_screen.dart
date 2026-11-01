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
    progress.refreshHearts(DateTime.now());
    final currentLesson = _currentLesson(progress.completedLessons);
    final nextSection = _nextSectionAfter(currentLesson);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageFrame(
          maxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            children: [
              _Header(progress: progress),
              const SizedBox(height: 10),
              _DailyGoalCard(
                xpToday: progress.xpTodayForDisplay,
                goal: progress.settings.dailyGoalXp,
                mastered: progress.masteredCount,
              ),
              const SizedBox(height: 16),
              for (final section in sections) ...[
                if (identical(section, nextSection)) ...[
                  const _UpNextLabel(),
                  const SizedBox(height: 4),
                ],
                _SectionHeader(
                  section: section,
                  completed: progress.completedLessons,
                  currentLessonId: currentLesson?.id,
                  onJump: section.number > 1
                      ? () => _confirmJump(context, ref, section, progress)
                      : null,
                ),
                const SizedBox(height: 6),
                for (final unit in section.units) ...[
                  _UnitHeader(
                    unit: unit,
                    completed: progress.completedLessons,
                    currentLessonId: currentLesson?.id,
                    onGuidebook: () => _showGuidebook(context, ref, unit),
                  ),
                  const SizedBox(height: 22),
                  _LessonPath(
                    unit: unit,
                    startOffset: _unitStartOffset(section, unit),
                    completed: progress.completedLessons,
                    currentLessonId: currentLesson?.id,
                    chest: chestForUnit(unit.id),
                    openedChests: progress.openedChests,
                    onChestTap: (chest) =>
                        _openChest(context, ref, chest, progress),
                    onLessonTap: (lesson) {
                      final unlocked =
                          progress.completedLessons.contains(lesson.id) ||
                          lesson.id == currentLesson?.id;
                      if (!unlocked) {
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
                        return;
                      }
                      _launchLesson(context, ref, lesson, progress);
                    },
                  ),
                  const SizedBox(height: 14),
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

  SectionDefinition? _nextSectionAfter(LessonDefinition? currentLesson) {
    if (currentLesson == null) return null;
    final index = sections.indexWhere(
      (section) => section.units.any(
        (unit) => unit.lessons.any((lesson) => lesson.id == currentLesson.id),
      ),
    );
    if (index < 0 || index + 1 >= sections.length) return null;
    return sections[index + 1];
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

  Future<void> _launchLesson(
    BuildContext context,
    WidgetRef ref,
    LessonDefinition lesson,
    ProgressState progress,
  ) async {
    if (progress.hearts <= 0) {
      await _showOutOfHearts(context, ref, progress);
      return;
    }
    unawaited(ref.read(soundServiceProvider).play(Sfx.lessonStart));
    await _openLesson(context, ref, lesson.id);
  }

  Future<void> _showOutOfHearts(
    BuildContext context,
    WidgetRef ref,
    ProgressState progress,
  ) async {
    final refill = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Out of hearts'),
        content: Text(
          'Refill all five hearts for $heartRefillCost gems, or finish a practice session to earn one back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('NOT NOW'),
          ),
          FilledButton(
            onPressed: progress.gems >= heartRefillCost
                ? () => Navigator.pop(dialogContext, true)
                : null,
            child: Text('REFILL · $heartRefillCost'),
          ),
        ],
      ),
    );
    if (refill != true || !context.mounted) return;
    final bought = await ref
        .read(appControllerProvider.notifier)
        .buyHeartRefill();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bought
              ? 'Hearts refilled. You are ready to play.'
              : 'Not enough gems for a refill.',
        ),
      ),
    );
  }

  Future<void> _confirmJump(
    BuildContext context,
    WidgetRef ref,
    SectionDefinition section,
    ProgressState progress,
  ) async {
    final priorLessons = [
      for (final earlier in sections.take(section.number - 1))
        for (final unit in earlier.units) ...unit.lessons,
    ];
    if (priorLessons.every((lesson) => progress.isLessonCompleted(lesson.id))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This section is already unlocked.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Jump ahead to ${section.title}?'),
        content: const Text(
          'Pass a 15-exercise test of the earlier material to unlock this section. Your note progress is kept either way.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('NOT YET'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('START TEST'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final settings = ref
        .read(appControllerProvider)
        .requireValue
        .progress
        .settings;
    final micAvailable = await _micAvailable(ref, settings);
    if (!context.mounted) return;
    ref
        .read(appControllerProvider.notifier)
        .startJumpTest(sectionId: section.id, micAvailable: micAvailable);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LessonScreen()));
  }

  Future<void> _openChest(
    BuildContext context,
    WidgetRef ref,
    ChestDefinition chest,
    ProgressState progress,
  ) async {
    if (!progress.completedLessons.contains(chest.afterLessonId)) {
      unawaited(ref.read(soundServiceProvider).play(Sfx.uiLocked));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finish the lesson before this chest first.'),
        ),
      );
      return;
    }
    if (progress.openedChests.contains(chest.id)) return;
    final opened = await ref
        .read(appControllerProvider.notifier)
        .openChest(chest.id);
    if (!context.mounted || !opened) return;
    unawaited(ref.read(soundServiceProvider).play(Sfx.copySuccess));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chest opened!'),
        content: Row(
          children: [
            const Icon(Icons.diamond_rounded, color: AppColors.blue, size: 30),
            const SizedBox(width: 10),
            Text(
              '+${chest.gems} gems',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('NICE'),
          ),
        ],
      ),
    );
  }

  Future<bool> _micAvailable(WidgetRef ref, AppSettings settings) async {
    if (settings.answerMode == AnswerMode.name) return false;
    final source = ref.read(pitchSourceFactoryProvider)();
    try {
      return await source.ensurePermission();
    } catch (_) {
      return false;
    } finally {
      await source.dispose();
    }
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
    final micAvailable = await _micAvailable(ref, settings);
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
  const _Header({required this.progress});

  final ProgressState progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _CounterPill(
          icon: Icons.local_fire_department_rounded,
          value: '${progress.effectiveStreak}',
          color: AppColors.orange,
        ),
        const SizedBox(width: 16),
        _CounterPill(
          icon: Icons.diamond_rounded,
          value: '${progress.gems}',
          color: AppColors.blue,
        ),
        const SizedBox(width: 16),
        _CounterPill(
          icon: Icons.favorite_rounded,
          value: '${progress.hearts}',
          color: AppColors.red,
        ),
      ],
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: value,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(0, 2),
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
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.greenSoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.flag_rounded,
                    size: 15,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Daily goal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$xpToday / $goal XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LessonProgressBar(value: ratio, height: 8),
          const SizedBox(height: 5),
          Text(
            ratio >= 1
                ? 'Goal complete. Nice work today.'
                : xpToday == 0
                ? (mastered == 0
                      ? 'Finish a lesson to start your streak.'
                      : '$mastered notes mastered so far.')
                : '${goal - xpToday} XP to your daily goal.',
            style: const TextStyle(
              fontSize: 11,
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

Color _sectionSoft(int number) => switch (number) {
  2 => AppColors.purpleSoft,
  3 => AppColors.blueSoft,
  _ => AppColors.greenSoft,
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

class _UpNextLabel extends StatelessWidget {
  const _UpNextLabel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 10),
      child: Row(
        children: [
          Icon(
            Icons.keyboard_double_arrow_down_rounded,
            size: 20,
            color: AppColors.textLight,
          ),
          SizedBox(width: 6),
          Text(
            'UP NEXT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.section,
    required this.completed,
    required this.currentLessonId,
    this.onJump,
  });

  final SectionDefinition section;
  final Set<String> completed;
  final String? currentLessonId;
  final VoidCallback? onJump;

  @override
  Widget build(BuildContext context) {
    final lessons = [for (final unit in section.units) ...unit.lessons];
    final done = lessons.where((lesson) => completed.contains(lesson.id)).length;
    final complete = done == lessons.length;
    final current = lessons.any((lesson) => lesson.id == currentLessonId);
    final sectionColor = _sectionColor(section.number);
    final sectionDark = _sectionDark(section.number);

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        color: sectionColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: sectionDark, width: 2),
        boxShadow: [
          BoxShadow(
            color: sectionDark.withValues(alpha: 0.35),
            offset: const Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${section.number}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complete
                      ? 'SECTION ${section.number} · COMPLETE'
                      : 'SECTION ${section.number}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  complete
                      ? 'All lessons finished.'
                      : current
                      ? 'You are here · ${section.subtitle}'
                      : section.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$done/${lessons.length}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (onJump != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onJump,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: sectionDark.withValues(alpha: 0.35),
                          offset: const Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'JUMP HERE?',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: sectionDark,
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
    final sectionSoft = _sectionSoft(section.number);
    // The active unit reads lighter than the section banner so the two
    // stacked headers do not compete.
    final background = complete
        ? AppColors.yellow
        : current
        ? sectionSoft
        : AppColors.surface;
    final foreground = complete
        ? AppColors.ink
        : current
        ? sectionDark
        : AppColors.text;
    final border = complete
        ? AppColors.yellowDark
        : current
        ? sectionColor
        : AppColors.border;
    final chipLabelColor = complete || current
        ? (complete ? AppColors.ink : sectionDark)
        : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: current || complete ? 0.25 : 0.16),
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
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: complete || current ? Colors.white : AppColors.border,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'UNIT ${unit.number}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: chipLabelColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  unit.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: foreground,
                  ),
                ),
              ),
              if (complete)
                Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.yellowDark,
                  size: 22,
                ),
              IconButton(
                onPressed: onGuidebook,
                tooltip: 'Unit guidebook',
                icon: Icon(
                  Icons.menu_book_rounded,
                  size: 21,
                  color: current ? sectionDark : AppColors.textMuted,
                ),
              ),
            ],
          ),
          Text(
            unit.focus,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$done/${unit.lessons.length} lessons',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: unit.lessons.isEmpty
                        ? 0
                        : done / unit.lessons.length,
                    minHeight: 8,
                    backgroundColor: complete || current
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      complete
                          ? AppColors.yellowDark
                          : current
                          ? sectionColor
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
    this.chest,
    this.openedChests = const {},
    this.onChestTap,
  });

  final UnitDefinition unit;
  final int startOffset;
  final Set<String> completed;
  final String? currentLessonId;
  final ValueChanged<LessonDefinition> onLessonTap;
  final ChestDefinition? chest;
  final Set<String> openedChests;
  final ValueChanged<ChestDefinition>? onChestTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chest = this.chest;
        final layout = PathLayout(
          unit: unit,
          width: constraints.maxWidth,
          startOffset: startOffset,
          chestAfterLessonId: chest?.afterLessonId,
        );
        final chestPosition = layout.chestPosition;
        final chestUnlocked =
            chest != null && completed.contains(chest.afterLessonId);
        final accent = _sectionColor(_sectionForUnit(unit).number);
        final mascotNode = layout.nodes
            .where((node) => node.lesson.id == currentLessonId)
            .toList();
        final mascotAt = mascotNode.isEmpty || mascotNode.first.lesson.isReview
            ? null
            : mascotNode.first.position;

        return SizedBox(
          height: layout.height,
          width: constraints.maxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathBackdropPainter(accent: accent),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(
                    nodes: layout.nodes,
                    completed: completed,
                    currentLessonId: currentLessonId,
                    accent: accent,
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
                    accent: accent,
                    onTap: () => onLessonTap(node.lesson),
                  ),
                ),
              if (mascotAt != null)
                Positioned(
                  left: mascotAt.dx + _mascotOffsetX(layout, mascotAt),
                  top: mascotAt.dy - 12,
                  child: IgnorePointer(
                    child: Mascot(size: 56, mood: MascotMood.cheer),
                  ),
                ),
              if (chest != null && chestPosition != null)
                Positioned(
                  left: chestPosition.dx - 29,
                  top: chestPosition.dy - 29,
                  child: _ChestNode(
                    chest: chest,
                    unlocked: chestUnlocked,
                    opened: openedChests.contains(chest.id),
                    onTap: chestUnlocked && onChestTap != null
                        ? () => onChestTap!(chest)
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Places the standing mascot on the side away from the curve so it never
  /// covers the lesson nodes or the START bubble.
  double _mascotOffsetX(PathLayout layout, Offset position) {
    return position.dx <= layout.center
        ? PathLayout.nodeSize / 2 + 6
        : -(PathLayout.nodeSize / 2 + 6 + 52);
  }
}

class _ChestNode extends StatelessWidget {
  const _ChestNode({
    required this.chest,
    required this.unlocked,
    required this.opened,
    required this.onTap,
  });

  final ChestDefinition chest;
  final bool unlocked;
  final bool opened;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = opened
        ? AppColors.surface
        : unlocked
        ? AppColors.yellow
        : AppColors.background;
    final border = opened
        ? AppColors.border
        : unlocked
        ? AppColors.yellowDark
        : AppColors.borderStrong;
    return Semantics(
      button: true,
      label: opened
          ? 'Chest opened'
          : unlocked
          ? 'Open chest'
          : 'Locked chest',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 3),
            boxShadow: [
              BoxShadow(
                color: border.withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(
            opened
                ? Icons.inventory_2_outlined
                : unlocked
                ? Icons.inventory_2_rounded
                : Icons.lock_rounded,
            size: 28,
            color: opened
                ? AppColors.textLight
                : unlocked
                ? Colors.white
                : AppColors.borderStrong,
          ),
        ),
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  const _LessonNode({
    required this.lesson,
    required this.completed,
    required this.current,
    required this.size,
    required this.accent,
    required this.onTap,
  });

  final LessonDefinition lesson;
  final bool completed;
  final bool current;
  final double size;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isReview = lesson.isReview;
    final lockedBorder = Color.lerp(
      AppColors.borderStrong,
      accent,
      0.45,
    )!;
    final (background, border, icon, iconColor) = completed
        ? (
            AppColors.yellow,
            AppColors.yellowDark,
            Icons.star_rounded,
            Colors.white,
          )
        : current
        ? (AppColors.green, AppColors.greenDark, Icons.star_rounded, Colors.white)
        : isReview
        ? (
            AppColors.background,
            AppColors.yellowDark,
            Icons.emoji_events_rounded,
            AppColors.yellowDark,
          )
        : (AppColors.background, lockedBorder, Icons.lock_rounded, accent);

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
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.greenDark,
                              offset: Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Text(
                          'START',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
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
                child: Icon(icon, color: iconColor, size: size * 0.42),
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
    canvas.drawPath(path, Paint()..color = AppColors.green);
  }

  @override
  bool shouldRepaint(covariant _StartTailPainter oldDelegate) => false;
}

/// Soft ambient decoration behind the path so the route does not float on
/// bare white.
class _PathBackdropPainter extends CustomPainter {
  _PathBackdropPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      Offset(size.width * 0.82, size.height * 0.12),
      Offset(size.width * 0.12, size.height * 0.38),
      Offset(size.width * 0.9, size.height * 0.62),
      Offset(size.width * 0.2, size.height * 0.86),
    ];
    final blobRadii = [90.0, 74.0, 96.0, 70.0];
    for (var index = 0; index < blobs.length; index++) {
      canvas.drawCircle(
        blobs[index],
        blobRadii[index],
        Paint()..color = accent.withValues(alpha: 0.05),
      );
    }

    final dot = Paint()..color = accent.withValues(alpha: 0.1);
    final columns = (size.width / 46).ceil();
    final rows = (size.height / 46).ceil();
    for (var column = 0; column <= columns; column++) {
      for (var row = 0; row <= rows; row++) {
        final offset = Offset(
          12 + column * 46 + (row.isOdd ? 18.0 : 0),
          8 + row * 46,
        );
        if (offset.dx < size.width && offset.dy < size.height) {
          canvas.drawCircle(offset, 2.5, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathBackdropPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.nodes,
    required this.completed,
    required this.currentLessonId,
    required this.accent,
  });

  final List<PathNodeLayout> nodes;
  final Set<String> completed;
  final String? currentLessonId;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) return;
    final base = Paint()
      ..color = AppColors.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final progress = Paint()
      ..color = accent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
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
      oldDelegate.accent != accent ||
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
