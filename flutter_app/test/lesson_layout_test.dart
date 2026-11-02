import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/notation/staff_painter.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/shared/widgets/feedback_panel.dart';
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
          ProgressState.fresh(
            settings: const AppSettings(
              onboardingComplete: true,
              answerMode: AnswerMode.name,
            ),
          ),
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

  // Two teach cards, then the first question.
  for (var index = 0; index < 4; index++) {
    final run = container.read(appControllerProvider).requireValue.run;
    if (run == null) break;
    if (run.current.isScored) break;
    await tester.tap(find.text('GOT IT'));
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
    expect(find.text('Step 3 of 8'), findsOneWidget);
  });

  testWidgets('the lesson uses the animated question switcher', (
    tester,
  ) async {
    final container = await openFirstQuestion(tester, const Size(390, 844));
    expect(find.byType(PageTransitionSwitcher), findsOneWidget);

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
