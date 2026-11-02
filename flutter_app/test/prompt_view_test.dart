import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/objective.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/learning/verifier.dart';
import 'package:hear_me_out/core/music/chords.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/rhythm.dart';
import 'package:hear_me_out/features/exercises/fret_tap_view.dart';
import 'package:hear_me_out/features/exercises/prompt_view.dart';
import 'package:hear_me_out/features/exercises/staff_tap_view.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  Answer? captured;

  Widget host(Prompt prompt) {
    captured = null;
    return ProviderScope(
      overrides: [
        soundServiceProvider.overrideWithValue(FakeSoundService()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PromptView(
              prompt: prompt,
              onAnswer: (answer) => captured = answer,
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // A 390 x 844 phone, the design target.
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  test('staff geometry puts each note on its line', () {
    expect(StaffTapView.yFor(30), StaffTapView.lineY(4));
    expect(StaffTapView.yFor(34), StaffTapView.lineY(2));
    expect(StaffTapView.yFor(38), StaffTapView.lineY(0));
    expect(StaffTapView.yFor(28), StaffTapView.ledgerY);
  });

  testWidgets('staff placement fits a phone and reports the tapped step', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const StaffTapPrompt(
          objective: ObjectiveRef(
            'note:E4',
            family: SkillFamily.noteReading,
          ),
          templateId: 'note.place',
          note: Note('E', 4),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('E4'), findsOneWidget);
    expect(find.textContaining('Tap the line'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('staff-step-30')));
    await tester.pumpAndSettle();
    expect(captured, isA<StaffAnswer>());
    expect((captured! as StaffAnswer).diatonicIndex, 30);
  });

  testWidgets('fret finding fits a phone and reports string and fret', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FretTapPrompt(
          objective: ObjectiveRef('note:E4', family: SkillFamily.noteReading),
          templateId: 'note.fretboard',
          note: Note('E', 4),
          maxFret: 4,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tap the string'), findsOneWidget);
    // Written E4 sounds E3: D string, fret 2.
    await tester.tap(find.byKey(const ValueKey('fret-4-2')));
    await tester.pumpAndSettle();
    expect(captured, isA<FretAnswer>());
    expect((captured! as FretAnswer).string, 4);
    expect((captured! as FretAnswer).fret, 2);
  });

  testWidgets('the neck hides the answer until the learner taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FretTapPrompt(
          objective: ObjectiveRef('note:E4', family: SkillFamily.noteReading),
          templateId: 'note.fretboard',
          note: Note('E', 4),
          maxFret: 4,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<FretTapView>(find.byType(FretTapView)).positions, isEmpty);

    await tester.tap(find.byKey(const ValueKey('fret-4-2')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<FretTapView>(find.byType(FretTapView)).positions,
      isNotEmpty,
    );
  });

  testWidgets('a chord question shows a diagram and its options', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        ChoicePrompt(
          objective: const ObjectiveRef('chord:G', family: SkillFamily.harmony),
          templateId: 'harmony.ask',
          question: 'Which chord is this shape?',
          options: const [
            ChoiceOption('a', 'G'),
            ChoiceOption('b', 'C'),
            ChoiceOption('c', 'D'),
          ],
          correctId: 'a',
          chord: chordById['G'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChordDiagram), findsOneWidget);
    expect(find.text('Which chord is this shape?'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);

    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(captured, isA<ChoiceAnswer>());
    expect((captured! as ChoiceAnswer).optionId, 'b');
  });

  testWidgets('a rhythm question fits a phone and can be started', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const RhythmPrompt(
          objective: ObjectiveRef('rhythm:quarters', family: SkillFamily.rhythm),
          templateId: 'rhythm.tap',
          pattern: fourQuarters,
          question: 'Tap the rhythm',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tap the rhythm'), findsOneWidget);
    expect(find.text('4 beats at 80 BPM'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pump();
    expect(find.text('Count in…'), findsOneWidget);
    await tester.tap(find.text('Count in…'));
    await tester.pump(const Duration(milliseconds: 50));
  });
}
