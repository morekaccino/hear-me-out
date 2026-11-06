// Dependencies stay private, so the public named parameters cannot be
// initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:typed_data';

import '../audio/phrase_recorder.dart';
import 'media_store.dart';
import 'recording_encoder.dart';
import 'recording_exporter.dart';
import 'recording_index.dart';
import 'recording_index_store.dart';

/// Why a recording operation could not complete.
enum RecordingFailureKind {
  permissionDenied,
  busy,
  quota,
  storage,
  notRecording,
  emptyTake,
  missingTake,
  export,
  capture,
}

/// Typed failure returned by [RecordingService]. Expected failures never
/// escape as an unhandled exception, so the UI can always show a calm message.
class RecordingFailure implements Exception {
  const RecordingFailure(this.kind, this.message, {this.cause});

  final RecordingFailureKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'RecordingFailure(${kind.name}: $message)';
}

/// Result of [RecordingService.start].
class RecordingStartResult {
  const RecordingStartResult.started() : failure = null;
  const RecordingStartResult.failed(this.failure);

  final RecordingFailure? failure;

  bool get started => failure == null;
}

/// Result of [RecordingService.stop].
class RecordingStopResult {
  const RecordingStopResult.saved({required this.take, required this.capped})
    : failure = null;

  const RecordingStopResult.failed(this.failure) : take = null, capped = false;

  final RecordingTake? take;
  final RecordingFailure? failure;
  final bool capped;

  bool get saved => take != null;
}

/// Result of [RecordingService.exportTake].
class RecordingExportOutcome {
  const RecordingExportOutcome.success(this.result) : failure = null;
  const RecordingExportOutcome.failed(this.failure) : result = null;

  final RecordingExportResult? result;
  final RecordingFailure? failure;

  bool get exported => result != null;
}

/// Summary of [RecordingService.reconcile].
class RecordingReconcileReport {
  const RecordingReconcileReport({
    this.removedIndexEntries = 0,
    this.deletedOrphans = 0,
    this.adoptedBlobs = 0,
    this.recovered = false,
    this.failure,
  });

  final int removedIndexEntries;
  final int deletedOrphans;
  final int adoptedBlobs;

  /// True when the index document was missing or unreadable and the app
  /// adopted the existing blobs instead of deleting them.
  final bool recovered;
  final RecordingFailure? failure;

  bool get changed =>
      removedIndexEntries > 0 ||
      deletedOrphans > 0 ||
      adoptedBlobs > 0 ||
      recovered;
}

/// A cancellable one-shot timer. Tests inject a fake so the 60-second cap does
/// not require a real wait.
abstract interface class RecordingTimer {
  void cancel();
}

typedef RecordingTimerFactory = RecordingTimer Function(
  Duration duration,
  void Function() callback,
);

RecordingTimer _realTimer(Duration duration, void Function() callback) =>
    _RealRecordingTimer(Timer(duration, callback));

class _RealRecordingTimer implements RecordingTimer {
  _RealRecordingTimer(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

/// Records one bounded WAV take, stores it locally, and applies retention.
///
/// The service owns at most one [PhraseRecorder] at a time. It never opens a
/// second capture while one is live, which matters because the platform
/// recorder is a single shared resource. Analysis and storage are separate
/// steps: the take is decoded once, encoded as PCM16 WAV, and written to
/// [MediaStore]. There is no simultaneous record and stream on the same
/// recorder.
class RecordingService {
  RecordingService({
    required MediaStore store,
    required RecordingIndexStore indexStore,
    required RecordingExporter exporter,
    required DateTime Function() clock,
    required PhraseRecorder Function() recorderFactory,
    RecordingEncoder encoder = const WavRecordingEncoder(),
    RecordingTimerFactory timerFactory = _realTimer,
    this.maxTakeDuration = defaultTakeDuration,
    this.takeLimit = defaultTakeLimit,
    this.byteLimit = defaultByteLimit,
    this.pieceTakeLimit = defaultPieceTakeLimit,
  }) : _store = store,
       _indexStore = indexStore,
       _exporter = exporter,
       _clock = clock,
       _recorderFactory = recorderFactory,
       _encoder = encoder,
       _timerFactory = timerFactory,
       assert(takeLimit > 0),
       assert(byteLimit > 0),
       assert(pieceTakeLimit > 0);

  /// A take is capped at 60 seconds.
  static const Duration defaultTakeDuration = Duration(seconds: 60);

  /// The global take cap. The first and last take per piece are protected by
  /// [pieceTakeLimit], but the global count still stops unbounded storage.
  static const int defaultTakeLimit = 20;

  /// WAV storage is bounded to roughly 200 MB.
  static const int defaultByteLimit = 200 * 1024 * 1024;

  /// Keep the first and last take per piece. A middle take is deleted when a
  /// new take for the same piece would exceed this set.
  static const int defaultPieceTakeLimit = 2;

  final MediaStore _store;
  final RecordingIndexStore _indexStore;
  final RecordingExporter _exporter;
  final DateTime Function() _clock;
  final PhraseRecorder Function() _recorderFactory;
  final RecordingEncoder _encoder;
  final RecordingTimerFactory _timerFactory;

  final Duration maxTakeDuration;
  final int takeLimit;
  final int byteLimit;
  final int pieceTakeLimit;

  final StreamController<RecordingStopResult> _autoStopController =
      StreamController<RecordingStopResult>.broadcast();

  PhraseRecorder? _recorder;
  RecordingTimer? _timer;
  String? _pieceId;
  String? _phraseId;
  bool _recording = false;
  bool _starting = false;
  bool _finishing = false;
  bool _disposed = false;
  int _generation = 0;

  bool get isRecording => _recording;

  /// Emits the result when the 60-second timer stops a take on its own.
  Stream<RecordingStopResult> get autoStopResults => _autoStopController.stream;

  /// Starts one take. A second call while a take is live returns a typed busy
  /// failure and never opens a second capture.
  Future<RecordingStartResult> start({
    String? pieceId,
    String? phraseId,
  }) async {
    if (_disposed) throw StateError('RecordingService has been disposed');
    if (_recording || _starting || _finishing) {
      return const RecordingStartResult.failed(
        RecordingFailure(
          RecordingFailureKind.busy,
          'A take is already recording. Stop it before starting another.',
        ),
      );
    }

    _starting = true;
    final generation = ++_generation;
    try {
      final index = await _loadIndex();
      if (generation != _generation) {
        return _startFailed(_cancelledFailure());
      }
      if (index.length >= takeLimit) {
        return _startFailed(_quotaFailure());
      }
      final usage = await _store.usageBytes();
      if (generation != _generation) {
        return _startFailed(_cancelledFailure());
      }
      if (usage >= byteLimit) {
        return _startFailed(_byteQuotaFailure());
      }

      PhraseRecorder? recorder;
      try {
        recorder = _recorderFactory();
        final started = await recorder.start();
        if (generation != _generation) {
          await recorder.dispose();
          return _startFailed(_cancelledFailure());
        }
        if (!started) {
          await recorder.dispose();
          return _startFailed(
            const RecordingFailure(
              RecordingFailureKind.permissionDenied,
              'Microphone unavailable. Check your permissions, then try again.',
            ),
          );
        }
      } catch (error) {
        if (recorder != null) await recorder.dispose();
        return _startFailed(
          RecordingFailure(
            RecordingFailureKind.capture,
            'Could not start the microphone.',
            cause: error,
          ),
        );
      }

      if (generation != _generation) {
        await recorder.dispose();
        return _startFailed(_cancelledFailure());
      }

      _pieceId = pieceId;
      _phraseId = phraseId;
      final RecordingTimer timer;
      try {
        timer = _timerFactory(maxTakeDuration, () {
          unawaited(_autoStop());
        });
      } catch (error) {
        await recorder.dispose();
        return _startFailed(
          RecordingFailure(
            RecordingFailureKind.capture,
            'Could not start the take timer.',
            cause: error,
          ),
        );
      }
      if (generation != _generation) {
        timer.cancel();
        await recorder.dispose();
        return _startFailed(_cancelledFailure());
      }
      _recorder = recorder;
      _recording = true;
      _timer = timer;
      return const RecordingStartResult.started();
    } catch (error) {
      return _startFailed(
        RecordingFailure(
          RecordingFailureKind.storage,
          'Could not check local recording storage.',
          cause: error,
        ),
      );
    } finally {
      _starting = false;
    }
  }

  /// Stops the live take, encodes it as WAV, and stores it.
  ///
  /// [capped] marks a take stopped by the length timer. Samples beyond
  /// [maxTakeDuration] are truncated even when the timer did not fire.
  Future<RecordingStopResult> stop({bool capped = false}) async {
    if (_finishing) {
      return const RecordingStopResult.failed(
        RecordingFailure(
          RecordingFailureKind.busy,
          'The take is still being saved.',
        ),
      );
    }

    final recorder = _recorder;
    if (recorder == null) {
      return const RecordingStopResult.failed(
        RecordingFailure(
          RecordingFailureKind.notRecording,
          'No take is recording.',
        ),
      );
    }

    _finishing = true;
    _recording = false;
    _recorder = null;
    _timer?.cancel();
    _timer = null;

    PhraseTake take;
    try {
      take = await recorder.stop();
    } catch (error) {
      await recorder.dispose();
      _finishing = false;
      return RecordingStopResult.failed(
        RecordingFailure(
          RecordingFailureKind.capture,
          'Could not read the take. Try again.',
          cause: error,
        ),
      );
    }
    await recorder.dispose();

    try {
      return await _storeTake(take, capped: capped);
    } finally {
      _pieceId = null;
      _phraseId = null;
      _finishing = false;
    }
  }

  /// Stops a live take and discards it without saving.
  ///
  /// The recordings screen calls this when its route is popped so the platform
  /// microphone is never left running behind the Practice screen. A take that
  /// is already being saved is left alone; [stop] owns that path.
  Future<void> cancel() async {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _recording = false;
    final recorder = _recorder;
    _recorder = null;
    _pieceId = null;
    _phraseId = null;
    if (recorder == null) return;
    try {
      await recorder.dispose();
    } catch (_) {
      // The platform recorder may already be released.
    }
  }

  /// Deletes one take. A missing id is a no-op on the store, and the index is
  /// updated only after the blob is gone.
  Future<RecordingFailure?> deleteTake(String id) async {
    try {
      await _store.delete(id);
    } catch (error) {
      return RecordingFailure(
        RecordingFailureKind.storage,
        'Could not delete the take. It is still stored.',
        cause: error,
      );
    }
    try {
      final index = await _loadIndex();
      if (index.takeFor(id) == null) return null;
      await _indexStore.save(index.remove(id));
      return null;
    } catch (error) {
      return RecordingFailure(
        RecordingFailureKind.storage,
        'The take was deleted, but the recording list could not be updated.',
        cause: error,
      );
    }
  }

  /// Deletes every recording. Progress and settings are untouched.
  Future<RecordingFailure?> clearAll() async {
    try {
      await _store.clear();
      await _indexStore.clear();
      return null;
    } catch (error) {
      return RecordingFailure(
        RecordingFailureKind.storage,
        'Could not clear all recordings. Some takes may still be stored.',
        cause: error,
      );
    }
  }

  /// Copies one take out without changing it. The stored bytes and index entry
  /// stay exactly as they were.
  Future<RecordingExportOutcome> exportTake(String id) async {
    try {
      final index = await _loadIndex();
      final take = index.takeFor(id);
      if (take == null) {
        return const RecordingExportOutcome.failed(
          RecordingFailure(
            RecordingFailureKind.missingTake,
            'That take is no longer stored.',
          ),
        );
      }
      final bytes = await _store.get(id);
      if (bytes == null) {
        return const RecordingExportOutcome.failed(
          RecordingFailure(
            RecordingFailureKind.missingTake,
            'That take is no longer stored.',
          ),
        );
      }
      final result = await _exporter.export(
        RecordingExportRequest(
          id: id,
          fileName: exportFileName(take),
          bytes: bytes,
          mimeType: _encoder.mimeType,
        ),
      );
      return RecordingExportOutcome.success(result);
    } on RecordingExportException catch (error) {
      return RecordingExportOutcome.failed(
        RecordingFailure(
          RecordingFailureKind.export,
          error.message,
          cause: error.cause,
        ),
      );
    } catch (error) {
      return RecordingExportOutcome.failed(
        RecordingFailure(
          RecordingFailureKind.export,
          'Could not export the take.',
          cause: error,
        ),
      );
    }
  }

  /// Reads stored bytes for playback. Returns null when the take is gone.
  Future<Uint8List?> readTake(String id) => _store.get(id);

  /// Returns the takes newest first for display.
  Future<List<RecordingTake>> listTakes() async {
    final index = await _loadIndex();
    return List<RecordingTake>.unmodifiable(index.takes.reversed);
  }

  /// Current local storage use in bytes.
  Future<int> usageBytes() => _store.usageBytes();

  /// Removes media bytes that the index does not reference, and removes index
  /// entries whose media is missing.
  ///
  /// A missing, corrupt, or future index is adopted from the existing media
  /// instead of deleting it. That keeps a damaged index from destroying
  /// recordings.
  Future<RecordingReconcileReport> reconcile() async {
    try {
      final refs = await _store.list();
      final loaded = await _loadIndexWithStatus();
      if (loaded.repaired) {
        // A missing, unreadable, or partially corrupt index is adopted. Do not
        // delete any blob on this run: a row the parser could not read may own
        // it, and the bytes are still a valid take.
        return RecordingReconcileReport(
          adoptedBlobs: loaded.adopted,
          recovered: true,
        );
      }

      final index = loaded.index;
      final refIds = <String>{for (final ref in refs) ref.id};
      final kept = <RecordingTake>[];
      var removedEntries = 0;
      for (final take in index.takes) {
        if (refIds.contains(take.id)) {
          kept.add(take);
        } else {
          removedEntries++;
        }
      }

      final keptIds = <String>{for (final take in kept) take.id};
      var deletedOrphans = 0;
      for (final ref in refs) {
        if (keptIds.contains(ref.id)) continue;
        try {
          await _store.delete(ref.id);
          deletedOrphans++;
        } catch (_) {
          // Leave it for the next reconcile. The index still does not
          // reference it, so it is never played.
        }
      }

      if (removedEntries > 0 || deletedOrphans > 0) {
        await _indexStore.save(RecordingIndex(kept));
      }
      return RecordingReconcileReport(
        removedIndexEntries: removedEntries,
        deletedOrphans: deletedOrphans,
      );
    } catch (error) {
      return RecordingReconcileReport(
        failure: RecordingFailure(
          RecordingFailureKind.storage,
          'Could not check local recording storage.',
          cause: error,
        ),
      );
    }
  }

  /// Stops any live take and releases the recorder.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _timer = null;
    _recording = false;
    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) {
      try {
        await recorder.stop();
      } catch (_) {
        // The platform may already be stopped.
      }
      try {
        await recorder.dispose();
      } catch (_) {
        // The platform may already be released.
      }
    }
    await _autoStopController.close();
  }

  Future<RecordingStopResult> _storeTake(
    PhraseTake take, {
    required bool capped,
  }) async {
    final sampleRate = take.sampleRate;
    final maxSamples = (maxTakeDuration.inMicroseconds * sampleRate / 1000000)
        .round();
    var samples = take.samples;
    var wasCapped = capped;
    if (samples.length > maxSamples) {
      samples = samples.sublist(0, maxSamples);
      wasCapped = true;
    }
    if (samples.isEmpty) {
      return const RecordingStopResult.failed(
        RecordingFailure(
          RecordingFailureKind.emptyTake,
          'That take was empty. Play for a moment, then try again.',
        ),
      );
    }

    final durationMs = (samples.length * 1000 / sampleRate).round();
    final Uint8List bytes;
    try {
      bytes = _encoder.encode(samples, sampleRate: sampleRate);
    } catch (error) {
      return RecordingStopResult.failed(
        RecordingFailure(
          RecordingFailureKind.storage,
          'Could not encode the take.',
          cause: error,
        ),
      );
    }

    try {
      final index = await _loadIndex();
      if (index.length >= takeLimit) {
        return RecordingStopResult.failed(_quotaFailure());
      }
      final usage = await _store.usageBytes();
      if (usage + bytes.length > byteLimit) {
        return RecordingStopResult.failed(_byteQuotaFailure());
      }

      final ref = await _store.put(
        bytes,
        mimeType: _encoder.mimeType,
        pieceId: _pieceId,
        phraseId: _phraseId,
        durationMs: durationMs,
      );
      final recording = RecordingTake(
        id: ref.id,
        createdAt: _clock().toUtc(),
        byteLength: bytes.length,
        durationMs: durationMs,
        pieceId: _pieceId,
        phraseId: _phraseId,
        capped: wasCapped,
      );
      final withTake = index.add(recording);
      final plan = _planRetention(withTake, protectedId: recording.id);
      try {
        // Commit the new manifest before deleting any retention victim. If this
        // write fails, only the new blob is removed and every older take stays
        // exactly as it was.
        await _indexStore.save(plan.index);
      } catch (error) {
        try {
          await _store.delete(recording.id);
        } catch (_) {}
        return RecordingStopResult.failed(
          RecordingFailure(
            RecordingFailureKind.storage,
            'Could not update the recording list. The take was not saved.',
            cause: error,
          ),
        );
      }
      for (final victim in plan.victims) {
        try {
          await _store.delete(victim.id);
        } catch (_) {
          // The committed index no longer references the victim, so a later
          // reconcile can retry the blob deletion.
        }
      }
      return RecordingStopResult.saved(take: recording, capped: wasCapped);
    } catch (error) {
      return RecordingStopResult.failed(
        RecordingFailure(
          RecordingFailureKind.storage,
          'Could not save the take. Your existing takes are still here.',
          cause: error,
        ),
      );
    }
  }

  /// Plans which takes the per-piece rule will evict. It never evicts the first
  /// take for a piece or the take that was just saved.
  _RetentionPlan _planRetention(
    RecordingIndex index, {
    required String protectedId,
  }) {
    var current = index;
    final victims = <RecordingTake>[];
    final pieces = <String>{
      for (final take in current.takes)
        if (take.pieceId != null) take.pieceId!,
    };
    for (final piece in pieces) {
      var group = current.takesForPiece(piece);
      if (group.length <= pieceTakeLimit) continue;
      final firstId = group.first.id;
      for (final take in group) {
        if (group.length <= pieceTakeLimit) break;
        if (take.id == firstId || take.id == protectedId) continue;
        victims.add(take);
        current = current.remove(take.id);
        group = current.takesForPiece(piece);
      }
    }
    return _RetentionPlan(index: current, victims: victims);
  }

  Future<RecordingIndex> _loadIndex() async =>
      (await _loadIndexWithStatus()).index;

  /// Loads the manifest and repairs partial corruption by adopting blobs that
  /// no parsed row references. [repaired] tells reconcile not to delete
  /// unreferenced media on this run.
  Future<({RecordingIndex index, bool repaired, int adopted})>
  _loadIndexWithStatus() async {
    try {
      final loaded = await _indexStore.load();
      if (loaded == null) {
        final refs = await _store.list();
        final adopted = RecordingIndex(<RecordingTake>[
          for (final ref in refs) RecordingTake.fromMediaRef(ref),
        ]);
        if (adopted.isNotEmpty) {
          try {
            await _indexStore.save(adopted);
          } catch (_) {
            // Keep the in-memory recovery; the next write can retry.
          }
        }
        return (
          index: adopted,
          repaired: adopted.isNotEmpty,
          adopted: adopted.length,
        );
      }
      if (loaded.skippedEntries == 0) {
        return (index: loaded, repaired: false, adopted: 0);
      }

      final refs = await _store.list();
      final known = <String>{for (final take in loaded.takes) take.id};
      final extras = <RecordingTake>[
        for (final ref in refs)
          if (!known.contains(ref.id)) RecordingTake.fromMediaRef(ref),
      ];
      final merged = RecordingIndex(<RecordingTake>[
        ...loaded.takes,
        ...extras,
      ]);
      try {
        await _indexStore.save(merged);
      } catch (_) {
        // The merged in-memory index is still safer than deleting the blobs.
      }
      return (index: merged, repaired: true, adopted: extras.length);
    } catch (_) {
      final refs = await _store.list();
      final recovered = RecordingIndex(<RecordingTake>[
        for (final ref in refs) RecordingTake.fromMediaRef(ref),
      ]);
      try {
        await _indexStore.save(recovered);
      } catch (_) {
        // Keep the in-memory recovery; the next write can retry.
      }
      return (
        index: recovered,
        repaired: recovered.isNotEmpty,
        adopted: recovered.length,
      );
    }
  }

  Future<void> _autoStop() async {
    if (!_recording || _finishing) return;
    final result = await stop(capped: true);
    if (result.failure?.kind == RecordingFailureKind.notRecording) return;
    if (!_autoStopController.isClosed) _autoStopController.add(result);
  }

  RecordingStartResult _startFailed(RecordingFailure failure) =>
      RecordingStartResult.failed(failure);

  RecordingFailure _cancelledFailure() => const RecordingFailure(
    RecordingFailureKind.notRecording,
    'Recording was cancelled.',
  );

  RecordingFailure _quotaFailure() => RecordingFailure(
    RecordingFailureKind.quota,
    'You can keep $takeLimit takes. Delete one to record another.',
  );

  RecordingFailure _byteQuotaFailure() => RecordingFailure(
    RecordingFailureKind.quota,
    'Recordings are using the local storage limit. Delete a take to record '
    'another.',
  );

  /// Safe download name for a take.
  String exportFileName(RecordingTake take) =>
      'recording-${take.id}.${_encoder.fileExtension}';

  /// MIME type used for the V1 stored takes.
  static const String wavMimeType = 'audio/wav';
}

class _RetentionPlan {
  const _RetentionPlan({required this.index, required this.victims});

  final RecordingIndex index;
  final List<RecordingTake> victims;
}
