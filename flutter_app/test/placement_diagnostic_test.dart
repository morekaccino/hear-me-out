import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/launch_pieces.dart';
import 'package:hear_me_out/content/pieces/placement_starters.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/onboarding_choices.dart';
import 'package:hear_me_out/core/learning/placement.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/placement_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/features/exercises/prompt_view.dart';
import 'package:hear_me_out/features/path/path_screen.dart';
import 'package:hear_me_out/features/phrase/phrase_loop_flag.dart';
import 'package:hear_me_out/features/phrase/phrase_player_screen.dart';
import 'package:hear_me_out/features/placement/placement_flow_screen.dart';
import 'package:hear_me_out/features/placement/placement_prompt_card.dart';
import 'package:hear_me_out/features/profile/profile_screen.dart';
import 'package:hear_me_out/shared/navigation/duo_route.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/placement_controller.dart';
import 'package:hear_me_out/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppColors.applyBrightness(Brightness.light);
    SharedPreferences.setMockInitialValues({});
  });

  group('placement inference', () {
    test('a comfortable reader with all checks lands at stage 10', () {
      final inferred = inferPlacementStage(
        readingLevel: ReadingLevel.comfortable,
        readingCorrect: 3,
        readingTotal: 3,
        playedTarget: true,
        techniqueYes: 3,
      );
      expect(inferred, 10);
      expect(resolvePlacementStage(inferred), 10);
      expect(phase2StageFor(inferred), isNull);
    });

    test('a note-name reader with no checks starts at stage 1', () {
      final inferred = inferPlacementStage(
        readingLevel: ReadingLevel.noteNames,
        readingCorrect: 0,
      );
      expect(inferred, 1);
      expect(resolvePlacementStage(inferred), 1);
    });

    test('phase 2 suggestions map to the nearest V1 stage', () {
      expect(resolvePlacementStage(4), 3);
      expect(resolvePlacementStage(6), 5);
      expect(resolvePlacementStage(7), 5);
      expect(resolvePlacementStage(8), 9);
      expect(phase2StageFor(4), 4);
      expect(phase2StageFor(6), 6);
      expect(phase2StageFor(7), 7);
      expect(phase2StageFor(8), 8);
      expect(phase2StageFor(5), isNull);
      expect(phase2StageFor(9), isNull);
    });

    test('every V1 stage resolves to itself', () {
      for (final stage in placementStages) {
        expect(resolvePlacementStage(stage), stage);
      }
    });
  });

  group('placement starter set', () {
    test('each stage gets three unique real launch pieces', () {
      for (final stage in placementStages) {
        final starters = placementStarterSet(stage);
        expect(starters, hasLength(3), reason: 'stage $stage');
        expect(
          starters.map((piece) => piece.piece.id).toSet(),
          hasLength(3),
          reason: 'stage $stage',
        );
        expect(starters.first.v1Stage, stage, reason: 'stage $stage');
        for (final starter in starters) {
          expect(
            launchPieceById(starter.piece.id),
            isNotNull,
            reason: starter.piece.id,
          );
        }
      }
    });

    test('a returner stage starts with returner pieces', () {
      final starters = placementStarterSet(5);
      expect(starters.first.tier, LaunchTier.returner);
      expect(
        starters.map((piece) => piece.piece.id),
        containsAll(<String>['scarborough-fair', 'londonderry-air']),
      );
    });

    test('a non-V1 stage has no starter set', () {
      expect(placementStarterSet(6), isEmpty);
      expect(placementStarterSet(0), isEmpty);
    });
  });

  group('placement record', () {
    PlacementRecord record({
      int stage = 5,
      int inferredStage = 5,
      int? phase2Stage,
      DateTime? savedAt,
    }) {
      final start = savedAt ?? DateTime(2026, 11, 6, 10);
      return PlacementRecord(
        stage: stage,
        inferredStage: inferredStage,
        phase2Stage: phase2Stage,
        starterPieceIds: const <String>[
          'scarborough-fair',
          'londonderry-air',
          'bach-minuet-in-g',
        ],
        savedAt: start,
        nextRetestAt: start.add(placementRetestInterval),
      );
    }

    test('round-trips through JSON and rejects a Phase 2 target', () {
      final original = record(stage: 9, inferredStage: 9);
      final decoded = PlacementRecord.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.stage, 9);
      expect(decoded.starterPieceIds, original.starterPieceIds);
      expect(decoded.nextRetestAt, original.nextRetestAt);

      expect(
        () => PlacementRecord.fromJson({...original.toJson(), 'stage': 7}),
        throwsFormatException,
      );
      expect(
        () => PlacementRecord.fromJson({
          ...original.toJson(),
          'starterPieceIds': <String>['scarborough-fair'],
        }),
        throwsFormatException,
      );
    });

    test('the re-test interval is four to six weeks', () {
      final savedAt = DateTime(2026, 11, 6, 10);
      final next = savedAt.add(placementRetestInterval);
      expect(next.difference(savedAt).inDays, inInclusiveRange(28, 42));
    });

    test('dismissing the re-test snoozes without changing the stage', () {
      final now = DateTime(2026, 11, 6, 10);
      final due = record(
        stage: 10,
        inferredStage: 8,
        phase2Stage: 8,
        savedAt: now.subtract(const Duration(days: 40)),
      );
      final dismissed = due.dismissRetest(now);
      expect(dismissed.stage, 10);
      expect(dismissed.nextRetestAt, now.add(placementRetestSnooze));
      expect(dismissed.retestDismissedAt, now);
      expect(dismissed.retestDue(now), isFalse);
    });
  });

  group('placement store', () {
    test('saves and loads one versioned record', () async {
      final store = SharedPreferencesPlacementStore();
      final savedAt = DateTime(2026, 11, 6, 10);
      final record = PlacementRecord(
        stage: 5,
        inferredStage: 7,
        phase2Stage: 7,
        starterPieceIds: const <String>[
          'scarborough-fair',
          'londonderry-air',
          'bach-minuet-in-g',
        ],
        savedAt: savedAt,
        nextRetestAt: savedAt.add(placementRetestInterval),
        manualOverride: true,
      );
      await store.save(record);

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.stage, 5);
      expect(loaded.phase2Stage, 7);
      expect(loaded.manualOverride, isTrue);
      expect(loaded.starterPieceIds, record.starterPieceIds);
    });

    test('rejects a future schema instead of guessing', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SharedPreferencesPlacementStore.storageKey,
        jsonEncode({'schemaVersion': 99, 'stage': 5}),
      );
      expect(await SharedPreferencesPlacementStore().load(), isNull);
    });

    test('ignores corrupt storage', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SharedPreferencesPlacementStore.storageKey,
        '{not json',
      );
      expect(await SharedPreferencesPlacementStore().load(), isNull);
    });
  });

  group('placement controller', () {
    test('saving placement leaves progress untouched', () async {
      final progressStore = MemoryProgressStore(
        ProgressState(completedLessons: {allLessons.first.id}, xp: 42),
      );
      final placementStore = MemoryPlacementStore();
      final container = ProviderContainer(
        overrides: [
          progressStoreProvider.overrideWithValue(progressStore),
          placementStoreProvider.overrideWithValue(placementStore),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 6, 10)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(placementControllerProvider.future);
      final record = await container
          .read(placementControllerProvider.notifier)
          .savePlacement(
            inferredStage: 10,
            stage: 10,
            starterPieceIds: const <String>[
              'original-study-2',
              'bach-minuet-in-g',
              'spanish-romance',
            ],
            manualOverride: false,
          );

      expect(record.stage, 10);
      expect(progressStore.value!.xp, 42);
      expect(
        progressStore.value!.completedLessons,
        contains(allLessons.first.id),
      );
      expect(placementStore.value!.stage, 10);
      expect(
        record.nextRetestAt.difference(record.savedAt).inDays,
        inInclusiveRange(28, 42),
      );
    });
  });

  group('placement flow', () {
    Widget buildFlow({
      required MemoryPlacementStore placement,
      required FakePitchSourceFactory sources,
      ReadingLevel readingLevel = ReadingLevel.comfortable,
      int? initialStage,
      bool startAtResult = false,
      DateTime Function()? clock,
    }) {
      return ProviderScope(
        overrides: [
          progressStoreProvider.overrideWithValue(
            MemoryProgressStore(
              ProgressState.fresh(
                settings: const AppSettings(onboardingComplete: true),
              ),
            ),
          ),
          placementStoreProvider.overrideWithValue(placement),
          onboardingStoreProvider.overrideWithValue(
            FakeOnboardingStore(
              OnboardingChoices(hasGuitar: true, readingLevel: readingLevel),
            ),
          ),
          retentionStoreProvider.overrideWithValue(MemoryRetentionStore()),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          pitchSourceFactoryProvider.overrideWithValue(sources.call),
          lessonGraceProvider.overrideWithValue(Duration.zero),
          clockProvider.overrideWithValue(
            clock ?? () => DateTime(2026, 11, 6, 10),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const ValueKey('open-placement'),
                  onPressed: () => Navigator.of(context).push(
                    duoLessonRoute(
                      (_) => PlacementFlowScreen(
                        readingLevel: readingLevel,
                        hasGuitar: true,
                        initialStage: initialStage,
                        startAtResult: startAtResult,
                      ),
                    ),
                  ),
                  child: const Text('OPEN PLACEMENT'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> openFlow(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('open-placement')));
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> answerReading(WidgetTester tester) async {
      final view = tester.widget<PromptView>(find.byType(PromptView));
      final prompt = view.prompt;
      if (prompt is StaffTapPrompt) {
        await tapVisible(
          tester,
          find.byKey(ValueKey('staff-step-${prompt.note.diatonicIndex}')),
        );
      } else if (prompt is ChoicePrompt) {
        final correct = prompt.options.firstWhere(
          (option) => option.id == prompt.correctId,
        );
        await tapVisible(tester, find.text(correct.label));
      }
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('placement-reading-continue')),
      );
      await tester.pumpAndSettle();
    }

    Future<void> skipToResult(WidgetTester tester) async {
      await tapVisible(
        tester,
        find.byKey(const ValueKey('placement-reading-skip')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('placement-playing-skip')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('placement-technique-skip')),
      );
    }

    testWidgets(
      'three screens are skippable and never expose the phrase loop',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        expect(phraseLoopEnabled, isFalse);
        final placement = MemoryPlacementStore();
        await tester.pumpWidget(
          buildFlow(placement: placement, sources: FakePitchSourceFactory()),
        );
        await openFlow(tester);

        expect(find.text('1/3'), findsOneWidget);
        expect(find.text('Quick reading check'), findsOneWidget);
        expect(find.text('SKIP FOR NOW'), findsOneWidget);

        await tapVisible(
          tester,
          find.byKey(const ValueKey('placement-reading-skip')),
        );
        expect(find.text('2/3'), findsOneWidget);
        expect(find.text('Play one note'), findsOneWidget);

        await tapVisible(
          tester,
          find.byKey(const ValueKey('placement-playing-skip')),
        );
        expect(find.text('3/3'), findsOneWidget);
        expect(find.text('Three quick self-checks'), findsOneWidget);

        await tapVisible(
          tester,
          find.byKey(const ValueKey('placement-technique-skip')),
        );
        expect(find.text('Your starting point'), findsOneWidget);
        expect(find.byType(PhrasePlayerScreen), findsNothing);
        expect(
          find.textContaining(RegExp('phrase', caseSensitive: false)),
          findsNothing,
        );
        expect(placement.value, isNull);
        expect(find.byIcon(Icons.favorite_rounded), findsNothing);
        expect(find.byIcon(Icons.diamond_rounded), findsNothing);
      },
    );

    testWidgets(
      'reading plus one played note plus self-checks infer stage 10',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final placement = MemoryPlacementStore();
        final sources = FakePitchSourceFactory();
        await tester.pumpWidget(
          buildFlow(placement: placement, sources: sources),
        );
        await openFlow(tester);

        await answerReading(tester);
        await answerReading(tester);
        await answerReading(tester);
        expect(find.text('2/3'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const ValueKey('placement-mic-start')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('placement-mic-start')));
        await tester.pumpAndSettle();
        final source = sources.created.last;
        for (var frame = 0; frame < 3; frame++) {
          source.emit(
            PitchFrame(
              frequency: 196.0,
              clarity: 0.95,
              rms: 0.2,
              timestamp: DateTime(2026, 11, 6, 10),
            ),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.text('Thanks. That is enough.'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('placement-playing-continue')),
        );
        await tester.pumpAndSettle();
        for (var index = 0; index < 3; index++) {
          await tapVisible(
            tester,
            find.byKey(ValueKey('placement-technique-$index-yes')),
          );
        }
        await tester.tap(
          find.byKey(const ValueKey('placement-technique-continue')),
        );
        await tester.pumpAndSettle();

        final stageText = tester.widget<Text>(
          find.byKey(const ValueKey('placement-result-stage')),
        );
        expect(stageText.data, 'STAGE 10');
        expect(find.textContaining('Phase 2'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('placement-save')));
        await tester.pumpAndSettle();

        final saved = placement.value;
        expect(saved, isNotNull);
        expect(saved!.stage, 10);
        expect(saved.inferredStage, 10);
        expect(saved.manualOverride, isFalse);
        expect(saved.starterPieceIds, hasLength(3));
        for (final id in saved.starterPieceIds) {
          expect(launchPieceById(id), isNotNull, reason: id);
        }
        expect(
          saved.nextRetestAt.difference(saved.savedAt).inDays,
          inInclusiveRange(28, 42),
        );
      },
    );

    testWidgets('the result is editable before it is saved', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final placement = MemoryPlacementStore();
      await tester.pumpWidget(
        buildFlow(
          placement: placement,
          sources: FakePitchSourceFactory(),
          initialStage: 5,
          startAtResult: true,
        ),
      );
      await openFlow(tester);

      expect(find.text('Your starting point'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('placement-stage-9')));
      final stageText = tester.widget<Text>(
        find.byKey(const ValueKey('placement-result-stage')),
      );
      expect(stageText.data, 'STAGE 9');
      expect(placement.value, isNull);

      await tester.tap(find.byKey(const ValueKey('placement-save')));
      await tester.pumpAndSettle();
      expect(placement.value!.stage, 9);
      expect(placement.value!.manualOverride, isTrue);
      expect(
        placement.value!.starterPieceIds,
        containsAll(<String>['bach-minuet-in-g', 'spanish-romance']),
      );
    });

    testWidgets(
      'the re-test prompt is dated four to six weeks out and dismisses',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime(2026, 11, 6, 10);
        final placement = MemoryPlacementStore(
          PlacementRecord(
            stage: 5,
            inferredStage: 5,
            starterPieceIds: const <String>[
              'scarborough-fair',
              'londonderry-air',
              'bach-minuet-in-g',
            ],
            savedAt: now.subtract(const Duration(days: 40)),
            nextRetestAt: now.subtract(const Duration(days: 1)),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              progressStoreProvider.overrideWithValue(
                MemoryProgressStore(
                  ProgressState.fresh(
                    settings: const AppSettings(onboardingComplete: true),
                  ),
                ),
              ),
              placementStoreProvider.overrideWithValue(placement),
              onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
              retentionStoreProvider.overrideWithValue(MemoryRetentionStore()),
              soundServiceProvider.overrideWithValue(FakeSoundService()),
              clockProvider.overrideWithValue(() => now),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: PlacementPromptCard()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Time for a short check-in? Your starting point can be updated.',
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('placement-prompt-skip')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('placement-prompt-skip')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('placement-prompt')), findsNothing);
        expect(placement.value!.stage, 5);
        expect(
          placement.value!.nextRetestAt.difference(now).inDays,
          inInclusiveRange(13, 15),
        );
        expect(placement.value!.retestDismissedAt, now);
      },
    );

    testWidgets('390x844 and 1200x900 render the whole flow without overflow', (
      tester,
    ) async {
      Future<void> checkSize(Size size) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        final placement = MemoryPlacementStore();
        await tester.pumpWidget(
          buildFlow(placement: placement, sources: FakePitchSourceFactory()),
        );
        await openFlow(tester);
        await skipToResult(tester);
        expect(find.text('Your starting point'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await checkSize(const Size(390, 844));
      await checkSize(const Size(1200, 900));
    });
  });

  group('placement entry points', () {
    testWidgets('the path shows the prompt and skip does not block the path', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressStoreProvider.overrideWithValue(
              MemoryProgressStore(
                ProgressState.fresh(
                  settings: const AppSettings(
                    onboardingComplete: true,
                    answerMode: AnswerMode.name,
                  ),
                ),
              ),
            ),
            placementStoreProvider.overrideWithValue(MemoryPlacementStore()),
            onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
            retentionStoreProvider.overrideWithValue(MemoryRetentionStore()),
            soundServiceProvider.overrideWithValue(FakeSoundService()),
            pitchSourceFactoryProvider.overrideWithValue(
              FakePitchSourceFactory(permission: false).call,
            ),
            clockProvider.overrideWithValue(() => DateTime(2026, 11, 6, 10)),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const PathScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('placement-prompt')), findsOneWidget);
      expect(find.text('Not sure where to start?'), findsOneWidget);
      expect(find.text('A short check can place you.'), findsOneWidget);

      final skip = find.byKey(const ValueKey('placement-prompt-skip'));
      await tester.ensureVisible(skip);
      await tester.tap(skip);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('placement-prompt')), findsNothing);
      expect(find.byType(PathScreen), findsOneWidget);
    });

    testWidgets('profile shows the saved stage and opens the override', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime(2026, 11, 6, 10);
      final placement = MemoryPlacementStore(
        PlacementRecord(
          stage: 9,
          inferredStage: 8,
          phase2Stage: 8,
          starterPieceIds: const <String>[
            'bach-minuet-in-g',
            'spanish-romance',
            'original-study-2',
          ],
          savedAt: now,
          nextRetestAt: now.add(placementRetestInterval),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressStoreProvider.overrideWithValue(
              MemoryProgressStore(
                ProgressState.fresh(
                  settings: const AppSettings(onboardingComplete: true),
                ),
              ),
            ),
            placementStoreProvider.overrideWithValue(placement),
            onboardingStoreProvider.overrideWithValue(
              FakeOnboardingStore(
                OnboardingChoices(
                  hasGuitar: true,
                  readingLevel: ReadingLevel.comfortable,
                ),
              ),
            ),
            retentionStoreProvider.overrideWithValue(MemoryRetentionStore()),
            soundServiceProvider.overrideWithValue(FakeSoundService()),
            pitchSourceFactoryProvider.overrideWithValue(
              FakePitchSourceFactory(permission: false).call,
            ),
            clockProvider.overrideWithValue(() => now),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final change = find.byKey(const ValueKey('placement-prompt-start'));
      await tester.ensureVisible(change);
      await tester.pumpAndSettle();
      expect(find.text('Starting point'), findsOneWidget);
      expect(find.text('Stage 9 · Sight-reading'), findsOneWidget);
      expect(find.textContaining('Phase 2'), findsOneWidget);

      await tester.tap(change);
      await tester.pumpAndSettle();
      expect(find.text('Your starting point'), findsOneWidget);
      expect(placement.value!.stage, 9);
    });
  });
}
