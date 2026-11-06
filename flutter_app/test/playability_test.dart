import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/score/authoring.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/note_event.dart';
import 'package:hear_me_out/core/music/phrase.dart';
import 'package:hear_me_out/core/music/piece.dart';
import 'package:hear_me_out/core/music/playability.dart';
import 'package:hear_me_out/core/music/score.dart';

const String etudeRoot = 'assets/content/etudes';

/// FNV-1a hashes of the 60 reviewed T3.6 etudes.
///
/// These files are the stable shipped core. The generator must never rewrite
/// them. If an etude is edited on purpose, update its hash in the same commit
/// that records the content review.
const Map<String, int> reviewedEtudeHashes = <String, int>{
  'etude-l1-01.json': 3061735944,
  'etude-l1-02.json': 2294480333,
  'etude-l1-03.json': 147355819,
  'etude-l1-04.json': 1360240562,
  'etude-l1-05.json': 2950268417,
  'etude-l1-06.json': 3419954090,
  'etude-l1-07.json': 720598824,
  'etude-l1-08.json': 3522220781,
  'etude-l1-09.json': 555257002,
  'etude-l1-10.json': 2824543024,
  'etude-l1-11.json': 212345957,
  'etude-l1-12.json': 1364201747,
  'etude-l2-01.json': 1633991762,
  'etude-l2-02.json': 2591670442,
  'etude-l2-03.json': 2996946235,
  'etude-l2-04.json': 2951049571,
  'etude-l2-05.json': 2611335520,
  'etude-l2-06.json': 3870593065,
  'etude-l2-07.json': 1958109022,
  'etude-l2-08.json': 3563237390,
  'etude-l2-09.json': 3819232246,
  'etude-l2-10.json': 91451866,
  'etude-l2-11.json': 330345935,
  'etude-l2-12.json': 205445132,
  'etude-l3-01.json': 3710122754,
  'etude-l3-02.json': 551032018,
  'etude-l3-03.json': 679786483,
  'etude-l3-04.json': 3231558393,
  'etude-l3-05.json': 2712830276,
  'etude-l3-06.json': 1162632035,
  'etude-l3-07.json': 2513799286,
  'etude-l3-08.json': 1947210617,
  'etude-l3-09.json': 1555051278,
  'etude-l3-10.json': 1745721533,
  'etude-l3-11.json': 4031410547,
  'etude-l3-12.json': 2043056213,
  'etude-l4-01.json': 1538384390,
  'etude-l4-02.json': 1053568291,
  'etude-l4-03.json': 4022564867,
  'etude-l4-04.json': 436850355,
  'etude-l4-05.json': 1377262186,
  'etude-l4-06.json': 1010567764,
  'etude-l4-07.json': 4022845177,
  'etude-l4-08.json': 2660575012,
  'etude-l4-09.json': 893461426,
  'etude-l4-10.json': 807874835,
  'etude-l4-11.json': 3851063968,
  'etude-l4-12.json': 262710494,
  'etude-l5-01.json': 1009839529,
  'etude-l5-02.json': 1045463323,
  'etude-l5-03.json': 901332974,
  'etude-l5-04.json': 3123790025,
  'etude-l5-05.json': 2282608146,
  'etude-l5-06.json': 3638438237,
  'etude-l5-07.json': 2331862942,
  'etude-l5-08.json': 3488925066,
  'etude-l5-09.json': 1586162242,
  'etude-l5-10.json': 2394477924,
  'etude-l5-11.json': 388006693,
  'etude-l5-12.json': 1450290236,
};

int _fnv1a(String text) {
  // Normalize line endings so the hash is identical on Windows (CRLF) and CI
  // (LF) checkouts.
  final normalized = text.replaceAll('\r\n', '\n');
  var hash = 0x811C9DC5;
  for (final unit in normalized.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

List<File> _etudeFiles() {
  final directory = Directory(etudeRoot);
  final files =
      directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

NoteEvent _note(
  double start,
  double duration,
  int soundingMidi,
  int string,
  int fret,
) {
  return NoteEvent(
    startBeat: start,
    durationBeats: duration,
    kind: NoteEventKind.note,
    writtenNote: Note.fromMidi(soundingMidi + 12),
    soundingMidi: soundingMidi,
    string: string,
    fret: fret,
  );
}

Score _score(
  List<NoteEvent> events, {
  int bars = 1,
  TimeSignature meter = const TimeSignature(4, 4),
  String key = 'C major',
  int tempo = 72,
  String id = 'test-etude',
}) {
  return Score(
    piece: Piece(
      id: id,
      title: 'Test Etude',
      composer: 'Hear Me Out',
      license: 'original',
      tuning: Tuning.standard,
      timeSignature: meter,
      key: key,
      sections: const <String>['A'],
    ),
    phrases: <Phrase>[
      Phrase(
        id: '$id-p1',
        bars: bars,
        timeSignature: meter,
        events: List<NoteEvent>.unmodifiable(events),
        targetTempoBpm: tempo,
        skills: const <String>['note-reading.first-position'],
        difficulty: 1,
        startBar: 1,
      ),
    ],
  );
}

/// E4, D4, B3, C4. One bar, first position, open string, step cadence.
List<NoteEvent> _validEvents() => <NoteEvent>[
  _note(0, 1, 64, 1, 0),
  _note(1, 1, 62, 2, 3),
  _note(2, 1, 59, 2, 0),
  _note(3, 1, 60, 2, 1),
];

List<String> _codes(List<PlayabilityIssue> issues) =>
    issues.map((issue) => issue.code).toList();

void main() {
  group('reviewed T3.6 etudes', () {
    test('all 60 files are unchanged', () {
      final files = _etudeFiles();
      expect(files, hasLength(60));
      expect(
        files.map((file) => file.uri.pathSegments.last).toSet(),
        reviewedEtudeHashes.keys.toSet(),
      );
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        expect(
          _fnv1a(file.readAsStringSync()),
          reviewedEtudeHashes[name],
          reason:
              '$name changed. The 60 reviewed etudes are the stable core; a '
              'generated candidate must never rewrite them.',
        );
      }
    });

    test('all 60 pass the playability validator', () {
      var count = 0;
      for (final file in _etudeFiles()) {
        final decoded = jsonDecode(file.readAsStringSync());
        expect(decoded, isA<Map<String, dynamic>>());
        final document = parseAuthoringDocument(
          Map<String, dynamic>.from(decoded as Map),
        );
        final issues = PlayabilityValidator(document.score).validate();
        expect(issues, isEmpty, reason: '${file.path}\n${issues.join('\n')}');
        count++;
      }
      expect(count, 60);
    });
  });

  group('playability rules', () {
    test('a clean first-position bar passes', () {
      final report = validateCandidateScore(_score(_validEvents()));
      expect(report.scoreIssues, isEmpty);
      expect(report.playabilityIssues, isEmpty);
      expect(report.isValid, isTrue);
    });

    test('stretch beyond one hand position is reported with a bar', () {
      final events = <NoteEvent>[
        _note(0, 1, 65, 2, 6), // F4, fret 6
        _note(1, 1, 59, 2, 0),
        _note(2, 1, 60, 2, 1),
        _note(3, 1, 60, 1, 12),
      ];
      final issues = PlayabilityValidator(
        _score(events),
        limits: const PlayabilityLimits(maxFret: 19, maxStretch: 4),
      ).validate();
      final stretch = issues.where(
        (issue) => issue.code == 'playability.stretch',
      );
      expect(stretch, isNotEmpty);
      expect(stretch.first.bar, 1);
      expect(stretch.first.phraseId, 'test-etude-p1');
      expect(stretch.first.eventIndex, isNotNull);
    });

    test('a wide string crossing is reported', () {
      final events = <NoteEvent>[
        _note(0, 1, 64, 1, 0),
        _note(1, 1, 43, 6, 3),
        _note(2, 1, 59, 2, 0),
        _note(3, 1, 60, 2, 1),
      ];
      final issues = PlayabilityValidator(
        _score(events),
        limits: const PlayabilityLimits(maxStringSkip: 2),
      ).validate();
      expect(_codes(issues), contains('playability.stringCrossing'));
      final crossing = issues.firstWhere(
        (issue) => issue.code == 'playability.stringCrossing',
      );
      expect(crossing.bar, 1);
      expect(crossing.eventIndex, 1);
    });

    test('repeated notes over the limit are reported once per run', () {
      final events = <NoteEvent>[
        _note(0, 1, 64, 1, 0),
        _note(1, 1, 64, 1, 0),
        _note(2, 1, 64, 1, 0),
        _note(3, 1, 60, 2, 1),
      ];
      final issues = PlayabilityValidator(
        _score(events),
        limits: const PlayabilityLimits(maxConsecutiveRepeatedNotes: 2),
      ).validate();
      expect(
        issues.where((issue) => issue.code == 'playability.repeatedNote'),
        hasLength(1),
      );
    });

    test('string, fret, and written range limits are typed issues', () {
      final events = <NoteEvent>[
        _note(0, 1, 64, 9, 0),
        _note(1, 1, 62, 2, 9),
        _note(2, 1, 84, 2, 1),
        _note(3, 1, 60, 2, 1),
      ];
      final issues = PlayabilityValidator(
        _score(events),
        limits: const PlayabilityLimits(
          minString: 1,
          maxString: 6,
          minFret: 0,
          maxFret: 3,
          maxWrittenMidi: 80,
        ),
      ).validate();
      expect(_codes(issues), contains('playability.stringRange'));
      expect(_codes(issues), contains('playability.fretRange'));
      expect(_codes(issues), contains('playability.writtenRange'));
    });

    test('a rhythm cell outside the level grammar is reported', () {
      final events = <NoteEvent>[
        _note(0, 1.5, 64, 1, 0),
        _note(1.5, 1, 62, 2, 3),
        _note(2.5, 1.5, 60, 2, 1),
      ];
      final issues = PlayabilityValidator(
        _score(events),
        limits: const PlayabilityLimits(allowedDurations: <double>[0.5, 1.0]),
      ).validate();
      expect(_codes(issues), contains('playability.rhythmCell'));
    });

    test('a cadence on the wrong pitch is reported', () {
      final events = <NoteEvent>[
        _note(0, 1, 64, 1, 0),
        _note(1, 1, 62, 2, 3),
        _note(2, 1, 59, 2, 0),
        _note(3, 1, 62, 2, 3), // D4, not the C tonic
      ];
      final issues = PlayabilityValidator(_score(events)).validate();
      final cadence = issues.where(
        (issue) => issue.code == 'playability.cadence',
      );
      expect(cadence, isNotEmpty);
      expect(cadence.first.bar, 1);
    });

    test('a leap into the tonic is reported', () {
      final events = <NoteEvent>[
        _note(0, 1, 64, 1, 0),
        _note(1, 1, 62, 2, 3),
        _note(2, 1, 55, 3, 0),
        _note(3, 1, 60, 1, 12), // C5, a perfect fourth above G4
      ];
      final issues = PlayabilityValidator(_score(events)).validate();
      expect(_codes(issues), contains('playability.cadenceApproach'));
    });

    test('an open-string requirement is enforced', () {
      final events = <NoteEvent>[
        _note(0, 1, 60, 2, 1),
        _note(1, 1, 62, 2, 3),
        _note(2, 1, 59, 3, 4),
        _note(3, 1, 60, 2, 1),
      ];
      final issues = PlayabilityValidator(
        _score(events),
        limits: const PlayabilityLimits(requireOpenString: true),
      ).validate();
      expect(_codes(issues), contains('playability.noOpenString'));
    });

    test('shifts are located and limited', () {
      final score = Score(
        piece: Piece(
          id: 'shift-test',
          title: 'Shift Test',
          composer: 'Hear Me Out',
          license: 'original',
          tuning: Tuning.standard,
          timeSignature: const TimeSignature(4, 4),
          key: 'C major',
        ),
        phrases: <Phrase>[
          Phrase(
            id: 'shift-test-p1',
            bars: 1,
            timeSignature: const TimeSignature(4, 4),
            events: <NoteEvent>[
              _note(0, 1, 64, 1, 0),
              _note(1, 1, 62, 2, 3),
              _note(2, 1, 60, 2, 1),
              _note(3, 1, 60, 2, 1),
            ],
            targetTempoBpm: 72,
          ),
          Phrase(
            id: 'shift-test-p2',
            bars: 1,
            timeSignature: const TimeSignature(4, 4),
            events: <NoteEvent>[
              _note(0, 1, 69, 1, 5),
              _note(1, 1, 67, 1, 3),
              _note(2, 1, 66, 1, 2),
              _note(3, 1, 64, 2, 5),
            ],
            targetTempoBpm: 72,
            startBar: 2,
          ),
        ],
      );
      final validator = PlayabilityValidator(
        score,
        limits: const PlayabilityLimits(maxShifts: 0),
      );
      final shifts = validator.findShifts();
      expect(shifts, hasLength(1));
      expect(shifts.first.phraseId, 'shift-test-p2');
      expect(shifts.first.bar, 1);
      expect(shifts.first.fromPosition, 'first');
      expect(shifts.first.toPosition, 'second');
      final issues = validator.validate();
      expect(_codes(issues), contains('playability.tooManyShifts'));
    });

    test(
      'composition reports structural and playability problems together',
      () {
        final events = <NoteEvent>[
          _note(0, 1, 64, 1, 0),
          _note(0, 1, 62, 2, 3), // chord, structural error
          _note(2, 1, 59, 2, 0),
          _note(3, 1, 60, 2, 1),
        ];
        final report = validateCandidateScore(_score(events));
        expect(report.scoreIssues, isNotEmpty);
        expect(
          report.scoreIssues.map((issue) => issue.code),
          contains('monophonic.chord'),
        );
        expect(report.isValid, isFalse);
      },
    );
  });
}
