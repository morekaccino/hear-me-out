import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/score/authoring.dart';
import 'package:hear_me_out/content/sight_reading/etude_generator.dart';
import 'package:hear_me_out/content/sight_reading/level_spec.dart';
import 'package:hear_me_out/content/sight_reading/level_validation.dart';
import 'package:hear_me_out/content/sight_reading/library.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/note_event.dart';
import 'package:hear_me_out/core/music/phrase.dart';
import 'package:hear_me_out/core/music/playability.dart';
import 'package:hear_me_out/core/music/score.dart';
import 'package:hear_me_out/core/music/score_parser.dart';

import '../tool/content/generate_etude.dart';

const Map<String, Set<int>> keyPitchClasses = <String, Set<int>>{
  'C major': <int>{0, 2, 4, 5, 7, 9, 11},
  'G major': <int>{7, 9, 11, 0, 2, 4, 6},
  'D major': <int>{2, 4, 6, 7, 9, 11, 1},
  'A minor': <int>{9, 11, 0, 2, 4, 5, 7},
  'E minor': <int>{4, 6, 7, 9, 11, 0, 2},
};

const Map<String, int> keyTonals = <String, int>{
  'C major': 0,
  'G major': 7,
  'D major': 2,
  'A minor': 9,
  'E minor': 4,
};

List<NoteEvent> _notes(Score score) => <NoteEvent>[
  for (final phrase in score.phrases) ...phrase.notes,
];

List<NoteEvent> _events(Score score) => <NoteEvent>[
  for (final phrase in score.phrases) ...phrase.events,
];

int _totalBars(Score score) =>
    score.phrases.fold<int>(0, (sum, phrase) => sum + phrase.bars);

Set<int> _accidentalPitchClasses(Score score) {
  final signature = keyPitchClasses[score.piece.key];
  if (signature == null) {
    throw StateError('Unexpected key ${score.piece.key}');
  }
  final pitchClasses = <int>{
    for (final note in _notes(score)) note.writtenNote!.midi % 12,
  };
  return pitchClasses.difference(signature);
}

double? _maxIntervalInPhrase(Phrase phrase) {
  final notes = phrase.notes;
  double? maximum;
  for (var index = 1; index < notes.length; index++) {
    final interval =
        (notes[index].writtenNote!.midi - notes[index - 1].writtenNote!.midi)
            .abs()
            .toDouble();
    if (maximum == null || interval > maximum) maximum = interval;
  }
  return maximum;
}

int _maxRepeatedRun(Phrase phrase) {
  var run = 1;
  var maximum = 1;
  final notes = phrase.notes;
  for (var index = 1; index < notes.length; index++) {
    if (notes[index].writtenNote?.id == notes[index - 1].writtenNote?.id) {
      run++;
      if (run > maximum) maximum = run;
    } else {
      run = 1;
    }
  }
  return maximum;
}

int _maxStringSkip(Phrase phrase) {
  var maximum = 0;
  final notes = phrase.notes;
  for (var index = 1; index < notes.length; index++) {
    final jump = (notes[index].string! - notes[index - 1].string!).abs();
    if (jump > maximum) maximum = jump;
  }
  return maximum;
}

String _rhythmSignature(Phrase phrase) => phrase.events
    .map((event) => '${event.durationBeats}:${event.kind.name}')
    .join(',');

/// Lowers the first accidental by a semitone so the score has none left.
///
/// Used to prove that the approval gate rejects a candidate which violates the
/// level's accidental rule even when the rest of the score is structurally
/// valid.
GeneratedEtude _withoutAccidentals(GeneratedEtude etude) {
  final keyClasses = PlayabilityValidator.keyPitchClassesForKey(
    etude.score.piece.key,
  )!;
  final phrases = <Phrase>[];
  var removed = false;
  for (final phrase in etude.score.phrases) {
    final events = <NoteEvent>[];
    for (final event in phrase.events) {
      final written = event.writtenNote;
      final fret = event.fret;
      if (!removed &&
          event.isNote &&
          written != null &&
          fret != null &&
          fret > 0 &&
          !keyClasses.contains(written.midi % 12)) {
        events.add(
          event.copyWith(
            writtenNote: Note.fromMidi(written.midi - 1),
            soundingMidi: event.soundingMidi! - 1,
            fret: fret - 1,
          ),
        );
        removed = true;
        continue;
      }
      events.add(event);
    }
    phrases.add(phrase.copyWith(events: events));
  }
  expect(removed, isTrue, reason: 'the candidate had no removable accidental');
  return GeneratedEtude(
    level: etude.level,
    seed: etude.seed,
    spec: etude.spec,
    key: etude.key,
    score: Score(piece: etude.score.piece, phrases: phrases),
  );
}

void _expectValidCandidate(GeneratedEtude etude, String reason) {
  final report = validateCandidateScore(
    etude.score,
    limits: etude.spec.playabilityLimits,
  );
  expect(
    report.scoreIssues,
    isEmpty,
    reason: '$reason\n${report.scoreIssues.join('\n')}',
  );
  expect(
    report.playabilityIssues,
    isEmpty,
    reason: '$reason\n${report.playabilityIssues.join('\n')}',
  );

  final authoring = AuthoringValidator(etude.score).validate();
  expect(authoring, isEmpty, reason: '$reason\n${authoring.join('\n')}');

  final grammar = validateLevelGrammar(etude);
  expect(grammar, isEmpty, reason: '$reason\n${grammar.join('\n')}');

  final json = etude.toAuthoringJson();
  final parsed = parseAuthoringDocument(json);
  expect(
    jsonEncode(scoreToJson(parsed.score)),
    jsonEncode(scoreToJson(etude.score)),
    reason: '$reason: the authoring envelope must round-trip.',
  );
}

void main() {
  const levels = <int>[1, 2, 3, 4, 5];
  const matrixSeeds = <int>[0, 1, 2, 3, 7, 11, 15, 42, 43, 99, 123, 2024];

  test('the same level and seed produce the same etude', () {
    for (final level in levels) {
      final first = EtudeGenerator(level: level, seed: 42).generate();
      final second = EtudeGenerator(level: level, seed: 42).generate();
      expect(
        jsonEncode(first.toAuthoringJson()),
        jsonEncode(second.toAuthoringJson()),
        reason: 'level $level seed 42 must be deterministic',
      );
      expect(first.candidateId, 'etude-candidate-l$level-s42');
      expect(
        first.score.piece.title,
        'Sight-reading Etude L$level candidate (seed 42)',
      );
    }

    final seedA = EtudeGenerator(level: 2, seed: 7).generate();
    final seedB = EtudeGenerator(level: 2, seed: 8).generate();
    expect(
      jsonEncode(seedA.toAuthoringJson()),
      isNot(jsonEncode(seedB.toAuthoringJson())),
      reason: 'different seeds must differ',
    );

    final levelA = EtudeGenerator(level: 1, seed: 7).generate();
    final levelB = EtudeGenerator(level: 5, seed: 7).generate();
    expect(
      jsonEncode(levelA.toAuthoringJson()),
      isNot(jsonEncode(levelB.toAuthoringJson())),
      reason: 'different levels with the same seed must differ',
    );
  });

  test('every candidate in the level/seed matrix passes both validators', () {
    for (final level in levels) {
      for (final seed in matrixSeeds) {
        final etude = EtudeGenerator(level: level, seed: seed).generate();
        _expectValidCandidate(etude, 'level $level seed $seed');
        final meta = parseAuthoringDocument(etude.toAuthoringJson()).meta!;
        expect(meta.kind, 'etude');
        expect(meta.tier, etude.spec.tier);
        expect(meta.stage, etude.spec.stage);
        expect(meta.reviewedBy, 'Pending human pedagogue review');
        expect(meta.reviewedBy, isNot(contains('human review')));
        expect(meta.notes, contains('pending-human'));
      }
    }
  });

  test('level grammar limits are enforced', () {
    for (final level in levels) {
      final spec = EtudeLevelSpec.forLevel(level);
      for (final seed in matrixSeeds) {
        final etude = EtudeGenerator(level: level, seed: seed).generate();
        final score = etude.score;
        final reason = 'level $level seed $seed';

        expect(_totalBars(score), spec.totalBars, reason: reason);
        expect(
          score.phrases,
          hasLength(spec.phrasePlan.length),
          reason: reason,
        );
        expect(
          spec.allowedMeters,
          contains(score.piece.timeSignature),
          reason: reason,
        );
        expect(keyPitchClasses.keys, contains(score.piece.key), reason: reason);

        final durations = <double>{
          for (final event in _events(score)) event.durationBeats,
        };
        expect(
          durations.every(
            (duration) =>
                spec.rhythmCells.any((cell) => (cell - duration).abs() < 1e-9),
          ),
          isTrue,
          reason: '$reason: $durations is outside ${spec.rhythmCells}',
        );
        for (final required in spec.requiredRhythmCells) {
          expect(
            durations.any((duration) => (duration - required).abs() < 1e-9),
            isTrue,
            reason: '$reason: missing required rhythm cell $required',
          );
        }
        if (spec.requiresDottedRhythm) {
          expect(
            durations.any(
              (duration) =>
                  (duration - 1.5).abs() < 1e-9 ||
                  (duration - 3.0).abs() < 1e-9,
            ),
            isTrue,
            reason: '$reason: missing a dotted rhythm',
          );
        }
        if (spec.requiresRest) {
          expect(
            _events(score).any((event) => event.isRest),
            isTrue,
            reason: '$reason: missing a rest',
          );
        }

        final accidentals = _accidentalPitchClasses(score);
        expect(
          accidentals.length,
          inInclusiveRange(spec.minAccidentals, spec.maxAccidentals),
          reason: '$reason: accidentals $accidentals',
        );

        for (
          var phraseIndex = 0;
          phraseIndex < score.phrases.length;
          phraseIndex++
        ) {
          final phrase = score.phrases[phraseIndex];
          final plan = spec.phrasePlan[phraseIndex];
          expect(phrase.bars, plan.bars, reason: '$reason phrase $phraseIndex');
          expect(phrase.targetTempoBpm, spec.tempoBpm, reason: reason);
          expect(
            phrase.timeSignature,
            score.piece.timeSignature,
            reason: reason,
          );
          expect(
            PlayabilityValidator.phrasePosition(phrase),
            plan.position == EtudePosition.first ? 'first' : 'second',
            reason: '$reason phrase $phraseIndex position',
          );
          expect(
            phrase.notes.every(
              (note) =>
                  spec.allowedStrings.contains(note.string) &&
                  note.fret! >= spec.minFret &&
                  note.fret! <= spec.maxFret,
            ),
            isTrue,
            reason: '$reason phrase $phraseIndex fingering',
          );
          final maxInterval = _maxIntervalInPhrase(phrase);
          if (maxInterval != null) {
            expect(
              maxInterval,
              lessThanOrEqualTo(spec.maxIntervalSemitones.toDouble()),
              reason: '$reason phrase $phraseIndex interval',
            );
          }
          expect(
            _maxRepeatedRun(phrase),
            lessThanOrEqualTo(spec.maxConsecutiveRepeatedNotes),
            reason: '$reason phrase $phraseIndex repeated notes',
          );
          expect(
            _maxStringSkip(phrase),
            lessThanOrEqualTo(spec.maxStringSkip),
            reason: '$reason phrase $phraseIndex string skip',
          );
        }

        if (spec.requiresOpenString) {
          expect(
            _notes(score).any((note) => note.fret == 0),
            isTrue,
            reason: '$reason: open string required',
          );
        }

        final shifts = PlayabilityValidator(
          score,
          limits: spec.playabilityLimits,
        ).findShifts();
        expect(
          shifts,
          hasLength(spec.maxShifts),
          reason: '$reason: shifts ${shifts.join(', ')}',
        );

        final notes = _notes(score);
        expect(notes.length, greaterThanOrEqualTo(2), reason: reason);
        expect(
          notes.last.writtenNote!.midi % 12,
          keyTonals[score.piece.key],
          reason: '$reason: final note must be the tonic',
        );
        expect(
          (notes.last.writtenNote!.midi -
                  notes[notes.length - 2].writtenNote!.midi)
              .abs(),
          inInclusiveRange(1, 2),
          reason: '$reason: cadence must approach by a step',
        );
      }
    }
  });

  test('level 3 repeats its rhythm between phrases 1 and 3', () {
    for (final seed in matrixSeeds) {
      final etude = EtudeGenerator(level: 3, seed: seed).generate();
      final phrases = etude.score.phrases;
      expect(
        _rhythmSignature(phrases[0]),
        _rhythmSignature(phrases[2]),
        reason: 'seed $seed',
      );
    }
  });

  test('level 3 always adds exactly one accidental over seeds 0-2000', () {
    // The independent review found these seeds emitting zero accidentals
    // before the exhaustive injection. Keep the full list as a regression
    // set and run the count over the whole sweep.
    const formerlyFailing = <int>[
      15,
      29,
      43,
      230,
      360,
      382,
      422,
      463,
      466,
      530,
      713,
      734,
      786,
      815,
      824,
      955,
      999,
      1004,
      1241,
      1416,
      1586,
      1589,
      1623,
      1624,
      1638,
      1645,
      1675,
      1775,
      1795,
    ];
    for (var seed = 0; seed <= 2000; seed++) {
      final etude = EtudeGenerator(level: 3, seed: seed).generate();
      expect(
        _accidentalPitchClasses(etude.score),
        hasLength(1),
        reason: 'level 3 seed $seed must have exactly one accidental',
      );
    }
    for (final seed in formerlyFailing) {
      final etude = EtudeGenerator(level: 3, seed: seed).generate();
      _expectValidCandidate(etude, 'formerly failing level 3 seed $seed');
    }
  });

  test('invalid levels and seeds are rejected explicitly', () {
    for (final level in <int>[-1, 0, 6, 99]) {
      expect(
        () => EtudeLevelSpec.forLevel(level),
        throwsArgumentError,
        reason: 'level $level',
      );
      expect(
        () => EtudeGenerator(level: level, seed: 1),
        throwsArgumentError,
        reason: 'level $level',
      );
    }
    expect(() => EtudeGenerator(level: 1, seed: -1), throwsArgumentError);
    expect(() => EtudeGenerator(level: 1, seed: 0).generate(), returnsNormally);
  });

  test('the approval gate only exposes approved candidates', () {
    final library = GeneratedEtudeLibrary();
    final etude = EtudeGenerator(level: 3, seed: 42).generate();
    final pending = library.register(etude);

    expect(pending.isPendingHuman, isTrue);
    expect(pending.isApproved, isFalse);
    expect(library.approved, isEmpty);
    expect(library.approvedEtudes, isEmpty);
    expect(library.pendingHuman, hasLength(1));

    expect(
      () => library.approve(
        etude.candidateId,
        reviewer: '   ',
        reviewedOn: '2026-11-06',
      ),
      throwsArgumentError,
    );
    expect(
      () => library.approve(
        etude.candidateId,
        reviewer: 'Pedagogue',
        reviewedOn: ' ',
      ),
      throwsArgumentError,
    );

    expect(
      library.approve(
        etude.candidateId,
        reviewer: 'Pedagogue',
        reviewedOn: '2026-11-06',
        notes: 'Stratified sample review.',
      ),
      isTrue,
    );
    expect(library.approved, hasLength(1));
    expect(library.approvedEtudes.single.candidateId, etude.candidateId);
    expect(library.pendingHuman, isEmpty);
    expect(library.approved.single.reviewer, 'Pedagogue');
    expect(library.approved.single.reviewedOn, '2026-11-06');
    expect(
      library.approvalRecords.single['status'],
      CandidateStatus.approved.wireName,
    );

    // Re-registering the same deterministic candidate must not downgrade it.
    final again = library.register(
      EtudeGenerator(level: 3, seed: 42).generate(),
    );
    expect(again.isApproved, isTrue);
    expect(library.approved, hasLength(1));

    final rejected = EtudeGenerator(level: 3, seed: 43).generate();
    library.register(rejected);
    expect(
      library.reject(
        rejected.candidateId,
        reviewer: 'Pedagogue',
        reviewedOn: '2026-11-06',
      ),
      isTrue,
    );
    expect(library.rejected, hasLength(1));
    expect(library.approved, hasLength(1));
    expect(
      library.approve('missing-id', reviewer: 'x', reviewedOn: 'y'),
      isFalse,
    );
  });

  test('an invalid candidate cannot be approved', () {
    final good = EtudeGenerator(level: 1, seed: 1).generate();
    final broken = GeneratedEtude(
      level: good.level,
      seed: good.seed,
      spec: good.spec,
      key: good.key,
      score: Score(piece: good.score.piece, phrases: const <Phrase>[]),
    );
    final candidate = GeneratedEtudeCandidate(etude: broken);
    expect(
      () => candidate.approve(reviewer: 'Pedagogue', reviewedOn: '2026-11-06'),
      throwsStateError,
    );
    expect(candidate.isApproved, isFalse);
  });

  test('a level-mismatched candidate is rejected by the approval gate', () {
    final generated = EtudeGenerator(level: 3, seed: 43).generate();
    final mismatched = GeneratedEtude(
      level: 1,
      seed: generated.seed,
      spec: generated.spec,
      key: generated.key,
      score: generated.score,
    );
    final issues = validateLevelGrammar(mismatched);
    expect(
      issues.map((issue) => issue.code),
      contains('grammar.levelMismatch'),
    );
    final candidate = GeneratedEtudeCandidate(etude: mismatched);
    expect(
      () => candidate.approve(reviewer: 'Pedagogue', reviewedOn: '2026-11-06'),
      throwsStateError,
    );
    expect(candidate.isApproved, isFalse);
  });

  test('a level-3 candidate without its accidental is rejected', () {
    final generated = EtudeGenerator(level: 3, seed: 43).generate();
    final withoutAccidentals = _withoutAccidentals(generated);
    final report = validateCandidateScore(
      withoutAccidentals.score,
      limits: withoutAccidentals.spec.playabilityLimits,
    );
    expect(
      report.playabilityIssues.map((issue) => issue.code),
      contains('playability.accidentalCount'),
    );
    expect(
      validateLevelGrammar(withoutAccidentals).map((issue) => issue.code),
      contains('grammar.accidentalCount'),
    );
    final candidate = GeneratedEtudeCandidate(etude: withoutAccidentals);
    expect(
      () => candidate.approve(reviewer: 'Pedagogue', reviewedOn: '2026-11-06'),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('accidentalCount'),
        ),
      ),
    );
  });

  test('the CLI writes a validated candidate to a scratch folder only', () {
    final assetDirectory = Directory('assets/content/etudes');
    final assetFilesBefore = assetDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .length;
    final temporary = Directory.systemTemp.createTempSync('t3_7_etude_cli_');
    addTearDown(() => temporary.deleteSync(recursive: true));

    final out = StringBuffer();
    final err = StringBuffer();
    final firstOut = Directory('${temporary.path}/first');
    final code = runCli(
      <String>['--level', '3', '--seed', '42', '--out', firstOut.path],
      out: out,
      err: err,
    );
    expect(code, 0, reason: '$out\n$err');
    expect(err.toString(), isEmpty);
    expect(out.toString(), contains('pending-human'));
    expect(out.toString(), contains('not reviewed library content'));

    final file = File(
      '${firstOut.path}${Platform.pathSeparator}etude-candidate-l3-s42.json',
    );
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync());
    final document = parseAuthoringDocument(
      Map<String, dynamic>.from(decoded as Map),
    );
    expect(document.meta!.kind, 'etude');
    expect(
      PlayabilityValidator(
        document.score,
        limits: EtudeLevelSpec.forLevel(3).playabilityLimits,
      ).validate(),
      isEmpty,
    );

    final secondOut = Directory('${temporary.path}/second');
    expect(
      runCli(
        <String>['--level', '3', '--seed', '42', '--out', secondOut.path],
        out: StringBuffer(),
        err: StringBuffer(),
      ),
      0,
    );
    final secondFile = File(
      '${secondOut.path}${Platform.pathSeparator}etude-candidate-l3-s42.json',
    );
    expect(secondFile.readAsStringSync(), file.readAsStringSync());

    final seed43Out = Directory('${temporary.path}/seed43');
    final seed43Err = StringBuffer();
    expect(
      runCli(
        <String>['--level', '3', '--seed', '43', '--out', seed43Out.path],
        out: StringBuffer(),
        err: seed43Err,
      ),
      0,
      reason: seed43Err.toString(),
    );
    expect(
      File(
        '${seed43Out.path}${Platform.pathSeparator}'
        'etude-candidate-l3-s43.json',
      ).existsSync(),
      isTrue,
    );

    expect(
      assetDirectory.listSync(recursive: true).whereType<File>().length,
      assetFilesBefore,
      reason: 'the CLI must not touch the reviewed asset library',
    );

    final rejectedErr = StringBuffer();
    expect(
      runCli(
        <String>[
          '--level',
          '1',
          '--seed',
          '1',
          '--out',
          '${assetDirectory.path}${Platform.pathSeparator}level_1',
        ],
        out: StringBuffer(),
        err: rejectedErr,
      ),
      2,
    );
    expect(rejectedErr.toString(), contains('reviewed asset library'));

    expect(
      runCli(
        <String>['--level', '3'],
        out: StringBuffer(),
        err: StringBuffer(),
      ),
      2,
    );
    expect(
      runCli(
        <String>['--level', '9', '--seed', '1'],
        out: StringBuffer(),
        err: StringBuffer(),
      ),
      2,
    );
    expect(
      runCli(<String>['--help'], out: StringBuffer(), err: StringBuffer()),
      0,
    );
  });

  test('the CLI rejects a level-mismatched candidate', () {
    final temporary = Directory.systemTemp.createTempSync('t3_7_cli_mismatch_');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final err = StringBuffer();
    final code = runCli(
      <String>['--level', '1', '--seed', '43', '--out', temporary.path],
      out: StringBuffer(),
      err: err,
      generateCandidate: (level, seed) =>
          EtudeGenerator(level: 3, seed: 43).generate(),
    );
    expect(code, 1);
    expect(err.toString(), contains('level'));
    expect(temporary.listSync(), isEmpty);
  });

  test('no unlimited claim appears in the generator or its docs', () {
    final files = <String>[
      'lib/content/sight_reading/etude_generator.dart',
      'lib/content/sight_reading/level_spec.dart',
      'lib/content/sight_reading/level_validation.dart',
      'lib/content/sight_reading/library.dart',
      'lib/core/music/playability.dart',
      'tool/content/generate_etude.dart',
      'docs/SIGHT_READING_GENERATOR.md',
      'docs/SIGHT_READING_ETUDES.md',
      'docs/CONTENT_AUTHORING.md',
    ];
    final claim = RegExp(
      r'unlimited\s+(etudes?|content|generated|practice|library|sight-reading)',
      caseSensitive: false,
    );
    for (final path in files) {
      final file = File(path.startsWith('docs/') ? '../$path' : path);
      expect(file.existsSync(), isTrue, reason: 'missing $path');
      final matches = claim.allMatches(file.readAsStringSync());
      expect(
        matches,
        isEmpty,
        reason: '$path must not market generated etudes as unlimited',
      );
    }
  });
}
