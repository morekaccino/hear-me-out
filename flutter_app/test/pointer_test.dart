import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

Widget buildApp({
  required Size size,
  required WidgetTester tester,
}) {
  tester.view.physicalSize = size;
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

MouseCursor? cursorFor(WidgetTester tester, String label) {
  final regions = find.ancestor(
    of: find.text(label),
    matching: find.byType(MouseRegion),
  );
  if (regions.evaluate().isEmpty) return null;
  return tester.widget<MouseRegion>(regions.first).cursor;
}

void main() {
  testWidgets('the side rail items use a pointer cursor', (tester) async {
    await tester.pumpWidget(buildApp(size: const Size(1200, 900), tester: tester));
    await tester.pumpAndSettle();

    expect(cursorFor(tester, 'PRACTICE'), SystemMouseCursors.click);
    expect(cursorFor(tester, 'LEARN'), SystemMouseCursors.click);
  });

  testWidgets('the bottom tabs use a pointer cursor', (tester) async {
    await tester.pumpWidget(buildApp(size: const Size(390, 844), tester: tester));
    await tester.pumpAndSettle();

    expect(cursorFor(tester, 'Practice'), SystemMouseCursors.click);
    expect(cursorFor(tester, 'Learn'), SystemMouseCursors.click);
  });

  testWidgets('only the selected rail item wears its colour', (tester) async {
    await tester.pumpWidget(
      buildApp(size: const Size(1200, 900), tester: tester),
    );
    await tester.pumpAndSettle();

    Icon iconFor(String label) => tester.widget<Icon>(
      find
          .descendant(
            of: find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(MouseRegion),
                )
                .first,
            matching: find.byType(Icon),
          )
          .first,
    );

    // Learn is selected by default; Practice is not.
    expect(iconFor('LEARN').color, isNot(AppColors.textMuted));
    expect(iconFor('PRACTICE').color, AppColors.textMuted);
  });

  testWidgets('hovering a rail item changes its background', (tester) async {
    await tester.pumpWidget(buildApp(size: const Size(1200, 900), tester: tester));
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle();

    await gesture.moveTo(tester.getCenter(find.text('PRACTICE')));
    await tester.pumpAndSettle();

    // The hovered rail item paints a surface-coloured pill behind the row.
    final decorated = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.ancestor(
              of: find.text('PRACTICE'),
              matching: find.byType(MouseRegion),
            ).first,
            matching: find.byType(AnimatedContainer),
          ),
        )
        .toList();
    expect(decorated, isNotEmpty);
    final box = decorated.first.decoration! as BoxDecoration;
    expect(box.color, isNotNull);
    expect(box.color, isNot(Colors.transparent));
  });
}
