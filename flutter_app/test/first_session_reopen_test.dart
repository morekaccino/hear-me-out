import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/audio/phrase_scorer.dart';
import 'package:hear_me_out/core/audio/phrase_verifier.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/features/first_session/first_session_screen.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

PhraseVerification _verification() {
  const result = PhraseResult(
    outcome: AttemptOutcome.correct,
    notes: <NoteResult>[],
    noteAccuracy: 1,
    medianCents: 0,
    meanOnsetErrorMs: 0,
    driftMsPerBar: 0,
    timingWithinTolerance: true,
    complete: true,
    timingIssue: null,
    practicePass: true,
    performanceReady: true,
    extraNotes: 0,
    falseStart: false,
    earlyStop: false,
    timingToleranceMs: 80,
    intonationInTune: true,
  );
  return const PhraseVerification(
    outcome: AttemptOutcome.correct,
    noteAccuracy: 1,
    timingWithinTolerance: true,
    complete: true,
    worstBar: null,
    confidence: 1,
    practicePass: true,
    performanceReady: true,
    correction: 'Clean take. Keep the same steady pulse.',
    result: result,
  );
}

Widget _fakePlayer(BuildContext context) {
  return Scaffold(
    body: Center(
      child: ElevatedButton(
        key: const ValueKey('fake-player-finish'),
        onPressed: () => Navigator.of(context).pop(_verification()),
        child: const Text('Finish take'),
      ),
    ),
  );
}

Widget _fakeRecording(
  BuildContext context,
  void Function(RecordingTake? take) onSaved,
  VoidCallback onSkip,
) {
  return Center(
    child: ElevatedButton(
      key: const ValueKey('fake-recording-skip'),
      onPressed: onSkip,
      child: const Text('Skip recording'),
    ),
  );
}

ProgressState _profile({
  FirstSessionStatus status = FirstSessionStatus.notStarted,
}) {
  return ProgressState.fresh(
    settings: AppSettings(
      onboardingComplete: true,
      answerMode: AnswerMode.name,
      firstSessionStatus: status,
    ),
  );
}

Widget _app(MemoryProgressStore store) {
  return ProviderScope(
    overrides: [
      progressStoreProvider.overrideWithValue(store),
      onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
      retentionStoreProvider.overrideWithValue(MemoryRetentionStore()),
      audioEngineProvider.overrideWithValue(FakeAudioEngine()),
      pitchSourceFactoryProvider.overrideWithValue(
        FakePitchSourceFactory(permission: false).call,
      ),
      soundServiceProvider.overrideWithValue(FakeSoundService()),
    ],
    child: const HearMeOutApp(),
  );
}

Widget _screen(MemoryProgressStore store) {
  return ProviderScope(
    overrides: [
      progressStoreProvider.overrideWithValue(store),
      retentionStoreProvider.overrideWithValue(MemoryRetentionStore()),
      audioEngineProvider.overrideWithValue(FakeAudioEngine()),
      soundServiceProvider.overrideWithValue(FakeSoundService()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const FirstSessionScreen(
        playerBuilder: _fakePlayer,
        recordingBuilder: _fakeRecording,
      ),
    ),
  );
}

Future<void> _finishFirstSession(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('first-session-start')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('first-session-ready')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('fake-player-finish')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('RECORD 10 SECONDS'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('fake-recording-skip')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('first-session-done')), findsOneWidget);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SKIP FOR NOW hides the Path card for this run and it returns '
      'on the next open', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryProgressStore(_profile());
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('first-session-card')), findsOneWidget);
    expect(find.text('Your first 3 minutes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('first-session-card-start')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('first-session-title')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('first-session-skip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('first-session-card')), findsNothing);
    expect(
      store.value!.settings.firstSessionStatus,
      FirstSessionStatus.skipped,
    );

    // A new ProviderScope is a new app run: the session-scoped skip is gone
    // and the card is back.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('first-session-card')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('first-session-card-start')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('first-session-title')), findsOneWidget);
  });

  testWidgets('a rapid double skip pops only the session, not the Path', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryProgressStore(_profile());
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressStoreProvider.overrideWithValue(store),
          retentionStoreProvider.overrideWithValue(MemoryRetentionStore()),
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          navigatorKey: navigator,
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('open-path-route'),
                onPressed: () => navigator.currentState!.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('Path route')),
                    ),
                  ),
                ),
                child: const Text('Home route'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-path-route')));
    await tester.pumpAndSettle();
    expect(find.text('Path route'), findsOneWidget);

    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const FirstSessionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('first-session-title')), findsOneWidget);

    final skip = find.byKey(const ValueKey('first-session-skip'));
    final button = tester.widget<TextButton>(skip);
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Path route'), findsOneWidget);
    expect(find.text('Home route'), findsNothing);
    expect(find.byKey(const ValueKey('first-session-title')), findsNothing);
  });

  testWidgets('completing the flow removes the Path card for good', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryProgressStore(_profile());
    await tester.pumpWidget(_screen(store));
    await tester.pumpAndSettle();

    await _finishFirstSession(tester);
    expect(
      store.value!.settings.firstSessionStatus,
      FirstSessionStatus.completed,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('first-session-card')), findsNothing);

    // Completing twice is harmless, and a late skip cannot undo it.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_screen(store));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('first-session-skip')));
    await tester.pumpAndSettle();
    expect(
      store.value!.settings.firstSessionStatus,
      FirstSessionStatus.completed,
    );
  });

  testWidgets('the practice-only flow writes no scored evidence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryProgressStore(_profile());
    await tester.pumpWidget(_screen(store));
    await tester.pumpAndSettle();

    await _finishFirstSession(tester);
    final progress = store.value!;

    expect(progress.xp, 0);
    expect(progress.streak, 0);
    expect(progress.bestStreak, 0);
    expect(progress.lastPracticeDay, isNull);
    expect(progress.skills, isEmpty);
    expect(progress.phraseProgress, isEmpty);
    expect(progress.completedLessons, isEmpty);
    expect(progress.recentSessions, isEmpty);
    expect(progress.quests.phrasesPracticed, 0);
    expect(progress.quests.recordingsMade, 0);
    expect(progress.quests.barsLearned, 0);
    expect(
      progress.settings.firstSessionStatus,
      FirstSessionStatus.completed,
    );
  });
}
