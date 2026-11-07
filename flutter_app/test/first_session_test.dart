import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_scorer.dart';
import 'package:hear_me_out/core/audio/phrase_verifier.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
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

Widget _build({
  required MemoryRetentionStore retention,
  required MemoryProgressStore progress,
}) {
  return ProviderScope(
    overrides: [
      retentionStoreProvider.overrideWithValue(retention),
      progressStoreProvider.overrideWithValue(progress),
      audioEngineProvider.overrideWithValue(FakeAudioEngine()),
      soundServiceProvider.overrideWithValue(FakeSoundService()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: FirstSessionScreen(
        playerBuilder: _fakePlayer,
        recordingBuilder: _fakeRecording,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the first session reaches a real correction and done state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final retention = MemoryRetentionStore(optIn: true);
    final progress = MemoryProgressStore(
      ProgressState.fresh(settings: const AppSettings(onboardingComplete: true)),
    );
    await tester.pumpWidget(_build(retention: retention, progress: progress));
    await tester.pumpAndSettle();

    expect(find.text('Your first 3 minutes'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('first-session-start')));
    await tester.pumpAndSettle();
    expect(find.text('Hear the first four notes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('first-session-ready')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fake-player-finish')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fake-player-finish')));
    await tester.pumpAndSettle();

    expect(find.text('One correction'), findsOneWidget);
    expect(find.textContaining('Clean take'), findsOneWidget);

    await tester.tap(find.text('RECORD 10 SECONDS'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fake-recording-skip')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fake-recording-skip')));
    await tester.pumpAndSettle();

    expect(find.text('You played your first phrase'), findsOneWidget);
    final stored = await retention.load();
    expect(
      stored.log.hasEvent(RetentionEventName.firstNote),
      isTrue,
    );
    expect(
      stored.log.hasEvent(RetentionEventName.firstPhrase),
      isTrue,
    );
    expect(
      stored.log.hasEvent(RetentionEventName.sessionComplete),
      isTrue,
    );
  });
}
