import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/skill.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/home_shell.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

const _phone = Size(390, 844);
const _wide = Size(1200, 900);

ProgressState _freshProgress() => ProgressState.fresh(
  settings: const AppSettings(
    onboardingComplete: true,
    answerMode: AnswerMode.name,
  ),
);

Widget _buildApp(MemoryProgressStore store) {
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
    child: const HearMeOutApp(),
  );
}

Widget _buildShell(MemoryProgressStore store, {required bool todayEnabled}) {
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

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  group('Reading Lab preserves the original course', () {
    test('still has 8 sections, 40 units, and the same 240 lesson ids', () {
      expect(sections, hasLength(8));
      expect(curriculum, hasLength(40));
      expect(allLessons, hasLength(240));

      final unitIds = [for (var unit = 1; unit <= 40; unit++) 'c3u$unit'];
      expect(curriculum.map((unit) => unit.id).toList(), unitIds);

      final lessonIds = [
        for (final unit in unitIds)
          for (var lesson = 1; lesson <= 6; lesson++) '${unit}l$lesson',
      ];
      expect(allLessons.map((lesson) => lesson.id).toList(), lessonIds);
      expect(allLessons.map((lesson) => lesson.id).toSet(), hasLength(240));

      expect(allLessons.first.id, 'c3u1l1');
      expect(allLessons.first.title, 'Discover');
      expect(allLessons.last.id, 'c3u40l6');
      expect(allLessons.last.isReview, isTrue);
    });
  });

  testWidgets('Profile opens the Reading Lab and keeps existing progress', (
    tester,
  ) async {
    _setSize(tester, _phone);
    final now = DateTime.now();
    final progress = _freshProgress()..completedLessons.add('c3u1l1');
    progress.addXp(70, now);
    progress.recordPracticeSeconds(180, now);
    progress.recordSkillAnswer(
      SkillAnswer(
        objectiveId: 'note:E4',
        family: SkillFamily.noteReading,
        outcome: AttemptOutcome.correct,
        now: now,
      ),
    );
    final store = MemoryProgressStore(progress);
    await tester.pumpWidget(_buildApp(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reading-lab-card')), findsOneWidget);
    expect(find.text('Reading Lab'), findsOneWidget);
    expect(find.text('Structured reading practice, optional'), findsOneWidget);
    expect(find.text('1 of 240 lessons'), findsOneWidget);
    // The Today loop is behind the closed gate, so the gate-off copy must not
    // promise it.
    expect(find.textContaining('self-paced reading practice'), findsOneWidget);
    expect(find.textContaining('5-minute Today loop'), findsNothing);

    await tester.ensureVisible(find.text('OPEN READING LAB'));
    await tester.pump();
    await tester.tap(find.text('OPEN READING LAB'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reading-lab-screen')), findsOneWidget);
    expect(find.text('READING LAB'), findsOneWidget);
    expect(find.text('1 / 240 lessons'), findsOneWidget);
    // The lab route owns the Reading Lab label; the path card does not repeat it.
    expect(find.textContaining('Optional · Lesson'), findsNothing);
    // The next lesson is the second one; the completed lesson is untouched.
    expect(find.text('Next: Build'), findsOneWidget);

    final saved = store.value!;
    expect(saved.completedLessons, contains('c3u1l1'));
    expect(saved.completedLessons, hasLength(1));
    expect(saved.xp, 70);
    expect(saved.skillProgressFor('note:E4')!.box, 1);
    expect(saved.weeklyPracticeMinutes(now), 3);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reading-lab-screen')), findsNothing);
    expect(find.byKey(const ValueKey('reading-lab-card')), findsOneWidget);
  });

  testWidgets('with the Today gate closed, Learn is still the full path', (
    tester,
  ) async {
    _setSize(tester, _phone);
    final store = MemoryProgressStore(_freshProgress());
    await tester.pumpWidget(_buildShell(store, todayEnabled: false));
    await tester.pumpAndSettle();

    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    // The path itself is labelled as the Reading Lab, and no duplicate entry
    // is needed on the course home.
    expect(find.text('READING LAB'), findsOneWidget);
    expect(find.byKey(const ValueKey('reading-lab-entry')), findsNothing);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('GOT IT'), findsOneWidget);
  });

  testWidgets('with the Today gate open, Today shows the Reading Lab entry', (
    tester,
  ) async {
    _setSize(tester, _phone);
    final store = MemoryProgressStore(_freshProgress());
    await tester.pumpWidget(_buildShell(store, todayEnabled: true));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    final entry = find.byKey(const ValueKey('reading-lab-entry'));
    expect(entry, findsOneWidget);

    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reading-lab-screen')), findsOneWidget);
    expect(find.text('SECTION 1, UNIT 1'), findsOneWidget);
  });

  testWidgets('the in-plan Reading Lab control opens the lab, not Practice', (
    tester,
  ) async {
    _setSize(tester, _phone);
    final store = MemoryProgressStore(_freshProgress());
    await tester.pumpWidget(_buildShell(store, todayEnabled: true));
    await tester.pumpAndSettle();

    await _tapKey(tester, 'today-session-start');
    await tester.pumpAndSettle();
    for (var block = 0; block <= 2; block++) {
      await _tapKey(tester, 'today-block-action-$block');
      await tester.pumpAndSettle();
    }

    final inPlan = find.text('OPEN READING LAB');
    expect(inPlan, findsOneWidget);
    await tester.ensureVisible(inPlan);
    await tester.pumpAndSettle();
    await tester.tap(inPlan);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reading-lab-screen')), findsOneWidget);
    expect(find.text('SECTION 1, UNIT 1'), findsOneWidget);
  });

  testWidgets('opening the lab from Today pauses the session', (tester) async {
    _setSize(tester, _phone);
    final store = MemoryProgressStore(_freshProgress());
    await tester.pumpWidget(_buildShell(store, todayEnabled: true));
    await tester.pumpAndSettle();

    await _tapKey(tester, 'today-session-start');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-session-pause')), findsOneWidget);

    final entry = find.byKey(const ValueKey('reading-lab-entry'));
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reading-lab-screen')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-session-resume')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-session-pause')), findsNothing);
  });

  testWidgets(
    'the Reading Lab has no loss economy and can browse a later unit',
    (tester) async {
      _setSize(tester, _phone);
      final store = MemoryProgressStore(_freshProgress());
      await tester.pumpWidget(_buildApp(store));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('OPEN READING LAB'));
      await tester.pump();
      await tester.tap(find.text('OPEN READING LAB'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byIcon(Icons.diamond_rounded), findsNothing);
      expect(find.text('Refill hearts'), findsNothing);
      expect(find.text('Streak freeze'), findsNothing);
      expect(find.textContaining('XP'), findsNothing);

      // No "finish every earlier lesson" gate: the course map opens any unit's
      // guidebook, so a learner can choose a section and leave.
      await tester.tap(find.text('VIEW COURSE MAP'));
      await tester.pumpAndSettle();
      expect(find.text('COURSE MAP'), findsOneWidget);

      final sheetScroll = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );
      expect(sheetScroll, findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Open Major Chords'),
        300,
        scrollable: sheetScroll.first,
      );
      await tester.ensureVisible(find.text('Open Major Chords'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Major Chords'));
      await tester.pumpAndSettle();
      expect(find.text('UNIT 16 GUIDEBOOK'), findsOneWidget);
    },
  );

  testWidgets('the Reading Lab fits a phone and a wide layout', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [_phone, _wide]) {
      // Drop the previous tree so a pushed route cannot survive the resize.
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_buildApp(MemoryProgressStore(_freshProgress())));
      await tester.pumpAndSettle();

      if (size.width >= 900) {
        expect(find.byKey(const ValueKey('side-rail')), findsOneWidget);
        await tester.tap(find.text('PROFILE'));
      } else {
        expect(find.byKey(const ValueKey('side-rail')), findsNothing);
        await tester.tap(find.text('Profile'));
      }
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('reading-lab-card')), findsOneWidget);
      await tester.ensureVisible(find.text('OPEN READING LAB'));
      await tester.pump();
      await tester.tap(find.text('OPEN READING LAB'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('reading-lab-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width >= 900) {
        expect(find.byKey(const ValueKey('learn-rail')), findsOneWidget);
        // The header title sits on the same left edge as the path card.
        final header = find.byKey(const ValueKey('reading-lab-header-title'));
        final cardTitle = find.textContaining('Next: ');
        // The header title sits on the same left edge as the path card's text
        // (the card's 2 px border is the only difference).
        expect(
          tester.getTopLeft(header).dx,
          moreOrLessEquals(tester.getTopLeft(cardTitle).dx, epsilon: 3),
        );
      } else {
        expect(find.byKey(const ValueKey('learn-rail')), findsNothing);
      }
    }
  });
}
