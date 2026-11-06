import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/launch_pieces.dart';
import 'package:hear_me_out/core/music/piece.dart';

void main() {
  group('launchPieces', () {
    test('locks exactly 10 pieces with a 5/5 tier split', () {
      expect(launchPieces, hasLength(10));
      expect(launchPiecesForTier(LaunchTier.foundation), hasLength(5));
      expect(launchPiecesForTier(LaunchTier.returner), hasLength(5));
    });

    test('every piece stays inside the V1 metadata rules', () {
      for (final launch in launchPieces) {
        final id = launch.piece.id;

        expect(launch.phraseCount, 4, reason: id);
        expect(launch.piece.capo, 0, reason: id);
        expect(launch.piece.tuning.isStandard, isTrue, reason: id);
        expect(launch.piece.isV1Compatible, isTrue, reason: id);
        expect(
          const <int>{1, 2, 3, 5, 9, 10},
          contains(launch.v1Stage),
          reason: id,
        );
        expect(launch.targetTempoBpm, inInclusiveRange(50, 90), reason: id);
        expect(launch.stageOutcome, isNotEmpty, reason: id);
        expect(launch.techniqueFocus, isNotEmpty, reason: id);
        expect(launch.rangeAndPosition, isNotEmpty, reason: id);
        expect(launch.licenseQuestion, isNotEmpty, reason: id);
        expect(launch.piece.title, isNotEmpty, reason: id);
        expect(launch.piece.composer, isNotEmpty, reason: id);
        expect(launch.piece.key, isNotEmpty, reason: id);
      }
    });

    test('licenses are public-domain or original', () {
      for (final launch in launchPieces) {
        final id = launch.piece.id;
        final status = launch.piece.licenseStatus;

        expect(
          status,
          anyOf(LicenseStatus.publicDomain, LicenseStatus.original),
          reason: id,
        );
        expect(launch.piece.license, status?.wireName, reason: id);
      }
    });

    test('ids are unique and slug-like', () {
      final ids = <String>[for (final launch in launchPieces) launch.piece.id];

      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$')), reason: id);
      }
    });

    test('stage map matches the approved plan', () {
      expect(launchPieceById('greensleeves')?.v1Stage, 1);
      expect(launchPieceById('ode-to-joy')?.v1Stage, 2);
      expect(launchPieceById('amazing-grace')?.v1Stage, 2);
      expect(launchPieceById('down-by-the-riverside')?.v1Stage, 3);
      expect(launchPieceById('original-study-1')?.v1Stage, 3);
      expect(launchPieceById('scarborough-fair')?.v1Stage, 5);
      expect(launchPieceById('londonderry-air')?.v1Stage, 5);
      expect(launchPieceById('bach-minuet-in-g')?.v1Stage, 9);
      expect(launchPieceById('spanish-romance')?.v1Stage, 9);
      expect(launchPieceById('original-study-2')?.v1Stage, 10);
    });

    test('tier mapping matches the approved plan', () {
      for (final id in <String>[
        'greensleeves',
        'ode-to-joy',
        'amazing-grace',
        'down-by-the-riverside',
        'original-study-1',
      ]) {
        expect(launchPieceById(id)?.tier, LaunchTier.foundation, reason: id);
      }

      for (final id in <String>[
        'scarborough-fair',
        'londonderry-air',
        'bach-minuet-in-g',
        'spanish-romance',
        'original-study-2',
      ]) {
        expect(launchPieceById(id)?.tier, LaunchTier.returner, reason: id);
      }
    });

    test('stage outcomes cover only the V1 stages the plan names', () {
      expect(v1StageOutcomes.keys.toSet(), <int>{1, 2, 3, 5, 9, 10});
      for (final launch in launchPieces) {
        expect(v1StageOutcomes, contains(launch.v1Stage));
        expect(launch.stageOutcome, v1StageOutcomes[launch.v1Stage]);
      }
    });

    test('every piece has a V1 stage and a non-empty outcome', () {
      for (final launch in launchPieces) {
        final id = launch.piece.id;

        expect(v1PlacementStages, contains(launch.v1Stage), reason: id);
        expect(launch.stageOutcome.trim(), isNotEmpty, reason: id);
        expect(
          launch.stageOutcome,
          v1StageOutcomes[launch.v1Stage],
          reason: id,
        );
      }
    });

    test('every V1 placement stage has at least one launch piece', () {
      for (final stage in v1PlacementStages) {
        expect(piecesForStage(stage), isNotEmpty, reason: 'stage $stage');
      }
    });

    test('the published stage map contains only V1 stages', () {
      expect(launchPiecesByStage.keys.toSet(), v1PlacementStages.toSet());
      for (final stage in phase2Stages) {
        expect(launchPiecesByStage, isNot(contains(stage)), reason: '$stage');
      }
    });

    test('phase2Stages is exactly the reviewed non-V1 set', () {
      expect(v1PlacementStages, <int>[1, 2, 3, 5, 9, 10]);
      expect(phase2Stages, <int>{4, 6, 7, 8});
    });

    test('placementStageForPiece returns the V1 stage or null', () {
      expect(placementStageForPiece('greensleeves'), 1);
      expect(placementStageForPiece('scarborough-fair'), 5);
      expect(placementStageForPiece('original-study-2'), 10);
      expect(placementStageForPiece('not-a-piece'), isNull);
      expect(placementStageForPiece(''), isNull);
    });

    test('piecesForStage returns the map rows and empty for other stages', () {
      for (final entry in launchPiecesByStage.entries) {
        expect(piecesForStage(entry.key), entry.value);
        for (final launch in entry.value) {
          expect(launch.v1Stage, entry.key, reason: launch.piece.id);
        }
      }
      for (final stage in phase2Stages) {
        expect(piecesForStage(stage), isEmpty, reason: 'stage $stage');
      }
      expect(piecesForStage(12), isEmpty);
      expect(piecesForStage(0), isEmpty);
    });

    test('no piece claims a polyphonic texture', () {
      for (final launch in launchPieces) {
        final id = launch.piece.id;
        final text = <String>[
          launch.texture,
          launch.techniqueFocus,
          launch.rangeAndPosition,
          launch.licenseQuestion,
        ].join(' ').toLowerCase();

        expect(launch.texture, 'monophonic', reason: id);
        expect(text, isNot(contains('polyphon')), reason: id);
        expect(text, isNot(contains('chord')), reason: id);
        expect(text, isNot(contains('two-voice')), reason: id);
        expect(text, isNot(contains('two voice')), reason: id);
      }
    });

    test('public-domain pieces record a source and their legal question', () {
      for (final launch in launchPieces) {
        final id = launch.piece.id;
        if (launch.piece.licenseStatus == LicenseStatus.publicDomain) {
          expect(launch.sourceUrl, isNotNull, reason: id);
          expect(
            launch.licenseQuestion.toLowerCase(),
            contains('public domain'),
          );
        }
        if (launch.piece.licenseStatus == LicenseStatus.original) {
          expect(
            launch.licenseQuestion.toLowerCase(),
            contains('original work'),
          );
        }
      }
    });

    test('IMSLP identifiers point at IMSLP source URLs', () {
      for (final launch in launchPieces) {
        final id = launch.piece.id;
        final imslpId = launch.imslpId;
        if (imslpId == null) continue;

        expect(launch.sourceUrl, contains('imslp.org/wiki/'), reason: id);
        expect(launch.sourceUrl, contains(imslpId), reason: id);
      }
    });

    test(
      'launchPieceById finds known ids and returns null for unknown ids',
      () {
        expect(launchPieceById('greensleeves')?.piece.title, 'Greensleeves');
        expect(
          launchPieceById('bach-minuet-in-g')?.piece.composer,
          contains('Petzold'),
        );
        expect(launchPieceById('not-a-piece'), isNull);
        expect(launchPieceById(''), isNull);
      },
    );

    test('launchPiecesForTier returns only the requested tier', () {
      for (final launch in launchPiecesForTier(LaunchTier.foundation)) {
        expect(launch.tier, LaunchTier.foundation);
      }
      for (final launch in launchPiecesForTier(LaunchTier.returner)) {
        expect(launch.tier, LaunchTier.returner);
      }
    });
  });
}
