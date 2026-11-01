import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/progress.dart';
import '../../core/music/curriculum.dart';
import '../../core/music/guitar.dart';
import '../../core/music/note.dart';
import '../../shared/audio/sound_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../lesson/lesson_screen.dart';
import 'learn_rail.dart';
import 'path_layout.dart';

class PathScreen extends ConsumerWidget {
  const PathScreen({super.key, this.onOpenQuests});

  final VoidCallback? onOpenQuests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final progress = data.progress;
    final now = DateTime.now();
    progress.refreshHearts(now);
    progress.refreshDaily(now);
    final currentLesson = _currentLesson(progress.completedLessons);
    final nextSection = _nextSectionAfter(currentLesson);
    final currentSectionNumber = _sectionNumberOf(currentLesson);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showRail = constraints.maxWidth >= 960;
            final railWidth = constraints.maxWidth >= 1180 ? 372.0 : 320.0;
            final pathWidth = math.min(
              600.0,
              constraints.maxWidth - railWidth - 22 - 24,
            );
            final bannerOffsets = _bannerOffsets(
              currentLesson: currentLesson,
              showCounters: !showRail,
            );
            final initialOffset =
                currentLesson?.unitId == curriculum.first.id
                ? 0.0
                : bannerOffsets[currentLesson?.unitId] ?? 0.0;

            final pathSlivers = <Widget>[
              if (!showRail)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _counterSlot,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                      child: PathCounters(
                        streak: progress.effectiveStreak,
                        gems: progress.gems,
                        hearts: progress.hearts,
                      ),
                    ),
                  ),
                ),
              for (final section in sections) ...[
                if (section.number > currentSectionNumber)
                  SliverToBoxAdapter(
                    child: _SectionBreak(
                      section: section,
                      isUpNext: identical(section, nextSection),
                      onJump: () => _confirmJump(
                        context,
                        ref,
                        section,
                        progress,
                      ),
                    ),
                  ),
                for (final unit in section.units)
                  SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _UnitBannerDelegate(
                          unit: unit,
                          backOffset: _backOffsetFor(unit, bannerOffsets),
                          onGuidebook: () => _showGuidebook(context, ref, unit),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _LessonPath(
                          unit: unit,
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
                                ref
                                    .read(soundServiceProvider)
                                    .play(Sfx.uiLocked),
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
                      ),
                    ],
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              const SliverToBoxAdapter(child: _FooterNote()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ];

            final scroll = _StickyPath(
              initialOffset: initialOffset,
              child: showRail
                  ? CustomScrollView(
                      slivers: [
                        SliverCrossAxisGroup(
                          slivers: [
                            SliverCrossAxisExpanded(
                              flex: 1,
                              sliver: const SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              ),
                            ),
                            SliverConstrainedCrossAxis(
                              maxExtent: pathWidth,
                              sliver: SliverMainAxisGroup(slivers: pathSlivers),
                            ),
                            const SliverConstrainedCrossAxis(
                              maxExtent: 22,
                              sliver: SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              ),
                            ),
                            SliverConstrainedCrossAxis(
                              maxExtent: railWidth,
                              sliver: SliverToBoxAdapter(
                                child: LearnRail(
                                  progress: progress,
                                  onOpenQuests: onOpenQuests,
                                ),
                              ),
                            ),
                            SliverCrossAxisExpanded(
                              flex: 1,
                              sliver: const SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : CustomScrollView(slivers: pathSlivers),
            );

            return showRail
                ? scroll
                : PageFrame(maxWidth: 600, child: scroll);
          },
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

  int _sectionNumberOf(LessonDefinition? currentLesson) {
    if (currentLesson == null) return sections.length + 1;
    for (final section in sections) {
      if (section.units.any(
        (unit) => unit.lessons.any((lesson) => lesson.id == currentLesson.id),
      )) {
        return section.number;
      }
    }
    return 1;
  }

  /// Scroll offset of each unit banner. Height is independent of width, so
  /// these offsets match the sliver extents exactly.
  Map<String, double> _bannerOffsets({
    required LessonDefinition? currentLesson,
    required bool showCounters,
  }) {
    final currentSection = _sectionNumberOf(currentLesson);
    final next = _nextSectionAfter(currentLesson);
    var offset = 0.0;
    final offsets = <String, double>{};
    for (final section in sections) {
      if (section.number > currentSection) {
        offset += _SectionBreak.heightFor(isUpNext: identical(section, next));
      }
      for (final unit in section.units) {
        offsets[unit.id] = offset;
        offset += _UnitBannerDelegate.extent;
        offset += _unitPathHeight(unit, currentLesson?.id);
      }
    }
    if (showCounters) {
      for (final key in offsets.keys) {
        offsets[key] = offsets[key]! + _counterSlot;
      }
    }
    return offsets;
  }

  double? _backOffsetFor(UnitDefinition unit, Map<String, double> offsets) {
    final index = curriculum.indexWhere((candidate) => candidate.id == unit.id);
    if (index <= 0) return null;
    return offsets[curriculum[index - 1].id];
  }

  double _unitPathHeight(UnitDefinition unit, String? currentLessonId) {
    return PathLayout(
      unit: unit,
      width: 400,
      startOffset: _unitStartOffset(unit),
      chestAfterLessonId: chestForUnit(unit.id)?.afterLessonId,
      currentLessonId: currentLessonId,
    ).height;
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

const double _counterSlot = 56;

class _StickyPath extends StatefulWidget {
  const _StickyPath({required this.initialOffset, required this.child});

  final double initialOffset;
  final Widget child;

  @override
  State<_StickyPath> createState() => _StickyPathState();
}

class _StickyPathState extends State<_StickyPath> {
  final _controller = ScrollController();
  var _jumped = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialOffset <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _jumped || !_controller.hasClients) return;
      _jumped = true;
      final max = _controller.position.maxScrollExtent;
      _controller.jumpTo(widget.initialOffset.clamp(0.0, max));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(controller: _controller, child: widget.child);
  }
}

class _UnitBannerDelegate extends SliverPersistentHeaderDelegate {
  _UnitBannerDelegate({
    required this.unit,
    required this.onGuidebook,
    this.backOffset,
  });

  final UnitDefinition unit;
  final VoidCallback onGuidebook;
  final double? backOffset;

  static const double extent = 88;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final section = _sectionForUnit(unit);
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: _UnitBanner(
          unit: unit,
          section: section,
          onGuidebook: onGuidebook,
          backOffset: backOffset,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _UnitBannerDelegate oldDelegate) =>
      oldDelegate.unit.id != unit.id ||
      oldDelegate.backOffset != backOffset;
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({
    required this.unit,
    required this.section,
    required this.onGuidebook,
    this.backOffset,
  });

  final UnitDefinition unit;
  final SectionDefinition section;
  final VoidCallback onGuidebook;
  final double? backOffset;

  void _back(BuildContext context) {
    final position = Scrollable.of(context).position;
    position.animateTo(
      backOffset!.clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = duoUnitColor(unit.number).face;
    final compact = MediaQuery.sizeOf(context).width < 480;
    final guidebookBorder = Border.all(
      color: Colors.white.withValues(alpha: 0.85),
      width: 2,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : (backOffset == null ? 18 : 10),
        0,
        8,
        0,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (backOffset != null)
            _Pressable(
              onTap: () => _back(context),
              scale: 0.9,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 8,
                  vertical: 20,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: compact ? 22 : 24,
                  color: Colors.white,
                ),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECTION ${section.number}, UNIT ${unit.number}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  unit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _Pressable(
            onTap: onGuidebook,
            scale: 0.94,
            child: compact
                ? Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: guidebookBorder,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: guidebookBorder,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'GUIDEBOOK',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.onTap,
    required this.child,
    this.scale = 0.95,
  });

  final VoidCallback onTap;
  final Widget child;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : _hovered ? 1.03 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class _SectionBreak extends StatelessWidget {
  const _SectionBreak({
    required this.section,
    required this.isUpNext,
    required this.onJump,
  });

  final SectionDefinition section;
  final bool isUpNext;
  final VoidCallback onJump;

  static const double _upNextSlot = 40;
  static const double _titleSlot = 28;

  static double heightFor({required bool isUpNext}) =>
      (isUpNext ? _upNextSlot : 12) + _titleSlot + 54;

  @override
  Widget build(BuildContext context) {
    final dark = _sectionDark(section.number);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Column(
        children: [
          if (isUpNext)
            const SizedBox(
              height: _upNextSlot,
              child: _UpNextLabel(),
            )
          else
            const SizedBox(height: 12),
          SizedBox(
            height: _titleSlot,
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.border,
                    thickness: 2,
                    height: 2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.border,
                    thickness: 2,
                    height: 2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            child: Center(
              child: _Pressable(
                onTap: onJump,
                scale: 0.94,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dark, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'JUMP HERE?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: dark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _sectionDark(int number) => switch (number) {
  2 => AppColors.purpleDark,
  3 => AppColors.blueDark,
  _ => AppColors.greenDark,
};

int _unitStartOffset(UnitDefinition unit) {
  var count = 0;
  for (final candidate in curriculum) {
    if (candidate.id == unit.id) break;
    count += candidate.lessons.length;
  }
  return count;
}

SectionDefinition _sectionForUnit(UnitDefinition unit) => sections.firstWhere(
  (section) => section.units.any((candidate) => candidate.id == unit.id),
);

class _UpNextLabel extends StatelessWidget {
  const _UpNextLabel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Up next',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textLight,
        ),
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
    this.chest,
    this.openedChests = const {},
    this.onChestTap,
  });

  final UnitDefinition unit;
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
          startOffset: _unitStartOffset(unit),
          chestAfterLessonId: chest?.afterLessonId,
          currentLessonId: currentLessonId,
        );
        final chestPosition = layout.chestPosition;
        final chestUnlocked =
            chest != null && completed.contains(chest.afterLessonId);
        final unitColor = duoUnitColor(unit.number);
        final accent = unitColor.face;
        final accentDark = unitColor.dark;

        return SizedBox(
          height: layout.height,
          width: constraints.maxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final node in layout.nodes)
                Positioned(
                  left: node.position.dx - PathLayout.nodeSize / 2,
                  top: node.position.dy - PathLayout.nodeHeight / 2,
                  child: _LessonNode(
                    lesson: node.lesson,
                    completed: completed.contains(node.lesson.id),
                    current: node.lesson.id == currentLessonId,
                    accent: accent,
                    accentDark: accentDark,
                    onTap: () => onLessonTap(node.lesson),
                  ),
                ),
              if (chest != null && chestPosition != null)
                Positioned(
                  left: chestPosition.dx - PathLayout.chestSize / 2,
                  top: chestPosition.dy - PathLayout.chestSize / 2,
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
        child: CustomPaint(
          size: const Size(
            PathLayout.chestSize,
            PathLayout.chestSize,
          ),
          painter: _ChestPainter(opened: opened, unlocked: unlocked),
        ),
      ),
    );
  }
}

class _LessonNode extends StatefulWidget {
  const _LessonNode({
    required this.lesson,
    required this.completed,
    required this.current,
    required this.accent,
    required this.accentDark,
    required this.onTap,
  });

  final LessonDefinition lesson;
  final bool completed;
  final bool current;
  final Color accent;
  final Color accentDark;
  final VoidCallback onTap;

  @override
  State<_LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<_LessonNode> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isReview = widget.lesson.isReview;
    final reached = widget.completed || widget.current;
    final face = reached ? widget.accent : AppColors.border;
    final base = Color.lerp(face, Colors.black, 0.1)!;
    final hoverFace = Color.lerp(
      face,
      Colors.white,
      AppColors.isDark ? 0.08 : 0.06,
    )!;
    final markColor = reached ? Colors.white : AppColors.textLight;
    const width = PathLayout.nodeSize;
    const height = PathLayout.faceHeight;
    const baseTop = PathLayout.nodeHeight - PathLayout.faceHeight;
    final ellipse = BorderRadius.all(
      Radius.elliptical(width / 2, height / 2),
    );

    final node = SizedBox(
      width: width,
      height: PathLayout.nodeHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (widget.current) ...[
            Positioned(
              top: -5,
              child: Container(
                width: width + 12,
                height: height + 13,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.all(
                    Radius.elliptical((width + 12) / 2, (height + 13) / 2),
                  ),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
              ),
            ),
            Positioned(
              top: -44,
              left: -28,
              right: -28,
              child: Center(
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentDark,
                              offset: const Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Text(
                          'START',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(14, 7),
                        painter: _StartTailPainter(widget.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Positioned(
            top: baseTop,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(color: base, borderRadius: ellipse),
            ),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              label: isReview
                  ? 'Unit checkpoint: ${widget.lesson.title}'
                  : 'Lesson: ${widget.lesson.title}',
              excludeSemantics: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: GestureDetector(
                  key: widget.current
                      ? const ValueKey('current-lesson-node')
                      : null,
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTap: widget.onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: _hovered ? hoverFace : face,
                      borderRadius: ellipse,
                    ),
                    child: Icon(
                      isReview
                          ? Icons.emoji_events_rounded
                          : widget.current
                          ? Icons.star_rounded
                          : Icons.music_note_rounded,
                      color: markColor,
                      size: widget.current ? 36 : 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.88 + 0.12 * value, child: child),
      ),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : _hovered ? 1.04 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.current ? _Bobbing(child: node) : node,
      ),
    );
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
  const _StartTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StartTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ChestPainter extends CustomPainter {
  const _ChestPainter({required this.opened, required this.unlocked});

  final bool opened;
  final bool unlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final body = unlocked
        ? AppColors.yellow
        : opened
        ? AppColors.surface
        : AppColors.border;
    final edge = unlocked
        ? AppColors.yellowDark
        : opened
        ? AppColors.borderStrong
        : AppColors.textLight;

    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.14, height * 0.24, width * 0.72, height * 0.26),
      const Radius.circular(7),
    );
    canvas
      ..drawCircle(
        Offset(width / 2, height / 2),
        width / 2,
        Paint()..color = AppColors.background,
      )
      ..drawRRect(lid.shift(const Offset(0, 3)), Paint()..color = edge)
      ..drawRRect(lid, Paint()..color = body)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            width * 0.14,
            height * 0.48,
            width * 0.72,
            height * 0.3,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = body,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            width * 0.42,
            height * 0.45,
            width * 0.16,
            height * 0.2,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = edge,
      );
    if (opened) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            width * 0.2,
            height * 0.52,
            width * 0.6,
            height * 0.22,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = AppColors.background,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChestPainter oldDelegate) =>
      oldDelegate.opened != opened || oldDelegate.unlocked != unlocked;
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
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: duoUnitColor(unit.number).dark,
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
              style: TextStyle(
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
                            style: TextStyle(
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
    return Padding(
      padding: const EdgeInsets.only(top: 4),
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
