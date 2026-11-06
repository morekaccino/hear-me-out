import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/onboarding_choices.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/onboarding/onboarding_pieces.dart';
import 'package:hear_me_out/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeOnboardingStore onboarding;
  late MemoryProgressStore progressStore;
  late FakeAudioEngine audioEngine;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    onboarding = FakeOnboardingStore();
    progressStore = MemoryProgressStore(ProgressState.fresh());
    audioEngine = FakeAudioEngine();
  });

  Widget buildApp({OnboardingStore? store, FakePitchSourceFactory? sources}) {
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(progressStore),
        onboardingStoreProvider.overrideWithValue(store ?? onboarding),
        audioEngineProvider.overrideWithValue(audioEngine),
        pitchSourceFactoryProvider.overrideWithValue(
          (sources ?? FakePitchSourceFactory(permission: false)).call,
        ),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
      ],
      child: const HearMeOutApp(),
    );
  }

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openPieces(WidgetTester tester, {bool hasGuitar = true}) async {
    await tester.tap(find.text(hasGuitar ? 'YES, I HAVE IT' : 'NOT NOW'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm a slow reader"));
    await tester.pumpAndSettle();
  }

  testWidgets('three screens run in order and back returns to each one', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Do you have your guitar?'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.text('YES, I HAVE IT'));
    await tester.pumpAndSettle();
    expect(find.text('How well do you read?'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(find.text("I'm a slow reader"));
    await tester.pumpAndSettle();
    expect(find.text('Pick a first piece'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('How well do you read?'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Do you have your guitar?'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('"Not now" advances and records that there is no guitar', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('NOT NOW'));
    await tester.pumpAndSettle();
    expect(find.text('How well do you read?'), findsOneWidget);

    await tester.tap(find.text("I'm a slow reader"));
    await tester.pumpAndSettle();
    await tapText(tester, 'Greensleeves');
    await tapText(tester, 'START PLAYING');

    expect(onboarding.value?.hasGuitar, isFalse);
    expect(find.text('Open Strings'), findsOneWidget);
  });

  testWidgets('reading level choice records the matching enum', (tester) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('YES, I HAVE IT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm comfortable reading"));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ode to Joy');
    await tapText(tester, 'START PLAYING');

    expect(onboarding.value?.readingLevel, ReadingLevel.comfortable);
    expect(onboarding.value?.firstPieceId, 'ode-to-joy');
  });

  testWidgets('"Not sure" defaults to slow reader', (tester) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('YES, I HAVE IT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not sure'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a first piece'), findsOneWidget);

    await tapText(tester, 'Choose later');

    expect(onboarding.value?.readingLevel, ReadingLevel.slowReader);
  });

  testWidgets('piece cards show three options and choose later picks first', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await openPieces(tester);

    expect(onboardingPieces, hasLength(3));
    expect(find.text('Greensleeves'), findsOneWidget);
    expect(find.text('Ode to Joy'), findsOneWidget);
    expect(find.text('Amazing Grace'), findsOneWidget);

    await tapText(tester, 'Choose later');

    expect(onboarding.value?.firstPieceId, onboardingPieces.first.id);
    expect(find.text('Open Strings'), findsOneWidget);
  });

  testWidgets('finish saves choices and opens the path', (tester) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await openPieces(tester);

    await tapText(tester, 'Amazing Grace');
    await tapText(tester, 'START PLAYING');

    final choices = onboarding.value;
    expect(onboarding.saveCount, 1);
    expect(choices?.hasGuitar, isTrue);
    expect(choices?.readingLevel, ReadingLevel.slowReader);
    expect(choices?.firstPieceId, 'amazing-grace');
    expect(choices?.completedAt, isNotNull);
    expect(progressStore.value?.settings.onboardingComplete, isTrue);
    expect(find.text('Open Strings'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('onboarding shows no hearts, gems, streak, or XP', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    void expectNoEconomy() {
      for (final word in ['heart', 'gem', 'streak', 'XP', 'quest']) {
        expect(
          find.textContaining(word, findRichText: false),
          findsNothing,
          reason: 'Found "$word" on onboarding',
        );
      }
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byIcon(Icons.diamond_rounded), findsNothing);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);
      expect(find.byIcon(Icons.inventory_2_rounded), findsNothing);
    }

    expectNoEconomy();
    await tester.tap(find.text('YES, I HAVE IT'));
    await tester.pumpAndSettle();
    expectNoEconomy();
    await tester.tap(find.text("I'm a slow reader"));
    await tester.pumpAndSettle();
    expectNoEconomy();
  });

  testWidgets('390x844 layout does not overflow on any screen', (tester) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('YES, I HAVE IT'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text("I'm a slow reader"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide layout reaches the path with its side rail', (
    tester,
  ) async {
    setSize(tester, const Size(1200, 900));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await openPieces(tester);
    await tapText(tester, 'Greensleeves');
    await tapText(tester, 'START PLAYING');

    expect(find.byKey(const ValueKey('side-rail')), findsOneWidget);
  });

  testWidgets('preview button plays the fake audio engine', (tester) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await openPieces(tester);

    final preview = find.byKey(const ValueKey('preview-greensleeves'));
    await tester.ensureVisible(preview);
    await tester.pumpAndSettle();
    await tester.tap(preview);
    await tester.pumpAndSettle();

    expect(audioEngine.played, hasLength(1));
    expect(audioEngine.played.single.events, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('corrupt onboarding JSON does not block the flow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesOnboardingStore.storageKey: '{not json',
    });
    setSize(tester, const Size(390, 844));

    final store = SharedPreferencesOnboardingStore();
    expect(await store.load(), isNull);

    await tester.pumpWidget(buildApp(store: store));
    await tester.pumpAndSettle();
    await openPieces(tester);
    await tapText(tester, 'Greensleeves');
    await tapText(tester, 'START PLAYING');

    expect(find.text('Open Strings'), findsOneWidget);
    final loaded = await store.load();
    expect(loaded?.firstPieceId, 'greensleeves');
  });

  testWidgets('future onboarding JSON does not block the flow', (tester) async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesOnboardingStore.storageKey: jsonEncode({
        'schemaVersion':
            SharedPreferencesOnboardingStore.currentSchemaVersion + 1,
        'hasGuitar': true,
      }),
    });
    setSize(tester, const Size(390, 844));

    final store = SharedPreferencesOnboardingStore();
    expect(await store.load(), isNull);

    await tester.pumpWidget(buildApp(store: store));
    await tester.pumpAndSettle();
    await openPieces(tester);
    await tapText(tester, 'Ode to Joy');
    await tapText(tester, 'START PLAYING');

    expect(find.text('Open Strings'), findsOneWidget);
    expect((await store.load())?.firstPieceId, 'ode-to-joy');
  });

  group('SharedPreferencesOnboardingStore', () {
    test('round-trips choices with a schema version', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesOnboardingStore();
      final completedAt = DateTime.utc(2026, 1, 2, 3, 4, 5);

      await store.save(
        OnboardingChoices(
          hasGuitar: true,
          readingLevel: ReadingLevel.comfortable,
          firstPieceId: 'ode-to-joy',
          completedAt: completedAt,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(SharedPreferencesOnboardingStore.storageKey);
      expect(jsonDecode(raw!)['schemaVersion'], 1);

      final loaded = await store.load();
      expect(loaded?.hasGuitar, isTrue);
      expect(loaded?.readingLevel, ReadingLevel.comfortable);
      expect(loaded?.firstPieceId, 'ode-to-joy');
      expect(loaded?.completedAt, completedAt);
    });

    test('corrupt JSON returns null', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesOnboardingStore.storageKey: '{not json',
      });
      final store = SharedPreferencesOnboardingStore();
      expect(await store.load(), isNull);
    });

    test('future schema version returns null', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesOnboardingStore.storageKey: jsonEncode({
          'schemaVersion':
              SharedPreferencesOnboardingStore.currentSchemaVersion + 1,
          'hasGuitar': true,
        }),
      });
      final store = SharedPreferencesOnboardingStore();
      expect(await store.load(), isNull);
    });

    test('unknown reading level returns null', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesOnboardingStore.storageKey: jsonEncode({
          'schemaVersion': 1,
          'readingLevel': 'wizard',
        }),
      });
      final store = SharedPreferencesOnboardingStore();
      expect(await store.load(), isNull);
    });

    test('clear removes saved choices', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesOnboardingStore();
      await store.save(const OnboardingChoices(hasGuitar: false));
      expect(await store.load(), isNotNull);
      await store.clear();
      expect(await store.load(), isNull);
    });
  });
}
