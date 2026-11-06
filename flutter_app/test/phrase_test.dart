import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/note_event.dart';
import 'package:hear_me_out/core/music/phrase.dart';
import 'package:hear_me_out/core/music/piece.dart';

const _note = NoteEvent(
  startBeat: 0,
  durationBeats: 1,
  kind: NoteEventKind.note,
  writtenNote: Note('E', 5),
  soundingMidi: 64,
  string: 1,
  fret: 0,
);

const _rest = NoteEvent(
  startBeat: 1,
  durationBeats: 1,
  kind: NoteEventKind.rest,
);

const _secondNote = NoteEvent(
  startBeat: 2,
  durationBeats: 1,
  kind: NoteEventKind.note,
  writtenNote: Note('F', 5),
  soundingMidi: 65,
  string: 1,
  fret: 1,
);

const _phrase = Phrase(
  id: 'phrase-1',
  bars: 2,
  timeSignature: TimeSignature(4, 4),
  events: [_note, _rest, _secondNote],
  targetTempoBpm: 80,
  title: 'A short phrase',
  skills: ['note-reading.open-strings'],
  difficulty: 2,
  startBar: 3,
  pickupBeats: 0,
);

void main() {
  group('Phrase', () {
    test('notes and rests are separated from the event list', () {
      expect(_phrase.notes, hasLength(2));
      expect(_phrase.rests, hasLength(1));
      expect(_phrase.notes.first.writtenNote?.id, 'E5');
      expect(_phrase.rests.first.startBeat, 1);
    });

    test('totalBeats and expectedTotalBeats stay explicit', () {
      expect(_phrase.totalBeats, 3);
      expect(_phrase.expectedTotalBeats, 8);
    });

    test('a pickup changes expectedTotalBeats without rounding', () {
      const pickup = Phrase(
        id: 'pickup',
        bars: 3,
        timeSignature: TimeSignature(4, 4),
        events: [],
        targetTempoBpm: 80,
        pickupBeats: 1,
      );

      expect(pickup.expectedTotalBeats, 9);
      expect(pickup.totalBeats, 0);
    });

    test('copyWith replaces only the requested fields', () {
      final changed = _phrase.copyWith(
        id: 'phrase-2',
        targetTempoBpm: 96,
        difficulty: 4,
        pickupBeats: 0.5,
      );

      expect(changed.id, 'phrase-2');
      expect(changed.targetTempoBpm, 96);
      expect(changed.difficulty, 4);
      expect(changed.pickupBeats, 0.5);
      expect(changed.bars, _phrase.bars);
      expect(changed.title, _phrase.title);
      expect(changed.events, _phrase.events);
    });

    test('JSON roundtrip preserves every field', () {
      final json = _phrase.toJson();

      expect(Phrase.fromJson(json).toJson(), json);
    });

    test('fromJson supplies defaults for optional fields', () {
      final phrase = Phrase.fromJson({
        'id': 'minimal',
        'bars': 1,
        'timeSignature': {'numerator': 4, 'denominator': 4},
        'events': <Map<String, dynamic>>[],
        'targetTempoBpm': 80,
      });

      expect(phrase.title, isNull);
      expect(phrase.skills, isEmpty);
      expect(phrase.difficulty, 1);
      expect(phrase.startBar, 1);
      expect(phrase.pickupBeats, 0);
      expect(phrase.contentVersion, 1);
    });

    test('contentVersion roundtrips and copyWith can bump it', () {
      final changed = _phrase.copyWith(contentVersion: 3);
      expect(changed.contentVersion, 3);
      expect(Phrase.fromJson(changed.toJson()).contentVersion, 3);

      final legacy = _phrase.toJson()..remove('contentVersion');
      expect(Phrase.fromJson(legacy).contentVersion, 1);
    });

    test('fromJson reports a nested event path', () {
      expect(
        () => Phrase.fromJson({
          'id': 'broken',
          'bars': 1,
          'timeSignature': {'numerator': 4, 'denominator': 4},
          'targetTempoBpm': 80,
          'events': [
            {
              'startBeat': 0,
              'durationBeats': 1,
              'kind': 'note',
              'writtenNote': 'E5',
              'soundingMidi': 64,
            },
            {'startBeat': 1, 'durationBeats': 'slow', 'kind': 'rest'},
          ],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('phrase.events[1].durationBeats'),
          ),
        ),
      );
    });

    test('fromJson rejects an event that is not an object', () {
      expect(
        () => Phrase.fromJson({
          'id': 'broken',
          'bars': 1,
          'timeSignature': {'numerator': 4, 'denominator': 4},
          'targetTempoBpm': 80,
          'events': ['E5'],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('phrase.events[0]'),
          ),
        ),
      );
    });
  });
}
