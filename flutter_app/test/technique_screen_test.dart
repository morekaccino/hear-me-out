import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/content/technique/technique_content.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/technique/technique_screen.dart';
import 'package:hear_me_out/shared/audio/sound_service.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    double delta = 300,
  }) async {
    await tester.scrollUntilVisible(finder, delta);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Widget buildScreen() {
    return ProviderScope(
      overrides: [soundServiceProvider.overrideWithValue(FakeSoundService())],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const TechniqueScreen(),
      ),
    );
  }

  Widget buildApp({FakePitchSourceFactory? factory, FakeSoundService? sounds}) {
    final sources = factory ?? FakePitchSourceFactory();
    return ProviderScope(
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
        onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        pitchSourceFactoryProvider.overrideWithValue(sources.call),
        soundServiceProvider.overrideWithValue(sounds ?? FakeSoundService()),
      ],
      child: const HearMeOutApp(),
    );
  }

  testWidgets('opens from the Practice hub', (tester) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();

    await reveal(tester, find.text('Technique check'));
    await tester.tap(find.text('Technique check'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Technique'), findsOneWidget);
    expect(find.text('Stop if it hurts'), findsOneWidget);
    expect(find.textContaining('pain, numbness, or tingling'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening Technique stops the tuner before any sound plays', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    final factory = FakePitchSourceFactory();
    final sounds = FakeSoundService();
    await tester.pumpWidget(buildApp(factory: factory, sounds: sounds));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START TUNER'));
    await tester.pumpAndSettle();
    expect(factory.created, hasLength(1));
    final source = factory.created.single;
    expect(source.started, isTrue);
    expect(find.text('STOP TUNER'), findsOneWidget);

    // The tuner is now listening. Opening Technique must tear it down before
    // the new route can play tap sounds.
    sounds.played.clear();
    await reveal(tester, find.text('Technique check'));
    await tester.tap(find.text('Technique check'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byType(TechniqueScreen), findsOneWidget);
    expect(source.started, isFalse);
    expect(source.disposed, isTrue);
    expect(sounds.played, isEmpty);
    expect(find.text('Technique'), findsOneWidget);

    await reveal(tester, find.byKey(const ValueKey('technique-drill-toggle')));
    await tester.tap(find.byKey(const ValueKey('technique-drill-toggle')));
    await tester.pump();
    expect(sounds.played, contains(Sfx.uiTapPrimary));
  });

  testWidgets('checklist state is dropped when the screen closes', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Technique check'));
    await tester.tap(find.text('Technique check'));
    await tester.pumpAndSettle();

    await reveal(tester, find.byKey(const ValueKey('technique-item-1-0')));
    await tester.tap(find.byKey(const ValueKey('technique-item-1-0')));
    await tester.pump();
    expect(find.text('1/3 checked'), findsOneWidget);

    await reveal(
      tester,
      find.byKey(const ValueKey('technique-back')),
      delta: -300,
    );
    await tester.tap(find.byKey(const ValueKey('technique-back')));
    await tester.pumpAndSettle();
    expect(find.text('Practice'), findsWidgets);

    await reveal(tester, find.text('Technique check'));
    await tester.tap(find.text('Technique check'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('0/3 checked'), findsOneWidget);
  });

  testWidgets('checks items and rates the rubric for the session only', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final firstItem = techniqueForStage(1)!.items.first;
    expect(find.text(firstItem), findsOneWidget);
    expect(find.text('0/3 checked'), findsOneWidget);

    await reveal(tester, find.byKey(const ValueKey('technique-item-1-0')));
    await tester.tap(find.byKey(const ValueKey('technique-item-1-0')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('technique-check-1-0')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(find.text('1/3 checked'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('technique-item-1-0')));
    await tester.pump();
    expect(find.text('0/3 checked'), findsOneWidget);

    await reveal(tester, find.text('Self-rating'));
    expect(
      tester.getSize(find.byKey(const ValueKey('technique-rating-1-0-3'))),
      const Size(44, 44),
    );
    await tester.tap(find.byKey(const ValueKey('technique-rating-1-0-3')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the drill counts down, stops, and cancels on dispose', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await reveal(tester, find.byKey(const ValueKey('technique-drill-toggle')));

    String timerText() => tester
        .widget<Text>(find.byKey(const ValueKey('technique-drill-time')))
        .data!;

    expect(timerText(), '1:00');
    await tester.tap(find.byKey(const ValueKey('technique-drill-toggle')));
    await tester.pump();
    expect(find.text('STOP DRILL'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(timerText(), '0:59');

    await tester.tap(find.byKey(const ValueKey('technique-drill-toggle')));
    await tester.pump();
    expect(find.text('START 60-SECOND DRILL'), findsOneWidget);
    expect(timerText(), '1:00');
    await tester.pump(const Duration(seconds: 2));
    expect(timerText(), '1:00');

    // Start again, then tear the screen down while it is running. A leaked
    // Timer.periodic would keep firing and the test would fail with a pending
    // timer or a setState-after-dispose error.
    await tester.tap(find.byKey(const ValueKey('technique-drill-toggle')));
    await tester.pump(const Duration(seconds: 2));
    expect(timerText(), '0:58');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the drill completes at sixty seconds', (tester) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await reveal(tester, find.byKey(const ValueKey('technique-drill-toggle')));
    await tester.tap(find.byKey(const ValueKey('technique-drill-toggle')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 60));

    final timer = tester.widget<Text>(
      find.byKey(const ValueKey('technique-drill-time')),
    );
    expect(timer.data, '0:00');
    expect(find.text('Drill complete. Shake out your hands.'), findsOneWidget);
  });

  testWidgets('the pain warning stays above the fold and no hearts show', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final warning = find.textContaining('pain, numbness, or tingling');
    expect(warning, findsOneWidget);
    expect(tester.getRect(warning).bottom, lessThan(844));
    expect(find.text('Stop if it hurts'), findsOneWidget);

    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
  });

  testWidgets('a 390 px phone and a wide layout both fit without overflow', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await reveal(tester, find.textContaining('Demo video pending'));
    expect(find.text('VIDEO PENDING'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    setSize(tester, const Size(1200, 900));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.text('Technique'), findsOneWidget);
    expect(tester.getSize(find.byType(ListView)).width, lessThanOrEqualTo(720));
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching stages swaps the checklist and drill', (tester) async {
    setSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('technique-stage-9')));
    await tester.pump();

    expect(find.text('Silent position shifts'), findsOneWidget);
    expect(
      find.text(
        'Lead the shift from the shoulder and keep the thumb behind the neck.',
      ),
      findsOneWidget,
    );
    await reveal(tester, find.text('Silent shift ladder'));
    expect(find.text('Silent shift ladder'), findsOneWidget);

    await reveal(tester, find.textContaining('Demo video pending'));
    expect(find.textContaining('Demo video pending'), findsOneWidget);
  });
}
