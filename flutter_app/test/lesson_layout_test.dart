import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/notation/staff_painter.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/shared/widgets/feedback_panel.dart';
import 'package:hear_me_out/shared/widgets/settle_in.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

Future<ProviderContainer> openFirstQuestion(
  WidgetTester tester,
  Size size,
) async {
  tester.view.physicalSize = size;
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
            // Finish the orientation unit so the first note-reading unit is
            // the current lesson and the note UI is on screen.
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

  final current = find.byKey(const ValueKey('current-lesson-node'));
  await tester.ensureVisible(current);
  await tester.pumpAndSettle();
  await tester.tap(current);
  await tester.pumpAndSettle();

  // Advance through teach cards and non-note review questions until a written
  // note question is on screen. The note layout is what this file measures.
  final notifier = container.read(appControllerProvider.notifier);
  for (var guard = 0; guard < 40; guard++) {
    final run = container.read(appControllerProvider).requireValue.run;
    if (run == null) break;
    if (run.current is NotePrompt && run.current.isScored) break;
    if (run.current.isScored) {
      await notifier.submitAnswer(correct: true);
    }
    await notifier.nextExercise();
    await tester.pumpAndSettle();
  }
  return container;
}

void main() {
  testWidgets('a phone pins the answers to the bottom reachable zone', (
    tester,
  ) async {
    const size = Size(390, 844);
    await openFirstQuestion(tester, size);

    final answers = find.byType(AnswerOption);
    final staff = find.byType(StaffView);
    expect(answers, findsWidgets);
    expect(staff, findsWidgets);

    final answerRect = tester.getRect(answers.first);
    final staffRect = tester.getRect(staff.first);

    // The first option sits in the lower quarter of the screen...
    expect(answerRect.top, greaterThan(size.height * 0.7));
    // ...and below the staff, not beside it.
    expect(answerRect.top, greaterThan(staffRect.bottom));
  });

  testWidgets('a wide screen keeps one column and stacks the answers', (
    tester,
  ) async {
    const size = Size(1400, 900);
    await openFirstQuestion(tester, size);

    final answers = find.byType(AnswerOption);
    final staff = find.byType(StaffView);
    expect(answers, findsWidgets);
    expect(staff, findsWidgets);

    final answerRect = tester.getRect(answers.first);
    final staffRect = tester.getRect(staff.first);

    // Same reading order as on a phone: question, then answers below it.
    expect(answerRect.top, greaterThan(staffRect.bottom));
    // The column stays narrow; the rest is margin.
    expect(staffRect.width, lessThanOrEqualTo(640));
    expect(answerRect.left, greaterThanOrEqualTo(380));
  });

  testWidgets('the lesson keeps its content inside the wide column', (
    tester,
  ) async {
    const size = Size(1600, 1000);
    await openFirstQuestion(tester, size);

    final staff = tester.getRect(find.byType(StaffView).first);
    final answers = tester.getRect(find.byType(AnswerOption).first);

    expect(staff.left, greaterThanOrEqualTo(0));
    expect(answers.right, lessThanOrEqualTo(size.width));
    // Centred 640 px column: 480 px of margin on each side at 1600.
    expect(staff.left, closeTo(480, 30));
    expect(answers.right, lessThanOrEqualTo(1120));
  });

  testWidgets('the progress bar says where the learner is', (tester) async {
    await openFirstQuestion(tester, const Size(390, 844));
    expect(find.textContaining('Step '), findsOneWidget);
    expect(find.textContaining(' of '), findsOneWidget);
  });

  testWidgets('the lesson uses the animated question switcher', (
    tester,
  ) async {
    final container = await openFirstQuestion(tester, const Size(390, 844));
    expect(find.byType(SettleIn), findsWidgets);

    final run = container.read(appControllerProvider).requireValue.run!;
    final indexBefore = run.index;

    await tester.tap(find.byType(AnswerOption).first);
    await tester.pumpAndSettle();
    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    final after = container.read(appControllerProvider).requireValue.run!;
    expect(after.index, indexBefore + 1);
  });
}
