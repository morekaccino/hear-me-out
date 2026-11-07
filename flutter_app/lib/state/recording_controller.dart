import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/media/recording_index.dart';
import '../core/media/recording_service.dart';
import 'app_controller.dart';
import 'providers.dart';
import 'retention_controller.dart';

/// State for the recordings screen.
class RecordingScreenState {
  const RecordingScreenState({
    required this.takes,
    required this.usageBytes,
    required this.takeLimit,
    required this.byteLimit,
    this.recording = false,
    this.starting = false,
    this.busy = false,
    this.failure,
    this.notice,
    this.lastSaved,
  });

  final List<RecordingTake> takes;
  final int usageBytes;
  final int takeLimit;
  final int byteLimit;
  final bool recording;
  final bool starting;
  final bool busy;
  final RecordingFailure? failure;
  final String? notice;
  final RecordingTake? lastSaved;

  bool get hasTakes => takes.isNotEmpty;

  double get usageRatio =>
      byteLimit <= 0 ? 0 : (usageBytes / byteLimit).clamp(0.0, 1.0);

  RecordingScreenState copyWith({
    List<RecordingTake>? takes,
    int? usageBytes,
    bool? recording,
    bool? starting,
    bool? busy,
    RecordingFailure? failure,
    String? notice,
    RecordingTake? lastSaved,
    bool clearFailure = false,
    bool clearNotice = false,
  }) => RecordingScreenState(
    takes: takes ?? this.takes,
    usageBytes: usageBytes ?? this.usageBytes,
    takeLimit: takeLimit,
    byteLimit: byteLimit,
    recording: recording ?? this.recording,
    starting: starting ?? this.starting,
    busy: busy ?? this.busy,
    failure: clearFailure ? null : (failure ?? this.failure),
    notice: clearNotice ? null : (notice ?? this.notice),
    lastSaved: lastSaved ?? this.lastSaved,
  );
}

/// Owns the recordings screen lifecycle: capture, list, delete, export, and
/// orphan reconciliation.
class RecordingController extends AsyncNotifier<RecordingScreenState> {
  late RecordingService _service;
  StreamSubscription<RecordingStopResult>? _autoStops;
  bool _disposed = false;

  @override
  Future<RecordingScreenState> build() async {
    final service = await ref.watch(recordingServiceProvider.future);
    _service = service;
    await _autoStops?.cancel();
    _autoStops = service.autoStopResults.listen(_onAutoStop);
    ref.onDispose(() {
      _disposed = true;
      unawaited(_autoStops?.cancel());
      // The route is gone. Stop and discard a live take so the microphone is
      // never left running behind Practice.
      unawaited(_service.cancel());
    });

    final report = await service.reconcile();
    final takes = await service.listTakes();
    final usage = await service.usageBytes();
    return RecordingScreenState(
      takes: takes,
      usageBytes: usage,
      takeLimit: service.takeLimit,
      byteLimit: service.byteLimit,
      failure: report.failure,
      notice: report.recovered
          ? 'The recording list was rebuilt from stored audio.'
          : null,
    );
  }

  Future<void> startTake({String? pieceId, String? phraseId}) async {
    final current = state.asData?.value ?? await future;
    if (current.recording || current.starting || current.busy) return;
    state = AsyncData(
      current.copyWith(starting: true, clearFailure: true, clearNotice: true),
    );
    final result = await _service.start(pieceId: pieceId, phraseId: phraseId);
    if (_disposed) return;
    if (!result.started) {
      state = AsyncData(
        current.copyWith(
          starting: false,
          failure: result.failure,
          clearNotice: true,
        ),
      );
      return;
    }
    state = AsyncData(
      current.copyWith(
        starting: false,
        recording: true,
        clearFailure: true,
        clearNotice: true,
      ),
    );
  }

  Future<void> stopTake() async {
    final current = state.asData?.value ?? await future;
    if (!current.recording || current.busy) return;
    state = AsyncData(
      current.copyWith(
        recording: false,
        busy: true,
        clearFailure: true,
        clearNotice: true,
      ),
    );
    final result = await _service.stop();
    await _applyStop(result);
  }

  Future<RecordingFailure?> deleteTake(String id) async {
    final current = state.asData?.value ?? await future;
    if (current.busy) return null;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    final failure = await _service.deleteTake(id);
    if (_disposed) return failure;
    final takes = await _service.listTakes();
    final usage = await _service.usageBytes();
    state = AsyncData(
      current.copyWith(
        takes: takes,
        usageBytes: usage,
        busy: false,
        failure: failure,
        clearFailure: failure == null,
        notice: failure == null ? 'Take deleted.' : null,
        clearNotice: failure != null,
      ),
    );
    return failure;
  }

  Future<RecordingFailure?> clearAll() async {
    final current = state.asData?.value ?? await future;
    if (current.busy) return null;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    final failure = await _service.clearAll();
    if (_disposed) return failure;
    final takes = await _service.listTakes();
    final usage = await _service.usageBytes();
    state = AsyncData(
      current.copyWith(
        takes: takes,
        usageBytes: usage,
        busy: false,
        failure: failure,
        clearFailure: failure == null,
        notice: failure == null ? 'All takes deleted.' : null,
        clearNotice: failure != null,
      ),
    );
    return failure;
  }

  Future<RecordingExportOutcome> exportTake(String id) async {
    final outcome = await _service.exportTake(id);
    if (_disposed) return outcome;
    final current = state.asData?.value ?? await future;
    if (outcome.exported) {
      final result = outcome.result!;
      final where = result.path == null
          ? 'Downloaded ${result.fileName}.'
          : 'Exported to ${result.path}';
      state = AsyncData(current.copyWith(clearFailure: true, notice: where));
    } else {
      state = AsyncData(
        current.copyWith(failure: outcome.failure, clearNotice: true),
      );
    }
    return outcome;
  }

  /// Reads bytes for the play button. This never removes the stored take.
  Future<Uint8List?> readTake(String id) => _service.readTake(id);

  /// Re-runs orphan reconciliation. The screen also does this when it opens.
  Future<void> reconcile() async {
    final current = state.asData?.value ?? await future;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    final report = await _service.reconcile();
    if (_disposed) return;
    final takes = await _service.listTakes();
    final usage = await _service.usageBytes();
    state = AsyncData(
      current.copyWith(
        takes: takes,
        usageBytes: usage,
        busy: false,
        failure: report.failure,
        clearFailure: report.failure == null,
        notice: report.failure != null
            ? null
            : report.recovered
            ? 'The recording list was rebuilt from stored audio.'
            : (report.changed ? 'Recording storage checked.' : null),
        clearNotice: report.failure != null,
      ),
    );
  }

  Future<void> _onAutoStop(RecordingStopResult result) async {
    if (_disposed) return;
    await _applyStop(result);
  }

  Future<void> _applyStop(RecordingStopResult result) async {
    // A save that finishes after the route closed is already durable in the
    // service. There is no screen left to update, and its retention/quest hooks
    // are intentionally skipped rather than touching a disposed Ref.
    if (_disposed) return;
    final RecordingScreenState current;
    try {
      current = state.asData?.value ?? await future;
    } catch (_) {
      // The route was disposed while the save was in flight.
      return;
    }
    if (_disposed) return;
    if (!result.saved) {
      state = AsyncData(
        current.copyWith(
          recording: false,
          busy: false,
          failure: result.failure,
          clearNotice: true,
        ),
      );
      return;
    }

    // A committed take changes the durable recording index. Refresh the
    // read-only recap provider here, in the save path, because Today's cadence
    // and the Quests recap pin it across tab switches even when the recorder
    // was opened from Practice. Invalidating only from Today's route cleanup
    // would leave both consumers with the pre-save list.
    ref.invalidate(recordingRecapTakesProvider);
    unawaited(
      ref.read(retentionControllerProvider.notifier).recordFirstRecording(),
    );
    await _recordRecordingQuest();
    await _maybeShowBeforeAfter(result.take);
    final takes = await _service.listTakes();
    final usage = await _service.usageBytes();
    if (_disposed) return;
    state = AsyncData(
      current.copyWith(
        takes: takes,
        usageBytes: usage,
        recording: false,
        starting: false,
        busy: false,
        lastSaved: result.take,
        clearFailure: true,
        notice: result.capped
            ? 'Take saved at the 60-second limit.'
            : 'Take saved on this device.',
      ),
    );
  }

  /// Shows the "Your before/after is ready" local notification after a take
  /// makes the piece's second recording.
  ///
  /// It never fires for the first take, and never when reminders are off. The
  /// take is already saved, so a missing permission or plugin failure is
  /// ignored here instead of turning a successful save into an error.
  Future<void> _maybeShowBeforeAfter(RecordingTake? take) async {
    final pieceId = take?.pieceId;
    if (pieceId == null || pieceId.trim().isEmpty) return;
    try {
      final data = await ref.read(appControllerProvider.future);
      if (!data.progress.settings.reminderEnabled) return;
      final takes = await _service.listTakes();
      final count = takes.where((item) => item.pieceId == pieceId).length;
      if (count < 2) return;
      await ref.read(reminderSchedulerProvider).showBeforeAfterReady(pieceId);
    } catch (_) {
      // The saved take is the user-visible result; the reminder is extra.
    }
  }

  /// Increments the weekly recording quest from a real saved take.
  ///
  /// The take is already stored. A progress failure must not turn it into a
  /// failed recording, so this is best-effort.
  Future<void> _recordRecordingQuest() async {
    try {
      await ref.read(appControllerProvider.future);
      if (_disposed) return;
      await ref.read(appControllerProvider.notifier).recordRecordingMade();
    } catch (_) {
      // The quest is a counter, not the saved take.
    }
  }
}

final recordingControllerProvider =
    AsyncNotifierProvider.autoDispose<
      RecordingController,
      RecordingScreenState
    >(RecordingController.new);
