import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/retention/retention_log.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/features/home_shell.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp(
    MemoryProgressStore progressStore,
    MemoryRetentionStore retentionStore,
  ) {
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(progressStore),
        retentionStoreProvider.overrideWithValue(retentionStore),
        onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        pitchSourceFactoryProvider.overrideWithValue(
          FakePitchSourceFactory(permission: false).call,
        ),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
      ],
      child: const HearMeOutApp(),
    );
  }

  MemoryProgressStore completedProgress() => MemoryProgressStore(
    ProgressState.fresh(
      settings: const AppSettings(
        onboardingComplete: true,
        answerMode: AnswerMode.name,
      ),
    ),
  );

  testWidgets('the beta usage log is off by default and fits 390x844', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seeded = RetentionLog(installId: 'widget-install')
        .record(RetentionEventName.firstNote, at: DateTime.utc(2026, 1, 1, 9));
    final retentionStore = MemoryRetentionStore(
      installId: 'widget-install',
      events: seeded.events,
    );

    await tester.pumpWidget(buildApp(completedProgress(), retentionStore));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Beta usage log'),
      300,
      scrollable: scrollable,
    );

    final switchFinder = find.byKey(const ValueKey('retention-opt-in-switch'));
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(find.textContaining('No audio'), findsOneWidget);
    expect(find.textContaining('not an unbiased baseline'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(retentionStore.value.optIn, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('copy and erase actions work and stay within 1200 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final seeded = RetentionLog(installId: 'widget-install')
        .record(RetentionEventName.firstNote, at: DateTime.utc(2026, 1, 1, 9));
    final retentionStore = MemoryRetentionStore(
      installId: 'widget-install',
      events: seeded.events,
    );

    await tester.pumpWidget(buildApp(completedProgress(), retentionStore));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PROFILE'));
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Copy usage log'),
      300,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.text('Copy usage log'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Copy usage log'));
    await tester.pumpAndSettle();

    expect(copied, isNotNull);
    expect(copied, contains('"name": "first_note"'));
    expect(copied, contains('"installId": "widget-install"'));
    expect(copied!.toLowerCase(), isNot(contains('audio')));

    await tester.scrollUntilVisible(
      find.text('Erase log'),
      300,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.text('Erase log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erase log'));
    await tester.pumpAndSettle();
    expect(find.text('Erase usage log?'), findsOneWidget);

    await tester.tap(find.text('Erase'));
    await tester.pumpAndSettle();

    expect(retentionStore.value.log.events, isEmpty);
    expect(retentionStore.value.log.installId, 'widget-install');
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeShell), findsOneWidget);
  });
}
