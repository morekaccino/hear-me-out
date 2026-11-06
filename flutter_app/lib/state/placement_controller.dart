import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/learning/placement.dart';
import '../core/storage/placement_store.dart';
import 'providers.dart';

/// Owns the separate, versioned placement result.
///
/// It never writes `ProgressState`. A placement save is additive: completed
/// lessons, notes, XP, minutes, streak, and phrase evidence are untouched.
class PlacementController extends AsyncNotifier<PlacementRecord?> {
  late PlacementStore _store;
  late DateTime Function() _clock;

  @override
  Future<PlacementRecord?> build() async {
    _store = ref.watch(placementStoreProvider);
    _clock = ref.watch(clockProvider);
    try {
      return await _store.load();
    } catch (_) {
      return null;
    }
  }

  Future<PlacementRecord> savePlacement({
    required int inferredStage,
    required int stage,
    required List<String> starterPieceIds,
    required bool manualOverride,
    DateTime? now,
  }) async {
    if (!placementStages.contains(stage)) {
      throw ArgumentError.value(stage, 'stage', 'must be a V1 stage');
    }
    if (inferredStage < 1 || inferredStage > 10) {
      throw ArgumentError.value(
        inferredStage,
        'inferredStage',
        'must be between 1 and 10',
      );
    }
    if (starterPieceIds.length != 3) {
      throw ArgumentError.value(
        starterPieceIds,
        'starterPieceIds',
        'must contain exactly three pieces',
      );
    }
    final savedAt = now ?? _clock();
    final record = PlacementRecord(
      stage: stage,
      inferredStage: inferredStage,
      phase2Stage: phase2StageFor(inferredStage),
      starterPieceIds: List<String>.unmodifiable(starterPieceIds),
      savedAt: savedAt,
      nextRetestAt: savedAt.add(placementRetestInterval),
      manualOverride: manualOverride,
    );
    state = AsyncData(record);
    try {
      await _store.save(record);
    } catch (_) {
      // A local storage failure must not block the learner from starting.
    }
    return record;
  }

  /// Hides the neutral re-test prompt for two weeks. The placement is kept.
  Future<PlacementRecord?> dismissRetest({DateTime? now}) async {
    final current = state.asData?.value;
    if (current == null) return null;
    final updated = current.dismissRetest(now ?? _clock());
    state = AsyncData(updated);
    try {
      await _store.save(updated);
    } catch (_) {
      // The prompt can stay hidden in memory even if the save fails.
    }
    return updated;
  }

  Future<void> clear() async {
    state = const AsyncData(null);
    try {
      await _store.clear();
    } catch (_) {
      // Resetting placement is best-effort storage work.
    }
  }
}

final placementControllerProvider =
    AsyncNotifierProvider<PlacementController, PlacementRecord?>(
      PlacementController.new,
    );
