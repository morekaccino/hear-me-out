import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/home_shell.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

RecordingTake _take({
  required String id,
  required DateTime createdAt,
  required String pieceId,
}) => RecordingTake(
  id: id,
  createdAt: createdAt.toUtc(),
  byteLength: 100,
  durationMs: 1000,
  pieceId: pieceId,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp({
    required ProgressState progress,
    required List<RecordingTake> takes,
  }) {
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(MemoryProgressStore(progress)),
        recordingRecapTakesProvider.overrideWithValue(AsyncData(takes)),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeShell()),
    );
  }

  Future<void> openQuests(WidgetTester tester, {required bool wide}) async {
    await tester.tap(find.text(wide ? 'QUESTS' : 'Quests'));
    await tester.pumpAndSettle();
  }

  testWidgets('the recap renders real numbers and a before/after', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final progress = ProgressState.fresh(
      settings: const AppSettings(onboardingComplete: true),
    );
    progress.recordPracticeSeconds(300, now);
    progress.quests.day = dayKey(now);
    progress.quests.week = weekKey(now);
    progress.quests.phrasesPracticed = 3;
    final takes = <RecordingTake>[
      _take(
        id: 'twinkle-1',
        createdAt: now.subtract(const Duration(days: 2)),
        pieceId: 'twinkle',
      ),
      _take(
        id: 'twinkle-2',
        createdAt: now.subtract(const Duration(days: 1)),
        pieceId: 'twinkle',
      ),
    ];

    await tester.pumpWidget(buildApp(progress: progress, takes: takes));
    await tester.pumpAndSettle();
    await openQuests(tester, wide: false);

    expect(find.text('Your week so far'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('recap-minutes'))).data,
      '5',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('recap-phrases'))).data,
      '3',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('recap-recordings'))).data,
      '2',
    );
    expect(find.textContaining('Before/after: twinkle'), findsOneWidget);
    expect(find.textContaining('2 takes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the empty recap is honest and links to recordings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        progress: ProgressState.fresh(
          settings: const AppSettings(onboardingComplete: true),
        ),
        takes: const <RecordingTake>[],
      ),
    );
    await tester.pumpAndSettle();
    await openQuests(tester, wide: false);

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('recap-minutes'))).data,
      '0',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('recap-recordings'))).data,
      '0',
    );
    expect(find.textContaining('No before/after yet'), findsOneWidget);
    expect(find.text('Open recordings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the recap fits a phone and 1200 px', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();

    for (final width in <double>[390, 1200]) {
      tester.view.physicalSize = Size(width, width >= 1200 ? 900 : 844);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        buildApp(
          progress: ProgressState.fresh(
            settings: const AppSettings(onboardingComplete: true),
          ),
          takes: <RecordingTake>[
            _take(
              id: 'a',
              createdAt: now.subtract(const Duration(days: 2)),
              pieceId: 'twinkle',
            ),
            _take(
              id: 'b',
              createdAt: now.subtract(const Duration(days: 1)),
              pieceId: 'twinkle',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await openQuests(tester, wide: width >= 900);

      expect(find.byKey(const ValueKey('weekly-recap-card')), findsOneWidget);
      expect(find.text('Your week so far'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
