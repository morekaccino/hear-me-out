import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/phrase_objectives.dart';
import 'package:hear_me_out/core/audio/scored_take_gate.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/skill.dart';
import 'package:hear_me_out/core/media/backup_exclusion.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/before_after/before_after_screen.dart';
import 'package:hear_me_out/features/home_shell.dart';
import 'package:hear_me_out/features/path/path_screen.dart';
import 'package:hear_me_out/features/recordings/recordings_screen.dart';
import 'package:hear_me_out/features/today/today_controller.dart';
import 'package:hear_me_out/features/today/today_screen.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MemoryProgressStore freshStore() => MemoryProgressStore(
    ProgressState.fresh(settings: const AppSettings(onboardingComplete: true)),
  );

  MemoryProgressStore storeWithLearnedSkills(DateTime now) {
    return MemoryProgressStore(
      ProgressState(
        settings: const AppSettings(onboardingComplete: true),
        skills: {
          'note:E4': SkillProgress(
            objectiveId: 'note:E4',
            family: SkillFamily.noteReading,
            reps: 2,
            correct: 1,
            incorrect: 1,
            dueAt: now.subtract(const Duration(minutes: 1)),
            lastSeenAt: now.subtract(const Duration(days: 2)),
          ),
          'note:G4': SkillProgress(
            objectiveId: 'note:G4',
            family: SkillFamily.noteReading,
            reps: 4,
            correct: 4,
            dueAt: now.add(const Duration(days: 7)),
            lastSeenAt: now.subtract(const Duration(days: 1)),
          ),
        },
      ),
    );
  }

  Widget buildToday({
    required MemoryProgressStore store,
    DateTime Function()? clock,
    bool performanceDay = false,
    ScoredTakeGate gate = const ScoredTakeGate(),
    PhraseObjectiveRegistry? registry,
    FakeAudioEngine? engine,
    VoidCallback? onOpenPractice,
    List<RecordingTake> recapTakes = const <RecordingTake>[],
    RecordingService? recordingService,
    MemoryRecordingIndexStore? recordingIndexStore,
  }) {
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        audioEngineProvider.overrideWithValue(engine ?? FakeAudioEngine()),
        takePlayerProvider.overrideWithValue(FakeTakePlayer()),
        mediaBackupStatusProvider.overrideWithValue(
          const AsyncData(BackupExclusionResult.failed('test')),
        ),
        recordingRecapTakesProvider.overrideWithValue(AsyncData(recapTakes)),
        if (recordingService != null)
          recordingServiceProvider.overrideWithValue(
            AsyncData(recordingService),
          ),
        if (recordingIndexStore != null)
          recordingIndexStoreProvider.overrideWithValue(recordingIndexStore),
        todayClockProvider.overrideWithValue(
          clock ?? () => DateTime(2026, 11, 6, 10),
        ),
        todayPerformanceDayProvider.overrideWithValue(performanceDay),
        todayScoredTakeGateProvider.overrideWithValue(gate),
        todayPhraseRegistryProvider.overrideWithValue(
          registry ?? PhraseObjectiveRegistry(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: TodayScreen(onOpenPractice: onOpenPractice),
      ),
    );
  }

  RecordingService buildRecordingService(MemoryRecordingIndexStore indexStore) {
    return RecordingService(
      store: MemoryMediaStore(),
      indexStore: indexStore,
      exporter: FakeRecordingExporter(),
      clock: () => DateTime(2026, 11, 6, 12),
      recorderFactory: () => throw StateError('No take in this test'),
    );
  }

  Widget buildHome({required bool enableToday, DateTime Function()? clock}) {
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(freshStore()),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        todayClockProvider.overrideWithValue(
          clock ?? () => DateTime(2026, 11, 6, 10),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: enableToday
            ? const HomeShell.withTodayForTesting()
            : const HomeShell(),
      ),
    );
  }

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  String textOf(WidgetTester tester, String key) {
    return tester.widget<Text>(find.byKey(ValueKey(key))).data!;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('renders the 5-minute plan at 390x844 with 3+ guitar minutes', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildToday(store: freshStore()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('today-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-target-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-length-5')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-length-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-length-20')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('today-length-5'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(textOf(tester, 'today-total-minutes'), '5 MIN');
    expect(
      find.textContaining('3:30 of this plan is guitar in hand'),
      findsOneWidget,
    );

    for (final title in const [
      'Tune and set up',
      'Technique warm-up',
      'Listen and model',
      'Acquire: one bar',
      'Apply at target tempo',
      'Reflect and plan',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    expect(find.textContaining('What: Tune each string'), findsOneWidget);
    expect(find.textContaining('Why: A tuned guitar'), findsOneWidget);
    expect(find.textContaining('What: Loop one bar'), findsOneWidget);
    expect(find.textContaining('Why: Slow reps'), findsOneWidget);
    expect(find.textContaining('What: Rate how it felt'), findsOneWidget);
    expect(find.textContaining('Why: Naming what happened'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('has one target and no game chrome', (tester) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildToday(store: freshStore()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('today-target-title')), findsOneWidget);
    expect(find.textContaining('One target.'), findsWidgets);

    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('Streak'), findsNothing);
    expect(find.textContaining('gems'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('10- and 20-minute options update the block budgets', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildToday(store: freshStore()));
    await tester.pumpAndSettle();

    await tapKey(tester, 'today-length-10');
    expect(textOf(tester, 'today-total-minutes'), '10 MIN');
    expect(
      find.textContaining('8:00 of this plan is guitar in hand'),
      findsOneWidget,
    );
    expect(find.text('Acquire: first phrase'), findsOneWidget);
    expect(find.text('Acquire: second phrase'), findsOneWidget);

    await tapKey(tester, 'today-length-20');
    expect(textOf(tester, 'today-total-minutes'), '20 MIN');
    expect(
      find.textContaining('16:30 of this plan is guitar in hand'),
      findsOneWidget,
    );
    expect(find.textContaining('Deep practice:'), findsOneWidget);
    expect(find.text('Technique deep drill'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('maintenance day adds the learned phrase and six minutes', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    final now = DateTime(2026, 11, 6, 10);
    await tester.pumpWidget(
      buildToday(store: storeWithLearnedSkills(now), clock: () => now),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('today-maintenance-toggle')),
      findsOneWidget,
    );
    await tapKey(tester, 'today-maintenance-toggle');

    expect(textOf(tester, 'today-total-minutes'), '6 MIN');
    expect(find.text('Maintenance: earlier phrase'), findsOneWidget);
    expect(
      find.textContaining('4:30 of this plan is guitar in hand'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('timer, pause, resume, early stop, and reflection are safe', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    final start = DateTime(2026, 11, 6, 10);
    var now = start;
    final store = freshStore();
    await tester.pumpWidget(buildToday(store: store, clock: () => now));
    await tester.pumpAndSettle();

    await tapKey(tester, 'today-session-start');
    expect(find.byKey(const ValueKey('today-session-pause')), findsOneWidget);

    for (var second = 0; second < 10; second++) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(textOf(tester, 'today-session-time'), '0:10 / 5:00');
    expect(textOf(tester, 'today-instrument-time'), '0:00');

    await tapKey(tester, 'today-session-pause');
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(textOf(tester, 'today-session-time'), '0:10 / 5:00');

    await tapKey(tester, 'today-session-resume');
    for (var second = 0; second < 20; second++) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(textOf(tester, 'today-session-time'), '0:30 / 5:00');
    expect(textOf(tester, 'today-instrument-time'), '0:00');

    for (var second = 0; second < 5; second++) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(textOf(tester, 'today-instrument-time'), '0:05');

    await tapKey(tester, 'today-session-stop');
    expect(find.byKey(const ValueKey('today-early-end')), findsOneWidget);
    expect(find.text('Today is done'), findsOneWidget);
    expect(store.value!.daily.practice, 1);

    await tapKey(tester, 'today-reflect-rating-3');
    expect(
      tester
          .getSize(find.byKey(const ValueKey('today-reflect-rating-3')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(find.byKey(const ValueKey('today-metric')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-correction')), findsOneWidget);
    expect(find.text('ONE CORRECTION · FROM YOUR RATING'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-next-step')), findsOneWidget);
    expect(find.textContaining('Guitar time: 0:05.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backgrounding pauses the clock instead of counting the gap', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    final start = DateTime(2026, 11, 6, 10);
    var now = start;
    await tester.pumpWidget(buildToday(store: freshStore(), clock: () => now));
    await tester.pumpAndSettle();

    await tapKey(tester, 'today-session-start');
    for (var second = 0; second < 5; second++) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(textOf(tester, 'today-session-time'), '0:05 / 5:00');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byKey(const ValueKey('today-session-resume')), findsOneWidget);

    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(textOf(tester, 'today-session-time'), '0:05 / 5:00');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('advancing moves the current block and its action', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildToday(store: freshStore()));
    await tester.pumpAndSettle();

    expect(find.text('NOW'), findsOneWidget);
    expect(find.text('START SESSION'), findsOneWidget);

    await tapKey(tester, 'today-session-start');
    await tapKey(tester, 'today-block-action-0');

    expect(find.text('I’M TUNED, NEXT'), findsNothing);
    expect(find.text('DONE, NEXT'), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('model block labels a synth preview and makes no human claim', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    final engine = FakeAudioEngine();
    await tester.pumpWidget(buildToday(store: freshStore(), engine: engine));
    await tester.pumpAndSettle();

    await tapKey(tester, 'today-session-start');
    await tapKey(tester, 'today-block-action-0');
    await tapKey(tester, 'today-block-action-1');

    expect(find.text('SYNTH PREVIEW'), findsOneWidget);
    expect(
      find.textContaining('Human reference recordings are not available yet.'),
      findsOneWidget,
    );
    expect(find.textContaining('Listen to the human reference'), findsNothing);

    final play = find.text('PLAY SYNTH PREVIEW');
    await tester.ensureVisible(play);
    await tester.tap(play);
    await tester.pump();
    expect(engine.played, hasLength(1));
    expect(engine.played.single.events, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('apply is practice only by default and never records', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildToday(store: freshStore()));
    await tester.pumpAndSettle();

    await tapKey(tester, 'today-session-start');
    await tapKey(tester, 'today-block-action-0');
    await tapKey(tester, 'today-block-action-1');
    await tapKey(tester, 'today-block-action-2');
    await tapKey(tester, 'today-block-action-3');

    final status = textOf(tester, 'today-apply-status');
    expect(status, contains('Practice only'));
    expect(status, contains('performance day'));
    expect(
      find.byKey(const ValueKey('today-performance-day-card')),
      findsNothing,
    );
    expect(find.text('OPEN RECORDING'), findsNothing);
    expect(find.text('OPEN PHRASE TAKE'), findsNothing);
    expect(find.text('OPEN PHRASE PRACTICE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a performance day frames a recital and opens the recorder', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    final indexStore = MemoryRecordingIndexStore();
    final service = buildRecordingService(indexStore);
    addTearDown(service.dispose);
    await tester.pumpWidget(
      buildToday(
        store: freshStore(),
        performanceDay: true,
        recordingService: service,
        recordingIndexStore: indexStore,
      ),
    );
    await tester.pumpAndSettle();

    // The calm banner sits above Apply and states the whole cadence.
    expect(
      find.byKey(const ValueKey('today-performance-day-card')),
      findsOneWidget,
    );
    expect(find.text('PERFORMANCE DAY'), findsOneWidget);
    expect(find.text('Today is a recital: one take.'), findsOneWidget);
    expect(find.textContaining('No score while you play'), findsWidgets);
    expect(find.textContaining('weekly before/after'), findsOneWidget);

    await tapKey(tester, 'today-session-start');
    await tapKey(tester, 'today-block-action-0');
    await tapKey(tester, 'today-block-action-1');
    await tapKey(tester, 'today-block-action-2');
    await tapKey(tester, 'today-block-action-3');

    final status = textOf(tester, 'today-apply-status');
    expect(status, contains('Performance day'));
    expect(status, contains('no score while you play'));
    expect(find.text('OPEN RECORDING'), findsOneWidget);
    expect(find.text('OPEN PHRASE TAKE'), findsNothing);

    await tester.ensureVisible(find.text('OPEN RECORDING'));
    await tester.tap(find.text('OPEN RECORDING'));
    await tester.pumpAndSettle();

    // The unscored local recorder is the performance take, not the gated
    // phrase player (decisions 0001/0010).
    expect(find.byType(RecordingsScreen), findsOneWidget);
    expect(find.text('Recordings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a performance day never opens the gated phrase player', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      buildToday(
        store: freshStore(),
        performanceDay: true,
        gate: const ScoredTakeGate(headphonesConfirmed: true),
      ),
    );
    await tester.pumpAndSettle();

    await tapKey(tester, 'today-session-start');
    await tapKey(tester, 'today-block-action-0');
    await tapKey(tester, 'today-block-action-1');
    await tapKey(tester, 'today-block-action-2');
    await tapKey(tester, 'today-block-action-3');

    expect(find.text('OPEN PHRASE TAKE'), findsNothing);
    expect(find.text('OPEN PHRASE PRACTICE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a saved performance take points to Recordings without a pair', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    final indexStore = MemoryRecordingIndexStore();
    final service = buildRecordingService(indexStore);
    addTearDown(service.dispose);
    await tester.pumpWidget(
      buildToday(
        store: freshStore(),
        performanceDay: true,
        recordingService: service,
        recordingIndexStore: indexStore,
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TodayScreen)),
    );
    final controller = container.read(todayControllerProvider.notifier);
    controller.markPerformanceTaken();
    controller.finishEarly();
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('today-before-after-result')),
      findsOneWidget,
    );
    expect(find.textContaining('lives in Recordings'), findsOneWidget);
    expect(find.text('OPEN RECORDINGS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a saved performance take links to the before/after card', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    final indexStore = MemoryRecordingIndexStore();
    final service = buildRecordingService(indexStore);
    addTearDown(service.dispose);
    final takes = [
      RecordingTake(
        id: 'take-old',
        createdAt: DateTime(2026, 11, 1, 12).toUtc(),
        byteLength: 1000,
        durationMs: 1000,
        pieceId: 'ode-to-joy',
      ),
      RecordingTake(
        id: 'take-new',
        createdAt: DateTime(2026, 11, 4, 12).toUtc(),
        byteLength: 1000,
        durationMs: 1000,
        pieceId: 'ode-to-joy',
      ),
    ];
    await tester.pumpWidget(
      buildToday(
        store: freshStore(),
        performanceDay: true,
        recapTakes: takes,
        recordingService: service,
        recordingIndexStore: indexStore,
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TodayScreen)),
    );
    final controller = container.read(todayControllerProvider.notifier);
    controller.markPerformanceTaken();
    controller.finishEarly();
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('today-before-after-result')),
      findsOneWidget,
    );
    expect(find.textContaining('days apart'), findsOneWidget);
    expect(find.text('OPEN BEFORE/AFTER'), findsOneWidget);

    await tester.ensureVisible(find.text('OPEN BEFORE/AFTER'));
    await tester.tap(find.text('OPEN BEFORE/AFTER'));
    await tester.pumpAndSettle();

    expect(find.byType(BeforeAfterScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the performance card and share row fit 1200 px', (tester) async {
    useSize(tester, const Size(1200, 900));
    final indexStore = MemoryRecordingIndexStore();
    final service = buildRecordingService(indexStore);
    addTearDown(service.dispose);
    final takes = [
      RecordingTake(
        id: 'take-old',
        createdAt: DateTime(2026, 11, 1, 12).toUtc(),
        byteLength: 1000,
        durationMs: 1000,
        pieceId: 'ode-to-joy',
      ),
      RecordingTake(
        id: 'take-new',
        createdAt: DateTime(2026, 11, 4, 12).toUtc(),
        byteLength: 1000,
        durationMs: 1000,
        pieceId: 'ode-to-joy',
      ),
    ];
    await tester.pumpWidget(
      buildToday(
        store: freshStore(),
        performanceDay: true,
        recapTakes: takes,
        recordingService: service,
        recordingIndexStore: indexStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('today-performance-day-card')),
      findsOneWidget,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TodayScreen)),
    );
    final controller = container.read(todayControllerProvider.notifier);
    controller.markPerformanceTaken();
    controller.finishEarly();
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('today-before-after-result')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(SingleChildScrollView)).width,
      lessThanOrEqualTo(720),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits 1200px without overflow and keeps a 720px column', (
    tester,
  ) async {
    useSize(tester, const Size(1200, 900));
    await tester.pumpWidget(buildToday(store: freshStore()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('today-title')), findsOneWidget);
    expect(
      tester.getSize(find.byType(SingleChildScrollView)).width,
      lessThanOrEqualTo(720),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home keeps the Path when the phrase switch is off', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildHome(enableToday: false));
    await tester.pumpAndSettle();

    expect(find.byType(PathScreen), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);
    expect(find.text('Learn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shows Today only through the test override and side rail', (
    tester,
  ) async {
    useSize(tester, const Size(1200, 900));
    await tester.pumpWidget(buildHome(enableToday: true));
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byType(PathScreen), findsNothing);
    expect(find.byKey(const ValueKey('side-rail')), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning to Today drops the unattended gap', (tester) async {
    useSize(tester, const Size(390, 844));
    final start = DateTime(2026, 11, 6, 10);
    var now = start;
    await tester.pumpWidget(buildHome(enableToday: true, clock: () => now));
    await tester.pumpAndSettle();

    await tapKey(tester, 'today-session-start');
    for (var second = 0; second < 5; second++) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(textOf(tester, 'today-session-time'), '0:05 / 5:00');

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Today'));
    await tester.pump();
    await tester.pump();
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(textOf(tester, 'today-session-time'), '0:06 / 5:00');
    expect(find.byKey(const ValueKey('today-session-pause')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
