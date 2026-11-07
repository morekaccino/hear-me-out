import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/pieces/phrase_objectives.dart';
import '../../core/audio/loudness.dart';
import '../../core/media/recording_index.dart';
import '../../core/media/take_comparison.dart';
import '../../shared/audio/take_player.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/providers.dart';
import '../../state/recording_controller.dart';

/// A/B playback with matched loudness.
///
/// Both sides are read from local storage and normalized in memory before the
/// player sees them. The stored take is never rewritten. The comparison shows
/// the date, length, and the phrase's target tempo when the registry resolves
/// one; it never invents a tempo.
class CompareTakesScreen extends ConsumerStatefulWidget {
  const CompareTakesScreen({super.key, this.registry});

  /// Injectable phrase registry for tests. The app uses
  /// [phraseObjectiveRegistry].
  final PhraseObjectiveRegistry? registry;

  @override
  ConsumerState<CompareTakesScreen> createState() => _CompareTakesScreenState();
}

class _CompareTakesScreenState extends ConsumerState<CompareTakesScreen> {
  late final TakePlayer _player;
  String? _leftId;
  String? _rightId;
  String? _normalizationError;

  @override
  void initState() {
    super.initState();
    _player = ref.read(takePlayerProvider);
  }

  @override
  void dispose() {
    unawaited(_player.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recordingControllerProvider);
    final state = async.asData?.value;
    final takes = state?.takes ?? const <RecordingTake>[];
    final pair = defaultTakeComparisonPair(takes);
    final left = _findTake(takes, _leftId) ?? pair?.left;
    final right = _findTake(takes, _rightId) ?? pair?.right;
    final busy = state == null || state.busy;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageFrame(
          maxWidth: 720,
          child: ListView(
            key: const ValueKey('compare-takes-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _header(),
              const SizedBox(height: DuoSpacing.md),
              _introCard(),
              if (async.isLoading && state == null) ...[
                const SizedBox(height: DuoSpacing.lg),
                const Center(child: CircularProgressIndicator()),
              ] else if (state == null) ...[
                const SizedBox(height: DuoSpacing.md),
                _errorCard(async.error),
              ] else if (left == null || right == null) ...[
                const SizedBox(height: DuoSpacing.md),
                _notEnoughTakes(),
              ] else ...[
                const SizedBox(height: DuoSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final sideBySide = constraints.maxWidth >= 600;
                    final cards = <Widget>[
                      _sideCard(
                        side: 'left',
                        label: 'TAKE A',
                        take: left,
                        takes: takes,
                        busy: busy,
                      ),
                      _sideCard(
                        side: 'right',
                        label: 'TAKE B',
                        take: right,
                        takes: takes,
                        busy: busy,
                      ),
                    ];
                    if (!sideBySide) {
                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: DuoSpacing.sm),
                          cards[1],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: DuoSpacing.sm),
                        Expanded(child: cards[1]),
                      ],
                    );
                  },
                ),
                if (_normalizationError != null) ...[
                  const SizedBox(height: DuoSpacing.sm),
                  _normalizationFailureCard(_normalizationError!),
                ],
                const SizedBox(height: DuoSpacing.md),
                _footerNote(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
        Expanded(
          child: Text(
            'Compare takes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blue, width: 1.5),
          ),
          child: Text(
            'LOUDNESS MATCHED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.blueDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _introCard() {
    return SectionCard(
      color: AppColors.purpleSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.balance_rounded,
            color: AppColors.purpleDark,
            size: 22,
          ),
          const SizedBox(width: DuoSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Same loudness, fair comparison',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: DuoSpacing.xxs),
                Text(
                  'Both takes are normalized before playback. The quieter take '
                  'is boosted and the louder take is turned down, so volume '
                  'does not decide which one sounds better.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(Object? error) {
    return SectionCard(
      color: AppColors.redSoft,
      borderColor: AppColors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recording storage is unavailable.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.redDark,
            ),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Text(
            error?.toString() ?? 'Try reopening the screen.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.redDark,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notEnoughTakes() {
    return SectionCard(
      key: const ValueKey('compare-not-enough-takes'),
      child: Column(
        children: [
          Icon(
            Icons.compare_arrows_rounded,
            size: 42,
            color: AppColors.textLight,
          ),
          const SizedBox(height: DuoSpacing.xs),
          const Text(
            'At least two takes are needed',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Text(
            'Record the same piece twice, then come back to hear them at the '
            'same loudness. Takes stay on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _normalizationFailureCard(String message) {
    return SectionCard(
      key: const ValueKey('compare-normalization-error'),
      color: AppColors.redSoft,
      borderColor: AppColors.red,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.redDark),
          const SizedBox(width: DuoSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.redDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideCard({
    required String side,
    required String label,
    required RecordingTake take,
    required List<RecordingTake> takes,
    required bool busy,
  }) {
    return SectionCard(
      key: ValueKey('compare-card-$side'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.purpleSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.audiotrack_rounded,
                  color: AppColors.purpleDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: DuoSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Text(
                  _formatDuration(take.durationMs),
                  key: ValueKey('compare-length-$side'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: ValueKey('compare-$side-take'),
                value: take.id,
                isExpanded: true,
                mouseCursor: SystemMouseCursors.click,
                items: <DropdownMenuItem<String>>[
                  for (final option in takes)
                    DropdownMenuItem<String>(
                      value: option.id,
                      child: Text(
                        _selectorLabel(option),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          if (side == 'left') {
                            _leftId = value;
                          } else {
                            _rightId = value;
                          }
                          _normalizationError = null;
                        });
                      },
              ),
            ),
          ),
          const SizedBox(height: DuoSpacing.xs),
          _detailRow(
            icon: Icons.event_rounded,
            label: 'Recorded',
            value: _formatTimestamp(take.createdAt),
            key: ValueKey('compare-date-$side'),
          ),
          const SizedBox(height: 6),
          _detailRow(
            icon: Icons.timer_outlined,
            label: 'Length',
            value: _formatDuration(take.durationMs),
            key: ValueKey('compare-duration-$side'),
          ),
          const SizedBox(height: 6),
          _detailRow(
            icon: Icons.speed_rounded,
            label: 'Tempo',
            value: _tempoLabel(take),
            key: ValueKey('compare-tempo-$side'),
          ),
          const SizedBox(height: DuoSpacing.sm),
          DuoButton(
            key: ValueKey('compare-play-$side'),
            label: side == 'left' ? 'PLAY A' : 'PLAY B',
            icon: Icons.play_arrow_rounded,
            height: 48,
            fontSize: 15,
            onPressed: busy ? null : () => unawaited(_play(take)),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  key: ValueKey('compare-export-$side'),
                  onPressed: busy ? null : () => unawaited(_export(take)),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('EXPORT'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  key: ValueKey('compare-delete-$side'),
                  onPressed: busy ? null : () => unawaited(_confirmDelete(take)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.redDark,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('DELETE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Key key,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            key: key,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _footerNote() {
    return Text(
      'Playback uses local files only. Normalization happens in memory and '
      'never changes the stored take.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textLight,
      ),
    );
  }

  RecordingTake? _findTake(List<RecordingTake> takes, String? id) {
    if (id == null) return null;
    for (final take in takes) {
      if (take.id == id) return take;
    }
    return null;
  }

  String _tempoLabel(RecordingTake take) {
    final phraseId = take.phraseId;
    if (phraseId == null) return 'Tempo not captured';
    final record = (widget.registry ?? phraseObjectiveRegistry).recordFor(
      phraseId,
    );
    final tempo = record?.phrase.targetTempoBpm;
    if (tempo == null || tempo <= 0) return 'Tempo not captured';
    return 'Target $tempo BPM';
  }

  Future<void> _play(RecordingTake take) async {
    final bytes = await ref
        .read(recordingControllerProvider.notifier)
        .readTake(take.id);
    if (!mounted) return;
    if (bytes == null) {
      _snack('That take is no longer stored.');
      return;
    }

    final Uint8List normalized;
    try {
      normalized = normalizeWavLoudness(bytes);
    } on LoudnessNormalizationException {
      if (!mounted) return;
      setState(() => _normalizationError = 'This take could not be normalized.');
      _snack('This take could not be normalized.');
      return;
    }
    if (_normalizationError != null) {
      setState(() => _normalizationError = null);
    }
    try {
      await ref.read(takePlayerProvider).playWav(normalized);
    } catch (_) {
      if (mounted) _snack('Could not play the take.');
    }
  }

  Future<void> _export(RecordingTake take) async {
    final outcome = await ref
        .read(recordingControllerProvider.notifier)
        .exportTake(take.id);
    if (!mounted) return;
    final result = outcome.result;
    if (result == null) {
      _snack(outcome.failure?.message ?? 'Could not export the take.');
      return;
    }
    _snack(
      result.path == null
          ? 'Downloaded ${result.fileName}.'
          : 'Exported to ${result.path}',
    );
  }

  Future<void> _confirmDelete(RecordingTake take) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this take?'),
        content: Text(
          '${_takeLabel(take)} from ${_formatTimestamp(take.createdAt)} will '
          'be removed from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref
        .read(recordingControllerProvider.notifier)
        .deleteTake(take.id);
    if (!mounted) return;
    _snack(failure?.message ?? 'Take deleted.');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _selectorLabel(RecordingTake take) =>
    '${_takeLabel(take)} · ${_formatTimestamp(take.createdAt)}';

String _takeLabel(RecordingTake take) {
  final parts = <String>[
    if (take.pieceId != null) _pretty(take.pieceId!),
    if (take.phraseId != null) _pretty(take.phraseId!),
  ];
  return parts.isEmpty ? 'Free take' : parts.join(' · ');
}

String _pretty(String value) {
  final words = value
      .replaceAll(RegExp(r'[-_]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'));
  return words
      .where((word) => word.isNotEmpty)
      .map(
        (word) => word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String _formatTimestamp(DateTime utc) {
  final local = utc.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _formatDuration(int durationMs) {
  final totalSeconds = (durationMs / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
