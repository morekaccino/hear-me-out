import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/storage/progress_migrations.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> _expectedLessons = [
  'c3u4l1',
  'c3u3l1',
  'c3u10l1',
  'c3u7l1',
  'c3u16l1',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Progress migration pipeline', () {
    test('every fixture migrates to v6 without losing progress', () {
      for (final name in <String>['v1', 'v2', 'v3', 'v4', 'v5', 'v6']) {
        final fixture = _loadFixture(name);
        final migrated = _migrate(fixture);
        expect(migrated['schemaVersion'], 6, reason: name);

        final progress = importProgress(jsonEncode(fixture));
        expect(progress, isNotNull, reason: name);
        final restored = progress!;
        expect(restored.schemaVersion, 6, reason: name);
        expect(
          restored.curriculumVersion,
          ProgressState.currentCurriculumVersion,
        );
        expect(restored.xp, 140, reason: name);
        expect(restored.streak, 4, reason: name);
        expect(restored.notes['G4']!.box, 3, reason: name);
        expect(restored.notes['G4']!.correct, 6, reason: name);
        expect(restored.skills['note:G4']!.box, 3, reason: name);
        expect(
          restored.completedLessons,
          containsAll(_expectedLessons),
          reason: name,
        );
        expect(restored.completedLessons.length, 5, reason: name);
        expect(restored.bestLessonAccuracy['c3u4l1'], 0.8, reason: name);
        if (name != 'v1') {
          expect(
            restored.completedCheckpoints,
            contains('c3u4cp'),
            reason: name,
          );
        }
        expect(restored.settings.answerMode, AnswerMode.play, reason: name);
        expect(restored.settings.toleranceCents, 35, reason: name);
        expect(restored.settings.a4Hz, 442, reason: name);
        expect(restored.recentSessions.single.lessonId, 'c3u4l1', reason: name);
        expect(restored.gems, name == 'v1' ? 500 : 420, reason: name);
        expect(restored.hearts, name == 'v1' ? 5 : 3, reason: name);
        expect(
          restored.settings.themeMode,
          name == 'v1' || name == 'v2'
              ? AppThemeMode.system
              : AppThemeMode.dark,
          reason: name,
        );
        expect(
          restored.contentVersion,
          name == 'v5' || name == 'v6' ? 3 : 1,
          reason: name,
        );
        if (name == 'v5' || name == 'v6') {
          expect(
            restored.phraseProgress.keys,
            containsAll(<String>['twinkle.a', 'twinkle.b']),
          );
        } else {
          expect(restored.phraseProgress, isEmpty, reason: name);
        }
        if (name == 'v5') {
          expect(
            restored.phraseProgressFor('twinkle.a')!.contentVersion,
            1,
            reason: 'v5 evidence predates per-phrase versions',
          );
        } else if (name == 'v6') {
          expect(
            restored.phraseProgressFor('twinkle.a')!.contentVersion,
            2,
            reason: name,
          );
          expect(restored.phraseProgressFor('twinkle.b')!.contentVersion, 1);
        }
      }
    });

    test('v1 gets the default economy and maps legacy lesson ids', () {
      final fixture = _loadFixture('v1');
      expect(fixture['gems'], isNull);
      expect(fixture['hearts'], isNull);

      final migrated = _migrate(fixture);
      expect(migrated['gems'], 500);
      expect(migrated['hearts'], 5);
      expect(migrated['openedChests'], isEmpty);
      expect(migrated['claimedQuests'], isEmpty);

      final restored = importProgress(jsonEncode(fixture))!;
      expect(restored.gems, 500);
      expect(restored.hearts, 5);
      expect(restored.openedChests, isEmpty);
      expect(restored.claimedQuests, isEmpty);
      expect(restored.streakFreezes, 0);
      expect(restored.settings.themeMode, AppThemeMode.system);
      expect(restored.completedLessons, containsAll(_expectedLessons));
      expect(restored.completedLessons.length, 5);
      expect(restored.recentSessions.single.lessonId, 'c3u4l1');
      expect(restored.skills['note:G4']!.reps, 7);
      expect(restored.skills['note:G4']!.stabilityDays, 7.0);
      expect(
        restored.skills['note:G4']!.difficulty,
        closeTo(10 - (6 / 7) * 8, 1e-9),
      );
    });

    test('v2 gets the System appearance while keeping the economy', () {
      final fixture = _loadFixture('v2');
      final settings = fixture['settings'] as Map<String, dynamic>;
      expect(settings.containsKey('themeMode'), isFalse);

      final migrated = _migrate(fixture);
      expect(
        (migrated['settings'] as Map<String, dynamic>)['themeMode'],
        'system',
      );

      final restored = importProgress(jsonEncode(fixture))!;
      expect(restored.settings.themeMode, AppThemeMode.system);
      expect(restored.gems, 420);
      expect(restored.hearts, 3);
      expect(restored.openedChests, contains('c3u4'));
      expect(restored.claimedQuests, contains('lesson'));
      expect(restored.daily.lessons, 2);
    });

    test('v3 migrates note boxes into skill cards and keeps the notes', () {
      final fixture = _loadFixture('v3');
      expect(fixture['skills'], isNull);

      final migrated = _migrate(fixture);
      final skills = migrated['skills'] as Map<String, dynamic>;
      expect(skills.keys, containsAll(<String>['note:G4', 'note:A4']));
      final g4 = skills['note:G4'] as Map<String, dynamic>;
      expect(g4['family'], 'noteReading');
      expect(g4['box'], 3);
      expect(g4['reps'], 7);
      expect(g4['correct'], 6);
      expect(g4['lapses'], 1);
      expect((skills['note:A4'] as Map<String, dynamic>)['stabilityDays'], 1.0);

      final restored = importProgress(jsonEncode(fixture))!;
      expect(restored.skills['note:G4']!.box, 3);
      expect(restored.skills['note:G4']!.correct, 6);
      expect(restored.skills['note:G4']!.correctDays.length, 2);
      expect(restored.notes['G4']!.box, 3);
      expect(restored.settings.themeMode, AppThemeMode.dark);
    });

    test('v4 gets contentVersion and an empty phrase map without rebuilding skills', () {
      final fixture = _loadFixture('v4');
      expect(fixture['contentVersion'], isNull);
      expect(fixture['phraseProgress'], isNull);

      final migrated = _migrate(fixture);
      expect(migrated['contentVersion'], 1);
      expect(migrated['phraseProgress'], isEmpty);

      final restored = importProgress(jsonEncode(fixture))!;
      expect(restored.contentVersion, 1);
      expect(restored.phraseProgress, isEmpty);
      expect(restored.completedCheckpoints, contains('c3u4cp'));
      expect(restored.skills['note:G4']!.stabilityDays, 21.0);
      expect(restored.skills['note:G4']!.productionCorrect, 2);
    });

    test('v5 gets a per-phrase content version without resetting evidence', () {
      final fixture = _loadFixture('v5');
      final before =
          (fixture['phraseProgress'] as Map<String, dynamic>)['twinkle.a']
              as Map<String, dynamic>;
      expect(before.containsKey('contentVersion'), isFalse);

      final migrated = _migrate(fixture);
      final phrase =
          (migrated['phraseProgress'] as Map<String, dynamic>)['twinkle.a']
              as Map<String, dynamic>;
      expect(phrase['contentVersion'], 1);
      expect(phrase['reps'], 5);
      expect(phrase['correct'], 6);
      expect(phrase['performanceDays'], before['performanceDays']);
      expect(migrated['contentVersion'], 3);

      final restored = importProgress(jsonEncode(fixture))!;
      expect(restored.phraseProgressFor('twinkle.a')!.contentVersion, 1);
      expect(restored.phraseProgressFor('twinkle.a')!.reps, 5);
      expect(restored.contentVersion, 3);
    });

    test('v6 keeps an explicit phrase content version', () {
      final fixture = _loadFixture('v6');
      final restored = importProgress(jsonEncode(fixture))!;
      expect(restored.phraseProgressFor('twinkle.a')!.contentVersion, 2);
      expect(restored.phraseProgressFor('twinkle.b')!.contentVersion, 1);
      expect(restored.phraseProgressFor('twinkle.a')!.reps, 5);
    });

    test('v4 with empty skills rebuilds note skills from boxes', () {
      final fixture = _loadFixture('v4')..['skills'] = <String, dynamic>{};
      expect(fixture['skills'], isEmpty);

      final restored = importProgress(jsonEncode(fixture))!;
      expect(restored.skills.keys, contains('note:G4'));
      expect(restored.skills['note:G4']!.box, 3);
      expect(restored.skills['note:G4']!.reps, 7);
    });

    test('a contentVersion below 1 is rejected', () {
      final fixture = _loadFixture('v5')..['contentVersion'] = 0;
      final result = migrateProgress(fixture);
      expect(result, isA<MigrationFailure>());
      expect(importProgress(jsonEncode(fixture)), isNull);
    });

    test('v6 is idempotent and keeps raw phrase evidence', () {
      final fixture = _loadFixture('v6');
      final once = _migrate(fixture);
      expect(once, equals(fixture));
      expect(identical(once, fixture), isFalse);

      final twice = _migrate(once);
      expect(twice, equals(once));
      expect(identical(twice, once), isFalse);

      final restored = importProgress(jsonEncode(fixture))!;
      expect(restored.contentVersion, 3);
      final phrase = restored.phraseProgressFor('twinkle.a')!;
      expect(phrase.contentVersion, 2);
      expect(phrase.reps, 5);
      expect(phrase.correct, 6);
      expect(phrase.correctDays, hasLength(3));
      expect(phrase.performanceDays, hasLength(3));
      expect(phrase.performanceSpanDays, 14);
      expect(phrase.bestTempoBpm, 84);
      expect(phrase.bestAccuracy, 0.92);
      final second = restored.phraseProgressFor('twinkle.b')!;
      expect(second.reps, 2);
      expect(second.performanceDays, hasLength(1));
      expect(restored.phraseProgressFor('missing'), isNull);
    });

    test('migration never mutates the input map', () {
      final fixture = _loadFixture('v1');
      final before = jsonEncode(fixture);
      _migrate(fixture);
      expect(jsonEncode(fixture), before);
      expect(fixture['schemaVersion'], 1);
      expect(fixture['gems'], isNull);
      final note = (fixture['notes'] as Map<String, dynamic>)['G4']!;
      expect((note as Map<String, dynamic>)['box'], 3);
    });

    test('unknown top-level fields survive migration and a save roundtrip', () {
      final fixture = _loadFixture('v2');
      fixture['futureTopLevel'] = <String, dynamic>{
        'flag': true,
        'values': <int>[1, 2, 3],
      };

      final migrated = _migrate(fixture);
      expect(
        migrated['futureTopLevel'],
        equals(<String, dynamic>{
          'flag': true,
          'values': <int>[1, 2, 3],
        }),
      );

      final restored = importProgress(jsonEncode(fixture))!;
      final exported =
          jsonDecode(exportProgress(restored)) as Map<String, dynamic>;
      expect(
        exported['futureTopLevel'],
        equals(<String, dynamic>{
          'flag': true,
          'values': <int>[1, 2, 3],
        }),
      );
    });

    test('future, old, and invalid schema versions are rejected', () {
      for (final version in <Object>[0, -1, 7, 999]) {
        final result = migrateProgress(<String, dynamic>{
          'schemaVersion': version,
        });
        expect(result, isA<MigrationFailure>(), reason: '$version');
        expect(
          importProgress(
            jsonEncode(<String, dynamic>{'schemaVersion': version}),
          ),
          isNull,
          reason: '$version',
        );
      }
      expect(
        migrateProgress(<String, dynamic>{'schemaVersion': '6'}),
        isA<MigrationFailure>(),
      );
      expect(migrateProgress(<String, dynamic>{}), isA<MigrationFailure>());
      expect(importProgress('{"schemaVersion": 7}'), isNull);
    });

    test('malformed fields fail cleanly', () {
      final cases = <String, Map<String, dynamic>>{
        'non-numeric economy': _loadFixture('v1')..['gems'] = 'many',
        'settings not an object': _loadFixture('v2')
          ..['settings'] = <dynamic>[],
        'notes not an object': _loadFixture('v3')..['notes'] = <dynamic>[],
        'note entry not an object': _loadFixture('v3')
          ..['notes'] = <String, dynamic>{'G4': 'bad'},
        'phrase progress not an object': _loadFixture('v5')
          ..['phraseProgress'] = <dynamic>[],
        'phrase performance day': _v5Phrase(<String, dynamic>{
          'performanceDays': <String>['not-a-day'],
        }),
        'phrase best accuracy': _v5Phrase(<String, dynamic>{
          'bestAccuracy': 'high',
        }),
        'phrase first performance day': _v5Phrase(<String, dynamic>{
          'firstPerformanceDay': 'not-a-day',
        }),
        'phrase due date': _v5Phrase(<String, dynamic>{'dueAt': 'not-a-date'}),
        'phrase content version': _v6Phrase(<String, dynamic>{
          'contentVersion': 0,
        }),
      };

      for (final entry in cases.entries) {
        final result = migrateProgress(entry.value);
        expect(result, isA<MigrationFailure>(), reason: entry.key);
        expect(
          (result as MigrationFailure).reason,
          isNotEmpty,
          reason: entry.key,
        );
        expect(
          importProgress(jsonEncode(entry.value)),
          isNull,
          reason: entry.key,
        );
      }
    });

    test(
      'malformed known fields fail with FormatException, not a type error',
      () {
        final cases = <Map<String, dynamic>>[
          <String, dynamic>{'schemaVersion': 6, 'daily': <dynamic>[]},
          <String, dynamic>{
            'schemaVersion': 6,
            'bestLessonAccuracy': <dynamic>[],
          },
          <String, dynamic>{'schemaVersion': 6, 'completedLessons': 'nope'},
          <String, dynamic>{
            'schemaVersion': 6,
            'recentSessions': <dynamic>[1],
          },
          <String, dynamic>{'schemaVersion': 6, 'xp': 'many'},
        ];
        for (final json in cases) {
          expect(migrateProgress(json), isA<MigrationFailure>());
          expect(() => ProgressState.fromJson(json), throwsFormatException);
          expect(importProgress(jsonEncode(json)), isNull);
        }
      },
    );
  });

  group('PhraseProgress', () {
    test('roundtrips every field', () {
      final original = PhraseProgress(
        phraseId: 'twinkle.a',
        stabilityDays: 12.5,
        difficulty: 4.25,
        dueAt: DateTime(2026, 11, 10, 9, 30),
        reps: 4,
        lapses: 1,
        correct: 5,
        incorrect: 1,
        correctDays: <String>{'2026-10-20', '2026-10-27'},
        performanceDays: <String>{'2026-10-20', '2026-10-27', '2026-11-03'},
        firstPerformanceDay: '2026-10-20',
        lastPerformanceAt: DateTime(2026, 11, 3, 9, 5),
        bestTempoBpm: 84,
        bestAccuracy: 0.92,
        contentVersion: 3,
      );

      final restored = PhraseProgress.fromJson(original.toJson());
      expect(restored.phraseId, 'twinkle.a');
      expect(restored.stabilityDays, 12.5);
      expect(restored.difficulty, 4.25);
      expect(restored.dueAt, DateTime(2026, 11, 10, 9, 30));
      expect(restored.reps, 4);
      expect(restored.lapses, 1);
      expect(restored.correct, 5);
      expect(restored.incorrect, 1);
      expect(restored.correctDays, original.correctDays);
      expect(restored.performanceDays, original.performanceDays);
      expect(restored.firstPerformanceDay, '2026-10-20');
      expect(restored.lastPerformanceAt, DateTime(2026, 11, 3, 9, 5));
      expect(restored.bestTempoBpm, 84);
      expect(restored.bestAccuracy, 0.92);
      expect(restored.contentVersion, 3);
      expect(restored.needsRetestFor(3), isFalse);
      expect(restored.needsRetestFor(4), isTrue);
      expect(restored.performanceSpanDays, 14);
      expect(restored.accuracy, closeTo(5 / 6, 1e-9));
    });

    test(
      'exposes raw counters and calendar-day spans without a mastery claim',
      () {
        final phrase = PhraseProgress(
          phraseId: 'p',
          reps: 7,
          correct: 6,
          incorrect: 1,
          correctDays: <String>{'2026-01-01', '2026-01-04'},
          performanceDays: <String>{'2026-01-01', '2026-01-04', '2026-01-08'},
          firstPerformanceDay: '2026-01-01',
        );
        expect(phrase.reps, 7);
        expect(phrase.correct, 6);
        expect(phrase.incorrect, 1);
        expect(phrase.correctDays, hasLength(2));
        expect(phrase.performanceDays, hasLength(3));
        expect(phrase.performanceSpanDays, 7);
        expect(phrase.lastPerformanceDay, '2026-01-08');
        expect(phrase.accuracy, closeTo(6 / 7, 1e-9));

        final oneDay = PhraseProgress(
          phraseId: 'p',
          performanceDays: <String>{'2026-01-01'},
        );
        expect(oneDay.performanceSpanDays, 0);

        // A seven-day calendar week that contains a daylight-saving change must
        // not collapse to six elapsed days.
        final dstWeek = PhraseProgress(
          phraseId: 'dst',
          performanceDays: <String>{'2026-03-07', '2026-03-10', '2026-03-14'},
          firstPerformanceDay: '2026-03-07',
        );
        expect(dstWeek.performanceSpanDays, 7);
      },
    );
  });

  group('Progress store', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed migration is quarantined and does not overwrite the stored document', () async {
      final malformed = jsonEncode(_loadFixture('v3')..['notes'] = <dynamic>[]);
      SharedPreferences.setMockInitialValues({
        SharedPreferencesProgressStore.storageKey: malformed,
      });

      final store = SharedPreferencesProgressStore();
      expect(await store.load(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(SharedPreferencesProgressStore.storageKey),
        malformed,
      );
      expect(
        prefs.getString(SharedPreferencesProgressStore.unreadableKey),
        malformed,
      );
    });

    test(
      'a future document is quarantined and survives a fresh save',
      () async {
        final future = jsonEncode(<String, dynamic>{
          'schemaVersion': 7,
          'xp': 999,
        });
        SharedPreferences.setMockInitialValues({
          SharedPreferencesProgressStore.storageKey: future,
        });

        final store = SharedPreferencesProgressStore();
        expect(await store.load(), isNull);
        await store.save(ProgressState.fresh());

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(SharedPreferencesProgressStore.storageKey),
          contains('"schemaVersion":6'),
        );
        expect(
          prefs.getString(SharedPreferencesProgressStore.unreadableKey),
          future,
        );
      },
    );

    test(
      'the controller fallback preserves a future document across a save',
      () async {
        final future = jsonEncode(<String, dynamic>{
          'schemaVersion': 7,
          'xp': 999,
        });
        SharedPreferences.setMockInitialValues({
          SharedPreferencesProgressStore.storageKey: future,
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);
        final data = await container.read(appControllerProvider.future);
        expect(data.progress.xp, 0);

        await container
            .read(appControllerProvider.notifier)
            .completeOnboarding(const AppSettings());

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(SharedPreferencesProgressStore.unreadableKey),
          future,
        );
        expect(
          prefs.getString(SharedPreferencesProgressStore.storageKey),
          contains('"schemaVersion":6'),
        );
      },
    );

    test('v6 progress saves and reloads phrase content version', () async {
      final store = SharedPreferencesProgressStore();
      final progress = ProgressState.fresh();
      progress.contentVersion = 2;
      progress.phraseProgress['twinkle.a'] = PhraseProgress(
        phraseId: 'twinkle.a',
        reps: 4,
        correct: 5,
        correctDays: <String>{'2026-10-20', '2026-10-27'},
        performanceDays: <String>{'2026-10-20', '2026-10-27', '2026-11-03'},
        firstPerformanceDay: '2026-10-20',
        contentVersion: 3,
      );

      await store.save(progress);
      final reloaded = await SharedPreferencesProgressStore().load();
      expect(reloaded, isNotNull);
      expect(reloaded!.contentVersion, 2);
      final phrase = reloaded.phraseProgress['twinkle.a']!;
      expect(phrase.reps, 4);
      expect(phrase.correctDays, hasLength(2));
      expect(phrase.performanceSpanDays, 14);
      expect(phrase.contentVersion, 3);
    });
  });
}

Map<String, dynamic> _loadFixture(String name) {
  final file = File('test/fixtures/progress/$name.json');
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Fixture $name is not a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}

Map<String, dynamic> _migrate(Map<String, dynamic> json) {
  final result = migrateProgress(json);
  expect(result, isA<MigrationSuccess>());
  return (result as MigrationSuccess).json;
}

Map<String, dynamic> _v5Phrase(Map<String, dynamic> phrase) =>
    <String, dynamic>{
      'schemaVersion': 5,
      'phraseProgress': <String, dynamic>{'p': phrase},
    };

Map<String, dynamic> _v6Phrase(Map<String, dynamic> phrase) =>
    <String, dynamic>{
      'schemaVersion': 6,
      'phraseProgress': <String, dynamic>{'p': phrase},
    };
