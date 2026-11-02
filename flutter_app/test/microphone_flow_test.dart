import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  Widget buildApp(
    ProgressState progress,
    FakePitchSourceFactory sources, {
    FakeSoundService? sounds,
  }) {
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(MemoryProgressStore(progress)),
        pitchSourceFactoryProvider.overrideWithValue(sources.call),
        soundServiceProvider.overrideWithValue(sounds ?? FakeSoundService()),
      ],
      child: const HearMeOutApp(),
    );
  }

  testWidgets('onboarding starts one microphone and then locks the test button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sources = FakePitchSourceFactory();
    await tester.pumpWidget(
      buildApp(ProgressState.fresh(), sources),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('TEST MICROPHONE'));
    await tester.pumpAndSettle();

    expect(sources.created, hasLength(1));
    expect(find.text('LISTENING…'), findsOneWidget);
    expect(find.text('TEST MICROPHONE'), findsNothing);

    await tester.tap(find.text('LISTENING…'));
    await tester.pumpAndSettle();
    expect(sources.created, hasLength(1));
  });

  testWidgets('skipping while the microphone starts disposes the pending source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gate = Completer<bool>();
    final sources = FakePitchSourceFactory(startGate: gate);
    await tester.pumpWidget(
      buildApp(ProgressState.fresh(), sources),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('TEST MICROPHONE'));
    await tester.pump();
    expect(find.text('STARTING…'), findsOneWidget);
    await tester.tap(find.text('Skip, I will type note names'));
    await tester.pumpAndSettle();

    gate.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Pick a daily goal'), findsOneWidget);
    expect(sources.created.single.disposed, isTrue);
  });

  testWidgets('name-only practice never touches the microphone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sources = FakePitchSourceFactory();
    await tester.pumpWidget(
      buildApp(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
        sources,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Free practice'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Free practice'));
    await tester.pumpAndSettle();

    expect(find.text('What note is this?'), findsOneWidget);
    expect(sources.created, isEmpty);
  });

  testWidgets('retry clears the forced note-name fallback', (tester) async {
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
    final sources = FakePitchSourceFactory(startResult: false);
    final sounds = FakeSoundService();
    final container = ProviderContainer(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        pitchSourceFactoryProvider.overrideWithValue(sources.call),
        soundServiceProvider.overrideWithValue(sounds),
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

    await tester.tap(find.byKey(const ValueKey('current-lesson-node')));
    await tester.pumpAndSettle();

    Future<void> answerUntilPlay() async {
      final notifier = container.read(appControllerProvider.notifier);
      for (var index = 0; index < 16; index++) {
        final run = container.read(appControllerProvider).requireValue.run;
        if (run == null) return;
        final prompt = run.current;
        if (prompt.usesMicrophone) return;
        if (prompt.isTeach) {
          await tester.tap(find.text('GOT IT'));
          await tester.pumpAndSettle();
          continue;
        }
        if (prompt is NotePrompt) {
          await tester.tap(find.text(prompt.note.display).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('CONTINUE'));
          await tester.pumpAndSettle();
          continue;
        }
        await notifier.submitAnswer(correct: true);
        await notifier.nextExercise();
        await tester.pumpAndSettle();
      }
    }

    await answerUntilPlay();
    expect(find.text('USE NOTE NAMES INSTEAD'), findsOneWidget);
    await tester.tap(find.text('USE NOTE NAMES INSTEAD'));
    await tester.pumpAndSettle();

    var guard = 0;
    while (container.read(appControllerProvider).requireValue.run != null &&
        guard < 20) {
      guard++;
      final notifier = container.read(appControllerProvider.notifier);
      final run = container.read(appControllerProvider).requireValue.run!;
      final prompt = run.current;
      if (prompt.isTeach) {
        await tester.tap(find.text('GOT IT'));
        await tester.pumpAndSettle();
        continue;
      }
      final notePrompt = prompt is NotePrompt ? prompt : null;
      if (notePrompt == null) {
        await notifier.submitAnswer(correct: false);
        await notifier.nextExercise();
        await tester.pumpAndSettle();
        continue;
      }
      final wrong = notePrompt.choices.firstWhere(
        (note) => note.id != notePrompt.note.id,
      );
      await tester.tap(find.text(wrong.display));
      await tester.pumpAndSettle();
      final seeResults = find.text('SEE RESULTS');
      await tester.tap(
        seeResults.evaluate().isNotEmpty
            ? seeResults
            : find.text('CONTINUE'),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text('Out of hearts'), findsOneWidget);
    final retry = find.text('TRY AGAIN').evaluate().isNotEmpty
        ? find.text('TRY AGAIN')
        : find.text('REFILL & RETRY');
    await tester.tap(retry);
    await tester.pumpAndSettle();

    await answerUntilPlay();
    expect(find.text('Play this note'), findsOneWidget);
    expect(sources.created.length, greaterThanOrEqualTo(2));
  });
}
