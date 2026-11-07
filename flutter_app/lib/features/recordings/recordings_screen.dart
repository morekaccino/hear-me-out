import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/media/recording_index.dart';
import '../../core/media/recording_service.dart';
import '../../core/media/take_comparison.dart';
import '../../content/pieces/launch_pieces.dart';
import '../../shared/audio/take_player.dart';
import '../../shared/navigation/duo_route.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/providers.dart';
import '../../state/recording_controller.dart';
import '../before_after/before_after_screen.dart';
import '../profile/privacy_note.dart';
import 'compare_takes_screen.dart';

/// Local-only take recorder and library.
///
/// No audio is uploaded. The screen shows the conditional backup-exclusion
/// copy from [MediaPrivacyCard] before the record controls, so an unconfirmed
/// backup status is never presented as private.
class RecordingsScreen extends ConsumerStatefulWidget {
  const RecordingsScreen({super.key});

  @override
  ConsumerState<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends ConsumerState<RecordingsScreen> {
  late final TakePlayer _player;
  String? _selectedPieceId;

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
    final backup = ref.watch(mediaBackupStatusProvider);
    final state = async.asData?.value;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageFrame(
          maxWidth: 720,
          child: ListView(
            key: const ValueKey('recordings-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _header(canPop),
              const SizedBox(height: DuoSpacing.md),
              MediaPrivacyCard(backup: backup),
              const SizedBox(height: DuoSpacing.md),
              if (async.isLoading && state == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(DuoSpacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state == null)
                _errorState(async.error),
              if (state != null) ...[
                _recordCard(state),
                if (state.failure != null) ...[
                  const SizedBox(height: DuoSpacing.sm),
                  _failureCard(state.failure!),
                ],
                if (state.notice != null) ...[
                  const SizedBox(height: DuoSpacing.sm),
                  _noticeCard(state.notice!),
                ],
                if (hasComparablePiecePair(state.takes)) ...[
                  const SizedBox(height: DuoSpacing.md),
                  _compareCard(),
                ],
                const SizedBox(height: DuoSpacing.md),
                if (state.takes.isEmpty)
                  _emptyState()
                else
                  for (final take in state.takes) ...[
                    _takeCard(
                      take,
                      state.busy || state.recording || state.starting,
                    ),
                    const SizedBox(height: DuoSpacing.sm),
                  ],
                const SizedBox(height: DuoSpacing.md),
                _usageCard(state),
                const SizedBox(height: DuoSpacing.md),
                Text(
                  'Takes are stored as WAV files on this device and are never '
                  'uploaded. Recording quality has not been validated on every '
                  'device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool canPop) {
    return Row(
      children: [
        if (canPop)
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          )
        else
          const SizedBox(width: DuoSpacing.xxs),
        Expanded(
          child: Text(
            'Recordings',
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
            'LOCAL ONLY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.blueDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(Object? error) {
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

  Widget _recordCard(RecordingScreenState state) {
    final status = state.starting
        ? 'Starting the microphone…'
        : state.busy
        ? 'Saving the take…'
        : state.recording
        ? 'Recording — play your guitar.'
        : 'Record a few bars, then listen back.';
    final recording = state.recording;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recording
                    ? Icons.fiber_manual_record_rounded
                    : Icons.mic_rounded,
                color: recording ? AppColors.red : AppColors.greenDark,
                size: 22,
              ),
              const SizedBox(width: DuoSpacing.xs),
              const Expanded(
                child: Text(
                  'New take',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '60 s max',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Text(
            'Link this take to a piece (optional)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                key: const ValueKey('recording-piece'),
                value: _selectedPieceId,
                isExpanded: true,
                hint: const Text('Free take'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Free take'),
                  ),
                  for (final piece in launchPieces)
                    DropdownMenuItem<String?>(
                      value: piece.piece.id,
                      child: Text(
                        piece.piece.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: state.starting || state.recording || state.busy
                    ? null
                    : (value) => setState(() => _selectedPieceId = value),
              ),
            ),
          ),
          const SizedBox(height: DuoSpacing.xs),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: recording ? AppColors.redDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Text(
            '${state.takes.length} of ${state.takeLimit} takes stored',
            key: const ValueKey('recording-record-count'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: DuoSpacing.sm),
          DuoButton(
            key: const ValueKey('record-button'),
            label: recording ? 'STOP' : 'RECORD',
            icon: recording ? Icons.stop_rounded : Icons.mic_rounded,
            color: recording ? AppColors.red : AppColors.green,
            onPressed: state.starting || state.busy
                ? null
                : () {
                    final controller = ref.read(
                      recordingControllerProvider.notifier,
                    );
                    if (recording) {
                      unawaited(controller.stopTake());
                    } else {
                      unawaited(_startRecording(controller));
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _failureCard(RecordingFailure failure) {
    return SectionCard(
      color: AppColors.redSoft,
      borderColor: AppColors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.redDark),
              const SizedBox(width: DuoSpacing.xs),
              Expanded(
                child: Text(
                  failure.message,
                  key: const ValueKey('recording-failure-message'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.redDark,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (failure.kind == RecordingFailureKind.quota) ...[
            const SizedBox(height: DuoSpacing.xs),
            TextButton.icon(
              key: const ValueKey('quota-delete-action'),
              onPressed: _showDeleteSheet,
              style: TextButton.styleFrom(foregroundColor: AppColors.redDark),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('DELETE A TAKE'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noticeCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.greenDark,
            size: 20,
          ),
          const SizedBox(width: DuoSpacing.xs),
          Expanded(
            child: Text(
              message,
              key: const ValueKey('recording-notice'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.greenDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageCard(RecordingScreenState state) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sd_storage_rounded,
                size: 20,
                color: AppColors.blueDark,
              ),
              const SizedBox(width: DuoSpacing.xs),
              const Expanded(
                child: Text(
                  'Local storage',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${state.takes.length} / ${state.takeLimit} takes',
                key: const ValueKey('recording-usage-count'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xs),
          LessonProgressBar(value: state.usageRatio, height: 10),
          const SizedBox(height: 6),
          Text(
            '${_formatBytes(state.usageBytes)} of '
            '${_formatBytes(state.byteLimit)} used.',
            key: const ValueKey('recording-usage-bytes'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Wrap(
            spacing: DuoSpacing.xs,
            runSpacing: DuoSpacing.xxs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                key: const ValueKey('clean-up-recordings'),
                onPressed: state.busy || state.recording
                    ? null
                    : () => unawaited(
                        ref
                            .read(recordingControllerProvider.notifier)
                            .reconcile(),
                      ),
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: const Text('CHECK STORAGE'),
              ),
              TextButton.icon(
                key: const ValueKey('clear-all-recordings'),
                onPressed: state.busy || state.recording || !state.hasTakes
                    ? null
                    : _confirmClearAll,
                style: TextButton.styleFrom(foregroundColor: AppColors.redDark),
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('CLEAR ALL'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compareCard() {
    return SectionCard(
      key: const ValueKey('compare-takes-card'),
      color: AppColors.purpleSoft,
      borderColor: AppColors.purple,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: AppColors.purpleDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hear the change',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compare the first and latest take with matched loudness.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DuoButton(
                key: const ValueKey('compare-takes-open'),
                label: 'COMPARE',
                height: 48,
                color: AppColors.purple,
                fontSize: 13,
                expanded: false,
                onPressed: _openCompare,
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlineDuoButton(
            key: const ValueKey('before-after-open'),
            label: 'PRIVATE BEFORE/AFTER CARD',
            color: AppColors.greenDark,
            onPressed: _openBeforeAfter,
          ),
        ],
      ),
    );
  }

  void _openCompare() {
    unawaited(
      Navigator.of(
        context,
      ).push(duoLessonRoute((context) => const CompareTakesScreen())),
    );
  }

  void _openBeforeAfter() {
    unawaited(
      Navigator.of(
        context,
      ).push(duoLessonRoute((context) => const BeforeAfterScreen())),
    );
  }

  Widget _emptyState() {
    return SectionCard(
      child: Column(
        children: [
          Icon(Icons.graphic_eq_rounded, size: 42, color: AppColors.textLight),
          const SizedBox(height: DuoSpacing.xs),
          const Text(
            'No takes yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Text(
            'Record a phrase or a few bars, then listen back. Takes stay on '
            'this device.',
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

  Widget _takeCard(RecordingTake take, bool busy) {
    return SectionCard(
      key: ValueKey('take-${take.id}'),
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
                  _takeLabel(take),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Wrap(
            spacing: DuoSpacing.sm,
            runSpacing: DuoSpacing.xxs,
            children: [
              Text(
                _formatTimestamp(take.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                _formatBytes(take.byteLength),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              if (take.capped)
                Text(
                  'Stopped at 60 s',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orangeDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Row(
            children: [
              TextButton.icon(
                key: ValueKey('play-take-${take.id}'),
                onPressed: busy ? null : () => unawaited(_play(take)),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('PLAY'),
              ),
              const Spacer(),
              IconButton(
                key: ValueKey('export-take-${take.id}'),
                tooltip: 'Export WAV',
                onPressed: busy ? null : () => unawaited(_export(take)),
                icon: const Icon(Icons.ios_share_rounded),
              ),
              IconButton(
                key: ValueKey('delete-take-${take.id}'),
                tooltip: 'Delete take',
                onPressed: busy ? null : () => unawaited(_delete(take)),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.redDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording(RecordingController controller) async {
    // Never play a stored take into a live microphone.
    await _player.stop();
    if (!mounted) return;
    await controller.startTake(pieceId: _selectedPieceId);
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
    try {
      await ref.read(takePlayerProvider).playWav(bytes);
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

  Future<void> _delete(RecordingTake take) async {
    final failure = await ref
        .read(recordingControllerProvider.notifier)
        .deleteTake(take.id);
    if (!mounted) return;
    _snack(failure?.message ?? 'Take deleted.');
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all takes?'),
        content: const Text(
          'This deletes every local recording. Your progress and settings stay '
          'as they are. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref
        .read(recordingControllerProvider.notifier)
        .clearAll();
    if (!mounted) return;
    _snack(failure?.message ?? 'All takes deleted.');
  }

  Future<void> _showDeleteSheet() async {
    final state = ref.read(recordingControllerProvider).asData?.value;
    if (state == null || state.takes.isEmpty) return;
    final chosen = await showModalBottomSheet<RecordingTake>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Delete a take',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: DuoSpacing.xxs),
            Text(
              'Deleting a take frees one slot. Your other takes are not '
              'changed.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: DuoSpacing.xs),
            for (final take in state.takes)
              ListTile(
                key: ValueKey('quota-delete-${take.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _takeLabel(take),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${_formatDuration(take.durationMs)} · '
                  '${_formatTimestamp(take.createdAt)}',
                ),
                trailing: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.redDark,
                ),
                onTap: () => Navigator.pop(sheetContext, take),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final failure = await ref
        .read(recordingControllerProvider.notifier)
        .deleteTake(chosen.id);
    if (!mounted) return;
    _snack(failure?.message ?? 'Take deleted.');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

String _takeLabel(RecordingTake take) {
  final parts = <String>[
    if (take.pieceId != null) _pieceTitle(take.pieceId!),
    if (take.phraseId != null) _pretty(take.phraseId!),
  ];
  return parts.isEmpty ? 'Free take' : parts.join(' · ');
}

String _pieceTitle(String pieceId) {
  for (final piece in launchPieces) {
    if (piece.piece.id == pieceId) return piece.piece.title;
  }
  return _pretty(pieceId);
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

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  final megabytes = kilobytes / 1024;
  return '${megabytes.toStringAsFixed(1)} MB';
}
