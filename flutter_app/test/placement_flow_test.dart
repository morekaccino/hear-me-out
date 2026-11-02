import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('placing a note correctly advances after continue', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        progressStoreProvider.overrideWithValue(
          MemoryProgressStore(
            () {
              final progress = ProgressState.fresh(
                settings: const AppSettings(
                  onboardingComplete: true,
                  answerMode: AnswerMode.name,
                ),
              );
              for (final lesson in sections.first.units.first.lessons) {
                progress.completedLessons.add(lesson.id);
              }
              return progress;
            }(),
          ),
        ),
        pitchSourceFactoryProvider.overrideWithValue(
          FakePitchSourceFactory().call,
        ),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
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

    final notifier = container.read(appControllerProvider.notifier);

    // Skip other questions until a staff-placement prompt is on screen.
    var guard = 0;
    while (guard < 40) {
      guard++;
      final run = container.read(appControllerProvider).requireValue.run!;
      final prompt = run.current;
      if (prompt is StaffTapPrompt) break;
      if (prompt.isScored) {
        await notifier.submitAnswer(correct: true);
      }
      await notifier.nextExercise();
      await tester.pumpAndSettle();
    }

    final before = container.read(appControllerProvider).requireValue.run!;
    expect(before.current, isA<StaffTapPrompt>());
    final prompt = before.current as StaffTapPrompt;
    final indexBefore = before.index;
    final step = prompt.note.diatonicIndex;

    await tester.tap(find.byKey(ValueKey('staff-step-$step')));
    await tester.pumpAndSettle();

    final afterAnswer = container.read(appControllerProvider).requireValue.run!;
    expect(afterAnswer.awaitingNext, isTrue);
    expect(afterAnswer.lastCorrect, isTrue);
    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    final afterContinue = container
        .read(appControllerProvider)
        .requireValue
        .run;
    expect(afterContinue?.index, indexBefore + 1);
  });
}
