import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/note_event.dart';

void main() {
  group('NoteEvent', () {
    test('a note exposes its end beat and expected sounding pitch', () {
      const event = NoteEvent(
        startBeat: 1,
        durationBeats: 2,
        kind: NoteEventKind.note,
        writtenNote: Note('E', 5),
        soundingMidi: 64,
        string: 1,
        fret: 0,
      );

      expect(event.endBeat, 3);
      expect(event.isNote, isTrue);
      expect(event.isRest, isFalse);
      expect(event.expectedSoundingMidi, 64);
    });

    test('a rest carries no pitch or fingering', () {
      const event = NoteEvent(
        startBeat: 0,
        durationBeats: 1,
        kind: NoteEventKind.rest,
      );

      expect(event.isRest, isTrue);
      expect(event.expectedSoundingMidi, isNull);
      expect(event.writtenNote, isNull);
      expect(event.soundingMidi, isNull);
      expect(event.string, isNull);
      expect(event.fret, isNull);
    });

    test('copyWith changes only the requested fields', () {
      const event = NoteEvent(
        startBeat: 0,
        durationBeats: 1,
        kind: NoteEventKind.note,
        writtenNote: Note('E', 5),
        soundingMidi: 64,
        string: 1,
        fret: 0,
      );

      final changed = event.copyWith(startBeat: 2, tieToNext: true);

      expect(changed.startBeat, 2);
      expect(changed.tieToNext, isTrue);
      expect(changed.writtenNote, event.writtenNote);
      expect(changed.soundingMidi, 64);
      expect(changed.string, 1);
      expect(changed.fret, 0);
    });

    test('note JSON roundtrip is stable', () {
      const event = NoteEvent(
        startBeat: 2.5,
        durationBeats: 0.5,
        kind: NoteEventKind.note,
        writtenNote: Note('C', 5),
        soundingMidi: 60,
        string: 2,
        fret: 1,
        tieToNext: true,
        velocity: 0.8,
      );

      final json = event.toJson();

      expect(NoteEvent.fromJson(json).toJson(), json);
    });

    test('rest JSON omits pitch fields', () {
      const event = NoteEvent(
        startBeat: 0,
        durationBeats: 1,
        kind: NoteEventKind.rest,
      );

      final json = event.toJson();

      expect(json.containsKey('writtenNote'), isFalse);
      expect(json.containsKey('soundingMidi'), isFalse);
      expect(json.containsKey('string'), isFalse);
      expect(json.containsKey('fret'), isFalse);
      expect(json.containsKey('tieToNext'), isFalse);
      expect(NoteEvent.fromJson(json).toJson(), json);
    });

    test('fromJson supplies defaults for optional fields', () {
      final event = NoteEvent.fromJson({
        'startBeat': 0,
        'durationBeats': 1,
        'kind': 'note',
        'writtenNote': 'E5',
        'soundingMidi': 64,
      });

      expect(event.tieToNext, isFalse);
      expect(event.velocity, 1.0);
      expect(event.string, isNull);
      expect(event.fret, isNull);
    });

    test('fromJson reports the failing field path', () {
      expect(
        () => NoteEvent.fromJson({
          'startBeat': 'zero',
          'durationBeats': 1,
          'kind': 'note',
          'writtenNote': 'E5',
          'soundingMidi': 64,
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('event.startBeat'),
          ),
        ),
      );
    });

    test('fromJson rejects an invalid written note with a path', () {
      expect(
        () => NoteEvent.fromJson({
          'startBeat': 0,
          'durationBeats': 1,
          'kind': 'note',
          'writtenNote': 'H9',
          'soundingMidi': 64,
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('event.writtenNote'),
          ),
        ),
      );
    });

    test('fromJson rejects an unknown kind with a path', () {
      expect(
        () => NoteEvent.fromJson({
          'startBeat': 0,
          'durationBeats': 1,
          'kind': 'chord',
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('event.kind'),
          ),
        ),
      );
    });
  });
}
