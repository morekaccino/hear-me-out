import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/progress.dart';
import '../../core/music/curriculum.dart';
import '../../core/music/guitar.dart';
import '../../core/music/note.dart';
import '../../content/objectives.dart';
import '../../shared/audio/sound_service.dart';
import '../../shared/navigation/duo_route.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../lesson/lesson_screen.dart';
import 'learn_rail.dart';
import 'path_layout.dart';
import 'path_node.dart';

class PathScreen extends ConsumerWidget {
  const PathScreen({super.key, this.onOpenQuests, this.onOpenPractice});

  final VoidCallback? onOpenQuests;
  final VoidCallback? onOpenPractice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final progress = data.progress;
    final now = DateTime.now();
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
            final initialOffset = currentLesson?.unitId == curriculum.first.id
                ? 0.0
                : bannerOffsets[currentLesson?.unitId] ?? 0.0;

            final pathSlivers = <Widget>[
              if (!showRail)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _counterSlot,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DuoSpacing.md,
                        DuoSpacing.sm,
                        DuoSpacing.md,
                        DuoSpacing.xs,
                      ),
                      child: PathCounters(
                        streak: progress.settings.streakEnabled
                            ? progress.effectiveStreak
                            : null,
                        gems: progress.gems,
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DuoSpacing.md,
                    DuoSpacing.xs,
                    DuoSpacing.md,
                    DuoSpacing.sm,
                  ),
                  child: _TodayCard(
                    progress: progress,
                    currentLesson: currentLesson,
                    onContinue: currentLesson == null
                        ? null
                        : () => _launchLesson(context, ref, currentLesson),
                    onReview: onOpenPractice,
                    onCourseMap: () =>
                        _showCourseMap(context, ref, progress),
                  ),
                ),
              ),
              for (final section in sections) ...[
                if (section.number > currentSectionNumber)
                  SliverToBoxAdapter(
                    child: _SectionBreak(
                      section: section,
                      isUpNext: identical(section, nextSection),
                      onJump: () =>
                          _confirmJump(context, ref, section, progress),
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
                        child: RepaintBoundary(
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
                                  progress.completedLessons.contains(
                                    lesson.id,
                                  ) ||
                                  lesson.id == currentLesson?.id;
                              if (!unlocked) {
                                unawaited(
                                  ref
                                      .read(soundServiceProvider)
                                      .play(Sfx.uiLocked),
                                );
                                unawaited(
                                  _showLockedSheet(
                                    context,
                                    ref,
                                    title: 'Lesson locked',
                                    message: currentLesson == null
                                        ? 'Finish the earlier lessons to unlock this one.'
                                        : 'Finish “${currentLesson.title}” first. Lessons unlock one at a time.',
                                    next: currentLesson,
                                    progress: progress,
                                  ),
                                );
                                return;
                              }
                              _launchLesson(context, ref, lesson);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: DuoSpacing.xl)),
              const SliverToBoxAdapter(child: _FooterNote()),
              const SliverToBoxAdapter(child: SizedBox(height: DuoSpacing.xl)),
            ];

            final scroll = _StickyPath(
              initialOffset: initialOffset,
              child: showRail
                  ? CustomScrollView(
                      scrollCacheExtent: const ScrollCacheExtent.pixels(800),
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
                  : CustomScrollView(
                      scrollCacheExtent: const ScrollCacheExtent.pixels(800),
                      slivers: pathSlivers,
                    ),
            );

            return showRail ? scroll : PageFrame(maxWidth: 600, child: scroll);
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

  Future<void> _showCourseMap(
    BuildContext context,
    WidgetRef ref,
    ProgressState progress,
  ) async {
    unawaited(ref.read(soundServiceProvider).play(Sfx.uiSelect));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourseMapSheet(
        progress: progress,
        onUnitTap: (unit) {
          Navigator.pop(context);
          _showGuidebook(context, ref, unit);
        },
      ),
    );
  }

  Future<void> _showLockedSheet(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required ProgressState progress,
    LessonDefinition? next,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(DuoSpacing.md),
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DuoSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.redSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppColors.redDark,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: DuoSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DuoSpacing.sm),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: DuoSpacing.lg),
              if (next != null) ...[
                DuoButton(
                  label: 'START “${next.title.toUpperCase()}”',
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    unawaited(_launchLesson(context, ref, next));
                  },
                  color: AppColors.green,
                ),
                const SizedBox(height: DuoSpacing.xs),
              ],
              OutlineDuoButton(
                label: next == null ? 'GOT IT' : 'NOT NOW',
                onPressed: () => Navigator.pop(sheetContext),
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchLesson(
    BuildContext context,
    WidgetRef ref,
    LessonDefinition lesson,
  ) async {
    unawaited(ref.read(soundServiceProvider).play(Sfx.lessonStart));
    await _openLesson(context, ref, lesson.id);
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
    await Navigator.of(context)
        .push(duoLessonRoute<void>((_) => const LessonScreen()));
  }

  Future<void> _openChest(
    BuildContext context,
    WidgetRef ref,
    ChestDefinition chest,
    ProgressState progress,
  ) async {
    if (!progress.completedLessons.contains(chest.afterLessonId)) {
      unawaited(ref.read(soundServiceProvider).play(Sfx.uiLocked));
      final next = lessonById[chest.afterLessonId];
      await _showLockedSheet(
        context,
        ref,
        title: 'Chest locked',
        message: next == null
            ? 'Finish the earlier lesson to open this chest.'
            : 'Finish “${next.title}” to open this chest.',
        next: next,
        progress: progress,
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
            const SizedBox(width: 8),
            Text(
              '+${chest.gems} gems',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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
    await Navigator.of(context)
        .push(duoLessonRoute<void>((_) => const LessonScreen()));
  }
}

const double _counterSlot = 64;

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
    return PrimaryScrollController(
      controller: _controller,
      child: widget.child,
    );
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

  static const double extent = 80;

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
    return RepaintBoundary(
      child: ColoredBox(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DuoSpacing.md,
            DuoSpacing.xs,
            DuoSpacing.md,
            DuoSpacing.xs,
          ),
          child: _UnitBanner(
            unit: unit,
            section: section,
            onGuidebook: onGuidebook,
            backOffset: backOffset,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _UnitBannerDelegate oldDelegate) =>
      oldDelegate.unit.id != unit.id || oldDelegate.backOffset != backOffset;
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
    final unitColor = duoUnitColor(unit.number);
    final color = unitColor.face;
    final compact = MediaQuery.sizeOf(context).width < 480;
    final guidebookBorder = Border.all(
      color: Colors.white.withValues(alpha: 0.85),
      width: 2,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact
            ? DuoSpacing.xs
            : (backOffset == null ? DuoSpacing.md : DuoSpacing.xs),
        0,
        DuoSpacing.xs,
        0,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: unitColor.dark,
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
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
                    width: 40,
                    height: 40,
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
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DuoSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DuoSpacing.sm),
                      border: guidebookBorder,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: DuoSpacing.xs),
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
          scale: _pressed
              ? widget.scale
              : _hovered
              ? 1.03
              : 1,
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
  static const double _titleSlot = 32;
  static const double _jumpSlot = 56;

  static double heightFor({required bool isUpNext}) =>
      (isUpNext ? _upNextSlot : DuoSpacing.md) + _titleSlot + _jumpSlot;

  @override
  Widget build(BuildContext context) {
    final dark = _sectionDark(section.number);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DuoSpacing.md),
      child: Column(
        children: [
          if (isUpNext)
            const SizedBox(height: _upNextSlot, child: _UpNextLabel())
          else
            const SizedBox(height: DuoSpacing.md),
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
            height: _jumpSlot,
            child: Center(
              child: _Pressable(
                onTap: onJump,
                scale: 0.94,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DuoSpacing.md,
                  ),
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
                  child: RepaintBoundary(
                    child: LessonNode(
                      lesson: node.lesson,
                      completed: completed.contains(node.lesson.id),
                      current: node.lesson.id == currentLessonId,
                      unitNumber: unit.number,
                      index: node.index,
                      onTap: () => onLessonTap(node.lesson),
                    ),
                  ),
                ),
              if (chest != null && chestPosition != null)
                Positioned(
                  left: chestPosition.dx - PathLayout.chestSize / 2,
                  top: chestPosition.dy - PathLayout.chestSize / 2,
                  child: RepaintBoundary(
                    child: ChestNode(
                      chest: chest,
                      unlocked: chestUnlocked,
                      opened: openedChests.contains(chest.id),
                      onTap: chestUnlocked && onChestTap != null
                          ? () => onChestTap!(chest)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CourseMapSheet extends StatelessWidget {
  const _CourseMapSheet({required this.progress, required this.onUnitTap});

  final ProgressState progress;
  final ValueChanged<UnitDefinition> onUnitTap;

  @override
  Widget build(BuildContext context) {
    final completed = progress.completedLessons.length;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        margin: const EdgeInsets.fromLTRB(
          DuoSpacing.md,
          0,
          DuoSpacing.md,
          DuoSpacing.md,
        ),
        padding: const EdgeInsets.fromLTRB(
          DuoSpacing.lg,
          DuoSpacing.md,
          DuoSpacing.lg,
          DuoSpacing.lg,
        ),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DuoSpacing.md),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'COURSE MAP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
                Text(
                  '$completed/${allLessons.length} lessons',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              '8 sections · 40 units · 240 lessons',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: DuoSpacing.sm),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final section in sections) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: DuoSpacing.sm,
                        bottom: DuoSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: duoUnitColor(
                                section.units.first.number,
                              ).face,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${section.number}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              section.title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final unit in section.units)
                      _CourseUnitTile(
                        unit: unit,
                        progress: progress,
                        onTap: () => onUnitTap(unit),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseUnitTile extends StatelessWidget {
  const _CourseUnitTile({
    required this.unit,
    required this.progress,
    required this.onTap,
  });

  final UnitDefinition unit;
  final ProgressState progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = duoUnitColor(unit.number);
    final done = unit.lessons
        .where((lesson) => progress.completedLessons.contains(lesson.id))
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DuoTappable(
        onTap: onTap,
        pressedScale: 0.99,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.face,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${unit.number}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      unit.focus,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$done/6',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: done == 6 ? AppColors.greenDark : AppColors.textMuted,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final concepts = <String>[];
    for (final lesson in unit.lessons) {
      for (final id in lesson.teaches) {
        final question = objectiveCatalog[id]?.data['question'] as String?;
        if (question != null && !concepts.contains(question)) {
          concepts.add(question);
        }
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        margin: const EdgeInsets.fromLTRB(
          DuoSpacing.md,
          0,
          DuoSpacing.md,
          DuoSpacing.md,
        ),
        padding: const EdgeInsets.fromLTRB(
          DuoSpacing.lg,
          DuoSpacing.md,
          DuoSpacing.lg,
          DuoSpacing.lg,
        ),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DuoSpacing.md),
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: DuoSpacing.xs),
            Text(
              unit.focus,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: DuoSpacing.md),
            if (notes.isEmpty && concepts.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: concepts.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DuoSpacing.xs),
                  itemBuilder: (_, index) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DuoSpacing.sm,
                      vertical: DuoSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(DuoSpacing.sm),
                    ),
                    child: Text(
                      concepts[index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              )
            else
              Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notes.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DuoSpacing.xs),
                itemBuilder: (_, index) {
                  final note = notes[index];
                  final position = Guitar.bestPosition(note);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DuoSpacing.sm,
                      vertical: DuoSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: newIds.contains(note.id)
                          ? AppColors.greenSoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(DuoSpacing.sm),
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
                            margin: const EdgeInsets.only(right: DuoSpacing.xs),
                            padding: const EdgeInsets.symmetric(
                              horizontal: DuoSpacing.xs,
                              vertical: DuoSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(
                                DuoSpacing.xxs,
                              ),
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

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.progress,
    required this.currentLesson,
    this.onContinue,
    this.onReview,
    this.onCourseMap,
  });

  final ProgressState progress;
  final LessonDefinition? currentLesson;
  final VoidCallback? onContinue;
  final VoidCallback? onReview;
  final VoidCallback? onCourseMap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = progress.dueSkills(now).length;
    final fragile = progress.fragileSkills(limit: 99).length;
    final goal = progress.settings.weeklyGoalMinutes;
    final minutes = progress.weeklyPracticeMinutes(now);
    final ratio = goal <= 0 ? 0.0 : (minutes / goal).clamp(0.0, 1.0);
    final lessonNumber = currentLesson == null
        ? allLessons.length
        : allLessons.indexWhere((lesson) => lesson.id == currentLesson!.id) + 1;

    return SectionCard(
      color: AppColors.greenSoft,
      borderColor: AppColors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'TODAY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.greenDark,
                ),
              ),
              const Spacer(),
              Text(
                'Lesson $lessonNumber of ${allLessons.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currentLesson == null
                ? 'Course complete'
                : 'Next: ${currentLesson!.title}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          LessonProgressBar(value: ratio, height: 12),
          const SizedBox(height: 4),
          Text(
            '$minutes / $goal min this week',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          if (due > 0 || fragile > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (due > 0)
                  _TodayChip(
                    icon: Icons.event_repeat_rounded,
                    label: '$due due',
                    color: AppColors.blueDark,
                  ),
                if (fragile > 0)
                  _TodayChip(
                    icon: Icons.healing_rounded,
                    label: '$fragile fragile',
                    color: AppColors.redDark,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DuoButton(
                  label: currentLesson == null ? 'REVIEW' : 'CONTINUE',
                  color: AppColors.green,
                  height: 48,
                  onPressed: currentLesson == null ? onReview : onContinue,
                ),
              ),
              if (currentLesson != null && due > 0 && onReview != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlineDuoButton(
                    label: 'REVIEW',
                    onPressed: onReview,
                  ),
                ),
              ],
            ],
          ),
          if (onCourseMap != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onCourseMap,
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text(
                'VIEW COURSE MAP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.greenDark,
                minimumSize: const Size(0, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
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
