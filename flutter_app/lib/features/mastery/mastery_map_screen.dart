import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/mastery_map.dart';
import '../../core/media/recording_index.dart';
import '../../shared/audio/sound_service.dart';
import '../../shared/navigation/duo_route.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../state/recording_controller.dart';

/// Opens the performance-mastery map on top of the shell.
Route<void> masteryMapRoute() =>
    duoLessonRoute<void>((_) => const MasteryMapScreen());

/// The honest progress surface: what the learner can play, what is shaky, what
/// they can read, and what comes next.
///
/// There is no lesson-completion percentage here. A can-play row exists only
/// when stored phrase evidence proves performance mastery.
class MasteryMapScreen extends ConsumerStatefulWidget {
  const MasteryMapScreen({super.key});

  @override
  ConsumerState<MasteryMapScreen> createState() => _MasteryMapScreenState();
}

class _MasteryMapScreenState extends ConsumerState<MasteryMapScreen> {
  String? _notice;

  Future<void> _playTake(String takeId) async {
    setState(() => _notice = null);
    try {
      final bytes = await ref
          .read(recordingControllerProvider.notifier)
          .readTake(takeId);
      if (!mounted) return;
      if (bytes == null) {
        setState(() => _notice = 'That take is no longer on this device.');
        return;
      }
      await ref.read(takePlayerProvider).playWav(bytes);
    } catch (_) {
      if (mounted) setState(() => _notice = 'Could not play that take.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final registry = ref.watch(phraseRegistryProvider);
    final takes =
        ref.watch(recordingControllerProvider).asData?.value.takes ??
        const <RecordingTake>[];
    final map = MasteryMap.build(
      progress: data.progress,
      registry: registry,
      takes: takes,
      now: DateTime.now(),
    );

    return Scaffold(
      key: const ValueKey('mastery-map-screen'),
      body: SafeArea(
        bottom: false,
        child: PageFrame(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Header(
                onClose: () {
                  unawaited(
                    ref.read(soundServiceProvider).play(Sfx.uiTapSecondary),
                  );
                  Navigator.of(context).maybePop();
                },
              ),
              if (_notice != null) ...[
                const SizedBox(height: DuoSpacing.xs),
                Text(
                  _notice!,
                  key: const ValueKey('mastery-map-notice'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: DuoSpacing.md),
              _Section(
                title: 'Can play',
                count: '${map.canPlay.length} phrases',
                child: map.canPlay.isEmpty
                    ? const _Empty(
                        'No performance-mastered phrases yet. Play a phrase at '
                        'tempo on three separate days.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final entry in map.canPlay) ...[
                            _CanPlayRow(
                              entry: entry,
                              onPlay: entry.recordingTakeId == null
                                  ? null
                                  : () => _playTake(entry.recordingTakeId!),
                            ),
                            if (entry != map.canPlay.last)
                              const SizedBox(height: DuoSpacing.xs),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: DuoSpacing.sm),
              _Section(
                title: 'Shaky',
                count: '${map.shaky.length} due or fragile',
                child: map.shaky.isEmpty
                    ? const _Empty('Nothing due or fragile right now.')
                    : _Rows(entries: map.shaky),
              ),
              const SizedBox(height: DuoSpacing.sm),
              _Section(
                title: 'Reading',
                count: map.readingTrackedCount == 0
                    ? 'No skills yet'
                    : '${map.readingMasteredCount} of '
                          '${map.readingTrackedCount} skills',
                child: map.reading.isEmpty
                    ? _Empty(
                        map.readingTrackedCount == 0
                            ? 'No reading skills yet. Notes and rhythm practice '
                                  'will appear here.'
                            : 'No reading skills mastered yet.',
                      )
                    : _Rows(entries: map.reading),
              ),
              const SizedBox(height: DuoSpacing.sm),
              _Section(
                title: 'Next',
                count: '${map.next.length} suggestions',
                child: map.next.isEmpty
                    ? const _Empty(
                        'Nothing due right now. Play a phrase when one is '
                        'available.',
                      )
                    : _Rows(entries: map.next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Back',
              child: DuoTappable(
                onTap: onClose,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DuoSpacing.sm),
            Text(
              'MASTERY MAP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.greenDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: DuoSpacing.xs),
        const Text(
          'What you can play',
          key: ValueKey('mastery-map-title'),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          'Progress means you can play it, not that a lesson is complete.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.count,
    required this.child,
  });

  final String title;
  final String count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: DuoSpacing.xs),
              Text(
                count,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.entries});

  final List<MasteryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries) ...[
          _SimpleRow(entry: entry),
          if (entry != entries.last) const SizedBox(height: DuoSpacing.xs),
        ],
      ],
    );
  }
}

class _SimpleRow extends StatelessWidget {
  const _SimpleRow({required this.entry});

  final MasteryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DuoSpacing.sm,
        vertical: DuoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(DuoSpacing.sm),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (entry.subtitle.isNotEmpty)
                  Text(
                    entry.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (entry.tempoBpm != null)
            Text(
              '${entry.tempoBpm} BPM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _CanPlayRow extends StatelessWidget {
  const _CanPlayRow({required this.entry, required this.onPlay});

  final MasteryEntry entry;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('mastery-can-play-${entry.phraseId}'),
      padding: const EdgeInsets.symmetric(
        horizontal: DuoSpacing.sm,
        vertical: DuoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(DuoSpacing.sm),
        border: Border.all(color: AppColors.green, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DuoSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CAN PLAY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (onPlay != null)
                Semantics(
                  button: true,
                  label: 'Play the latest recording of ${entry.title}',
                  child: DuoTappable(
                    key: ValueKey('mastery-play-${entry.phraseId}'),
                    onTap: onPlay!,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.greenDark,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 24,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xs),
          Text(
            entry.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            entry.subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            [
              if (entry.tempoBpm != null) '${entry.tempoBpm} BPM',
              if (entry.date != null) _formatDate(entry.date!),
            ].join(' · '),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

const _months = <String>[
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

String _formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
