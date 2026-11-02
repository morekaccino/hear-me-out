import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

Widget buildApp(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
      pitchSourceFactoryProvider.overrideWithValue(
        FakePitchSourceFactory().call,
      ),
      soundServiceProvider.overrideWithValue(FakeSoundService()),
    ],
    child: const HearMeOutApp(),
  );
}

void main() {
  testWidgets('a locked lesson explains what to do next', (tester) async {
    await tester.pumpWidget(buildApp(tester));
    await tester.pumpAndSettle();

    final locked = find.byKey(const ValueKey('lesson-face-c3u1l2'));
    await tester.ensureVisible(locked);
    await tester.pumpAndSettle();
    await tester.tap(locked);
    await tester.pumpAndSettle();

    expect(find.text('Lesson locked'), findsOneWidget);
    expect(find.textContaining('Finish “Discover” first'), findsOneWidget);
    expect(find.text('START “DISCOVER”'), findsOneWidget);
    expect(find.text('NOT NOW'), findsOneWidget);
  });

  testWidgets('the sheet starts the blocking lesson', (tester) async {
    await tester.pumpWidget(buildApp(tester));
    await tester.pumpAndSettle();

    final locked = find.byKey(const ValueKey('lesson-face-c3u1l2'));
    await tester.ensureVisible(locked);
    await tester.pumpAndSettle();
    await tester.tap(locked);
    await tester.pumpAndSettle();

    await tester.tap(find.text('START “DISCOVER”'));
    await tester.pumpAndSettle();

    // The first lesson opened, so its teach card and continue button are on
    // screen.
    expect(find.text('GOT IT'), findsOneWidget);
  });
}
