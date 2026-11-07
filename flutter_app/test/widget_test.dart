import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/guitar.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/notation/staff_painter.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/home_shell.dart';
import 'package:hear_me_out/features/path/path_layout.dart';
import 'package:hear_me_out/shared/audio/sound_service.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp(
    ProgressState progress, {
    FakePitchSourceFactory? factory,
    FakeSoundService? sounds,
  }) {
    final store = MemoryProgressStore(progress);
    final sources = factory ?? FakePitchSourceFactory(permission: false);
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        pitchSourceFactoryProvider.overrideWithValue(sources.call),
        soundServiceProvider.overrideWithValue(sounds ?? FakeSoundService()),
      ],
      child: const HearMeOutApp(),
    );
  }

  Widget buildShell(ProgressState progress, {required bool todayEnabled}) {
    final store = MemoryProgressStore(progress);
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        pitchSourceFactoryProvider.overrideWithValue(
          FakePitchSourceFactory(permission: false).call,
        ),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: todayEnabled
            ? const HomeShell.withTodayForTesting()
            : const HomeShell(),
      ),
    );
  }

  testWidgets('path shows real units and the next lesson', (tester) async {
    tester.view.physicalSize = const Size(390, 4800);
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

    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.text('SECTION 1, UNIT 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Up next'), 300);
    expect(find.text('Up next'), findsOneWidget);
    expect(find.text('Open Strings'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('course map lists the year and opens a unit guidebook', (
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

    await tester.tap(find.text('VIEW COURSE MAP'));
    await tester.pumpAndSettle();

    expect(find.text('COURSE MAP'), findsOneWidget);
    expect(find.text('8 sections · 40 units · 240 lessons'), findsOneWidget);
    expect(find.text('Open Strings'), findsWidgets);

    await tester.tap(find.text('Open Strings').last);
    await tester.pumpAndSettle();
    expect(find.text('UNIT 1 GUIDEBOOK'), findsOneWidget);
  });

  testWidgets('path nodes expose their 3D face and state', (tester) async {
    tester.view.physicalSize = const Size(390, 4800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    final progress = ProgressState.fresh(
      settings: const AppSettings(
        onboardingComplete: true,
        answerMode: AnswerMode.name,
      ),
    )..completedLessons.add('c3u1l1');

    await tester.pumpWidget(buildApp(progress));
    await tester.pumpAndSettle();

    final faceSize = Size(
      PathLayout.nodeSize,
      PathLayout.faceHeight,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('lesson-face-c3u1l1'))),
      faceSize,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('lesson-face-c3u1l2'))),
      faceSize,
    );
    expect(
      find.bySemanticsLabel('Lesson: Unit 1, Discover, completed'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Lesson: Unit 1, Build, current'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Lesson: Unit 1, Connect, locked'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('quests are reachable from the bottom bar and there is no shop', (
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

    expect(find.text('Shop'), findsNothing);

    await tester.tap(find.text('Quests'));
    await tester.pumpAndSettle();
    expect(find.text('Play 3 phrases'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Learn 4 bars'), 200);
    expect(find.text('Record a take'), findsOneWidget);
    expect(find.text('Learn 4 bars'), findsOneWidget);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.text('Refill hearts'), findsNothing);
    expect(find.text('Streak freeze'), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('HomeShell shows Learn when the phrase gate is closed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildShell(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
        todayEnabled: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Quests'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Shop'), findsNothing);
  });

  testWidgets('HomeShell shows Today when the phrase gate is open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildShell(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
        todayEnabled: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Learn'), findsNothing);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Quests'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Shop'), findsNothing);
  });

  testWidgets('quests fit a phone and a wide layout without overflow', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in <Size>[const Size(390, 844), const Size(1200, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
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
      await tester.tap(find.text(size.width >= 900 ? 'QUESTS' : 'Quests'));
      await tester.pumpAndSettle();
      expect(find.text('Quests'), findsWidgets);
      expect(find.text('Today'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width >= 900) {
        expect(find.byKey(const ValueKey('side-rail')), findsOneWidget);
      } else {
        expect(find.byKey(const ValueKey('side-rail')), findsNothing);
      }
    }
  });

  testWidgets('wide layouts use the side rail instead of bottom tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
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

    expect(find.byKey(const ValueKey('side-rail')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Shop'), findsNothing);
    expect(find.text('SHOP'), findsNothing);
    expect(find.text('Open Strings'), findsOneWidget);
    expect(find.text('Musical quests'), findsOneWidget);
    expect(find.text('Weekly goal'), findsOneWidget);

    // The path and the quest rail share one scrollable, like Duo.
    expect(find.byType(CustomScrollView), findsOneWidget);
    final railFinder = find.text('Musical quests');
    final nodeFinder = find.byKey(const ValueKey('current-lesson-node'));
    final railBefore = tester.getTopLeft(railFinder).dy;
    final nodeBefore = tester.getTopLeft(nodeFinder).dy;
    final bannerBefore = tester.getTopLeft(find.text('Open Strings')).dy;
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(railFinder).dy,
      closeTo(railBefore - 400, 40),
    );
    expect(
      tester.getTopLeft(nodeFinder).dy,
      closeTo(nodeBefore - 400, 40),
    );
    // The unit banner pins to the top of the shared scroll instead of scrolling
    // away with the page.
    final bannerAfter = tester.getTopLeft(find.text('Open Strings')).dy;
    expect(bannerAfter, lessThan(bannerBefore));
    expect(bannerAfter, greaterThanOrEqualTo(0));
  });

  testWidgets('selected bottom tab takes its own color', (tester) async {
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

    final learn = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
    expect(learn.color, AppColors.yellowDark);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final profile = tester.widget<Icon>(
      find.byIcon(Icons.account_circle_rounded),
    );
    expect(profile.color, AppColors.purple);
  });

  testWidgets('path fits a 320 px viewport without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
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

    expect(tester.takeException(), isNull);
    expect(find.text('Open Strings'), findsOneWidget);
    expect(find.byKey(const ValueKey('current-lesson-node')), findsOneWidget);
  });

  testWidgets('practice and profile fit a 390 px phone', (tester) async {
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

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Practice'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Technique check'), 300);
    expect(find.text('Technique check'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Guitarist'), findsOneWidget);
  });

  testWidgets('unit guidebook opens with string and fret hints', (
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

    await tester.tap(find.byIcon(Icons.menu_book_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('UNIT 1 GUIDEBOOK'), findsOneWidget);
    expect(find.textContaining('String'), findsWidgets);
  });

  testWidgets('a lesson can be answered by tapping the note name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final progress = ProgressState.fresh(
      settings: const AppSettings(
        onboardingComplete: true,
        answerMode: AnswerMode.name,
      ),
    );
    for (final lesson in sections.first.units.first.lessons) {
      progress.completedLessons.add(lesson.id);
    }
    final container = ProviderContainer(
      overrides: [
        progressStoreProvider.overrideWithValue(MemoryProgressStore(progress)),
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
    for (var guard = 0; guard < 40; guard++) {
      final run = container.read(appControllerProvider).requireValue.run!;
      final prompt = run.current;
      if (prompt is NotePrompt && prompt.isScored && !prompt.isPlay) break;
      if (prompt.isScored) {
        await notifier.submitAnswer(correct: true);
      }
      await notifier.nextExercise();
      await tester.pumpAndSettle();
    }

    final run = container.read(appControllerProvider).requireValue.run!;
    final notePrompt = run.current as NotePrompt;
    expect(find.byType(StaffView), findsOneWidget);
    expect(find.text('What note is this?'), findsOneWidget);

    await tester.tap(find.text(notePrompt.note.display).first);
    await tester.pumpAndSettle();

    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(container.read(appControllerProvider).requireValue.run, isNotNull);
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

    expect(find.text('Do you have your guitar?'), findsOneWidget);
    await tester.tap(find.text('YES, I HAVE IT'));
    await tester.pumpAndSettle();

    expect(find.text('How well do you read?'), findsOneWidget);
    await tester.tap(find.text("I'm a slow reader"));
    await tester.pumpAndSettle();

    expect(find.text('Pick a first piece'), findsOneWidget);
    await tester.tap(find.text('Greensleeves'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START PLAYING'));
    await tester.pumpAndSettle();
    final skipFirstSession = find.byKey(const ValueKey('first-session-skip'));
    if (skipFirstSession.evaluate().isNotEmpty) {
      await tester.tap(skipFirstSession);
      await tester.pumpAndSettle();
    }

    expect(find.text('Open Strings'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('playing the correct note completes a mic exercise', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final progress = ProgressState.fresh(
      settings: const AppSettings(
        onboardingComplete: true,
        answerMode: AnswerMode.mixed,
      ),
    );
    for (final lesson in sections.first.units.first.lessons) {
      progress.completedLessons.add(lesson.id);
    }
    final store = MemoryProgressStore(progress);
    final sources = FakePitchSourceFactory(permission: true);
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

    var guard = 0;
    final notifier = container.read(appControllerProvider.notifier);
    while (guard < 50) {
      guard++;
      final run = container.read(appControllerProvider).requireValue.run!;
      final prompt = run.current;
      if (prompt is NotePrompt && prompt.isPlay) break;
      if (prompt.isScored) {
        await notifier.submitAnswer(correct: true);
      }
      await notifier.nextExercise();
      await tester.pumpAndSettle();
    }

    final run = container.read(appControllerProvider).requireValue.run!;
    final playPrompt = run.current as NotePrompt;
    expect(playPrompt.isPlay, isTrue);
    expect(run.current.usesMicrophone, isTrue);
    expect(sources.created.length, greaterThanOrEqualTo(2));
    final source = sources.created.last;
    expect(source.started, isTrue);

    final frequency = midiToFrequency(
      Guitar.soundingMidiForWritten(playPrompt.note).toDouble(),
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
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(
      sounds.played.any(
        (sound) =>
            sound == Sfx.answerCorrect || sound == Sfx.answerCorrectCombo,
      ),
      isTrue,
    );
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
