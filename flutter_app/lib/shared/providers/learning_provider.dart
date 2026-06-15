import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/learning/progressive_learning_service.dart';
import '../../shared/models/learning_card.dart';
import '../../shared/models/session_stats.dart';

final learningServiceProvider = Provider<ProgressiveLearningService>((ref) {
  return ProgressiveLearningService();
});

final learningStatsProvider = StateProvider<SessionStats>((ref) {
  return SessionStats();
});

final currentCardProvider = StateProvider<LearningCard?>((ref) {
  return null;
});

final sessionStreakProvider = StateProvider<int>((ref) {
  return 0;
});

class LearningNotifier extends StateNotifier<AsyncValue<List<LearningCard>>> {
  final ProgressiveLearningService _service;
  final Ref _ref;

  LearningNotifier(this._service, this._ref) : super(const AsyncValue.data([]));

  void generateInitialStack(int size) {
    final stack = _service.generateInitialStack(size);
    state = AsyncValue.data(stack);
    _nextCard();
  }

  void _nextCard() {
    final card = _service.getNextCard();
    _ref.read(currentCardProvider.notifier).state = card;
  }

  void markCorrect(String noteValue) {
    _service.markCorrect(noteValue);
    _ref.read(learningStatsProvider.notifier).state = _service.getStats();
    _ref.read(sessionStreakProvider.notifier).update((s) => s + 1);
    _nextCard();
  }

  void markIncorrect(String noteValue) {
    _service.markIncorrect(noteValue);
    _ref.read(learningStatsProvider.notifier).state = _service.getStats();
    _ref.read(sessionStreakProvider.notifier).state = 0;
    _nextCard();
  }

  void reset() {
    _service.reset();
    _ref.read(learningStatsProvider.notifier).state = _service.getStats();
    _ref.read(sessionStreakProvider.notifier).state = 0;
    state = const AsyncValue.data([]);
  }

  Map<String, dynamic> serializeState() => _service.serializeState();
  void restoreState(Map<String, dynamic> stateData) => _service.restoreState(stateData);
}

final learningProvider = StateNotifierProvider<LearningNotifier, AsyncValue<List<LearningCard>>>((ref) {
  final service = ref.watch(learningServiceProvider);
  return LearningNotifier(service, ref);
});
