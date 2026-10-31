import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/guitar.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/notation/staff_painter.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp(ProgressState progress, {FakePitchSourceFactory? factory}) {
    final store = MemoryProgressStore(progress);
    final sources = factory ?? FakePitchSourceFactory(permission: false);
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        pitchSourceFactoryProvider.overrideWithValue(sources.call),
      ],
      child: const HearMeOutApp(),
    );
  }

  testWidgets('path shows real units and the next lesson', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hear Me Out'), findsOneWidget);
    expect(find.text('Daily goal'), findsOneWidget);
    expect(find.text('Read the Staff'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('a lesson can be answered by tapping the note name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('What note is this?'), findsOneWidget);
    expect(find.byType(StaffView), findsOneWidget);

    await tester.tap(find.text('E4'));
    await tester.pumpAndSettle();

    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('What note is this?'), findsOneWidget);
  });

  testWidgets('onboarding reaches the path and persists the choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(ProgressState.fresh()));
    await tester.pumpAndSettle();

    expect(find.text('Read music.\nPlay guitar.'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('Two ways to answer'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('Check your microphone'), findsOneWidget);
    await tester.tap(find.text('Skip, I will type note names'));
    await tester.pumpAndSettle();

    expect(find.text('Pick a daily goal'), findsOneWidget);
    await tester.tap(find.text("LET'S PLAY"));
    await tester.pumpAndSettle();

    expect(find.text('Read the Staff'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('playing the correct note completes a mic exercise', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryProgressStore(
      ProgressState.fresh(
        settings: const AppSettings(
          onboardingComplete: true,
          answerMode: AnswerMode.mixed,
        ),
      ),
    );
    final sources = FakePitchSourceFactory(permission: true);
    final container = ProviderContainer(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        pitchSourceFactoryProvider.overrideWithValue(sources.call),
        lessonGraceProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HearMeOutApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pumpAndSettle();

    for (var index = 0; index < 2; index++) {
      final run = container.read(appControllerProvider).requireValue.run!;
      expect(run.current.isPlay, isFalse);
      await tester.tap(find.text(run.current.note.display));
      await tester.pumpAndSettle();
      expect(find.text('Correct!'), findsOneWidget);
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
    }

    final run = container.read(appControllerProvider).requireValue.run!;
    expect(run.current.isPlay, isTrue);
    expect(sources.created.length, greaterThanOrEqualTo(2));
    final source = sources.created.last;
    expect(source.started, isTrue);

    final frequency = midiToFrequency(
      Guitar.soundingMidiForWritten(run.current.note).toDouble(),
    );
    for (var frame = 0; frame < 3; frame++) {
      source.emit(
        PitchFrame(
          frequency: frequency,
          clarity: 0.95,
          rms: 0.1,
          timestamp: DateTime.now(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();

    final playedRun = container.read(appControllerProvider).requireValue.run!;
    expect(playedRun.awaitingNext, isTrue);
    expect(playedRun.lastCorrect, isTrue);
    expect(playedRun.lastOctaveError, isFalse);
    expect(playedRun.lastCents, closeTo(0, 1));
    expect(find.text('Combo x3!'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });

  testWidgets('every curriculum note renders on the staff', (tester) async {
    for (final note in noteCatalog) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 350, child: StaffView(note: note)),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: note.id);
    }
  });
}
