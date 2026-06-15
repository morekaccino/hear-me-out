import 'dart:math';
import '../../config/constants.dart';
import '../../shared/models/learning_card.dart';
import '../../shared/models/session_stats.dart';

class ProgressiveLearningService {
  final List<LearningCard> _learningCards = [];
  final List<LearningCard> _masteredCards = [];
  final List<String> _allNoteValues;
  int _cardIdCounter = 0;
  int _totalCorrect = 0;
  int _totalIncorrect = 0;

  ProgressiveLearningService({List<String>? allNotes})
      : _allNoteValues = allNotes ?? List.from(AppConstants.noteNames);

  List<LearningCard> generateInitialStack(int maxCards) {
    _learningCards.clear();
    _masteredCards.clear();
    _cardIdCounter = 0;
    _totalCorrect = 0;
    _totalIncorrect = 0;

    // Start with 1 card from the note range
    final firstNote = _allNoteValues.first;
    final card = LearningCard(
      id: 'card_${_cardIdCounter++}',
      noteValue: firstNote,
      cardType: CardType.newCard,
    );
    _learningCards.add(card);

    return List.from(_learningCards);
  }

  LearningCard? getNextCard() {
    if (_learningCards.isEmpty && _masteredCards.isEmpty) return null;

    // If no learning cards, review a mastered one
    if (_learningCards.isEmpty && _masteredCards.isNotEmpty) {
      _masteredCards.shuffle();
      return _masteredCards.first;
    }

    // Review a mastered card with some probability
    if (_masteredCards.isNotEmpty && Random().nextDouble() < AppConstants.reviewProbability) {
      _masteredCards.shuffle();
      return _masteredCards.first;
    }

    // Try to introduce a new card if we have room
    if (_learningCards.length < AppConstants.maxLearningCards && _hasNewCards()) {
      final newNote = _getNextNewNote();
      final card = LearningCard(
        id: 'card_${_cardIdCounter++}',
        noteValue: newNote,
        cardType: CardType.newCard,
      );
      _learningCards.add(card);
      return card;
    }

    // Pick a learning card
    _learningCards.shuffle();
    return _learningCards.first;
  }

  void markCorrect(String noteValue) {
    _totalCorrect++;
    _updateCard(noteValue, true);

    final card = _findInLearning(noteValue);
    if (card != null && card.correctStreak >= AppConstants.masteryCorrectStreak) {
      _learningCards.removeWhere((c) => c.noteValue == noteValue);
      _masteredCards.add(card.copyWith(
        cardType: CardType.review,
        masteredAt: DateTime.now(),
      ));
    }
  }

  void markIncorrect(String noteValue) {
    _totalIncorrect++;
    _updateCard(noteValue, false);

    final masteredCard = _masteredCards.where((c) => c.noteValue == noteValue).firstOrNull;
    if (masteredCard != null) {
      _masteredCards.removeWhere((c) => c.noteValue == noteValue);
      _learningCards.add(masteredCard.copyWith(
        cardType: CardType.learning,
        correctStreak: 0,
      ));
    }
  }

  void _updateCard(String noteValue, bool correct) {
    LearningCard? card = _findInLearning(noteValue) ?? _findInMastered(noteValue);
    if (card == null) return;

    final updated = card.copyWith(
      correctStreak: correct ? card.correctStreak + 1 : 0,
      totalCorrect: card.totalCorrect + (correct ? 1 : 0),
      totalIncorrect: card.totalIncorrect + (correct ? 0 : 1),
      lastSeen: DateTime.now(),
      reviewCount: card.reviewCount + 1,
    );

    _replaceCard(updated);
  }

  LearningCard? _findInLearning(String noteValue) =>
      _learningCards.where((c) => c.noteValue == noteValue).firstOrNull;

  LearningCard? _findInMastered(String noteValue) =>
      _masteredCards.where((c) => c.noteValue == noteValue).firstOrNull;

  void _replaceCard(LearningCard card) {
    final learningIdx = _learningCards.indexWhere((c) => c.noteValue == card.noteValue);
    if (learningIdx >= 0) { _learningCards[learningIdx] = card; return; }
    final masteredIdx = _masteredCards.indexWhere((c) => c.noteValue == card.noteValue);
    if (masteredIdx >= 0) { _masteredCards[masteredIdx] = card; }
  }

  bool _hasNewCards() {
    final used = {..._learningCards.map((c) => c.noteValue), ..._masteredCards.map((c) => c.noteValue)};
    return _allNoteValues.any((n) => !used.contains(n));
  }

  String _getNextNewNote() {
    final used = {..._learningCards.map((c) => c.noteValue), ..._masteredCards.map((c) => c.noteValue)};
    return _allNoteValues.firstWhere((n) => !used.contains(n));
  }

  SessionStats getStats() {
    final total = _learningCards.length + _masteredCards.length;
    return SessionStats(
      totalCorrect: _totalCorrect,
      totalIncorrect: _totalIncorrect,
      accuracy: (_totalCorrect + _totalIncorrect) > 0
          ? (_totalCorrect / (_totalCorrect + _totalIncorrect)) * 100 : 0.0,
      total: total,
      learning: _learningCards.length,
      mastered: _masteredCards.length,
      notStarted: _allNoteValues.length - total,
      progressPercentage: total > 0 ? (_masteredCards.length / total) * 100 : 0.0,
    );
  }

  void reset() {
    _learningCards.clear();
    _masteredCards.clear();
    _cardIdCounter = 0;
    _totalCorrect = 0;
    _totalIncorrect = 0;
  }

  Map<String, dynamic> serializeState() => {
    'learningCards': _learningCards.map((c) => c.toJson()).toList(),
    'masteredCards': _masteredCards.map((c) => c.toJson()).toList(),
    'cardIdCounter': _cardIdCounter,
    'stats': {'totalCorrect': _totalCorrect, 'totalIncorrect': _totalIncorrect},
  };

  void restoreState(Map<String, dynamic> state) {
    _learningCards.clear();
    _masteredCards.clear();
    if (state['learningCards'] != null) {
      for (final c in state['learningCards']) {
        _learningCards.add(LearningCard.fromJson(c as Map<String, dynamic>));
      }
    }
    if (state['masteredCards'] != null) {
      for (final c in state['masteredCards']) {
        _masteredCards.add(LearningCard.fromJson(c as Map<String, dynamic>));
      }
    }
    _cardIdCounter = (state['cardIdCounter'] as num?)?.toInt() ?? 0;
    final stats = state['stats'] as Map<String, dynamic>? ?? {};
    _totalCorrect = (stats['totalCorrect'] as num?)?.toInt() ?? 0;
    _totalIncorrect = (stats['totalIncorrect'] as num?)?.toInt() ?? 0;
  }
}
