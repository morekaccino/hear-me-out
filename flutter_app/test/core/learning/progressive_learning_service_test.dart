import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progressive_learning_service.dart';

void main() {
  group('ProgressiveLearningService', () {
    late ProgressiveLearningService service;

    setUp(() {
      service = ProgressiveLearningService();
      service.generateInitialStack(3);
    });

    test('starts with 1 card in the stack', () {
      final card = service.getNextCard();
      expect(card, isNotNull);
    });

    test('getNextCard returns a card', () {
      final card = service.getNextCard();
      expect(card, isNotNull);
      expect(card!.noteValue, isNotEmpty);
    });

    test('markCorrect increments totalCorrect', () {
      final card = service.getNextCard()!;
      service.markCorrect(card.noteValue);
      expect(service.getStats().totalCorrect, 1);
    });

    test('markIncorrect increments totalIncorrect', () {
      final card = service.getNextCard()!;
      service.markIncorrect(card.noteValue);
      expect(service.getStats().totalIncorrect, 1);
    });

    test('correctStreak of 3 masters the note', () {
      final card = service.getNextCard()!;
      final noteValue = card.noteValue;
      service.markCorrect(noteValue);
      service.markCorrect(noteValue);
      service.markCorrect(noteValue);
      expect(service.getStats().mastered, 1);
    });

    test('reset clears all progress', () {
      final card = service.getNextCard()!;
      service.markCorrect(card.noteValue);
      service.reset();
      expect(service.getStats().totalCorrect, 0);
    });

    test('serializeState produces valid JSON structure', () {
      service.markCorrect(service.getNextCard()!.noteValue);
      final state = service.serializeState();
      expect(state, contains('learningCards'));
      expect(state, contains('masteredCards'));
      expect(state, contains('cardIdCounter'));
      expect(state, contains('stats'));
    });

    test('restoreState correctly restores progress', () {
      final state = service.serializeState();
      final newService = ProgressiveLearningService();
      newService.restoreState(state);
      expect(newService.getStats().totalCorrect, service.getStats().totalCorrect);
    });
  });
}
